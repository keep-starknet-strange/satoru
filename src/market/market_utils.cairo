// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, get_block_timestamp};
use result::ResultTrait;

use debug::PrintTrait;
use zeroable::Zeroable;

// Local imports.
use satoru::utils::calc::roundup_magnitude_division;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::chain::chain::{IChainDispatcher, IChainDispatcherTrait};
use satoru::chain::chain::Chain;
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::keys;
use satoru::market::{
    market::Market, error::MarketError, market_pool_value_info::MarketPoolValueInfo,
    market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait}
};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::oracle::oracle::{Oracle, SetPricesParams};
use satoru::oracle::oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait};
use satoru::price::price::{Price, PriceTrait};
use satoru::utils::calc;
use satoru::utils::span32::Span32;
use satoru::utils::i128::{StoreI128, u128_to_i128, I128Serde, I128Div, I128Mul};
use satoru::utils::precision::{FLOAT_PRECISION, FLOAT_PRECISION_SQRT};
use satoru::utils::precision::{mul_div_roundup, to_factor_ival, apply_factor_u128};
use satoru::utils::calc::{roundup_division};
use satoru::position::position::Position;
use satoru::utils::i128::I128Default;
use integer::u128_to_felt252;

/// Struct to store the prices of tokens of a market.
/// # Params
/// * `indexTokenPrice` - Price of the market's index token.
/// * `tokens` - Price of the market's long token.
/// * `compacted_oracle_block_numbers` - Price of the market's short token.
/// Struct to store the prices of tokens of a market
#[derive(Default, Drop, Copy, starknet::Store, Serde)]
struct MarketPrices {
    index_token_price: Price,
    long_token_price: Price,
    short_token_price: Price,
}


#[derive(Drop, starknet::Store, Serde)]
struct CollateralType {
    long_token: u128,
    short_token: u128,
}

#[derive(Drop, starknet::Store, Serde)]
struct PositionType {
    long: CollateralType,
    short: CollateralType,
}

#[derive(Drop, starknet::Store, Serde)]
struct GetNextFundingAmountPerSizeResult {
    longs_pay_shorts: bool,
    funding_factor_per_second: u128,
    funding_fee_amount_per_size_delta: PositionType,
    claimable_funding_amount_per_size_delta: PositionType,
}

// @dev get the token price from the stored MarketPrices
// @param token the token to get the price for
// @param the market values
// @param the market token prices
// @return the token price from the stored MarketPrices
fn get_cached_token_price(token: ContractAddress, market: Market, prices: MarketPrices) -> Price {
    if (token == market.long_token) {
        prices.long_token_price
    } else if (token == market.short_token) {
        prices.short_token_price
    } else if (token == market.index_token) {
        prices.index_token_price
    } else {
        MarketError::UNABLE_TO_GET_CACHED_TOKEN_PRICE(token);
        prices.index_token_price //todo : remove 
    }
}

/// Get the long and short open interest for a market based on the collateral token used.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to get the open interest for.
/// * `collateral_token` - The collateral token to check.
/// * `is_long` - Whether to get the long or short open interest.
/// * `divisor` - The divisor to use for the open interest.
fn get_open_interest(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    divisor: u128
) -> u128 {
    assert(divisor != 0, MarketError::DIVISOR_CANNOT_BE_ZERO);
    let key = keys::open_interest_key(market, collateral_token, is_long);
    data_store.get_u128(key) / divisor
}

/// Get the long and short open interest for a market.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to get the open interest for.
/// # Returns
/// The long and short open interest for a market.
fn get_open_interest_for_market(data_store: IDataStoreDispatcher, market: @Market) -> u128 {
    // Get the open interest for the long token as collateral.
    let long_open_interest = get_open_interest_for_market_is_long(data_store, market, true);
    // Get the open interest for the short token as collateral.
    let short_open_interest = get_open_interest_for_market_is_long(data_store, market, false);
    long_open_interest + short_open_interest
}

/// Get the long and short open interest for a market.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to get the open interest for.
/// * `is_long` - Whether to get the long or short open interest.
/// # Returns
/// The long and short open interest for a market.
fn get_open_interest_for_market_is_long(
    data_store: IDataStoreDispatcher, market: @Market, is_long: bool
) -> u128 {
    // Get the pool divisor.
    let divisor = get_pool_divisor(*market.long_token, *market.short_token);
    // Get the open interest for the long token as collateral.
    let open_interest_using_long_token_as_collateral = get_open_interest(
        data_store, *market.market_token, *market.long_token, is_long, divisor
    );
    // Get the open interest for the short token as collateral.
    let open_interest_using_short_token_as_collateral = get_open_interest(
        data_store, *market.market_token, *market.short_token, is_long, divisor
    );
    // Return the sum of the open interests.
    open_interest_using_long_token_as_collateral + open_interest_using_short_token_as_collateral
}


/// Get the long and short open interest in tokens for a market.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to get the open interest for.
/// * `is_long` - Whether to get the long or short open interest.
/// # Returns
/// The long and short open interest in tokens for a market based on the collateral token used.
fn get_open_interest_in_tokens_for_market(
    data_store: IDataStoreDispatcher, market: @Market, is_long: bool,
) -> u128 {
    // Get the pool divisor.
    let divisor = get_pool_divisor(*market.long_token, *market.short_token);

    // Get the open interest for the long token as collateral.
    let open_interest_using_long_token_as_collateral = get_open_interest_in_tokens(
        data_store, *market.market_token, *market.long_token, is_long, divisor
    );
    // Get the open interest for the short token as collateral.
    let open_interest_using_short_token_as_collateral = get_open_interest_in_tokens(
        data_store, *market.market_token, *market.short_token, is_long, divisor
    );
    // Return the sum of the open interests.
    open_interest_using_long_token_as_collateral + open_interest_using_short_token_as_collateral
}

