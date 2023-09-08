// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;

use zeroable::Zeroable;

// Local imports.
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use satoru::data::keys;
use satoru::market::{error::MarketError, market::Market, market_store_utils};
use satoru::oracle::oracle::{IOracleSafeDispatcher, IOracleSafeDispatcherTrait};
use satoru::price::price::{Price, PriceTrait};
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

/// Struct to store the prices of tokens of a market.
/// # Params
/// * `indexTokenPrice` - Price of the market's index token.
/// * `tokens` - Price of the market's long token.
/// * `compacted_oracle_block_numbers` - Price of the market's short token.
/// Struct to store the prices of tokens of a market
#[derive(Drop, starknet::Store, Serde)]
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

struct GetExpectedMinTokenBalanceCache {
    pool_amount: u128,
    swap_impact_pool_amount: u128,
    claimable_collateral_amount: u128,
    claimable_fee_amount: u128,
    claimable_ui_fee_amount: u128,
    affiliate_reward_amount: u128,
}

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
fn get_open_interest_for_market(data_store: IDataStoreSafeDispatcher, market: @Market) -> u128 {
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
/// * `event_emitter` - The interface to interact with `EventEmitter` contract.
/// * `market_address` - The market to increment.
/// * `token` - The claimable token.
/// * `account` - The account to increment the claimable collateral for.
/// * `delta` - The amount to increment by.
/// * `block_timestamp` - The block timestamp.
fn increment_claimable_collateral_amount(
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    market_address: ContractAddress,
    token: ContractAddress,
    account: ContractAddress,
    delta: u128,
    block_timestamp: u64,
) {
    let divisor = data_store.get_u128(keys::claimable_collateral_time_divisor()).unwrap();
    // Get current timestamp.
    let current_timestamp = block_timestamp.into();
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
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    market: @Market,
    collateral_token: ContractAddress,
    is_long: bool,
    // TODO: Move to `i128` when `apply_delta_to_u128` is implemented and when supported in used Cairo version.
    delta: u128
) -> u128 {
    // Check that the market is not a swap only market.
    assert(
        (*market.index_token).is_non_zero(),
        MarketError::OPEN_INTEREST_CANNOT_BE_UPDATED_FOR_SWAP_ONLY_MARKET
    );

    // Increment the open interest by the delta.
    // TODO: create `apply_delta_to_u128` function in `DataStore` contract and pass `delta` as `i128`.
    let next_value = data_store
        .increment_u128(keys::open_interest_key(*market.market_token, collateral_token, is_long), 0)
        .unwrap();

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

/// Validata the open interest.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to validate the open interest for.
/// * `is_long` - Whether to validate the long or short side.
fn validate_open_interest(data_store: IDataStoreSafeDispatcher, market: @Market, is_long: bool) {
    // Get the open interest.
    let open_interest = get_open_interest_for_market_is_long(data_store, market, is_long);

    // Get the maximum open interest.
    let max_open_interest = get_max_open_interest(data_store, *market.market_token, is_long);

    // Check that the open interest is not greater than the maximum open interest.
    assert(open_interest <= max_open_interest, MarketError::MAX_OPEN_INTEREST_EXCEEDED);
}

// Get the min pnl factor after ADL
// Parameters
// * `data_store` - - The data store to use.
// * `market` - the market to check.
// * `is_long` whether to check the long or short side.
fn get_min_pnl_factor_after_adl(
    data_store: IDataStoreSafeDispatcher, market: ContractAddress, is_long: bool
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
    data_store: IDataStoreSafeDispatcher,
    oracle: IOracleSafeDispatcher,
    market: ContractAddress,
    is_long: bool,
    maximize: bool
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
    data_store: IDataStoreSafeDispatcher,
    oracle: IOracleSafeDispatcher,
    market_address: ContractAddress,
    is_long: bool,
    pnl_factor_type: felt252
) -> (bool, u128, u128) {
    // TODO
    (true, 0, 0)
}


/// Validate that the specified market exists and is enabled
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - The address of the market
fn validate_enable_market(data_store: IDataStoreSafeDispatcher, market: Market) {
    assert(market.market_token.is_non_zero(), 'EmptyMarket');
    let is_market_disabled = data_store
        .get_bool(keys::is_market_disabled_key(market.market_token))
        .expect('validate_enable_market::result')
        .expect('validate_enable_market::bool');
    assert(!is_market_disabled, 'DisabledMarket');
}

/// Get the enabled market, revert if the market does not exist or is not enabled
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - The address of the market
fn get_enabled_market(data_store: IDataStoreSafeDispatcher, market: ContractAddress) -> Market {
    let market = market_store_utils::get(data_store, market);
    validate_enable_market(data_store, market);
    market
}

/// Check if the market is valid for an adress
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - The address of the market
fn validate_market_token_balance(data_store: IDataStoreSafeDispatcher, market: ContractAddress,) {
    let market = get_enabled_market(data_store, market);
    validate_market_token_balance_market(data_store, market);
}


/// Check if the market is valid
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - The market
fn validate_market_token_balance_market(data_store: IDataStoreSafeDispatcher, market: Market,) {
    validate_market_token_balance_token(data_store, market, market.long_token);

    if (market.long_token == market.short_token) {
        return;
    }

    validate_market_token_balance_token(data_store, market, market.short_token);
}

///  Validate that market is valid for the token 
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - The market to increment claimable fees for.
/// * `token` - The fee token.
fn validate_market_token_balance_token(
    data_store: IDataStoreSafeDispatcher, market: Market, token: ContractAddress
) {
    assert(
        market.market_token.is_non_zero(),
        MarketError::EMPTY_ADDRESS_IN_MARKET_TOKEN_BALANCE_VALIDATION
    );
    assert(token.is_non_zero(), MarketError::EMPTY_ADDRESS_TOKEN_BALANCE_VAL);

    let balance = IERC20Dispatcher { contract_address: token }.balance_of(market.market_token);
    let balance_u128 = balance.try_into().unwrap();
    let expected_min_balance = get_expected_min_token_balance(data_store, market, token);
    assert(balance_u128 >= expected_min_balance, MarketError::INVALID_MARKET_TOKEN_BALANCE);

    // funding fees can be claimed even if the collateral for positions that should pay funding fees
    // hasn't been reduced yet
    // due to that, funding fees and collateral is excluded from the expectedMinBalance calculation
    // and validated separately

    // use 1 for the getCollateralSum divisor since getCollateralSum does not sum over both the
    // longToken and shortToken
    let mut collateral_amount = get_collateral_sum(data_store, market.market_token, token, true, 1);
    collateral_amount += get_collateral_sum(data_store, market.market_token, token, false, 1);
    assert(
        balance_u128 >= collateral_amount,
        MarketError::INVALID_MARKET_TOKEN_BALANCE_FOR_COLLATERAL_AMOUNT
    );
    let claimable_funding_fee_amount = data_store
        .get_u128(keys::claimable_funding_amount_key(market.market_token, token))
        .expect('claimable_funding_fee_amount');

    // in case of late liquidations, it may be possible for the claimableFundingFeeAmount to exceed the market token balance
    // but this should be very rare
    assert(
        balance >= claimable_funding_fee_amount.into(),
        MarketError::INVALID_MARKET_TOKEN_BALANCE_FOR_CLAIMABLE_FUNDING
    );
}

/// Get the expected min token balance by summing all fees
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - The market to increment claimable fees for.
/// * `token` - The fee token.
fn get_expected_min_token_balance(
    data_store: IDataStoreSafeDispatcher, market: Market, token: ContractAddress
) -> u128 {
    // get the pool amount directly as MarketUtils.getPoolAmount will divide the amount by 2
    // for markets with the same long and short token
    let pool_amount = data_store
        .get_u128(keys::pool_amount_key(market.market_token, token))
        .expect('pool_amount');
    let swap_impact_pool_amount = get_swap_impact_pool_amount(
        data_store, market.market_token, token
    )
        .into();
    let claimable_collateral_amount = data_store
        .get_u128(keys::claimable_collateral_amount_key(market.market_token, token))
        .expect('claimable_collateral_amount');
    let claimable_fee_amount = data_store
        .get_u128(keys::claimable_fee_amount_key(market.market_token, token))
        .expect('claimable_fee_amount');
    let claimable_ui_fee_amount = data_store
        .get_u128(keys::claimable_fee_amount_key(market.market_token, token))
        .expect('claimable_ui_fee_amount');
    let affiliate_reward_amount = data_store
        .get_u128(keys::affiliate_reward_key(market.market_token, token))
        .expect('affiliate_reward_amount');

    // funding fees are excluded from this summation as claimable funding fees
    // are incremented without a corresponding decrease of the collateral of
    // other positions, the collateral of other positions is decreased when
    // those positions are updated
    pool_amount
        + swap_impact_pool_amount
        + claimable_collateral_amount
        + claimable_fee_amount
        + claimable_ui_fee_amount
        + affiliate_reward_amount
}

/// Get the total amount of position collateral for a market
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - The market to check
/// * `collateral_token` - the collateral_token to check
/// * `is_long` - Whether to get the value for longs or shorts
/// # Returns
/// The total amount of position collateral for a market
fn get_collateral_sum(
    data_store: IDataStoreSafeDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    divisor: u128
) -> u128 {
    let collateral_sum = data_store
        .get_u128(keys::collateral_sum_key(market, collateral_token, is_long))
        .expect('get_collateral_sum');
    collateral_sum / divisor
}
