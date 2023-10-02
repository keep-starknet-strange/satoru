// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, get_block_timestamp};

// Local imports.
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::chain::chain::{IChainDispatcher, IChainDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::keys;
use satoru::market::{
    market::Market, error::MarketError, market_pool_value_info::MarketPoolValueInfo,
    market_store_utils, market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait}
};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::price::price::{Price, PriceTrait};
use satoru::position::position::Position;
use satoru::utils::{i128::{I128Store, I128Serde, I128Div, I128Mul, I128Default}, error_utils};
use satoru::utils::{calc, precision, span32::Span32};
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

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

#[derive(Default, Drop, starknet::Store, Serde)]
struct CollateralType {
    long_token: u128,
    short_token: u128,
}

#[derive(Default, Drop, starknet::Store, Serde)]
struct PositionType {
    long: CollateralType,
    short: CollateralType,
}

#[derive(Default, Drop, starknet::Store, Serde)]
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

/// Get the market token price.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to get the market token price for.
/// * `long_token_price` - The price of the long token.
/// * `short_token_price` - The price of the short token.
/// * `index_token_price` - The price of the index token.
/// * `maximize` - Whether to maximize or minimize the market token price.
/// # Returns
/// The market token price.
fn get_market_token_price(
    data_store: IDataStoreDispatcher,
    market: Market,
    index_token_price: Price,
    long_token_price: Price,
    short_token_price: Price,
    pnl_factor_type: felt252,
    maximize: bool
) -> (i128, MarketPoolValueInfo) {
    let supply = get_market_token_supply(
        IMarketTokenDispatcher { contract_address: market.market_token }
    );

    let pool_value_info = get_pool_value_info(
        data_store,
        market,
        index_token_price,
        long_token_price,
        short_token_price,
        pnl_factor_type,
        maximize
    );

    // if the supply is zero then treat the market token price as 1 USD
    if supply == 0 {
        return (calc::to_signed(precision::FLOAT_PRECISION, true), pool_value_info);
    }

    if pool_value_info.pool_value == 0 {
        return (0, pool_value_info);
    }

    let market_token_price = precision::mul_div_inum(
        precision::WEI_PRECISION, pool_value_info.pool_value, supply
    );
    (market_token_price, pool_value_info)
}

/// Gets the total supply of the marketToken.
/// # Arguments
/// * `market_token` - The market token whose total supply is to be retrieved.
/// # Returns
/// The total supply of the given marketToken.
fn get_market_token_supply(market_token: IMarketTokenDispatcher) -> u128 {
    market_token.total_supply()
}

/// Get the opposite token of the market
/// if the input_token is the token_long return the short_token and vice versa
/// # Arguments
/// * `market` - The market to validate the open interest for.
/// * `token` - The input_token.
/// # Returns
/// The opposite token.
fn get_opposite_token(input_token: ContractAddress, market: @Market) -> ContractAddress {
    if input_token == *market.long_token {
        *market.short_token
    } else if input_token == *market.short_token {
        *market.long_token
    } else {
        panic(
            array![
                MarketError::UNABLE_TO_GET_OPPOSITE_TOKEN,
                input_token.into(),
                (*market.market_token).into()
            ]
        )
    }
}

fn validate_swap_market_with_address(
    data_store: IDataStoreDispatcher, market_address: ContractAddress
) {
    let market = market_store_utils::get(data_store, market_address);
    validate_swap_market(data_store, market);
}

/// Validata the swap market.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to validate the open interest for.
fn validate_swap_market(data_store: IDataStoreDispatcher, market: Market) {
    validate_enabled_market(data_store, market);

    if market.long_token == market.short_token {
        panic(array![MarketError::INVALID_SWAP_MARKET, market.market_token.into()])
    }
}

// @dev get the token price from the stored MarketPrices
// @param token the token to get the price for
// @param the market values
// @param the market token prices
// @return the token price from the stored MarketPrices
fn get_cached_token_price(token: ContractAddress, market: Market, prices: MarketPrices) -> Price {
    if token == market.long_token {
        prices.long_token_price
    } else if token == market.short_token {
        prices.short_token_price
    } else if token == market.index_token {
        prices.index_token_price
    } else {
        MarketError::UNABLE_TO_GET_CACHED_TOKEN_PRICE(token, market.market_token)
    }
}