/// Get the long and short open interest in tokens for a market based on the collateral token used.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to get the open interest for.
/// * `collateral_token` - The collateral token to check.
/// * `is_long` - Whether to get the long or short open interest.
/// * `divisor` - The divisor to use for the open interest.
/// # Returns
/// The long and short open interest in tokens for a market based on the collateral token used.
fn get_open_interest_in_tokens(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    divisor: u128
) -> u128 {
    data_store.get_u128(keys::open_interest_in_tokens_key(market, collateral_token, is_long))
        / divisor
}

/// Get the amount of tokens in the pool
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to check.
/// * `token_address` - The token to check.
/// # Returns
/// The amount of tokens in the pool.
fn get_pool_amount(
    data_store: IDataStoreDispatcher, market: @Market, token_address: ContractAddress
) -> u128 {
    let divisor = get_pool_divisor(*market.long_token, *market.short_token);
    data_store.get_u128(keys::pool_amount_key(*market.market_token, token_address)) / divisor
}

/// Get the maximum amount of tokens allowed to be in the pool.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market_address` - The market to check.
/// * `token_address` - The token to check.
/// # Returns
/// The maximum amount of tokens allowed to be in the pool.
fn get_max_pool_amount(
    data_store: IDataStoreDispatcher,
    market_address: ContractAddress,
    token_address: ContractAddress
) -> u128 {
    data_store.get_u128(keys::max_pool_amount_key(market_address, token_address))
}

/// Get the maximum open interest allowed for a market.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market_address` - The market to check.
/// * `is_long` - Whether this is for the long or short side.
/// # Returns
/// The maximum open interest allowed for a market.
fn get_max_open_interest(
    data_store: IDataStoreDispatcher, market_address: ContractAddress, is_long: bool
) -> u128 {
    data_store.get_u128(keys::max_open_interest_key(market_address, is_long))
}

/// Increment the claimable collateral amount.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `chain` - The interface to interact with `Chain` library contract.
/// * `event_emitter` - The interface to interact with `EventEmitter` contract.
/// * `market_address` - The market to increment.
/// * `token` - The claimable token.
/// * `account` - The account to increment the claimable collateral for.
/// * `delta` - The amount to increment by.
fn increment_claimable_collateral_amount(
    data_store: IDataStoreDispatcher,
    chain: IChainDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market_address: ContractAddress,
    token: ContractAddress,
    account: ContractAddress,
    delta: u128
) {
    let divisor = data_store.get_u128(keys::claimable_collateral_time_divisor());
    // Get current timestamp.
    let current_timestamp = chain.get_block_timestamp().into();
    let time_key = current_timestamp / divisor;

    // Increment the collateral amount for the account.
    let next_value = data_store
        .increment_u128(
            keys::claimable_collateral_amount_for_account_key(
                market_address, token, time_key, account
            ),
            delta
        );

    // Increment the total collateral amount for the market.
    let next_pool_value = data_store
        .increment_u128(keys::claimable_collateral_amount_key(market_address, token), delta);

    // Emit event.
    event_emitter
        .emit_claimable_collateral_updated(
            market_address, token, account, time_key, delta, next_value, next_pool_value
        );
}

/// Increment the claimable funding amount.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `event_emitter` - The interface to interact with `EventEmitter` contract.
/// * `market_address` - The market to increment.
/// * `token` - The claimable token.
/// * `account` - The account to increment the claimable funding for.
/// * `delta` - The amount to increment by.
fn increment_claimable_funding_amount(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market_address: ContractAddress,
    token: ContractAddress,
    account: ContractAddress,
    delta: u128
) {
    // Increment the funding amount for the account.
    let next_value = data_store
        .increment_u128(
            keys::claimable_funding_amount_by_account_key(market_address, token, account), delta
        );

    // Increment the total funding amount for the market.
    let next_pool_value = data_store
        .increment_u128(keys::claimable_funding_amount_key(market_address, token), delta);

    // Emit event.
    event_emitter
        .emit_claimable_funding_updated(
            market_address, token, account, delta, next_value, next_pool_value
        );
}

/// Get the pool divisor.
/// This is used to divide the values of `get_pool_amount` and `get_open_interest`
/// if the longToken and shortToken are the same, then these values have to be divided by two
/// to avoid double counting
/// # Arguments
/// * `long_token` - The long token.
/// * `short_token` - The short token.
/// # Returns
/// The pool divisor.
fn get_pool_divisor(long_token: ContractAddress, short_token: ContractAddress) -> u128 {
    if long_token == short_token {
        2
    } else {
        1
    }
}

/// Get the pending PNL for a market for either longs or shorts.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to get the pending PNL for.
/// * `index_token_price` - The price of the index token.
/// * `is_long` - Whether to get the long or short pending PNL.
/// * `maximize` - Whether to maximize or minimize the net PNL.
/// # Returns
/// The pending PNL for a market for either longs or shorts.
fn get_pnl(
    data_store: IDataStoreDispatcher,
    market: @Market,
    index_token_price: @Price,
    is_long: bool,
    maximize: bool
) -> i128 {
    // Get the open interest.
    let open_interest = calc::to_signed(
        get_open_interest_for_market_is_long(data_store, market, is_long), true
    );
    // Get the open interest in tokens.
    let open_interest_in_tokens = get_open_interest_in_tokens_for_market(
        data_store, market, is_long
    );
    // If either the open interest or the open interest in tokens is zero, return zero.
    if open_interest == 0 || open_interest_in_tokens == 0 {
        return 0;
    }

    // Pick the price for PNL.
    let price = index_token_price.pick_price_for_pnl(is_long, maximize);

    //  `open_interest` is the cost of all positions, `open_interest_valu`e is the current worth of all positions.
    let open_interest_value = calc::to_signed(open_interest_in_tokens * price, true);

    // Return the PNL.
    // If `is_long` is true, then the PNL is the difference between the current worth of all positions and the cost of all positions.
    // If `is_long` is false, then the PNL is the difference between the cost of all positions and the current worth of all positions.
    if is_long {
        open_interest_value - open_interest
    } else {
        open_interest - open_interest_value
    }
}

