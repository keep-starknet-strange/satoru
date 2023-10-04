//! Library to help with auto-deleveraging.
//! This is particularly for markets with an index token that is different from
//! the long token.
//!
//! For example, if there is a STRK / USD perp market with ETH as the long token
//! it would be possible for the price of STRK to increase faster than the price of
//! ETH.
//!
//! In this scenario, profitable positions should be closed through ADL to ensure
//! that the system remains fully solvent.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{get_caller_address, ContractAddress, contract_address_const};
use integer::BoundedInt;
// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::{event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait},};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::market::market_utils::{
    MarketPrices, get_enabled_market, get_market_prices, is_pnl_factor_exceeded_direct
};
use satoru::adl::error::AdlError;
use satoru::data::keys;
use satoru::utils::arrays::u64_are_gte;
use satoru::position::position_utils;
use satoru::position::position::Position;
use satoru::order::order::{Order, OrderType, DecreasePositionSwapType};
use satoru::nonce::nonce_utils;
use satoru::callback::callback_utils::get_saved_callback_contract;
use satoru::utils::span32::{Span32, Array32Trait};
/// CreateAdlOrderParams struct used in createAdlOrder to avoid stack
#[derive(Drop, Copy, starknet::Store, Serde)]
struct CreateAdlOrderParams {
    /// `DataStore` contract dispatcher.
    data_store: IDataStoreDispatcher,
    /// `EventEmitter` contract dispatcher.
    event_emitter: IEventEmitterDispatcher,
    /// The account to reduce the position.
    account: ContractAddress,
    /// The position's market.
    market: ContractAddress,
    /// The position's collateral_token.
    collateral_token: ContractAddress,
    /// Whether the position is long or short.
    is_long: bool,
    /// The size to reduce the position by.
    size_delta_usd: u128,
    /// The block to set the order's updated_at_block.
    updated_at_block: u64,
}

/// Multiple positions may need to be reduced to ensure that the pending
/// profits do not exceed the allowed thresholds.
///
/// This automatic reduction of positions can only be done if the pool is in a state
/// where auto-deleveraging is required.
///
/// This function checks the pending profit state and updates an isAdlEnabled
/// flag to avoid having to repeatedly validate whether auto-deleveraging is required.
///
/// Once the pending profit has been reduced below the threshold this function can
/// be called again to clear the flag.
///
/// The ADL check would be possible to do in AdlHandler.executeAdl as well
/// but with that order keepers could use stale oracle prices to prove that
/// an ADL state is possible.
///
/// Having this function allows any order keeper to disable ADL if prices
/// have updated such that ADL is no longer needed.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `oracle` - The `Oracle` contract dispatcher.
/// * `market` - Address of the market to check.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// * `max_oracle_block_numbers` - The oracle block numbers for the prices stored in the oracle.
/// # Returns
/// Return felt252 hash using the next nonce value

fn update_adl_state(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    oracle: IOracleDispatcher,
    market: ContractAddress,
    is_long: bool,
    max_oracle_block_numbers: Span<u64>
) {
    let latest_adl_block = get_latest_adl_block(data_store, market, is_long);
    assert(
        u64_are_gte(max_oracle_block_numbers, latest_adl_block),
        AdlError::ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED
    );
    let _market = get_enabled_market(data_store, market);
    let prices: MarketPrices = get_market_prices(oracle, _market);
    // if the MAX_PNL_FACTOR_FOR_ADL is set to be higher than MAX_PNL_FACTOR_FOR_WITHDRAWALS
    // it is possible for a pool to be in a state where withdrawals and ADL is not allowed
    // this is similar to the case where there is a large amount of open positions relative
    // to the amount of tokens in the pool
    let (should_enable_adl, pnl_to_pool_factor, max_pnl_factor) = is_pnl_factor_exceeded_direct(
        data_store, _market, prices, is_long, keys::max_pnl_factor_for_adl()
    );
    set_adl_enabled(data_store, market, is_long, should_enable_adl);
    // the latest ADL block is always updated, an ADL keeper could continually
    // cause the latest ADL block to be updated and prevent ADL orders
    // from being executed, however, this may be preferrable over a case
    // where stale prices could be used by ADL keepers to execute orders
    // as such updating of the ADL block is allowed and it is expected
    // that ADL keepers will keep this block updated so that latest prices
    // will be used for ADL
    set_latest_adl_block(data_store, market, is_long, starknet::info::get_block_number());

    emit_adl_state_updated(
        event_emitter, market, is_long, pnl_to_pool_factor, max_pnl_factor, should_enable_adl
    );
}