/// Returns the primary prices for the market tokens.
/// # Parameters
/// - `oracle`: The Oracle instance.
/// - `market`: The market values.
fn get_market_prices(oracle: IOracleDispatcher, market: Market) -> MarketPrices {
    MarketPrices {
        index_token_price: oracle.get_primary_price(market.index_token),
        long_token_price: oracle.get_primary_price(market.long_token),
        short_token_price: oracle.get_primary_price(market.short_token),
    }
}

/// Get the usd value of either the long or short tokens in the pool
/// without accounting for the pnl of open positions
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market values.
/// * `prices` - The prices of the market tokens.
/// * `is_long` - Whether to return the value for the long or short token.
/// * `maximize` - Whether to maximize or minimize the pool value.
/// # Returns
/// The usd value of either the long or short tokens in the pool.
fn get_pool_usd_without_pnl(
    data_store: IDataStoreDispatcher,
    market: @Market,
    prices: MarketPrices,
    is_long: bool,
    maximize: bool
) -> u128 {
    let token = if is_long {
        *market.long_token
    } else {
        *market.short_token
    };
    // note that if it is a single token market, the poolAmount returned will be
    // the amount of tokens in the pool divided by 2
    let pool_amount = get_pool_amount(data_store, market, token);
    let token_price = if maximize {
        if is_long {
            prices.long_token_price.max
        } else {
            prices.short_token_price.max
        }
    } else {
        if is_long {
            prices.long_token_price.min
        } else {
            prices.short_token_price.min
        }
    };
    pool_amount * token_price
}

/// Get the USD value of a pool.
/// The value of a pool is the worth of the liquidity provider tokens in the pool - pending trader pnl.
/// We use the token index prices to calculate this and ignore price impact since if all positions were closed the
/// net price impact should be zero.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market values.
/// * `index_token_price` - The price of the index token.
/// * `long_token_price` - The price of the long token.
/// * `short_token_price` - The price of the short token.
/// * `maximize` - Whether to maximize or minimize the pool value.
/// # Returns
/// The value information of a pool.
fn get_pool_value_info(
    data_store: IDataStoreDispatcher,
    market: Market,
    index_token_price: Price,
    long_token_price: Price,
    short_token_price: Price,
    pnl_factor_type: felt252,
    maximize: bool
) -> MarketPoolValueInfo {
    let mut result: MarketPoolValueInfo = Default::default();

    result.long_token_amount = get_pool_amount(data_store, @market, market.long_token);
    result.short_token_amount = get_pool_amount(data_store, @market, market.short_token);

    result.long_token_usd = result.long_token_amount * long_token_price.pick_price(maximize);
    result.short_token_usd = result.short_token_amount * short_token_price.pick_price(maximize);

    result.pool_value = calc::to_signed(result.long_token_usd + result.short_token_usd, true);

    let prices = MarketPrices { index_token_price, long_token_price, short_token_price };

    result
        .total_borrowing_fees = get_total_pending_borrowing_fees(data_store, market, prices, true);

    result
        .total_borrowing_fees +=
            get_total_pending_borrowing_fees(data_store, market, prices, false);

    result.borrowing_fee_pool_factor = precision::FLOAT_PRECISION
        - data_store.get_u128(keys::borrowing_fee_receiver_factor());

    let value = precision::apply_factor_u128(
        result.total_borrowing_fees, result.borrowing_fee_pool_factor
    );
    result.pool_value += calc::to_signed(value, true);

    // !maximize should be used for net pnl as a larger pnl leads to a smaller pool value
    // and a smaller pnl leads to a larger pool value
    //
    // while positions will always be closed at the less favourable price
    // using the inverse of maximize for the getPnl calls would help prevent
    // gaming of market token values by increasing the spread
    //
    // liquidations could be triggerred by manipulating a large spread but
    // that should be more difficult to execute

    result.long_pnl = get_pnl(data_store, @market, @index_token_price, true, !maximize);

    result
        .long_pnl =
            get_capped_pnl(
                data_store,
                market.market_token,
                true,
                result.long_pnl,
                result.long_token_usd,
                pnl_factor_type,
            );

    result.short_pnl = get_pnl(data_store, @market, @index_token_price, false, !maximize);

    result
        .short_pnl =
            get_capped_pnl(
                data_store,
                market.market_token,
                false,
                result.short_pnl,
                result.short_token_usd,
                pnl_factor_type,
            );

    result.net_pnl = result.long_pnl + result.short_pnl;
    result.pool_value = result.pool_value - result.net_pnl;

    result.impact_pool_amount = get_position_impact_pool_amount(data_store, market.market_token);
    // use !maximize for pick_price since the impact_pool_usd is deducted from the pool_value
    let impact_pool_usd = result.impact_pool_amount * index_token_price.pick_price(!maximize);

    result.pool_value -= calc::to_signed(impact_pool_usd, true);

    result
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
    let long_pnl = get_pnl(data_store, market, index_token_price, true, maximize);
    let short_pnl = get_pnl(data_store, market, index_token_price, false, maximize);
    long_pnl + short_pnl
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
    if pnl < 0 {
        return pnl;
    }
    let max_pnl_factor = get_max_pnl_factor(data_store, pnl_factor_type, market, is_long);
    let max_pnl = calc::to_signed(precision::apply_factor_u128(pool_usd, max_pnl_factor), true);
    if pnl > max_pnl {
        max_pnl
    } else {
        pnl
    }
}