/// Get the position impact pool amount.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market_address` - The market to get the position impact pool amount for.
/// # Returns
/// The position impact pool amount.
fn get_position_impact_pool_amount(
    data_store: IDataStoreDispatcher, market_address: ContractAddress
) -> u128 {
    data_store.get_u128(keys::position_impact_pool_amount_key(market_address))
}

/// Get the swap impact pool amount.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market_address` - The market to get the swap impact pool amount for.
/// * `token` - The token to get the swap impact pool amount for.
/// # Returns
/// The swap impact pool amount.
fn get_swap_impact_pool_amount(
    data_store: IDataStoreDispatcher, market_address: ContractAddress, token: ContractAddress
) -> u128 {
    data_store.get_u128(keys::swap_impact_pool_amount_key(market_address, token))
}

/// Apply delta to the position impact pool.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `event_emitter` - The interface to interact with `EventEmitter` contract.
/// * `market_address` - The market to apply the delta to.
/// * `delta` - The delta to apply.
/// # Returns
/// The updated position impact pool amount.
fn apply_delta_to_position_impact_pool(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market_address: ContractAddress,
    delta: u128
) -> u128 {
    // Increment the position impact pool amount.
    let next_value = data_store
        .increment_u128(keys::position_impact_pool_amount_key(market_address), delta);

    // Emit event.
    event_emitter.emit_position_impact_pool_amount_updated(market_address, delta, next_value);

    // Return the updated position impact pool amount.
    next_value
}

/// Applies a delta to the pool amount for a given market and token.
/// `validatePoolAmount` is not called in this function since `apply_delta_to_pool_amount`
/// is typically called when receiving fees.
/// # Arguments
/// * `data_store` - Data store to manage internal states.
/// * `event_emitter` - Emits events for the system.
/// * `market` - The market to which the delta will be applied.
/// * `token` - The token to which the delta will be applied.
/// * `delta` - The delta amount to apply.
fn apply_delta_to_pool_amount(
    data_store: IDataStoreDispatcher,
    eventEmitter: IEventEmitterDispatcher,
    market: Market,
    token: ContractAddress,
    delta: u128 // This is supposed to be i128 when it will be supported.
) -> u128 {
    //TODO
    0
}

/// Apply delta to the swap impact pool.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `event_emitter` - The interface to interact with `EventEmitter` contract.
/// * `market_address` - The market to apply the delta to.
/// * `token` - The token to apply the delta to.
/// * `delta` - The delta to apply.
/// # Returns
/// The updated swap impact pool amount.
fn apply_delta_to_swap_impact_pool(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market_address: ContractAddress,
    token: ContractAddress,
    delta: u128
) -> u128 {
    // Increment the swap impact pool amount.
    let next_value = data_store
        .increment_u128(keys::swap_impact_pool_amount_key(market_address, token), delta);

    // Emit event.
    event_emitter.emit_swap_impact_pool_amount_updated(market_address, token, delta, next_value);

    // Return the updated swap impact pool amount.
    next_value
}

/// Apply a delta to the open interest.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `event_emitter` - The interface to interact with `EventEmitter` contract.
/// * `market` - The market to apply the delta to.
/// * `collateral_token` - The collateral token to apply the delta to.
/// * `is_long` - Whether to apply the delta to the long or short side.
/// * `delta` - The delta to apply.
/// # Returns
/// The updated open interest.
fn apply_delta_to_open_interest(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: @Market,
    collateral_token: ContractAddress,
    is_long: bool,
    // TODO: Move to `i128` when `apply_delta_to_u128` is implemented and when supported in used Cairo version.
    delta: i128
) -> u128 {
    // Check that the market is not a swap only market.
    assert(
        (*market.index_token).is_non_zero(),
        MarketError::OPEN_INTEREST_CANNOT_BE_UPDATED_FOR_SWAP_ONLY_MARKET
    );

    // Increment the open interest by the delta.
    // TODO: create `apply_delta_to_u128` function in `DataStore` contract and pass `delta` as `i128`.
    let next_value = data_store
        .increment_u128(
            keys::open_interest_key(*market.market_token, collateral_token, is_long), 0
        );

    // If the open interest for longs is increased then tokens were virtually bought from the pool
    // so the virtual inventory should be decreased.
    // If the open interest for longs is decreased then tokens were virtually sold to the pool
    // so the virtual inventory should be increased.
    // If the open interest for shorts is increased then tokens were virtually sold to the pool
    // so the virtual inventory should be increased.
    // If the open interest for shorts is decreased then tokens were virtually bought from the pool
    // so the virtual inventory should be decreased.

    // We need to validate the open interest if the delta is positive.
    //if 0_i128 < delta {
    //validate_open_interest(data_store, market, is_long);
    //}

    0
}

/// Validates the swap path to ensure each market in the path is valid and the path length does not 
//  exceed the maximum allowed length.
/// # Arguments
/// * `data_store` - The DataStore contract containing platform configuration.
/// * `swap_path` - A vector of market addresses forming the swap path.
fn validate_swap_path(
    data_store: IDataStoreDispatcher, token_swap_path: Span32<ContractAddress>
) { //TODO
}

/// @dev validate that the amount of tokens required to be reserved
/// is below the configured threshold
/// # Arguments
/// * `data_store` DataStore
/// * `market` the market values
/// * `prices` the prices of the market tokens
/// * `is_long` whether to check the long or short side
fn validata_reserve(
    data_store: @IDataStoreDispatcher, market: @Market, prices: @MarketPrices, is_long: bool
) { // TODO
}

/// Validata the swap market.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to validate the open interest for.
fn validate_swap_market(data_store: @IDataStoreDispatcher, market: @Market) { // TODO
}

// @dev get the opposite token of the market
// if the input_token is the token_long return the short_token and vice versa
/// # Arguments
/// * `market` - The market to validate the open interest for.
/// * `token` - The input_token.
/// # Returns
/// The opposite token.
fn get_opposite_token(market: @Market, token: ContractAddress) -> ContractAddress {
    // TODO
    token
}