/// Construct an ADL order, a decrease order is used to reduce a profitable position.
/// # Arguments
/// * `CreateAdlOrderParams` - The struct used to create an ADL order.
/// # Returns
/// Return the key of the created order.
fn create_adl_order(params: CreateAdlOrderParams) -> felt252 {
    let positon_key = position_utils::get_position_key(
        params.account, params.market, params.collateral_token, params.is_long
    );
    let position_result = params.data_store.get_position(positon_key);
    let mut position: Position = Default::default();

    // Check if the position is valid
    match position_result {
        Option::Some(pos) => {
            assert(params.size_delta_usd <= pos.size_in_usd, AdlError::INVALID_SIZE_DELTA_FOR_ADL);
            position = pos;
        },
        Option::None => {
            panic_with_felt252(AdlError::POSTION_NOT_VALID);
        }
    }

    // no slippage is set for this order, it may be preferrable for ADL orders
    // to be executed, in case of large price impact, the user could be refunded
    // through a protocol fund if required, this amount could later be claimed
    // from the price impact pool, this claiming process should be added if
    // required
    //
    // setting a maximum price impact that will work for majority of cases
    // may also be challenging since the price impact would vary based on the
    // amount of collateral being swapped
    //
    // note that the decreasePositionSwapType should be SwapPnlTokenToCollateralToken
    // because fees are calculated with reference to the collateral token
    // fees are deducted from the output amount if the output token is the same as the
    // collateral token
    // swapping the pnl token to the collateral token helps to ensure fees can be paid
    // using the realized profit

    let acceptable_price_: u128 = if position.is_long {
        0_u128
    } else {
        BoundedInt::max()
    };
    let key = nonce_utils::get_next_key(params.data_store);
    let order = Order {
        key: key,
        order_type: OrderType::MarketDecrease,
        decrease_position_swap_type: DecreasePositionSwapType::SwapPnlTokenToCollateralToken,
        account: params.account,
        receiver: params.account,
        callback_contract: get_saved_callback_contract(
            params.data_store, params.account, params.market
        ),
        ui_fee_receiver: contract_address_const::<0>(),
        market: params.market,
        initial_collateral_token: position.collateral_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        size_delta_usd: params.size_delta_usd,
        initial_collateral_delta_amount: 0,
        trigger_price: 0,
        acceptable_price: acceptable_price_,
        execution_fee: 0,
        callback_gas_limit: params
            .data_store
            .get_felt252(keys::max_callback_gas_limit())
            .try_into()
            .expect('get_felt252 into u128 failed'),
        min_output_amount: 0,
        updated_at_block: params.updated_at_block,
        is_long: position.is_long,
        is_frozen: false,
    };
    params.data_store.set_order(key, order);
    params.event_emitter.emit_order_created(key, order);
    key
}


/// Validate if the requested ADL can be executed.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Address of the market to check.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// * `max_oracle_block_numbers` - The oracle block numbers for the prices stored in the oracle.
fn validate_adl(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    is_long: bool,
    max_oracle_block_numbers: Span<u64>
) {
    let is_adl_enabled = get_adl_enabled(data_store, market, is_long);
    assert(is_adl_enabled, AdlError::ADL_NOT_ENABLED);
    let latest_block = get_latest_adl_block(data_store, market, is_long);
    assert(
        u64_are_gte(max_oracle_block_numbers, latest_block),
        AdlError::ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED
    );
}

/// Get the latest block at which the ADL flag was updated.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Address of the market to check.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// # Returns
/// Return the latest block at which the ADL flag was updated.
fn get_latest_adl_block(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u64 {
    data_store
        .get_u128(keys::latest_adl_block_key(market, is_long))
        .try_into()
        .expect('get_u128 into u64 failed')
}

/// Set the latest block at which the ADL flag was updated.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Address of the market to check.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// * `value` - The latest block number value.
/// # Returns
/// Return the latest block number value.
fn set_latest_adl_block(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool, value: u64
) -> u64 {
    data_store.set_u128(keys::latest_adl_block_key(market, is_long), value.into());
    value
}

/// Get whether ADL is enabled.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Address of the market to check.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// # Returns
/// Return whether ADL is enabled.
fn get_adl_enabled(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> bool { // TODO
    let result = data_store.get_bool(keys::is_adl_enabled_key(market, is_long));
    match result {
        Option::Some(data) => {
            return data;
        },
        Option::None => {
            return false;
        }
    }
}

/// Set whether ADL is enabled.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Address of the market to check.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// * `value` - Whether ADL is enabled.
/// # Returns
/// Return whether ADL is enabled.
fn set_adl_enabled(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool, value: bool
) -> bool {
    data_store.set_bool(keys::is_adl_enabled_key(market, is_long), value);
    value
}

/// Emit ADL state update events.
/// # Arguments
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `market` - Address of the market to check.
/// * `is_long` - Indicates the ADL state update is for the long or short side of the market.
/// * `pnl_to_pool_factor` - The ratio of PnL to pool value.
/// * `max_pnl_factor` - The max PnL factor.
/// * `should_enable_adl` - Whether ADL was enabled or disabled.
fn emit_adl_state_updated(
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    is_long: bool,
    pnl_to_pool_factor: i128,
    max_pnl_factor: u128,
    should_enable_adl: bool
) {
    event_emitter
        .emit_adl_state_updated(
            market, is_long, pnl_to_pool_factor.into(), max_pnl_factor, should_enable_adl,
        );
}