fn get_pnl_with_u128_price(
    data_store: IDataStoreDispatcher,
    market: @Market,
    index_token_price: u128,
    is_long: bool,
    maximize: bool
) -> i128 {
    let index_token_price_ = Price { min: index_token_price, max: index_token_price };
    get_pnl(data_store, market, @index_token_price_, is_long, maximize)
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
    error_utils::check_division_by_zero(divisor, 'get_pool_amount');
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
    error_utils::check_division_by_zero(divisor, 'increment_claimable_collateral');
    // Get current timestamp.
    let current_timestamp = chain.get_block_timestamp().into();
    let time_key = current_timestamp / divisor;

    // Increment the collateral amount for the account.
    let key = keys::claimable_collateral_amount_for_account_key(
        market_address, token, time_key, account
    );
    let next_value = data_store.increment_u128(key, delta);

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

/// Claim funding fees
/// # Arguments
/// * `data_store` - The data store to use.
/// * `event_emitter` - The interface to interact with `EventEmitter` contract.
/// * `market_address` - The market to claim for.
/// * `token` - The token to claim.
/// * `account` - The account to claim for.
/// * `receiver` - The receiver to send the amount to.
fn claim_funding_fees(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market_address: ContractAddress,
    token: ContractAddress,
    account: ContractAddress,
    receiver: ContractAddress
) -> u128 {
    let key = keys::claimable_funding_amount_by_account_key(market_address, token, account);
    let claimable_amount = data_store.get_u128(key);
    data_store.set_u128(key, 0);

    let next_pool_value = data_store
        .decrement_u128(
            keys::claimable_funding_amount_key(market_address, token), claimable_amount
        );

    // Transfer the amount to the receiver.
    IBankDispatcher { contract_address: market_address }
        .transfer_out(token, receiver, claimable_amount);

    // Validate the market token balance.
    validate_market_token_balance_with_address(data_store, market_address);

    event_emitter
        .emit_funding_fees_claimed(
            market_address, token, account, receiver, claimable_amount, next_pool_value
        );

    claimable_amount
}

/// Claim collateral
/// # Arguments
/// * `data_store` - The data store to use.
/// * `event_emitter` - The interface to interact with `EventEmitter` contract.
/// * `market_address` - The market to claim for.
/// * `token` - The token to claim.
/// * `time_key` - The time key.
/// * `account` - The account to claim for.
/// * `receiver` - The receiver to send the amount to.
fn claim_collateral(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market_address: ContractAddress,
    token: ContractAddress,
    time_key: u128,
    account: ContractAddress,
    receiver: ContractAddress
) -> u128 {
    let key = keys::claimable_collateral_amount_for_account_key(
        market_address, token, time_key, account
    );
    let claimable_amount = data_store.get_u128(key);
    data_store.set_u128(key, 0);

    let key = keys::claimable_collateral_factor_key(market_address, token, time_key);
    let claimable_factor_for_time = data_store.get_u128(key);

    let key = keys::claimable_collateral_factor_for_account_key(
        market_address, token, time_key, account
    );
    let claimable_factor_for_account = data_store.get_u128(key);

    let claimable_factor = if claimable_factor_for_time > claimable_factor_for_account {
        claimable_factor_for_time
    } else {
        claimable_factor_for_account
    };

    let key = keys::claimed_collateral_amount_key(market_address, token, time_key, account);
    let claimed_amount = data_store.get_u128(key);

    let adjusted_claimable_amount = precision::apply_factor_u128(
        claimable_amount, claimable_factor
    );
    if adjusted_claimable_amount <= claimed_amount {
        panic(
            array![
                MarketError::COLLATERAL_ALREADY_CLAIMED,
                adjusted_claimable_amount.into(),
                claimed_amount.into()
            ]
        )
    }

    let amount_to_be_claimed = adjusted_claimable_amount - claimed_amount;

    let key = keys::claimed_collateral_amount_key(market_address, token, time_key, account);
    data_store.set_u128(key, adjusted_claimable_amount);

    let key = keys::claimable_collateral_amount_key(market_address, token);
    let next_pool_value = data_store.decrement_u128(key, amount_to_be_claimed);

    IBankDispatcher { contract_address: market_address }
        .transfer_out(token, receiver, amount_to_be_claimed);

    validate_market_token_balance_with_address(data_store, market_address);

    event_emitter
        .emit_collateral_claimed(
            market_address,
            token,
            account,
            receiver,
            time_key,
            amount_to_be_claimed,
            next_pool_value
        );

    amount_to_be_claimed
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
    event_emitter: IEventEmitterDispatcher,
    market: Market,
    token: ContractAddress,
    delta: i128
) -> u128 {
    let key = keys::pool_amount_key(market.market_token, token);
    let next_value = data_store.apply_delta_to_u128(key, delta, 'negative poolAmount');

    apply_delta_to_virtual_inventory_for_swaps(data_store, event_emitter, market, token, delta);

    event_emitter.emit_pool_amount_updated(market.market_token, token, delta, next_value);

    next_value
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
    data_store: IDataStoreDispatcher, market: ContractAddress, is_positive: bool
) -> u128 {
    let (positive_impact_factor, negative_impact_factor) = get_adjusted_position_impact_factors(
        data_store, market
    );
    if is_positive {
        positive_impact_factor
    } else {
        negative_impact_factor
    }
}

fn get_adjusted_position_impact_factors(
    data_store: IDataStoreDispatcher, market: ContractAddress
) -> (u128, u128) {
    let mut positive_impact_factor = data_store
        .get_u128(keys::position_impact_factor_key(market, true));
    let negative_impact_factor = data_store
        .get_u128(keys::position_impact_factor_key(market, false));
    // if the positive impact factor is more than the negative impact factor, positions could be opened
    // and closed immediately for a profit if the difference is sufficient to cover the position fees
    if positive_impact_factor > negative_impact_factor {
        positive_impact_factor = negative_impact_factor;
    }
    (positive_impact_factor, negative_impact_factor)
}

/// Cap the input priceImpactUsd by the available amount in the swap impact pool and the max positive swap impact factor.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The trading market.
/// * `token_price` - The price of the token.
/// * `price_impact_usd` - The calculated USD price impact.
/// * `size_delta_usd` - The size delta in USD.
/// # Returns
/// The capped priceImpactUsd.
fn get_capped_position_impact_usd(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    token_price: Price,
    mut price_impact_usd: i128,
    size_delta_usd: u128
) -> i128 {
    if price_impact_usd < 0 {
        return price_impact_usd;
    }

    let impact_pool_amount = get_position_impact_pool_amount(data_store, market);
    let max_price_impact_usd_based_on_impact_pool = calc::to_signed(
        impact_pool_amount * token_price.min, true
    );

    if price_impact_usd > max_price_impact_usd_based_on_impact_pool {
        price_impact_usd = max_price_impact_usd_based_on_impact_pool;
    }

    let max_price_impact_factor = get_max_position_impact_factor(data_store, market, true);
    let max_price_impact_usd_based_on_max_price_impact_factor = calc::to_signed(
        precision::apply_factor_u128(size_delta_usd, max_price_impact_factor), true
    );

    if price_impact_usd > max_price_impact_usd_based_on_max_price_impact_factor {
        max_price_impact_usd_based_on_max_price_impact_factor
    } else {
        price_impact_usd
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
    delta: i128
) -> u128 {
    // Check that the market is not a swap only market.
    assert(
        (*market.index_token).is_non_zero(),
        MarketError::OPEN_INTEREST_CANNOT_BE_UPDATED_FOR_SWAP_ONLY_MARKET
    );

    // Increment the open interest by the delta.
    let key = keys::open_interest_key(*market.market_token, collateral_token, is_long);
    let next_value = data_store.apply_delta_to_u128(key, delta, 'negative open interest');

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

/// Apply a delta to the open interest in tokens.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `event_emitter` - The interface to interact with `EventEmitter` contract.
/// * `market` - The market to apply the delta to.
/// * `collateral_token` - The collateral token to apply the delta to.
/// * `is_long` - Whether to apply the delta to the long or short side.
/// * `delta` - The delta to apply.
/// # Returns
/// The updated open interest in tokens.
fn apply_delta_to_open_interest_in_tokens(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: Market,
    collateral_token: ContractAddress,
    is_long: bool,
    delta: i128
) -> u128 {
    let key = keys::open_interest_in_tokens_key(market.market_token, collateral_token, is_long);
    let next_value = data_store.apply_delta_to_u128(key, delta, 'negative open interest tokens');

    event_emitter
        .emit_open_interest_in_tokens_updated(
            market.market_token, collateral_token, is_long, delta, next_value
        );

    next_value
}

/// @dev apply a delta to the collateral sum
/// # Arguments
/// * `data_store` DataStore
/// * `event_emitter` EventEmitter
/// * `market` the market to apply to
/// * `collateral_token` the collateralToken to apply to
/// * `is_long` whether to apply to the long or short side
/// * `delta` the delta amount
/// # Returns
/// The updated collateral sum amount
fn apply_delta_to_collateral_sum(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    delta: i128
) -> u128 {
    let key = keys::collateral_sum_key(market, collateral_token, is_long);
    let next_value = data_store.apply_delta_to_u128(key, delta, 'negative collateralSum');

    event_emitter.emit_collateral_sum_updated(market, collateral_token, is_long, delta, next_value);

    next_value
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
) {
    let result = get_next_funding_amount_per_size(data_store, market, prices);

    apply_delta_to_funding_fee_amount_per_size(
        data_store,
        event_emitter,
        market.market_token,
        market.long_token,
        true,
        result.funding_fee_amount_per_size_delta.long.long_token
    );

    apply_delta_to_funding_fee_amount_per_size(
        data_store,
        event_emitter,
        market.market_token,
        market.long_token,
        false,
        result.funding_fee_amount_per_size_delta.short.long_token
    );

    apply_delta_to_funding_fee_amount_per_size(
        data_store,
        event_emitter,
        market.market_token,
        market.short_token,
        true,
        result.funding_fee_amount_per_size_delta.long.short_token
    );

    apply_delta_to_funding_fee_amount_per_size(
        data_store,
        event_emitter,
        market.market_token,
        market.short_token,
        false,
        result.funding_fee_amount_per_size_delta.short.short_token
    );

    apply_delta_to_claimable_funding_amount_per_size(
        data_store,
        event_emitter,
        market.market_token,
        market.long_token,
        true,
        result.claimable_funding_amount_per_size_delta.long.long_token
    );

    apply_delta_to_claimable_funding_amount_per_size(
        data_store,
        event_emitter,
        market.market_token,
        market.long_token,
        false,
        result.claimable_funding_amount_per_size_delta.short.long_token
    );

    apply_delta_to_claimable_funding_amount_per_size(
        data_store,
        event_emitter,
        market.market_token,
        market.short_token,
        true,
        result.claimable_funding_amount_per_size_delta.long.short_token
    );

    apply_delta_to_claimable_funding_amount_per_size(
        data_store,
        event_emitter,
        market.market_token,
        market.short_token,
        false,
        result.claimable_funding_amount_per_size_delta.short.short_token
    );

    let key = keys::funding_updated_at_key(market.market_token);
    data_store.set_u128(key, get_block_timestamp().into());
}

/// Get the next funding amount per size values.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to update.
/// * `prices` - The market prices.
/// # Returns
/// The next funding amount per size values.
fn get_next_funding_amount_per_size(
    data_store: IDataStoreDispatcher, market: Market, prices: MarketPrices
) -> GetNextFundingAmountPerSizeResult {
    let mut result: GetNextFundingAmountPerSizeResult = Default::default();
    let divisor = get_pool_divisor(market.long_token, market.short_token);

    // get the open interest values by long / short and by collateral used.

    let open_interest = PositionType {
        long: CollateralType {
            long_token: get_open_interest(
                data_store, market.market_token, market.long_token, true, divisor
            ),
            short_token: get_open_interest(
                data_store, market.market_token, market.short_token, true, divisor
            ),
        },
        short: CollateralType {
            long_token: get_open_interest(
                data_store, market.market_token, market.long_token, false, divisor
            ),
            short_token: get_open_interest(
                data_store, market.market_token, market.short_token, false, divisor
            ),
        },
    };

    // sum the open interest values to get the total long and short open interest values.
    let long_open_interest = open_interest.long.long_token + open_interest.long.short_token;
    let short_open_interest = open_interest.short.long_token + open_interest.short.short_token;

    // if either long or short open interest is zero, then funding should not be updated
    // as there would not be any user to pay the funding to.
    if long_open_interest == 0 || short_open_interest == 0 {
        return result;
    }

    // if the blockchain is not progressing / a market is disabled, funding fees
    // will continue to accumulate
    // this should be a rare occurrence so funding fees are not adjusted for this case.
    let duration_in_seconds = get_seconds_since_funding_updated(data_store, market.market_token);

    let diff_usd = calc::diff(long_open_interest, short_open_interest);
    let total_open_interest = long_open_interest + short_open_interest;
    let size_of_larger_side = if long_open_interest > short_open_interest {
        long_open_interest
    } else {
        short_open_interest
    };

    result
        .funding_factor_per_second =
            get_funding_factor_per_second(
                data_store, market.market_token, diff_usd, total_open_interest
            );

    // for single token markets, if there is $200,000 long open interest
    // and $100,000 short open interest and if the fundingUsd is $8:
    // fundingUsdForLongCollateral: $4
    // fundingUsdForShortCollateral: $4
    // fundingFeeAmountPerSizeDelta.long.longToken: 4 / 100,000
    // fundingFeeAmountPerSizeDelta.long.shortToken: 4 / 100,000
    // claimableFundingAmountPerSizeDelta.short.longToken: 4 / 100,000
    // claimableFundingAmountPerSizeDelta.short.shortToken: 4 / 100,000
    //
    // the divisor for fundingFeeAmountPerSizeDelta is 100,000 because the
    // cache.openInterest.long.longOpenInterest and cache.openInterest.long.shortOpenInterest is divided by 2
    //
    // when the fundingFeeAmountPerSize value is incremented, it would be incremented twice:
    // 4 / 100,000 + 4 / 100,000 = 8 / 100,000
    //
    // since the actual long open interest is $200,000, this would result in a total of 8 / 100,000 * 200,000 = $16 being charged
    //
    // when the claimableFundingAmountPerSize value is incremented, it would similarly be incremented twice:
    // 4 / 100,000 + 4 / 100,000 = 8 / 100,000
    //
    // when calculating the amount to be claimed, the longTokenClaimableFundingAmountPerSize and shortTokenClaimableFundingAmountPerSize
    // are compared against the market's claimableFundingAmountPerSize for the longToken and claimableFundingAmountPerSize for the shortToken
    //
    // since both these values will be duplicated, the amount claimable would be:
    // (8 / 100,000 + 8 / 100,000) * 100,000 = $16
    //
    // due to these, the fundingUsd should be divided by the divisor

    let funding_usd = precision::apply_factor_u128(
        size_of_larger_side, duration_in_seconds * result.funding_factor_per_second
    );
    let funding_usd = funding_usd / divisor;

    result.longs_pay_shorts = long_open_interest > short_open_interest;

    // split the fundingUsd value by long and short collateral
    // e.g. if the fundingUsd value is $500, and there is $1000 of long open interest using long collateral and $4000 of long open interest
    // with short collateral, then $100 of funding fees should be paid from long positions using long collateral, $400 of funding fees
    // should be paid from long positions using short collateral
    // short positions should receive $100 of funding fees in long collateral and $400 of funding fees in short collateral
    let funding_usd_for_long_collateral = if result.longs_pay_shorts {
        precision::mul_div(funding_usd, open_interest.long.long_token, long_open_interest)
    } else {
        precision::mul_div(funding_usd, open_interest.short.long_token, short_open_interest)
    };

    let funding_usd_for_short_collateral = if result.longs_pay_shorts {
        precision::mul_div(funding_usd, open_interest.long.short_token, long_open_interest)
    } else {
        precision::mul_div(funding_usd, open_interest.short.short_token, short_open_interest)
    };

    // calculate the change in funding amount per size values
    // for example, if the fundingUsdForLongCollateral is $100, the longToken price is $2000, the longOpenInterest is $10,000, shortOpenInterest is $5000
    // if longs pay shorts then the fundingFeeAmountPerSize.long.longToken should be increased by 0.05 tokens per $10,000 or 0.000005 tokens per $1
    // the claimableFundingAmountPerSize.short.longToken should be increased by 0.05 tokens per $5000 or 0.00001 tokens per $1
    if result.longs_pay_shorts {
        // use the same longTokenPrice.max and shortTokenPrice.max to calculate the amount to be paid and received
        // positions only pay funding in the position's collateral token
        // so the fundingUsdForLongCollateral is divided by the total long open interest for long positions using the longToken as collateral
        // and the fundingUsdForShortCollateral is divided by the total long open interest for long positions using the shortToken as collateral
        let amount = get_funding_amount_per_size_delta(
            funding_usd_for_long_collateral,
            open_interest.long.long_token,
            prices.long_token_price.max,
            true // roundUpMagnitude
        );
        result.funding_fee_amount_per_size_delta.long.long_token = amount;

        let amount = get_funding_amount_per_size_delta(
            funding_usd_for_short_collateral,
            open_interest.long.short_token,
            prices.short_token_price.max,
            true // roundUpMagnitude
        );
        result.funding_fee_amount_per_size_delta.long.short_token = amount;

        // positions receive funding in both the longToken and shortToken
        // so the fundingUsdForLongCollateral and fundingUsdForShortCollateral is divided by the total short open interest
        let amount = get_funding_amount_per_size_delta(
            funding_usd_for_long_collateral,
            short_open_interest,
            prices.long_token_price.max,
            false // roundUpMagnitude
        );
        result.claimable_funding_amount_per_size_delta.short.long_token = amount;

        let amount = get_funding_amount_per_size_delta(
            funding_usd_for_short_collateral,
            short_open_interest,
            prices.short_token_price.max,
            false // roundUpMagnitude
        );
        result.claimable_funding_amount_per_size_delta.short.short_token = amount;
    } else {
        // use the same longTokenPrice.max and shortTokenPrice.max to calculate the amount to be paid and received
        // positions only pay funding in the position's collateral token
        // so the fundingUsdForLongCollateral is divided by the total short open interest for short positions using the longToken as collateral
        // and the fundingUsdForShortCollateral is divided by the total short open interest for short positions using the shortToken as collateral
        let amount = get_funding_amount_per_size_delta(
            funding_usd_for_long_collateral,
            open_interest.short.long_token,
            prices.long_token_price.max,
            true // roundUpMagnitude
        );
        result.funding_fee_amount_per_size_delta.short.long_token = amount;

        let amount = get_funding_amount_per_size_delta(
            funding_usd_for_short_collateral,
            open_interest.short.short_token,
            prices.short_token_price.max,
            true // roundUpMagnitude
        );
        result.funding_fee_amount_per_size_delta.short.short_token = amount;

        // positions receive funding in both the longToken and shortToken
        // so the fundingUsdForLongCollateral and fundingUsdForShortCollateral is divided by the total long open interest
        let amount = get_funding_amount_per_size_delta(
            funding_usd_for_long_collateral,
            long_open_interest,
            prices.long_token_price.max,
            false // roundUpMagnitude
        );
        result.claimable_funding_amount_per_size_delta.long.long_token = amount;

        let amount = get_funding_amount_per_size_delta(
            funding_usd_for_short_collateral,
            long_open_interest,
            prices.short_token_price.max,
            false // roundUpMagnitude
        );
        result.claimable_funding_amount_per_size_delta.long.short_token = amount;
    }

    result
}


///////////////////////////////////////////////////////////////////////

fn get_swap_impact_amount_with_cap(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    token_price: Price,
    price_impact_usd: i128 //TODO : check u128
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
    error_utils::check_division_by_zero(divisor, 'get_open_interest');
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
    error_utils::check_division_by_zero(divisor, 'get_open_interest_in_tokens');
    data_store.get_u128(keys::open_interest_in_tokens_key(market, collateral_token, is_long))
        / divisor
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

/// Validates the swap path to ensure each market in the path is valid and the path length does not 
//  exceed the maximum allowed length.
/// # Arguments
/// * `data_store` - The DataStore contract containing platform configuration.
/// * `swap_path` - A vector of market addresses forming the swap path.
fn validate_swap_path(
    data_store: IDataStoreDispatcher, token_swap_path: Span32<ContractAddress>
) { //TODO
}


/// Update the swap impact pool amount, if it is a positive impact amount
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


/// Get the cumulative borrowing factor for a market
/// # Arguments
/// * `data_store` DataStore
/// * `market` the market to check
/// * `is_long` whether to check the long or short side
/// # Returns
// The cumulative borrowing factor for a market
fn get_cumulative_borrowing_factor(
    data_store: @IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u128 {
    (*data_store).get_u128(keys::cumulative_borrowing_factor_key(market, is_long))
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
    data_store: @IDataStoreDispatcher, market: ContractAddress
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

/// Get the virtual inventory for positions
/// # Arguments
/// * `dataStore` - DataStore
/// * `token` - the token to check
/// TODO internal function
fn get_virtual_inventory_for_positions(
    dataStore: IDataStoreDispatcher, token: ContractAddress
) -> (bool, i128) { /// TODO
    (true, 0)
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

/// Get the borrowing fees for a position, assumes that cumulativeBorrowingFactor
/// has already been updated to the latest value
/// # Arguments
/// * `dataStore` - DataStore
/// * `position` - Position
/// * `dataStore` - DataStore
/// # Returns
/// The borrowing fees for a position
fn get_borrowing_fees(dataStore: IDataStoreDispatcher, position: Position) -> u128 {
    0
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
    round_up_magnitude: bool
) -> u128 {
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

/// Get the total pending borrowing fees
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to check.
/// * `prices` - The prices of the market tokens.
/// * `is_long` - Whether to check the long or short side.
fn get_total_pending_borrowing_fees(
    data_store: IDataStoreDispatcher, market: Market, prices: MarketPrices, is_long: bool
) -> u128 {
    // TODO
    0
}

fn get_max_pnl_factor(
    data_store: IDataStoreDispatcher,
    pnl_factor_type: felt252,
    market: ContractAddress,
    is_long: bool
) -> u128 {
    // TODO
    0
}

fn apply_delta_to_virtual_inventory_for_swaps(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: Market,
    token: ContractAddress,
    delta: i128
) -> (bool, u128) {
    // TODO
    (true, 0)
}

fn get_max_position_impact_factor(
    data_store: IDataStoreDispatcher, market: ContractAddress, foo: bool
) -> u128 {
    // TODO
    0
}

fn apply_delta_to_funding_fee_amount_per_size(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    delta: u128
) { // TODO
}

fn apply_delta_to_claimable_funding_amount_per_size(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    delta: u128
) { // TODO
}

fn get_funding_amount_per_size_delta(
    funding_usd: u128, open_interest: u128, token_price: u128, round_up_magnitude: bool
) -> u128 {
    // TODO
    0
}

fn get_seconds_since_funding_updated(
    data_store: IDataStoreDispatcher, market: ContractAddress
) -> u128 {
    // TODO
    0
}

fn get_funding_factor_per_second(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    diff_usd: u128,
    total_open_interest: u128
) -> u128 {
    // TODO
    0
}


/// Validate that the specified market exists and is enabled
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - The address of the market
fn validate_enable_market(data_store: IDataStoreDispatcher, market: Market) {
    0;
}

/// Check if the market is valid
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - The market
fn validate_market_token_balance_market(data_store: IDataStoreDispatcher, market: Market) {
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
    data_store: IDataStoreDispatcher, market: Market, token: ContractAddress
) {
    0;
}

/// Get the expected min token balance by summing all fees
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - The market to increment claimable fees for.
/// * `token` - The fee token.
fn get_expected_min_token_balance(
    data_store: IDataStoreDispatcher, market: Market, token: ContractAddress
) -> u128 {
    // get the pool amount directly as MarketUtils.getPoolAmount will divide the amount by 2
    // for markets with the same long and short token
    0
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
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    divisor: u128
) -> u128 {
    0
}

/// Get the borrowing fees for a position by calculating the latest cumulativeBorrowingFactor
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher
/// * `position` - `Position`
/// * `market` - `Market`
/// * `prices` - The prices of the market tokens
/// # Returns
/// The borrowing fees for a position
fn get_next_borrowing_fees(
    data_store: IDataStoreDispatcher, position: Position, market: Market, prices: MarketPrices
) -> u128 {
    0
}
