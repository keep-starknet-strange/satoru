// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, get_block_timestamp};
use result::ResultTrait;
use traits::Into;
use debug::PrintTrait;

// Local imports.
use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::chain::chain::{IChainSafeDispatcher, IChainSafeDispatcherTrait};
use gojo::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use gojo::data::keys;
use gojo::market::error::MarketError;
use gojo::market::market::Market;
use gojo::price::price::{Price, PriceTrait};

/// Get the long and short open interest for a market based on the collateral token used.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to get the open interest for.
/// * `collateral_token` - The collateral token to check.
/// * `is_long` - Whether to get the long or short open interest.
/// * `divisor` - The divisor to use for the open interest.
fn get_open_interest(
    data_store: IDataStoreSafeDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    divisor: u128
) -> u128 {
    assert(divisor != 0, MarketError::DIVISOR_CANNOT_BE_ZERO);
    let key = keys::open_interest_key(market, collateral_token, is_long);
    data_store.get_u128(key).unwrap() / divisor
}

/// Get the long and short open interest for a market.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to get the open interest for.
/// # Returns
/// The long and short open interest for a market.
fn get_open_interest_for_market(data_store: IDataStoreSafeDispatcher, market: @Market, ) -> u128 {
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
    data_store: IDataStoreSafeDispatcher, market: @Market, is_long: bool
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
    data_store: IDataStoreSafeDispatcher, market: @Market, is_long: bool, 
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
    data_store: IDataStoreSafeDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    divisor: u128
) -> u128 {
    data_store
        .get_u128(keys::open_interest_in_tokens_key(market, collateral_token, is_long))
        .unwrap()
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
    data_store: IDataStoreSafeDispatcher, market: @Market, token_address: ContractAddress
) -> u128 {
    let divisor = get_pool_divisor(*market.long_token, *market.short_token);
    data_store.get_u128(keys::pool_amount_key(*market.market_token, token_address)).unwrap()
        / divisor
}

/// Get the maximum amount of tokens allowed to be in the pool.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market_address` - The market to check.
/// * `token_address` - The token to check.
/// # Returns
/// The maximum amount of tokens allowed to be in the pool.
fn get_max_pool_amount(
    data_store: IDataStoreSafeDispatcher,
    market_address: ContractAddress,
    token_address: ContractAddress
) -> u128 {
    data_store.get_u128(keys::max_pool_amount_key(market_address, token_address)).unwrap()
}

/// Get the maximum open interest allowed for a market.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market_address` - The market to check.
/// * `is_long` - Whether this is for the long or short side.
/// # Returns
/// The maximum open interest allowed for a market.
fn get_max_open_interest(
    data_store: IDataStoreSafeDispatcher, market_address: ContractAddress, is_long: bool
) -> u128 {
    data_store.get_u128(keys::max_open_interest_key(market_address, is_long)).unwrap()
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
    data_store: IDataStoreSafeDispatcher,
    chain: IChainSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    market_address: ContractAddress,
    token: ContractAddress,
    account: ContractAddress,
    delta: u128
) {
    let divisor = data_store.get_u128(keys::claimable_collateral_time_divisor()).unwrap();
    // Get current timestamp.
    let current_timestamp = chain.get_block_timestamp().unwrap().into();
    let time_key = current_timestamp / divisor;

    // Increment the collateral amount for the account.
    let next_value = data_store
        .increment_u128(
            keys::claimable_collateral_amount_for_account_key(
                market_address, token, time_key, account
            ),
            delta
        )
        .unwrap();

    // Increment the total collateral amount for the market.
    let next_pool_value = data_store
        .increment_u128(keys::claimable_collateral_amount_key(market_address, token), delta)
        .unwrap();

    // Emit event.
    event_emitter
        .emit_claimable_collateral_updated(
            market_address, token, account, time_key, delta, next_value, next_pool_value
        )
        .unwrap();
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
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    market_address: ContractAddress,
    token: ContractAddress,
    account: ContractAddress,
    delta: u128
) {
    // Increment the funding amount for the account.
    let next_value = data_store
        .increment_u128(
            keys::claimable_funding_amount_by_account_key(market_address, token, account), delta
        )
        .unwrap();

    // Increment the total funding amount for the market.
    let next_pool_value = data_store
        .increment_u128(keys::claimable_funding_amount_key(market_address, token), delta)
        .unwrap();

    // Emit event.
    event_emitter
        .emit_claimable_funding_updated(
            market_address, token, account, delta, next_value, next_pool_value
        )
        .unwrap();
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
    data_store: IDataStoreSafeDispatcher,
    market: @Market,
    index_token_price: @Price,
    is_long: bool,
    maximize: bool
) -> u128 {
    // Get the open interest.
    let open_interest = get_open_interest_for_market_is_long(data_store, market, is_long);
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
    let open_interest_value = open_interest_in_tokens * price;

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
    data_store: IDataStoreSafeDispatcher, market_address: ContractAddress
) -> u128 {
    data_store.get_u128(keys::position_impact_pool_amount_key(market_address)).unwrap()
}

/// Get the swap impact pool amount.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market_address` - The market to get the swap impact pool amount for.
/// * `token` - The token to get the swap impact pool amount for.
/// # Returns
/// The swap impact pool amount.
fn get_swap_impact_pool_amount(
    data_store: IDataStoreSafeDispatcher, market_address: ContractAddress, token: ContractAddress
) -> u128 {
    data_store.get_u128(keys::swap_impact_pool_amount_key(market_address, token)).unwrap()
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
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    market_address: ContractAddress,
    delta: u128
) -> u128 {
    // Increment the position impact pool amount.
    let next_value = data_store
        .increment_u128(keys::position_impact_pool_amount_key(market_address), delta)
        .unwrap();

    // Emit event.
    event_emitter
        .emit_position_impact_pool_amount_updated(market_address, delta, next_value)
        .unwrap();

    // Return the updated position impact pool amount.
    next_value
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
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    market_address: ContractAddress,
    token: ContractAddress,
    delta: u128
) -> u128 {
    // Increment the swap impact pool amount.
    let next_value = data_store
        .increment_u128(keys::swap_impact_pool_amount_key(market_address, token), delta)
        .unwrap();

    // Emit event.
    event_emitter
        .emit_swap_impact_pool_amount_updated(market_address, token, delta, next_value)
        .unwrap();

    // Return the updated swap impact pool amount.
    next_value
}
