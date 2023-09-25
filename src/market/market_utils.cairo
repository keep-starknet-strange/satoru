// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, get_block_timestamp};
use result::ResultTrait;

use debug::PrintTrait;
use zeroable::Zeroable;

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::chain::chain::{IChainDispatcher, IChainDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::keys;
use satoru::market::{
    market::Market, error::MarketError, market_pool_value_info::MarketPoolValueInfo,
    market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait}
};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::price::price::{Price, PriceTrait};
use satoru::utils::span32::Span32;
use satoru::utils::i128::{StoreI128, u128_to_i128, I128Serde, I128Div, I128Mul};
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

fn get_swap_impact_amount_with_cap(
    dataStore: IDataStoreDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    tokenPrice: Price,
    priceImpactUsd: i128 //TODO : check u128
) -> i128 { //Todo : check u128
    //TODO
    return 0;
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
    let open_interest = u128_to_i128(
        get_open_interest_for_market_is_long(data_store, market, is_long)
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
    let open_interest_value = u128_to_i128(open_interest_in_tokens * price);

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
) -> i128 {
    // TODO: implement
    return 0;
}

/// @dev validate that the pool amount is within the max allowed amount
/// # Arguments
/// *`data_store` DataStore
/// *`market` the market to check
/// *`token` the token to check
fn validate_pool_amount(
    data_store: @IDataStoreDispatcher, market: @Market, token: ContractAddress
) { // TODO
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
) -> u128 {
    // TODO
    0
}

// Get the ratio of pnl to pool value.
// # Arguments
// * `data_store` - The data_store dispatcher.
// * `market` Rhe market.
// * `prices` the prices of the market tokens.
// * `is_long` whether to get the value for the long or short side.
// * `maximize` whether to maximize the factor.
// # Returns
// (pnl of positions) / (long or short pool value)
// TODO same function names getPnlToPoolFactor
fn get_pnl_to_pool_factor_from_prices(
    data_store: IDataStoreDispatcher,
    market: Market,
    prices: MarketPrices,
    is_long: bool,
    maximize: bool
) -> i128 {
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

/// Validates that the amount of tokens required to be reserved is below the configured threshold.
/// # Arguments
/// * `dataStore`: DataStore - The data storage instance.
/// * `market`: Market values to consider.
/// * `prices`: Prices of the market tokens.
/// * `isLong`: A boolean flag to indicate whether to check the long or short side.
fn validate_reserve(
    data_store: IDataStoreDispatcher, market: Market, prices: @MarketPrices, is_long: bool
) { //TODO
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


/// Validata if the given token is a collateral token of the market
/// # Arguments
/// * `market` - The market to validate.
/// * `token` - The token to check
fn validate_market_collateral_token(market: Market, token: ContractAddress) { // TODO
}

/// Get the max position impact factor for liquidations
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market.
fn get_max_position_impact_factor_for_liquidations(
    data_store: IDataStoreDispatcher, market: ContractAddress
) -> u128 {
    data_store.get_u128(keys::get_min_collateral_factor_for_liquidations_key(market))
}

/// Get the min collateral factor
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market.
fn get_min_collateral_factor(data_store: IDataStoreDispatcher, market: ContractAddress) -> u128 {
    data_store.get_u128(keys::get_min_collateral_factor_key(market))
}


/// Get the min collateral factor for open interest
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market.
/// * `open_interest_delta` - The change in open interest.
/// * `is_long` - Whether it is for the long or short side
fn _for_open_interest(
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
    is_long: bool
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


/// Get the borrowing factor per second.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market.
/// * `prices` - The prices of the market tokens.
/// * `is_long` - Whether to get the factor for the long or short side
/// # Returns
/// The borrowing factor per second.
fn get_borrowing_factor_per_second(
    data_store: IDataStoreDispatcher, market: Market, prices: MarketPrices, is_long: bool
) -> u128 {
    // TODO
    0
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
/// * `market` - The market address.
/// # Returns
/// has virtual inventory, virtual long token inventory, virtual short token inventory
fn get_virtual_inventory_for_swaps(
    data_store: IDataStoreDispatcher, market: ContractAddress,
) -> (bool, u128, u128) {
    // TODO
    (false, 0, 0)
}


/// Get the virtual inventory for positions
/// # Arguments
/// * `data_store` - The data store to use.
/// * `token` - The token to check.
/// # Returns
/// has virtual inventory, virtual inventory
fn get_virtual_inventory_for_positions(
    data_store: IDataStoreDispatcher, token: ContractAddress,
) -> (bool, i128) {
    // TODO
    (false, 0)
}

fn get_max_position_impact_factor(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_positive: bool,
) -> u128 {
    let (max_positive_impact_factor, max_negative_impact_factor) = get_max_position_impact_factors(data_store, market);

    if is_positive {
        max_positive_impact_factor
    } else {
        max_negative_impact_factor
    }
}

fn get_max_position_impact_factors(
    data_store: IDataStoreDispatcher, market: ContractAddress,
) -> (u128, u128) {
    let mut max_positive_impact_factor: u128 = data_store.get_u128(keys::max_positive_impact_factor_key(market));
    let max_negative_impact_factor: u128 = data_store.get_u128(keys::max_negative_impact_factor_key(market));

    if max_positive_impact_factor > max_negative_impact_factor {
        max_positive_impact_factor = max_negative_impact_factor;
    }

    (max_positive_impact_factor, max_negative_impact_factor)
}

// get_max_position_impact_factor_for_liquidations done above 

// get_min_collaterak_factor done above


    //Find what is Market.props to do it 
fn get_min_collateral_factor_for_open_interest(
    data_store: IDataStoreDispatcher, market: market, open_interest_delta: i128, is_long: bool
) -> u128 {
    let mut open_interest: u128 = get_open_interest_for_market_is_long(data_store, market, is_long);
    open_interest = sum_return_uint_128(open_interest, open_interest_delta);
    let multiplier_factor = get_min_collateral_factor_for_open_interest_multiplier(data_store, market, is_long);
    apply_factor_u128(open_interest, multiplier_factor)
}

fn get_collateral_sum(
    data_store: IDataStoreDispatcher, market: Market, CreateAdlOrderParams::collateral_token: ContractAddress, is_long: bool, divisor: u128
) -> u128 {
    data_store.get_u128(keys::collateral_sum_key(market.market_token, collateral_token, is_long)) / divisor
}

fn get_reserve_factor(
    data_store: IDataStoreDispatcher, market: Market, is_long: bool
) -> u128 {
    data_store.get_u128(keys::reserve_factor_key(market.market_token, is_long))
}

fn get_open_interest_reserve_factor(
    data_store: IDataStoreDispatcher, market: Market, is_long: bool
) -> u128 {
    data_store.get_u128(keys::open_interest_reserve_factor_key(market.market_token, is_long))
}

fn get_max_pnl_factor(
    data_store: IDataStoreDispatcher, pnl_factor_type: felt252, market: Market, is_long: bool
) -> u128 {
    data_store.get_u128(keys::max_pnl_factor_key(pnl_factor_type, market.market_token, is_long))
}

fn get_min_pnl_factor_after_adl(
    data_store: IDataStoreDispatcher, market: Market, is_long: bool
) -> u128 {
    data_store.get_u128(keys::min_pnl_factor_after_adl_key(market.market_token, is_long))
}

fn get_funding_factor(
    data_store: IDataStoreDispatcher, market: Market
) -> u128 {
    data_store.get_u128(keys::funding_factor_key(market.market_token)
}