// Get the min pnl factor after ADL
// Parameters
// * `data_store` - - The data store to use.
// * `market` - the market to check.
// * `is_long` whether to check the long or short side.
fn get_min_pnl_factor_after_adl(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u128 {
    // TODO
    0
}

// Check if the pending pnl exceeds the allowed amount
// # Arguments
// * `data_store` - The data_store dispatcher.
// * `oracle` - The oracle dispatcher.
// * `market` - The market to check.
// * `prices` - The prices of the market tokens.
// * `is_long` - Whether to check the long or short side.
// * `pnl_factor_type` - The pnl factor type to check.
fn is_pnl_factor_exceeded(
    data_store: IDataStoreDispatcher,
    oracle: IOracleDispatcher,
    market_address: ContractAddress,
    is_long: bool,
    pnl_factor_type: felt252
) -> (bool, u128, u128) {
    // TODO
    (true, 0, 0)
}

// Check if the pending pnl exceeds the allowed amount
// # Arguments
// * `data_store` - The data_store dispatcher.
// * `market` - The market to check.
// * `prices` - The prices of the market tokens.
// * `is_long` - Whether to check the long or short side.
// * `pnl_factor_type` - The pnl factor type to check.
fn is_pnl_factor_exceeded_direct(
    data_store: IDataStoreDispatcher,
    market: Market,
    prices: MarketPrices,
    is_long: bool,
    pnl_factor_type: felt252
) -> (bool, i128, u128) {
    // TODO
    (true, 0, 0)
}

fn get_ui_fee_factor(data_store: IDataStoreDispatcher, account: ContractAddress) -> u128 {
    let max_ui_fee_factor = data_store.get_u128(keys::max_ui_fee_factor());
    let ui_fee_factor = data_store.get_u128(keys::ui_fee_factor_key(account));
    if ui_fee_factor < max_ui_fee_factor {
        ui_fee_factor
    } else {
        max_ui_fee_factor
    }
}

/// Gets the enabled market. This function will revert if the market does not exist or is not enabled.
/// # Arguments
/// * `dataStore` - DataStore
/// * `marketAddress` - The address of the market.
fn get_enabled_market(data_store: IDataStoreDispatcher, market_address: ContractAddress) -> Market {
    //TODO
    Market {
        market_token: Zeroable::zero(),
        index_token: Zeroable::zero(),
        long_token: Zeroable::zero(),
        short_token: Zeroable::zero(),
    }
}

/// Returns the primary prices for the market tokens.
/// # Parameters
/// - `oracle`: The Oracle instance.
/// - `market`: The market values.
fn get_market_prices(oracle: IOracleDispatcher, market: Market) -> MarketPrices {
    //TODO
    Default::default()
}

/// Validates that the pending pnl is below the allowed amount.
/// # Arguments
/// * `dataStore` - DataStore
/// * `market` - The market to check
/// * `prices` - The prices of the market tokens
/// * `pnlFactorType` - The pnl factor type to check
fn validate_max_pnl(
    data_store: IDataStoreDispatcher,
    market: Market,
    prices: @MarketPrices,
    pnl_factor_type_for_longs: felt252,
    pnl_factor_type_for_shorts: felt252,
) { //TODO
}

/// Validates the token balance for a single market.
/// # Arguments
/// * `data_store` - The data_store dispatcher
/// * `market` - Address of the market to check.
fn validate_market_token_balance_with_address(
    data_store: IDataStoreDispatcher, market: ContractAddress
) { //TODO
}

fn validate_market_token_balance(data_store: IDataStoreDispatcher, market: Market) { //TODO
}

fn validate_markets_token_balance(data_store: IDataStoreDispatcher, market: Span<Market>) { //TODO
}

/// Validate that the positions can be opened in the given market
/// # Parameters
/// * `data_store`: dispatcher for the data store
/// * `market`: the market to check
fn validate_position_market(data_store: IDataStoreDispatcher, market: Market) {} // TODO

/// Gets a list of market values based on an input array of market addresses.
/// # Parameters
/// * `swap_path`: A list of market addresses.
fn get_swap_path_markets(
    data_store: IDataStoreDispatcher, swap_path: Span32<ContractAddress>
) -> Array<Market> { //TODO
    Default::default()
}

/// Gets the USD value of a pool.
/// The value of a pool is determined by the worth of the liquidity provider tokens in the pool,
/// minus any pending trader profit and loss (PNL).
/// We use the token index prices for this calculation and ignore price impact. The reasoning is that
/// if all positions were closed, the net price impact should be zero.
/// # Arguments
/// * `data_store` - The DataStore structure.
/// * `market` - The market values.
/// * `long_token_price` - Price of the long token.
/// * `short_token_price` - Price of the short token.
/// * `index_token_price` - Price of the index token.
/// * `maximize` - Whether to maximize or minimize the pool value.
/// # Returns
/// Returns the value information of a pool.
fn get_pool_value_info(
    data_store: IDataStoreDispatcher,
    market: Market,
    index_token_price: Price,
    long_token_price: Price,
    short_token_price: Price,
    pnl_factor_type: felt252,
    maximize: bool
) -> MarketPoolValueInfo {
    // TODO
    Default::default()
}

/// Get the capped pending pnl for a market
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to get the pending PNL for.
/// * `is_long` - Whether to get the long or short pending PNL.
/// * `pnl` - The uncapped pnl of the market.
/// * `pool_usd` - The USD value of the pool.
/// * `pnl_factor_type` - The pnl factor type to use.
/// # Returns
/// The net pending pnl for a market
fn get_capped_pnl(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    is_long: bool,
    pnl: i128,
    pool_usd: u128,
    pnl_factor_type: felt252
) -> i128 {
    // TODOs
    0
}


/// Validata that the specified market exists and is enabled
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to validate.
fn validate_enabled_market(data_store: IDataStoreDispatcher, market: Market) {
    assert(!market.market_token.is_zero(), MarketError::EMPTY_MARKET);
    let is_market_disabled = data_store.get_bool(keys::is_market_disabled_key(market.market_token));

    match is_market_disabled {
        Option::Some(result) => {
            assert(!result, MarketError::DISABLED_MARKET);
        },
        Option::None => {
            panic_with_felt252(MarketError::DISABLED_MARKET);
        }
    };
}


/// Validata that the specified market exists and is enabled
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to validate.
fn validate_enabled_market_address(
    data_store: IDataStoreDispatcher, market: ContractAddress
) { // TODO
}

// Check if the given token is a collateral token of the market
// # Arguments
// * `market` - the market to check
// * `token` -  the token to check
fn is_market_collateral_token(market: Market, token: ContractAddress) -> bool {
    token == market.long_token || token == market.short_token
}

/// Validata if the given token is a collateral token of the market
/// # Arguments
/// * `market` - The market to validate.
/// * `token` - The token to check
fn validate_market_collateral_token(market: Market, token: ContractAddress) {
    if !is_market_collateral_token(market, token) {
        panic_with_felt252(MarketError::INVALID_COLLATERAL_TOKEN_FOR_MARKET)
    }
}

/// Get the max position impact factor for liquidations
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market.
fn get_max_position_impact_factor_for_liquidations(
    data_store: IDataStoreDispatcher, market: ContractAddress
) -> u128 {
    // TODOs
    0
}

/// Get the min collateral factor
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market.
fn get_min_collateral_factor(data_store: IDataStoreDispatcher, market: ContractAddress) -> u128 {
    // TODOs
    0
}


/// Get the min collateral factor for open interest
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market.
/// * `open_interest_delta` - The change in open interest.
/// * `is_long` - Whether it is for the long or short side
fn get_min_collateral_factor_for_open_interest(
    data_store: IDataStoreDispatcher, market: Market, open_interest_delta: i128, is_long: bool
) -> u128 {
    // TODOs
    0
}


/// Update the funding state
/// # Arguments
/// * `data_store` - The data store to use.
/// * `event_emitter` - The event emitter.
/// * `market` - The market.
/// * `prices` - The market prices.
fn update_funding_state(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: Market,
    prices: MarketPrices
) { // TODO
}

/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market.
/// * `is_long` - Whether to update the long or short side.
/// * `prev_position_size_in_usd` - The previous position size in USD.
/// * `prev_position_borrowing_factor` - The previous position borrowing factor.
/// * `next_position_size_in_usd` - The next position size in USD.
/// * `next_position_borrowing_factor` - The next position borrowing factor.
fn update_total_borrowing(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    is_long: bool,
    prev_position_size_in_usd: u128,
    prev_position_borrowing_factor: u128,
    next_position_size_in_usd: u128,
    next_position_borrowing_factor: u128
) { // TODO
}


/// Gets the total supply of the marketToken.
/// # Arguments
/// * `market_token` - The market token whose total supply is to be retrieved.
/// # Returns
/// The total supply of the given marketToken.
fn get_market_token_supply(market_token: IMarketTokenDispatcher) -> u128 {
    // TODO
    market_token.total_supply()
}

/// Converts a number of market tokens to its USD value.
/// # Arguments
/// * `market_token_amount` - The input number of market tokens.
/// * `pool_value` - The value of the pool.
/// * `supply` - The supply of market tokens.
/// # Returns
/// The USD value of the market tokens.
fn market_token_amount_to_usd(
    market_token_amount: u128, pool_value: u128, supply: u128
) -> u128 { // TODO
    0
}

//FROM HERE

// store funding values as token amount per (Precision.FLOAT_PRECISION_SQRT / Precision.FLOAT_PRECISION) of USD size
fn get_funding_amount_per_size_delta(
    funding_usd: u128, open_interest: u128, token_price: u128,roundup_magnitude: bool
) -> u128 { // TODO
    if funding_usd == 0 || open_interest == 0 {
        return 0;
    }
    let funding_usd_per_size: u128 = mul_div_roundup(
        funding_usd,
        FLOAT_PRECISION * FLOAT_PRECISION_SQRT,
        open_interest,
        roundup_magnitude
    );
    if roundup_magnitude {
        roundup_division(funding_usd_per_size, token_price)
    } else {
        funding_usd_per_size / token_price
    }
}


/// Update the cumulative borrowing factor for a market
/// # Arguments
/// * `data_store` - The data store to use.
/// * `event_emitter` - The event emitter.
/// * `market` - The market.
/// * `prices` - The market prices.
/// * `is_long` - Whether to update the long or short side.
fn update_cumulative_borrowing_factor(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: Market,
    prices: MarketPrices,
    // chain: IChainDispatcher,
    is_long: bool
) { // TODO
    let (_, delta) = get_next_cumulative_borrowing_factor(
        data_store, prices, market, is_long
    );
    increment_cumulative_borrowing_factor(
        data_store, event_emitter, market.market_token, is_long, delta
    );
    data_store.set_u128(
        keys::cumulative_borrowing_factor_updated_at_key(
            market.market_token, is_long
        ),
        0 // put chain.get_block_timestamp().into() instead
    );

}

// Get the ratio of pnl to pool value.
// # Arguments
// * `data_store` - The data_store dispatcher.
// * `market` the market values.
// * `prices` the prices of the market tokens.
// * `is_long` whether to get the value for the long or short side.
// * `maximize` whether to maximize the factor.
// # Returns
// (pnl of positions) / (long or short pool value)
fn get_pnl_to_pool_factor(
    data_store: IDataStoreDispatcher,
    oracle: IOracleDispatcher,
    market: ContractAddress,
    is_long: bool,
    maximize: bool
) -> i128 { // TODO
    let _market: Market = get_enabled_market(data_store, market);
    let prices: MarketPrices = MarketPrices {
        index_token_price: oracle.get_primary_price(_market.index_token),
        long_token_price: oracle.get_primary_price(_market.long_token),
        short_token_price: oracle.get_primary_price(_market.short_token)
    };

    return get_pnl_to_pool_factor_from_prices(data_store, _market, prices, is_long, maximize);
}

/// Get the ratio of PNL (Profit and Loss) to pool value.
///
/// # Arguments
/// * `dataStore`: DataStore - The data storage instance.
/// * `market`: Market values.
/// * `prices`: Prices of the market tokens.
/// * `isLong`: Whether to get the value for the long or short side.
/// * `maximize`: Whether to maximize the factor.
///
/// # Returns
/// Returns the ratio of PNL of positions to long or short pool value.
fn get_pnl_to_pool_factor_from_prices(
    data_store: IDataStoreDispatcher,
    market: Market,
    prices: MarketPrices,
    is_long: bool,
    maximize: bool
) -> i128 {
    let pool_usd: u128 = get_pool_usd_without_pnl(
        data_store, market, prices, is_long, !maximize
    );
    if pool_usd == 0_u128 {
        0_i128
    }
    let pnl: i128 = get_pnl(
        data_store, @market, @prices.index_token_price, is_long, maximize
    );
    return to_factor_ival(pnl, pool_usd);
}


/// Validata the open interest.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to validate the open interest for.
/// * `is_long` - Whether to validate the long or short side.
fn validate_open_interest(data_store: IDataStoreDispatcher, market: @Market, is_long: bool) {
    // Get the open interest.
    let open_interest = get_open_interest_for_market_is_long(data_store, market, is_long);

    // Get the maximum open interest.
    let max_open_interest = get_max_open_interest(data_store, *market.market_token, is_long);

    // Check that the open interest is not greater than the maximum open interest.
    assert(open_interest <= max_open_interest, MarketError::MAX_OPEN_INTEREST_EXCEEDED);
}

/// @dev validate that the pool amount is within the max allowed amount
/// # Arguments
/// *`data_store` DataStore
/// *`market` the market to check
/// *`token` the token to check
fn validate_pool_amount(
    data_store: @IDataStoreDispatcher, market: @Market, token: ContractAddress
) { // TODO
    let pool_amount: u128 = get_pool_amount(*data_store, market, token);
    let max_pool_amount: u128 = get_max_pool_amount(*data_store, *market.market_token, token);
    assert(pool_amount <= max_pool_amount, MarketError::MAX_POOL_AMOUNT_EXCEEDED);
}

/// Validates that the amount of tokens required to be reserved is below the configured threshold.
/// # Arguments
/// * `dataStore`: DataStore - The data storage instance.
/// * `market`: Market values to consider.
/// * `prices`: Prices of the market tokens.
/// * `is_long`: A boolean flag to indicate whether to check the long or short side.
fn validate_reserve(
    data_store: IDataStoreDispatcher, market: Market, prices: @MarketPrices, is_long: bool
) { //TODO
    // poolUsd is used instead of pool amount as the indexToken may not match the longToken
    // additionally, the shortToken may not be a stablecoin
    let pool_usd: u128 = get_pool_usd_without_pnl(data_store, market, *prices, is_long, false);
    let reserve_factor: u128 = get_reserve_factor(data_store, market.market_token, is_long);
    let max_reserved_usd: u128 = apply_factor_u128(pool_usd, reserve_factor);

    let reserved_usd: u128 = get_reserved_usd(
        data_store,
        market,
        *prices,
        is_long
    );

    assert(reserved_usd <= max_reserved_usd, MarketError::INSUFFICIENT_RESERVE);
}

// @dev validate that the amount of tokens required to be reserved for open interest
// is below the configured threshold
// @param dataStore: DataStore - The data storage instance.
// @param market: Market values to consider.
// @param prices: Prices of the market tokens.
// @param is_long: A boolean flag to indicate whether to check the long or short side.
fn validate_open_interest_reserve(
    data_store: IDataStoreDispatcher, market: Market, prices: MarketPrices, is_long: bool
) { // TODO
    // poolUsd is used instead of pool amount as the indexToken may not match the longToken
    // additionally, the shortToken may not be a stablecoin
    let pool_usd: u128 = get_pool_usd_without_pnl(data_store, market, prices, is_long, false);
    let reserve_factor: u128 = get_open_interest_reserve_factor(data_store, market.market_token, is_long);
    let max_reserved_usd: u128 = apply_factor_u128(pool_usd, reserve_factor);

    let reserved_usd: u128 = get_reserved_usd(
        data_store,
        market,
        prices,
        is_long
    );

    assert(reserved_usd <= max_reserved_usd, MarketError::INSUFFICIENT_RESERVE);
}

/// @dev update the swap impact pool amount, if it is a positive impact amount
/// cap the impact amount to the amount available in the swap impact pool
/// # Arguments
/// *`data_store` DataStore
/// *`event_emitter` EventEmitter
/// *`market` the market to apply to
/// *`token` the token to apply to
/// *`token_price` the price of the token
/// *`price_impact_usd` the USD price impact
/// # Returns
/// The impact amount as integer
fn apply_swap_impact_with_cap(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    token_price: Price,
    price_impact_usd: i128
) -> i128 { // TODO
    let impact_amount: u128 = get_swap_impact_amount_with_cap(
        data_store,
        market,
        token,
        token_price,
        price_impact_usd
    );
    // if there is a positive impact, the impact pool amount should be reduced
    // if there is a negative impact, the impact pool amount should be increased
    // apply_delta_to_swap_impact_pool(
    //     data_store,
    //     event_emitter,
    //     market,
    //     token,
    //     -impact_amount
    // );

    return impact_amount;
}

fn get_swap_impact_amount_with_cap(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    token_price: Price,
    price_impact_usd: i128
) -> i128 { //Todo : check u128
    let mut impact_amount: i128 = 0;
    // positive impact: minimize impactAmount, use tokenPrice.max
    // negative impact: maximize impactAmount, use tokenPrice.min
    if price_impact_usd > 0 {
        let price_u128: u128 = token_price.max;
        // round positive impactAmount down, this will be deducted from the swap impact pool for the user
        let price: i128 = u128_to_i128(price_u128);
        impact_amount = price_impact_usd / price;

        let max_impact_amount: i128 = u128_to_i128(
            get_swap_impact_pool_amount(data_store, market, token)
        );
        if (impact_amount > max_impact_amount) {
            impact_amount = max_impact_amount;
        }
    } else {
        let price: u128 = token_price.min;
        // round negative impactAmount up, this will be deducted from the user
        impact_amount = roundup_magnitude_division(price_impact_usd, price);
    }
    impact_amount
}

// @notice Get the next borrowing fees for a position.
//
// @param data_store IDataStoreDispatcher
// @param position Position
// @param market Market
// @param prices @MarketPrices
//
// @return The next borrowing fees for a position.
fn get_next_borrowing_fees(
    data_store: IDataStoreDispatcher, 
    position: Position, 
    market: Market,
    prices: MarketPrices
) -> u128 {
    let (next_cumulative_borrowing_factor, _) = get_next_cumulative_borrowing_factor(
        data_store, market, prices, position.is_long
    );
    assert(next_cumulative_borrowing_factor >= position.borrowing_factor, MarketError::UNEXCEPTED_BORROWING_FACTOR);
    let diff_factor: u128 = next_cumulative_borrowing_factor - position.borrowing_factor;
    return apply_factor_u128(position.size_in_usd, diff_factor);
}

// @notice Get the total reserved USD required for positions.
//
// @param market The market to check.
// @param prices The prices of the market tokens.
// @param is_long Whether to get the value for the long or short side.
//
// @return The total reserved USD required for positions.
fn get_reserved_usd(
    data_store: IDataStoreDispatcher, 
    market: Market,
    prices: MarketPrices,
    is_long: bool
) -> u128 { // TODO
    0
}

fn get_is_long_token(
    market: Market, token: ContractAddress
) -> bool { // TODO
    false
}

/// Get the virtual inventory for positions.
///
/// # Arguments
/// * `dataStore`: DataStore - The data storage instance.
/// * `token`: The token to check.
///
/// # Returns
/// Returns a tuple (has_virtual_inventory, virtual_token_inventory).
fn get_virtual_inventory_for_positions(
    data_store: IDataStoreDispatcher, token: ContractAddress
) -> (bool, u128) { // TODO
    (false, 0)
}

/// Update the virtual inventory for swaps.
///
/// # Arguments
/// * `data_store`: The data storage instance.
/// * `market_address`: The address of the market to update.
/// * `token`: The token to update.
/// * `delta`: The update amount.
///
/// # Returns
/// Returns a tuple (success, updated_amount).
fn apply_delta_to_virtual_inventory_for_swaps(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: Market,
    token: ContractAddress,
    delta: i128
) -> (bool, u128){ // TODO
    (false, 0)
}

/// Get the next cumulative borrowing factor.
///
/// # Arguments
/// * `dataStore`: DataStore - The data storage instance.
/// * `prices`: Prices of the market tokens.
/// * `market`: The market to check.
/// * `longToken`: The long token of the market.
/// * `shortToken`: The short token of the market.
/// * `isLong`: Whether to check the long or short side.
///
/// # Returns
/// Returns a tuple (cumulative_borrowing_factor, updated_timestamp).
fn get_next_cumulative_borrowing_factor(
    data_store: IDataStoreDispatcher,
    market: Market,
    prices: MarketPrices,
    is_long: bool
) -> (u128, u128) { // TODO
    (0, 0)
}

//NOT TO DO

/// Increase the cumulative borrowing factor.
///
/// # Arguments
/// * `dataStore`: DataStore - The data storage instance.
/// * `eventEmitter`: EventEmitter - The event emitter.
/// * `market`: The market to increment the borrowing factor for.
/// * `isLong`: Whether to increment the long or short side.
/// * `delta`: The increase amount.
fn increment_cumulative_borrowing_factor(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    is_long: bool,
    delta: u128
) {
    ()
}

/// Get the USD value of either the long or short tokens in the pool without accounting for the PNL of open positions.
///
/// # Arguments
/// * `dataStore`: DataStore - The data storage instance.
/// * `market`: Market values.
/// * `prices`: Prices of the market tokens.
/// * `isLong`: Whether to return the value for the long or short token.
/// * `maximize`: Whether to maximize the value.
///
/// # Returns
/// Returns the USD value of either the long or short tokens in the pool.
fn get_pool_usd_without_pnl(
    data_store: IDataStoreDispatcher,
    market: Market,
    prices: MarketPrices,
    is_long: bool,
    maximize: bool
) -> u128 {
    Default::default()
}

/// Get the reserve factor for a market.
///
/// # Arguments
/// * `dataStore`: DataStore - The data storage instance.
/// * `market`: The market to check.
/// * `isLong`: Whether to get the value for longs or shorts.
///
/// # Returns
/// Returns the reserve factor for a market.
fn get_reserve_factor(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    is_long: bool
) -> u128 {
    Default::default()
}
/// Get the borrowing fees for a position, assumes that cumulativeBorrowingFactor
/// has already been updated to the latest value
/// # Arguments
/// * `dataStore` - DataStore
/// * `position` - Position
/// * `dataStore` - DataStore
/// # Returns
/// The borrowing fees for a position
fn get_borrowing_fees(data_store: IDataStoreDispatcher, position: Position) -> u128 {
    let cumulative_borrowing_factor: u128 = get_cumulative_borrowing_factor(data_store, position.market, position.is_long);
    assert(cumulative_borrowing_factor >= position.borrowing_factor, MarketError::UNEXCEPTED_BORROWING_FACTOR);
    let diff_factor: u128 = cumulative_borrowing_factor - position.borrowing_factor;
    return apply_factor_u128(position.size_in_usd, diff_factor);
}

/// Get the funding fee amount per size for a market
/// # Arguments
/// * `dataStore` - DataStore
/// * `market` - the market to check
/// * `collateral_token` - the collateralToken to check
/// * `is_long` - whether to check the long or short size
/// # Returns
/// The funding fee amount per size for a market based on collateralToken
fn get_funding_fee_amount_per_size(
    dataStore: IDataStoreDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool
) -> u128 {
    0
}

/// Get the claimable funding amount per size for a market
/// # Arguments
/// * `dataStore` - DataStore
/// * `market` - the market to check
/// * `collateral_token` - the collateralToken to check
/// * `is_long` - whether to check the long or short size
/// # Returns
/// The claimable funding amount per size for a market based on collateralToken
fn get_claimable_funding_amount_per_size(
    dataStore: IDataStoreDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool
) -> u128 {
    0
}

/// Get the funding amount to be deducted or distributed
/// # Arguments
/// * `latestFundingAmountPerSize` - the latest funding amount per size
/// * `dataSpositionFundingAmountPerSizetore` - the funding amount per size for the position
/// * `positionSizeInUsd` - the position size in USD
/// * `roundUpMagnitude` - whether the round up the result
/// # Returns
/// fundingAmount
fn get_funding_amount(
    latest_funding_amount_per_size: u128,
    position_funding_amount_per_size: u128,
    position_size_in_usd: u128,
    roundup_magnitude: bool
) -> u128 {
    let funding_diff_factor: u128 = (latest_funding_amount_per_size - position_funding_amount_per_size);
    return mul_div_roundup(
        position_size_in_usd,
        funding_diff_factor,
        FLOAT_PRECISION * FLOAT_PRECISION_SQRT,
        roundup_magnitude
    );
}

/// Get the borrowing factor per second.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Market to check.
/// * `index_token_price` - Price of the market's index token.
/// * `long_token_price` - Price of the market's long token.
/// * `short_token_price` - Price of the market's short token.
/// * `pnl_factor_type` - The pnl factor type.
/// * `maximize` - Whether to maximize or minimize the net PNL.
/// # Returns
/// Returns an integer representing the calculated market token price and MarketPoolValueInfo struct containing additional information related to market pool value.

fn get_market_token_price(
    data_store: IDataStoreDispatcher,
    market: Market,
    index_token_price: Price,
    long_token_price: Price,
    short_token_price: Price,
    pnl_factor_type: felt252,
    maximize: bool
) -> (i128, MarketPoolValueInfo) {
    // TODO
    (0, Default::default())
}

/// Get the net pending pnl for a market
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to get the pending PNL for.
/// * `index_token_price` - The price of the index token.
/// * `maximize` - Whether to maximize or minimize the net PNL.
/// # Returns
/// The net pending pnl for a market
fn get_net_pnl(
    data_store: IDataStoreDispatcher, market: @Market, index_token_price: @Price, maximize: bool
) -> i128 {
    // TODO
    0
}

/// The sum of open interest and pnl for a market
// get_open_interest_in_tokens * token_price would not reflect pending positive pnl
// for short positions, so get_open_interest_with_pnl should be used if that info is needed
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market.
/// * `index_token_price` - The price of the index token.
/// * `is_long` -  Whether to check the long or short side
/// * `maximize` - Whether to maximize or minimize the net PNL.
/// # Returns
/// The net pending pnl for a market
fn get_open_interest_with_pnl(
    data_store: IDataStoreDispatcher,
    market: Market,
    index_token_price: Price,
    is_long: bool,
    maximize: bool
) -> i128 {
    // TODO
    0
}

/// Get the virtual inventory for swaps
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market.
/// # Returns
/// The tuple (has virtual inventory, virtual long token inventory, virtual short token inventory)
fn get_virtual_inventory_for_swaps(
    data_store: IDataStoreDispatcher, market: ContractAddress
) -> (bool, u128, u128) {
    let virtual_market_id = data_store.get_felt252(keys::virtual_market_id_key(market));
    if virtual_market_id.is_zero() {
        return (false, 0, 0);
    }

    return (
        true,
        data_store.get_u128(keys::virtual_inventory_for_swaps_key(virtual_market_id, true)),
        data_store.get_u128(keys::virtual_inventory_for_swaps_key(virtual_market_id, false))
    );
}

fn get_adjusted_swap_impact_factor(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_positive: bool
) -> u128 {
    let (positive_impact_factor, negative_impact_factor) = get_adjusted_swap_impact_factors(
        data_store, market
    );
    if is_positive {
        positive_impact_factor
    } else {
        negative_impact_factor
    }
}

fn get_adjusted_swap_impact_factors(
    data_store: IDataStoreDispatcher, market: ContractAddress
) -> (u128, u128) {
    let mut positive_impact_factor = data_store
        .get_u128(keys::swap_impact_factor_key(market, true));
    let negative_impact_factor = data_store.get_u128(keys::swap_impact_factor_key(market, false));
    // if the positive impact factor is more than the negative impact factor, positions could be opened
    // and closed immediately for a profit if the difference is sufficient to cover the position fees
    if positive_impact_factor > negative_impact_factor {
        positive_impact_factor = negative_impact_factor;
    }
    (positive_impact_factor, negative_impact_factor)
}

fn get_adjusted_position_impact_factor(
    data_store: IDataStoreDispatcher, market: ContractAddress, isPositive: bool
) -> u128 {
    // TODO
    0
}

// @dev get the open interest reserve factor for a market
// @param dataStore DataStore
// @param market the market to check
// @param isLong whether to get the value for longs or shorts
// @return the open interest reserve factor for a market
fn get_open_interest_reserve_factor(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u128 {
    Default::default()
}

// @dev get the cumulative borrowing factor for a market
// @param dataStore DataStore
// @param market the market to check
// @param isLong whether to check the long or short side
// @return the cumulative borrowing factor for a market
fn get_cumulative_borrowing_factor(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u128 {
    0
}