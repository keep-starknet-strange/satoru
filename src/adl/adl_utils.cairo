//! Library to help with auto-deleveraging.
//! This is particularly for markets with an index token that is different from
//! the long token.
//!
//! For example, if there is a DOGE / USD perp market with ETH as the long token
//! it would be possible for the price of DOGE to increase faster than the price of
//! ETH.
//!
//! In this scenario, profitable positions should be closed through ADL to ensure
//! that the system remains fully solvent.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use result::ResultTrait;
use starknet::ContractAddress;

// Local imports.
use satoru::chain::chain::{IChainSafeDispatcher, IChainSafeDispatcherTrait};
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::data::keys;
use satoru::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use satoru::market::{market::Market, market_utils};
use satoru::oracle::oracle::{IOracleSafeDispatcher, IOracleSafeDispatcherTrait};
use satoru::position::position_utils;
use satoru::utils::arrays::are_gte;


/// CreateAdlOrderParams struct used in createAdlOrder to avoid stack
#[derive(Drop, Copy, starknet::Store, Serde)]
struct CreateAdlOrderParams {
    /// `DataStore` contract dispatcher.
    data_store: IDataStoreSafeDispatcher,
    /// `EventEmitter` contract dispatcher.
    event_emitter: IEventEmitterSafeDispatcher,
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
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    oracle: IOracleSafeDispatcher,
    market_address: ContractAddress,
    is_long: bool,
    max_oracle_block_numbers: Span<u128>,
    chain: IChainSafeDispatcher,
) {
    let latest_adl_block = get_latest_adl_block(data_store, market_address, is_long);
    assert(are_gte(max_oracle_block_numbers, latest_adl_block), 'block numbers smaller than req');

    let market: Market = data_store.get_market(market_address.into()).unwrap().unwrap();
    let prices: market_utils::MarketPrices = market_utils::get_market_prices(oracle, market);
    // if the MAX_PNL_FACTOR_FOR_ADL is set to be higher than MAX_PNL_FACTOR_FOR_WITHDRAWALS
    // it is possible for a pool to be in a state where withdrawals and ADL is not allowed
    // this is similar to the case where there is a large amount of open positions relative
    // to the amount of tokens in the pool
    let (should_enable_adl, pnl_to_pool_factor, max_pnl_factor) =
        market_utils::is_pnl_factor_exceeded_(
        data_store, market, @prices, is_long, keys::max_pnl_factor()
    );
    set_adl_enabled(data_store, market_address, is_long, should_enable_adl);
    // the latest ADL block is always updated, an ADL keeper could continually
    // cause the latest ADL block to be updated and prevent ADL orders
    // from being executed, however, this may be preferrable over a case
    // where stale prices could be used by ADL keepers to execute orders
    // as such updating of the ADL block is allowed and it is expected
    // that ADL keepers will keep this block updated so that latest prices
    // will be used for ADL
    set_latest_adl_block(data_store, market_address, is_long, chain.get_block_number().unwrap());

    event_emitter
        .emit_adl_state_updated(
            market_address, is_long, pnl_to_pool_factor, max_pnl_factor, should_enable_adl
        );
}

/// Construct an ADL order, a decrease order is used to reduce a profitable position.
/// # Arguments
/// * `CreateAdlOrderParams` - The struct used to create an ADL order.
/// # Returns
/// Return the key of the created order.
fn create_adl_order(params: CreateAdlOrderParams) -> felt252 {
    0
}

/// Validate if the requested ADL can be executed.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Address of the market to check.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// * `max_oracle_block_numbers` - The oracle block numbers for the prices stored in the oracle.
fn validate_adl(
    data_store: IDataStoreSafeDispatcher,
    market: ContractAddress,
    is_long: bool,
    mut max_oracle_block_numbers: Span<u128>
) {
    let is_adl_enabled = get_adl_enabled(data_store, market, is_long);
    assert(is_adl_enabled, 'adl not enabled');

    let latest_adl_block = get_latest_adl_block(data_store, market, is_long);

    let mut len = max_oracle_block_numbers.len();
    loop {
        if len == 0 {
            break;
        }
        let block_number = max_oracle_block_numbers.pop_front().unwrap();
        assert(*block_number >= latest_adl_block, 'block # smaller than req');
        len -= 1;
    };
}

/// Get the latest block at which the ADL flag was updated.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Address of the market to check.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// # Returns
/// Return the latest block at which the ADL flag was updated.
fn get_latest_adl_block(
    data_store: IDataStoreSafeDispatcher, market: ContractAddress, is_long: bool
) -> u128 {
    data_store.get_u128(keys::latest_adl_block_key(market, is_long)).unwrap()
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
    data_store: IDataStoreSafeDispatcher, market: ContractAddress, is_long: bool, value: u64
) {
    data_store.set_u128(keys::latest_adl_block_key(market, is_long), value.into()).unwrap();
}

/// Get whether ADL is enabled.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Address of the market to check.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// # Returns
/// Return whether ADL is enabled.
fn get_adl_enabled(
    data_store: IDataStoreSafeDispatcher, market: ContractAddress, is_long: bool
) -> bool {
    data_store.get_bool(keys::is_adl_enabled_key(market, is_long)).unwrap().unwrap()
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
    data_store: IDataStoreSafeDispatcher, market: ContractAddress, is_long: bool, value: bool
) {
    data_store.set_bool(keys::is_adl_enabled_key(market, is_long), value).unwrap()
}

/// Emit ADL state update events.
/// # Arguments
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `market` - Address of the market to check.
/// * `is_long` - Indicates the ADL state update is for the long or short side of the market.
/// * `pnt_to_pool_factor` - The ratio of PnL to pool value.
/// * `max_pnl_factor` - The max PnL factor.
/// * `should_enable_adl` - Whether ADL was enabled or disabled.
fn emit_adl_state_updated(
    event_emitter: IEventEmitterSafeDispatcher,
    market: ContractAddress,
    is_long: bool,
    pnt_to_pool_factor: i128,
    max_pnl_factor: u128,
    should_enable_adl: bool
) { // TODO
}
