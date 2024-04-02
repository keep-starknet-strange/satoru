// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, get_caller_address, get_block_timestamp, contract_address_const};
// Local imports.
use satoru::utils::calc::roundup_magnitude_division;
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::chain::chain::{IChainDispatcher, IChainDispatcherTrait};
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use satoru::chain::chain::Chain;
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::keys;
use satoru::event::event_emitter;
use satoru::market::{
    market::Market, error::MarketError, market_pool_value_info::MarketPoolValueInfo,
    market_store_utils, market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait}
};
use satoru::utils::span32::{Span32, Span32Trait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::oracle::oracle::{Oracle, SetPricesParams};
use satoru::oracle::oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait};
use satoru::price::price::{Price, PriceTrait};
use satoru::utils::calc;
use satoru::utils::precision::{FLOAT_PRECISION, FLOAT_PRECISION_SQRT};
use satoru::utils::precision::{mul_div_roundup, to_factor_ival, apply_factor_u256, to_factor};
use satoru::utils::precision;
use satoru::utils::calc::{roundup_division, to_signed, sum_return_int_256, to_unsigned};
use satoru::position::position::Position;
use satoru::utils::{i256::{i256, i256_neg}, error_utils};
use satoru::utils::precision::{apply_exponent_factor, float_to_wei, mul_div};
use satoru::data::keys::{skip_borrowing_fee_for_smaller_side, max_swap_path_length};
use debug::PrintTrait;

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
    long_token: u256,
    short_token: u256,
}

#[derive(Default, Drop, starknet::Store, Serde)]
struct PositionType {
    long: CollateralType,
    short: CollateralType,
}

#[derive(Default, Drop, starknet::Store, Serde)]
struct GetNextFundingAmountPerSizeResult {
    longs_pay_shorts: bool,
    funding_factor_per_second: u256,
    funding_fee_amount_per_size_delta: PositionType,
    claimable_funding_amount_per_size_delta: PositionType,
}

struct GetExpectedMinTokenBalanceCache {
    pool_amount: u256,
    swap_impact_pool_amount: u256,
    claimable_collateral_amount: u256,
    claimable_fee_amount: u256,
    claimable_ui_fee_amount: u256,
    affiliate_reward_amount: u256,
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
) -> (i256, MarketPoolValueInfo) {
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

    if pool_value_info.pool_value == Zeroable::zero() {
        return (Zeroable::zero(), pool_value_info);
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
fn get_market_token_supply(market_token: IMarketTokenDispatcher) -> u256 {
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
    let market = data_store.get_market(market_address);
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
        MarketError::UNABLE_TO_GET_CACHED_TOKEN_PRICE(token, market.market_token);
        Default::default()
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
    prices: @MarketPrices,
    is_long: bool,
    maximize: bool
) -> u256 {
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
    pool_amount * (*token_price)
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
        - data_store.get_u256(keys::borrowing_fee_receiver_factor());

    let value = precision::apply_factor_u256(
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
) -> i256 {
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
    pnl: i256,
    pool_usd: u256,
    pnl_factor_type: felt252
) -> i256 {
    if pnl < Zeroable::zero() {
        return pnl;
    }
    let max_pnl_factor = get_max_pnl_factor(data_store, pnl_factor_type, market, is_long);
    let max_pnl = calc::to_signed(precision::apply_factor_u256(pool_usd, max_pnl_factor), true);
    if pnl > max_pnl {
        max_pnl
    } else {
        pnl
    }
}

fn get_pnl_with_u256_price(
    data_store: IDataStoreDispatcher,
    market: @Market,
    index_token_price: u256,
    is_long: bool,
    maximize: bool
) -> i256 {
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
) -> i256 {
    // Get the open interest.
    let open_interest = calc::to_signed(
        get_open_interest_for_market_is_long(data_store, market, is_long), true
    );
    // Get the open interest in tokens.
    let open_interest_in_tokens = get_open_interest_in_tokens_for_market(
        data_store, market, is_long
    );
    // If either the open interest or the open interest in tokens is zero, return zero.
    if open_interest == Zeroable::zero() || open_interest_in_tokens == 0 {
        return Zeroable::zero();
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
) -> u256 {
    let divisor = get_pool_divisor(*market.long_token, *market.short_token);
    error_utils::check_division_by_zero(divisor, 'get_pool_amount');
    data_store.get_u256(keys::pool_amount_key(*market.market_token, token_address)) / divisor
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
) -> u256 {
    data_store.get_u256(keys::max_pool_amount_key(market_address, token_address))
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
) -> u256 {
    data_store.get_u256(keys::max_open_interest_key(market_address, is_long))
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
    event_emitter: IEventEmitterDispatcher,
    market_address: ContractAddress,
    token: ContractAddress,
    account: ContractAddress,
    delta: u256
) {
    let divisor = data_store.get_u256(keys::claimable_collateral_time_divisor());
    error_utils::check_division_by_zero(divisor, 'increment_claimable_collateral');
    // Get current timestamp.
    let current_timestamp = get_block_timestamp().into();
    let time_key = current_timestamp / divisor;

    // Increment the collateral amount for the account.
    let key = keys::claimable_collateral_amount_for_account_key(
        market_address, token, time_key, account
    );
    let next_value = data_store.increment_u256(key, delta);

    // Increment the total collateral amount for the market.
    let next_pool_value = data_store
        .increment_u256(keys::claimable_collateral_amount_key(market_address, token), delta);

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
    delta: u256
) {
    // Increment the funding amount for the account.
    let next_value = data_store
        .increment_u256(
            keys::claimable_funding_amount_by_account_key(market_address, token, account), delta
        );

    // Increment the total funding amount for the market.
    let next_pool_value = data_store
        .increment_u256(keys::claimable_funding_amount_key(market_address, token), delta);

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
) -> u256 {
    let key = keys::claimable_funding_amount_by_account_key(market_address, token, account);
    let claimable_amount = data_store.get_u256(key);
    data_store.set_u256(key, 0);

    let next_pool_value = data_store
        .decrement_u256(
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
    time_key: u256,
    account: ContractAddress,
    receiver: ContractAddress
) -> u256 {
    let key = keys::claimable_collateral_amount_for_account_key(
        market_address, token, time_key, account
    );
    let claimable_amount = data_store.get_u256(key);
    data_store.set_u256(key, 0);

    let key = keys::claimable_collateral_factor_key(market_address, token, time_key);
    let claimable_factor_for_time = data_store.get_u256(key);

    let key = keys::claimable_collateral_factor_for_account_key(
        market_address, token, time_key, account
    );
    let claimable_factor_for_account = data_store.get_u256(key);

    let claimable_factor = if claimable_factor_for_time > claimable_factor_for_account {
        claimable_factor_for_time
    } else {
        claimable_factor_for_account
    };

    let key = keys::claimed_collateral_amount_key(market_address, token, time_key, account);
    let claimed_amount = data_store.get_u256(key);

    let adjusted_claimable_amount = precision::apply_factor_u256(
        claimable_amount, claimable_factor
    );
    if adjusted_claimable_amount <= claimed_amount {
        panic(
            array![
                MarketError::COLLATERAL_ALREADY_CLAIMED,
                adjusted_claimable_amount.try_into().expect('u256 into felt failed'),
                claimed_amount.try_into().expect('u256 into felt failed')
            ]
        )
    }

    let amount_to_be_claimed = adjusted_claimable_amount - claimed_amount;

    let key = keys::claimed_collateral_amount_key(market_address, token, time_key, account);
    data_store.set_u256(key, adjusted_claimable_amount);

    let key = keys::claimable_collateral_amount_key(market_address, token);
    let next_pool_value = data_store.decrement_u256(key, amount_to_be_claimed);

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
    delta: i256
) -> u256 {
    let key = keys::pool_amount_key(market.market_token, token);
    let next_value = data_store.apply_delta_to_u256(key, delta, 'negative poolAmount');

    apply_delta_to_virtual_inventory_for_swaps(data_store, event_emitter, market, token, delta);

    event_emitter.emit_pool_amount_updated(market.market_token, token, delta, next_value);

    next_value
}

fn get_adjusted_swap_impact_factor(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_positive: bool
) -> u256 {
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
) -> (u256, u256) {
    let mut positive_impact_factor = data_store
        .get_u256(keys::swap_impact_factor_key(market, true));
    let negative_impact_factor = data_store.get_u256(keys::swap_impact_factor_key(market, false));
    // if the positive impact factor is more than the negative impact factor, positions could be opened
    // and closed immediately for a profit if the difference is sufficient to cover the position fees
    if positive_impact_factor > negative_impact_factor {
        positive_impact_factor = negative_impact_factor;
    }
    (positive_impact_factor, negative_impact_factor)
}

fn get_adjusted_position_impact_factor(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_positive: bool
) -> u256 {
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
) -> (u256, u256) {
    let mut positive_impact_factor = data_store
        .get_u256(keys::position_impact_factor_key(market, true));
    let negative_impact_factor = data_store
        .get_u256(keys::position_impact_factor_key(market, false));
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
    mut price_impact_usd: i256,
    size_delta_usd: u256
) -> i256 {
    if price_impact_usd < Zeroable::zero() {
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
        precision::apply_factor_u256(size_delta_usd, max_price_impact_factor), true
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
) -> u256 {
    data_store.get_u256(keys::position_impact_pool_amount_key(market_address))
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
) -> u256 {
    data_store.get_u256(keys::swap_impact_pool_amount_key(market_address, token))
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
    delta: i256
) -> u256 {
    // Increment the swap impact pool amount.
    let next_value = data_store
        .apply_bounded_delta_to_u256(
            keys::swap_impact_pool_amount_key(market_address, token), delta
        );

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
    delta: i256
) -> u256 {
    // Increment the position impact pool amount.
    let next_value = data_store
        .apply_bounded_delta_to_u256(keys::position_impact_pool_amount_key(market_address), delta);

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
    delta: i256
) -> u256 {
    // Check that the market is not a swap only market.
    assert(
        (*market.index_token).is_non_zero(),
        MarketError::OPEN_INTEREST_CANNOT_BE_UPDATED_FOR_SWAP_ONLY_MARKET
    );
    'pass assert'.print();
    // Increment the open interest by the delta.
    let key = keys::open_interest_key(*market.market_token, collateral_token, is_long);
    'got key'.print();
    let next_value = data_store.apply_delta_to_u256(key, delta, 'negative open interest');
    'got next value'.print();

    // If the open interest for longs is increased then tokens were virtually bought from the pool
    // so the virtual inventory should be decreased.
    // If the open interest for longs is decreased then tokens were virtually sold to the pool
    // so the virtual inventory should be increased.
    // If the open interest for shorts is increased then tokens were virtually sold to the pool
    // so the virtual inventory should be increased.
    // If the open interest for shorts is decreased then tokens were virtually bought from the pool
    // so the virtual inventory should be decreased.

    if is_long {
        'goes here'.print();
        apply_delta_to_virtual_inventory_for_positions(
            data_store, event_emitter, *market.index_token, i256_neg(delta)
        );
    } else {
        apply_delta_to_virtual_inventory_for_positions(
            data_store, event_emitter, *market.index_token, delta
        );
    }

    if (delta > Zeroable::zero()) {
        'validates ?'.print();
        validate_open_interest(data_store, market, is_long);
    }
    event_emitter
        .emit_open_interest_updated(
            *market.market_token, collateral_token, is_long, delta, next_value
        );

    next_value
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
    delta: i256
) -> u256 {
    let key = keys::open_interest_in_tokens_key(market.market_token, collateral_token, is_long);
    let next_value = data_store.apply_delta_to_u256(key, delta, 'negative open interest tokens');

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
    delta: i256
) -> u256 {
    let key = keys::collateral_sum_key(market, collateral_token, is_long);
    let next_value = data_store.apply_delta_to_u256(key, delta, 'negative collateralSum');

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
    data_store.set_u256(key, get_block_timestamp().into());
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
            long_token: get_open_interest_div(
                data_store, market.market_token, market.long_token, true, divisor
            ),
            short_token: get_open_interest_div(
                data_store, market.market_token, market.short_token, true, divisor
            ),
        },
        short: CollateralType {
            long_token: get_open_interest_div(
                data_store, market.market_token, market.long_token, false, divisor
            ),
            short_token: get_open_interest_div(
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

    let funding_usd = precision::apply_factor_u256(
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

fn get_swap_impact_amount_with_cap(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    token_price: Price,
    price_impact_usd: i256
) -> i256 {
    let mut impact_amount: i256 = Zeroable::zero();
    // positive impact: minimize impactAmount, use tokenPrice.max
    // negative impact: maximize impactAmount, use tokenPrice.min
    if price_impact_usd > Zeroable::zero() {
        // round positive impactAmount down, this will be deducted from the swap impact pool for the user
        let price = to_signed(token_price.max, true);

        let max_impact_amount = to_signed(
            get_swap_impact_pool_amount(data_store, market, token), true
        );

        if (impact_amount > max_impact_amount) {
            impact_amount = max_impact_amount;
        }
    } else {
        let price = token_price.min;
        // round negative impactAmount up, this will be deducted from the user
        impact_amount = roundup_magnitude_division(price_impact_usd, price);
    }
    impact_amount
}

fn get_open_interest_div(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    divisor: u256
) -> u256 {
    error_utils::check_division_by_zero(divisor, 'get_open_interest');
    let key = keys::open_interest_key(market, collateral_token, is_long);
    data_store.get_u256(key) / divisor
}

/// Get the long and short open interest for a market.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to get the open interest for.
/// # Returns
/// The long and short open interest for a market.
fn get_open_interest_for_market(data_store: IDataStoreDispatcher, market: @Market) -> u256 {
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
) -> u256 {
    // Get the pool divisor.
    let divisor = get_pool_divisor(*market.long_token, *market.short_token);
    // Get the open interest for the long token as collateral.
    let open_interest_using_long_token_as_collateral = get_open_interest_div(
        data_store, *market.market_token, *market.long_token, is_long, divisor
    );
    // Get the open interest for the short token as collateral.
    let open_interest_using_short_token_as_collateral = get_open_interest_div(
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
) -> u256 {
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
    divisor: u256
) -> u256 {
    error_utils::check_division_by_zero(divisor, 'get_open_interest_in_tokens');
    data_store.get_u256(keys::open_interest_in_tokens_key(market, collateral_token, is_long))
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
fn get_pool_divisor(long_token: ContractAddress, short_token: ContractAddress) -> u256 {
    if long_token == short_token {
        2
    } else {
        1
    }
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
    price_impact_usd: i256
) -> i256 {
    let impact_amount: i256 = get_swap_impact_amount_with_cap(
        data_store, market, token, token_price, price_impact_usd
    );

    // if there is a positive impact, the impact pool amount should be reduced
    // if there is a negative impact, the impact pool amount should be increased
    apply_delta_to_swap_impact_pool(
        data_store, event_emitter, market, token, i256_neg(impact_amount)
    );

    return impact_amount;
}

/// @dev validate that the pool amount is within the max allowed amount
/// # Arguments
/// *`data_store` DataStore
/// *`market` the market to check
/// *`token` the token to check
fn validate_pool_amount(
    data_store: @IDataStoreDispatcher, market: @Market, token: ContractAddress
) {
    let pool_amount: u256 = get_pool_amount(*data_store, market, token);
    let max_pool_amount: u256 = get_max_pool_amount(*data_store, *market.market_token, token);
    if (pool_amount > max_pool_amount) {
        MarketError::MAX_POOL_AMOUNT_EXCEEDED(pool_amount, max_pool_amount);
    }
}

/// Validates that the amount of tokens required to be reserved is below the configured threshold.
/// # Arguments
/// * `dataStore`: DataStore - The data storage instance.
/// * `market`: Market values to consider.
/// * `prices`: Prices of the market tokens.
/// * `is_long`: A boolean flag to indicate whether to check the long or short side.
fn validate_reserve(
    data_store: IDataStoreDispatcher, market: @Market, prices: @MarketPrices, is_long: bool
) {
    // poolUsd is used instead of pool amount as the indexToken may not match the longToken
    // additionally, the shortToken may not be a stablecoin
    let pool_usd = get_pool_usd_without_pnl(data_store, market, prices, is_long, false);
    let reserve_factor = get_reserve_factor(data_store, *market.market_token, is_long);
    let max_reserved_usd = apply_factor_u256(pool_usd, reserve_factor);

    let reserved_usd = get_reserved_usd(data_store, market, prices, is_long);

    if (reserved_usd > max_reserved_usd) {
        MarketError::INSUFFICIENT_RESERVE(reserved_usd, max_reserved_usd);
    }
}


/// Validate the open interest.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to validate the open interest for.
/// * `is_long` - Whether to validate the long or short side.
fn validate_open_interest(data_store: IDataStoreDispatcher, market: @Market, is_long: bool) {
    // Get the open interest.
    let open_interest = get_open_interest_for_market_is_long(data_store, market, is_long);
    'pass get int for long'.print();
    // Get the maximum open interest.
    let max_open_interest = get_max_open_interest(data_store, *market.market_token, is_long);
    'pass get int second'.print();

    // Check that the open interest is not greater than the maximum open interest.
    if (open_interest > max_open_interest) {
        'goes here'.print();
        MarketError::MAX_OPEN_INTEREST_EXCEDEED(open_interest, max_open_interest);
    }
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
) -> i256 {
    let market: Market = get_enabled_market(data_store, market);
    let prices: MarketPrices = MarketPrices {
        index_token_price: oracle.get_primary_price(market.index_token),
        long_token_price: oracle.get_primary_price(market.long_token),
        short_token_price: oracle.get_primary_price(market.short_token)
    };

    return get_pnl_to_pool_factor_from_prices(data_store, @market, @prices, is_long, maximize);
}

/// Get the ratio of PNL (Profit and Loss) to pool value.
/// # Arguments
/// * `dataStore`: DataStore - The data storage instance.
/// * `market`: Market values.
/// * `prices`: Prices of the market tokens.
/// * `isLong`: Whether to get the value for the long or short side.
/// * `maximize`: Whether to maximize the factor.
/// # Returns
/// Returns the ratio of PNL of positions to long or short pool value.
fn get_pnl_to_pool_factor_from_prices(
    data_store: IDataStoreDispatcher,
    market: @Market,
    prices: @MarketPrices,
    is_long: bool,
    maximize: bool
) -> i256 {
    let pool_usd: u256 = get_pool_usd_without_pnl(data_store, market, prices, is_long, !maximize);
    if pool_usd == 0 {
        return Zeroable::zero();
    }
    let pnl: i256 = get_pnl(data_store, market, prices.index_token_price, is_long, maximize);
    return to_factor_ival(pnl, pool_usd);
}

/// Validates the token balance for a single market.
/// # Arguments
/// * `data_store` - The data_store dispatcher
/// * `market` - Address of the market to check.
fn validate_market_token_balance_with_address(
    data_store: IDataStoreDispatcher, market: ContractAddress
) {
    let enabled_market: Market = get_enabled_market(data_store, market);
    validate_market_token_balance_check(data_store, enabled_market);
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
) {
    let (_, delta) = get_next_cumulative_borrowing_factor(data_store, market, prices, is_long);
    increment_cumulative_borrowing_factor(
        data_store, event_emitter, market.market_token, is_long, delta
    );
    let block_timestamp: u256 = starknet::info::get_block_timestamp().into();

    data_store
        .set_u256(
            keys::cumulative_borrowing_factor_updated_at_key(market.market_token, is_long),
            block_timestamp
        );
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
) -> (bool, i256) {
    let virtual_token_id: felt252 = data_store.get_felt252(keys::virtual_token_id_key(token));
    if virtual_token_id == 0.into() {
        return (false, Zeroable::zero());
    }
    return (true, data_store.get_i256(keys::virtual_inventory_for_positions_key(virtual_token_id)));
}

// store funding values as token amount per (Precision.FLOAT_PRECISION_SQRT / Precision.FLOAT_PRECISION) of USD size
fn get_funding_amount_per_size_delta(
    funding_usd: u256, open_interest: u256, token_price: u256, roundup_magnitude: bool
) -> u256 {
    if funding_usd == 0 || open_interest == 0 {
        return 0;
    }
    let funding_usd_per_size: u256 = mul_div_roundup(
        funding_usd, FLOAT_PRECISION * FLOAT_PRECISION_SQRT, open_interest, roundup_magnitude
    );
    if roundup_magnitude {
        roundup_division(funding_usd_per_size, token_price)
    } else {
        funding_usd_per_size / token_price
    }
}

// @dev validate that the amount of tokens required to be reserved for open interest
// is below the configured threshold
// @param dataStore: DataStore - The data storage instance.
// @param market: Market values to consider.
// @param prices: Prices of the market tokens.
// @param is_long: A boolean flag to indicate whether to check the long or short side.
fn validate_open_interest_reserve(
    data_store: IDataStoreDispatcher, market: @Market, prices: @MarketPrices, is_long: bool
) {
    // poolUsd is used instead of pool amount as the indexToken may not match the longToken
    // additionally, the shortToken may not be a stablecoin
    let pool_usd: u256 = get_pool_usd_without_pnl(data_store, market, prices, is_long, false);
    let reserve_factor: u256 = get_open_interest_reserve_factor(
        data_store, *market.market_token, is_long
    );
    let max_reserved_usd: u256 = apply_factor_u256(pool_usd, reserve_factor);

    let reserved_usd: u256 = get_reserved_usd(data_store, market, prices, is_long);

    if (reserved_usd > max_reserved_usd) {
        MarketError::INSUFFICIENT_RESERVE(reserved_usd, max_reserved_usd);
    }
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
    data_store: IDataStoreDispatcher, position: @Position, market: @Market, prices: @MarketPrices
) -> u256 {
    let (next_cumulative_borrowing_factor, _) = get_next_cumulative_borrowing_factor(
        data_store, *market, *prices, *position.is_long
    );
    if (next_cumulative_borrowing_factor < *position.borrowing_factor) {
        MarketError::UNEXCEPTED_BORROWING_FACTOR(
            *position.borrowing_factor, next_cumulative_borrowing_factor
        );
    }
    let diff_factor = next_cumulative_borrowing_factor - *position.borrowing_factor;
    return apply_factor_u256(*position.size_in_usd, diff_factor);
}

// @notice Get the total reserved USD required for positions.
//
// @param market The market to check.
// @param prices The prices of the market tokens.
// @param is_long Whether to get the value for the long or short side.
//
// @return The total reserved USD required for positions.
fn get_reserved_usd(
    data_store: IDataStoreDispatcher, market: @Market, prices: @MarketPrices, is_long: bool
) -> u256 {
    let mut reserved_usd: u256 = 0;
    if (is_long) {
        // for longs calculate the reserved USD based on the open interest and current indexTokenPrice
        // this works well for e.g. an ETH / USD market with long collateral token as WETH
        // the available amount to be reserved would scale with the price of ETH
        // this also works for e.g. a SOL / USD market with long collateral token as WETH
        // if the price of SOL increases more than the price of ETH, additional amounts would be
        // automatically reserved
        let open_interest_in_tokens = get_open_interest_in_tokens_for_market(
            data_store, market, is_long
        );
        reserved_usd = open_interest_in_tokens * *prices.index_token_price.max;
    } else {
        // for shorts use the open interest as the reserved USD value
        // this works well for e.g. an ETH / USD market with short collateral token as USDC
        // the available amount to be reserved would not change with the price of ETH
        reserved_usd = get_open_interest_for_market_is_long(data_store, market, is_long);
    }
    reserved_usd
}

fn get_is_long_token(market: Market, token: ContractAddress) -> bool {
    if (token != market.long_token && token != market.short_token) {
        MarketError::UNEXCEPTED_TOKEN(token);
    }
    return token == market.long_token;
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
    delta: i256
) -> (bool, u256) {
    let virtual_market_id: felt252 = data_store
        .get_felt252(keys::virtual_market_id_key(market.market_token));
    if (virtual_market_id == 0) {
        return (false, 0);
    }
    let is_long_token: bool = get_is_long_token(market, token);

    let next_value: u256 = data_store
        .apply_bounded_delta_to_u256(
            keys::virtual_inventory_for_swaps_key(virtual_market_id, is_long_token), delta
        );

    event_emitter
        .emit_virtual_swap_inventory_updated(
            market.market_token, is_long_token, virtual_market_id, delta, next_value
        );

    return (true, next_value);
}

/// Update the virtual inventory for positions.
///
/// # Arguments
/// * `data_store`: The data storage instance.
/// * `event_emitter`: The event emitter instance.
/// * `token`: The token to update.
/// * `delta`: The update amount.
fn apply_delta_to_virtual_inventory_for_positions(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    token: ContractAddress,
    delta: i256
) -> (bool, i256) {
    let virtual_token_id: felt252 = data_store.get_felt252(keys::virtual_token_id_key(token));
    if (virtual_token_id == 0) {
        return (false, Zeroable::zero());
    }

    let next_value: i256 = data_store
        .apply_delta_to_i256(keys::virtual_inventory_for_positions_key(virtual_token_id), delta);
    event_emitter
        .emit_virtual_position_inventory_updated(token, virtual_token_id, delta, next_value);

    return (true, next_value);
}

/// Get the borrowing fees for a position, assumes that cumulativeBorrowingFactor
/// has already been updated to the latest value
/// # Arguments
/// * `dataStore` - DataStore
/// * `position` - Position
/// * `dataStore` - DataStore
/// # Returns
/// The borrowing fees for a position
fn get_borrowing_fees(data_store: IDataStoreDispatcher, position: @Position) -> u256 {
    let cumulative_borrowing_factor: u256 = get_cumulative_borrowing_factor(
        @data_store, *position.market, *position.is_long
    );

    if (cumulative_borrowing_factor < *position.borrowing_factor) {
        MarketError::UNEXCEPTED_BORROWING_FACTOR(
            *position.borrowing_factor, cumulative_borrowing_factor
        );
    }
    let diff_factor: u256 = cumulative_borrowing_factor - *position.borrowing_factor;
    return apply_factor_u256(*position.size_in_usd, diff_factor);
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
    latest_funding_amount_per_size: u256,
    position_funding_amount_per_size: u256,
    position_size_in_usd: u256,
    roundup_magnitude: bool
) -> u256 {
    let funding_diff_factor: u256 = latest_funding_amount_per_size
        - position_funding_amount_per_size;
    return mul_div_roundup(
        position_size_in_usd,
        funding_diff_factor,
        FLOAT_PRECISION * FLOAT_PRECISION_SQRT,
        roundup_magnitude
    );
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
    market: @Market,
    index_token_price: @Price,
    is_long: bool,
    maximize: bool
) -> i256 {
    let open_interest: u256 = get_open_interest_for_market_is_long(data_store, market, is_long);
    let pnl: i256 = get_pnl(data_store, market, index_token_price, is_long, maximize);
    return sum_return_int_256(open_interest, pnl);
}


/// Get the virtual inventory for swaps
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market.
/// # Returns
/// The tuple (has virtual inventory, virtual long token inventory, virtual short token inventory)
fn get_virtual_inventory_for_swaps(
    data_store: IDataStoreDispatcher, market: ContractAddress
) -> (bool, u256, u256) {
    let virtual_market_id = data_store.get_felt252(keys::virtual_market_id_key(market));
    if virtual_market_id.is_zero() {
        return (false, 0, 0);
    }

    return (
        true,
        data_store.get_u256(keys::virtual_inventory_for_swaps_key(virtual_market_id, true)),
        data_store.get_u256(keys::virtual_inventory_for_swaps_key(virtual_market_id, false))
    );
}

fn apply_delta_to_funding_fee_amount_per_size(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    delta: u256
) {
    if delta == 0 {
        return;
    }
    let delta = to_signed(delta, true);
    let next_value: u256 = data_store
        .apply_delta_to_u256(
            keys::funding_fee_amount_per_size_key(market, collateral_token, is_long),
            delta,
            'negative_funding_fee'
        );
    let delta = to_unsigned(delta);
    event_emitter
        .emit_funding_fee_amount_per_size_updated(
            market, collateral_token, is_long, delta, next_value
        );
}

// Get the max position impact factor 
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// `is_positive` - whether to check the positive or negative side
// # Returns
// The max position impact factor 
fn get_max_position_impact_factor(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_positive: bool,
) -> u256 {
    let (max_positive_impact_factor, max_negative_impact_factor) = get_max_position_impact_factors(
        data_store, market
    );

    if is_positive {
        max_positive_impact_factor
    } else {
        max_negative_impact_factor
    }
}

fn get_max_position_impact_factors(
    data_store: IDataStoreDispatcher, market: ContractAddress,
) -> (u256, u256) {
    let mut max_positive_impact_factor: u256 = data_store
        .get_u256(keys::max_position_impact_factor_key(market, true));
    let max_negative_impact_factor: u256 = data_store
        .get_u256(keys::max_position_impact_factor_key(market, false));

    if max_positive_impact_factor > max_negative_impact_factor {
        max_positive_impact_factor = max_negative_impact_factor;
    }

    (max_positive_impact_factor, max_negative_impact_factor)
}

// Get the max position impact factor for liquidations
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// # Returns
// The max position impact factor for liquidations
fn get_max_position_impact_factor_for_liquidations(
    data_store: IDataStoreDispatcher, market: ContractAddress
) -> u256 {
    data_store.get_u256(keys::max_position_impact_factor_for_liquidations_key(market))
}

// Get the min collateral factor
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// # Returns
// The min collateral factor 
fn get_min_collateral_factor(data_store: IDataStoreDispatcher, market: ContractAddress) -> u256 {
    data_store.get_u256(keys::min_collateral_factor_key(market))
}

// Get the min collateral factor for open interest multiplier
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// `is_long` - whether to check the long or short side
// # Returns
// The min collateral factor for open interest multiplier
fn get_min_collateral_factor_for_open_interest_multiplier(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u256 {
    data_store
        .get_u256(keys::min_collateral_factor_for_open_interest_multiplier_key(market, is_long))
}

// Get the min collateral factor for open interest
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// `open_interest_delta` - the delta in open interest
// `is_long` - whether to check the long or short side
// # Returns
// The min collateral factor for open interest
fn get_min_collateral_factor_for_open_interest(
    data_store: IDataStoreDispatcher, market: Market, open_interest_delta: i256, is_long: bool
) -> u256 {
    let mut open_interest: u256 = get_open_interest_for_market_is_long(
        data_store, @market, is_long
    );
    open_interest = calc::sum_return_uint_256(open_interest, open_interest_delta);
    let multiplier_factor = get_min_collateral_factor_for_open_interest_multiplier(
        data_store, market.market_token, is_long
    );
    apply_factor_u256(open_interest, multiplier_factor)
}

// Get the total amount of position collateral for a market
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// 'collateral_token' - the collateral token to check
// `is_long` - whether to check the long or short side
// # Returns
// the total amount of position collateral for a market
fn get_collateral_sum(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    divisor: u256
) -> u256 {
    error_utils::check_division_by_zero(divisor, 'get_collaral_sum');
    data_store.get_u256(keys::collateral_sum_key(market, collateral_token, is_long)) / divisor
}

// Get the reserve factor for a market
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// `is_long` - whether to check the long or short side
// # Returns
// The reserve factor for a market
fn get_reserve_factor(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u256 {
    data_store.get_u256(keys::reserve_factor_key(market, is_long))
}

// Get open interest reserve factor
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// `is_long` - whether to check the long or short side
// # Returns
// The open interest reserve factor
fn get_open_interest_reserve_factor(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u256 {
    data_store.get_u256(keys::open_interest_reserve_factor_key(market, is_long))
}

// Get the max pnl factor
// # Arguments
// `data_store` - the data store to use
// `pnl_factor_type` the type of the pnl factor
// `market` - the market to check
// `is_long` - whether to check the long or short side
// # Returns
// The max pnl factor
fn get_max_pnl_factor(
    data_store: IDataStoreDispatcher,
    pnl_factor_type: felt252,
    market: ContractAddress,
    is_long: bool
) -> u256 {
    data_store.get_u256(keys::max_pnl_factor_key(pnl_factor_type, market, is_long))
}

// Get the min pnl factor after Adl
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// `is_long` - whether to check the long or short side
// # Returns
// The min pnl factor after adl
fn get_min_pnl_factor_after_adl(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u256 {
    data_store.get_u256(keys::min_pnl_factor_after_adl_key(market, is_long))
}

// Get the funding factor for a market
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// # Returns
// the funding factor for a market
fn get_funding_factor(data_store: IDataStoreDispatcher, market: ContractAddress) -> u256 {
    data_store.get_u256(keys::funding_factor_key(market))
}

// Get the funding exponent factor for a market
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// # Returns
// the funding exponent factor for a market
fn get_funding_exponent_factor(data_store: IDataStoreDispatcher, market: ContractAddress) -> u256 {
    data_store.get_u256(keys::funding_exponent_factor_key(market))
}

// Get the funding fee amount per size for a market
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// `collateral_token` - the collateral token to check
// `is_long` - whether to check the long or short side
// # Returns
// the funding fee amount per size for a market
fn get_funding_fee_amount_per_size(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool
) -> u256 {
    data_store.get_u256(keys::funding_fee_amount_per_size_key(market, collateral_token, is_long))
}

// Get the claimable funding fee amount per size for a market
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// `collateral_token` - the collateral token to check
// `is_long` - whether to check the long or short side
// # Returns
// the claimable funding fee amount per size for a market
fn get_claimable_funding_amount_per_size(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool
) -> u256 {
    data_store
        .get_u256(keys::claimable_funding_amount_per_size_key(market, collateral_token, is_long))
}

// Apply delta to the funding fee amount per size for a market
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// `collateral_token` - the collateral token to check
// `is_long` - whether to check the long or short side
// `delta` - the delta to increment by
fn apply_delta_to_funding_fee_per_size(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    delta: u256
) {
    if delta == 0 {
        return;
    }
    let error: felt252 = 0;
    let delta = to_signed(delta, true);
    let next_value: u256 = data_store
        .apply_delta_to_u256(
            keys::funding_fee_amount_per_size_key(market, collateral_token, is_long),
            delta,
            error //Error doesnt exist on solidity function, i just added it because of the merge of Library #1
        );
    let delta = to_unsigned(delta);
    event_emitter
        .emit_funding_fee_amount_per_size_updated(
            market, collateral_token, is_long, delta, next_value
        );
}

// Apply delta to the claimable funding fee amount per size for a market
// # Arguments
// `data_store` - the data store to use
// `market` - the market to check
// `collateral_token` - the collateral token to check
// `is_long` - whether to check the long or short side
// `delta` - the delta to increment by
fn apply_delta_to_claimable_funding_amount_per_size(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    delta: u256
) {
    if delta == 0 {
        return;
    }
    let next_value: u256 = data_store
        .apply_delta_to_u256(
            keys::claimable_funding_amount_per_size_key(market, collateral_token, is_long),
            to_signed(delta, true),
            0
        );
    event_emitter
        .emit_claimable_funding_amount_per_size_updated(
            market, collateral_token, is_long, delta, next_value
        );
}

// Get the number of seconds since funding was updated for a market
// `data_store` - the data store to use
// `market` - the market to check
// # Returns
// the number of seconds since funding was updated for a market
fn get_seconds_since_funding_updated(
    data_store: IDataStoreDispatcher, market: ContractAddress
) -> u256 {
    //Error on this one but its normal the function is not create yet 
    let updated_at: u256 = data_store.get_u256(keys::funding_updated_at_key(market));
    if (updated_at == 0) {
        return 0;
    }
    let block_time_stamp = starknet::info::get_block_timestamp().into();
    block_time_stamp - updated_at
}

// Get the funding factor per second for a market
// `data_store` - the data store to use
// `market` - the market to check
// `diff_usd` - the difference between the long and short open interest
// `total_open_interest` - the total open interest
fn get_funding_factor_per_second(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    diff_usd: u256,
    total_open_interest: u256
) -> u256 {
    let stable_funding_factor: u256 = data_store.get_u256(keys::stable_funding_factor_key(market));

    if (stable_funding_factor > 0) {
        return stable_funding_factor;
    };

    if (diff_usd == 0) {
        return 0;
    }

    if (total_open_interest == 0) {
        MarketError::UNABLE_TO_GET_FUNDING_FACTOR_EMPTY_OPEN_INTEREST(total_open_interest);
    }

    let funding_factor: u256 = get_funding_factor(data_store, market);

    let funding_exponent_factor: u256 = get_funding_exponent_factor(data_store, market);
    let diff_usd_after_exponent: u256 = apply_exponent_factor(diff_usd, funding_exponent_factor);

    let diff_usd_to_open_interest_factor: u256 = to_factor(
        diff_usd_after_exponent, total_open_interest
    );

    return apply_factor_u256(diff_usd_to_open_interest_factor, funding_factor);
}

// Get the borrowing factor for a market
// `data_store` - the data store to use
// `market` - the market to check
// `is_long` - whether to check the long or short side
// # Returns
// the borrowing factor for a market
fn get_borrowing_factor(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u256 {
    data_store.get_u256(keys::borrowing_factor_key(market, is_long))
}

// Get the borrowing exponent factor for a market
// `data_store` - the data store to use
// `market` - the market to check
// `is_long` - whether to check the long or short side
// # Returns
// the borrowing exponent factor for a market
fn get_borrowing_exponent_factor(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u256 {
    data_store.get_u256(keys::borrowing_exponent_factor_key(market, is_long))
}

// Get the cumulative borrowing factor for a market
// `data_store` - the data store to use
// `market` - the market to check
// `is_long` - whether to check the long or short side
// # Returns
// the cumulative borrowing factor for a market
fn get_cumulative_borrowing_factor(
    data_store: @IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u256 {
    let data_store_n: IDataStoreDispatcher = *data_store;
    data_store_n.get_u256(keys::cumulative_borrowing_factor_key(market, is_long))
}

// Increment the cumulative borrowing factor
// `data_store` - the data store to use
// `market` - the market to check
// `event_emitter` - the event emitter
// `is_long` - whether to check the long or short side
// `delta` - the increase amount
fn increment_cumulative_borrowing_factor(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    is_long: bool,
    delta: u256
) {
    let next_cumulative_borrowing_factor = data_store
        .increment_u256(keys::cumulative_borrowing_factor_key(market, is_long), delta);

    event_emitter
        .emit_cumulative_borrowing_factor_updated(
            market, is_long, delta, next_cumulative_borrowing_factor
        );
}

// Get the timestamp of when the cumulative borrowing factor was last updated
// `data_store` - the data store to use
// `market` - the market to check
// `is_long` - whether to check the long or short side
// #Return 
// the timestamp of when the cumulative borrowing factor was last updated
fn get_cumulative_borrowing_factor_updated_at(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u256 {
    data_store.get_u256(keys::cumulative_borrowing_factor_updated_at_key(market, is_long))
}

// Get the number of seconds since the cumulative borrowing factor was last updated
// `data_store` - the data store to use
// `market` - the market to check
// `is_long` - whether to check the long or short side
// #Return 
// the number of seconds since the cumulative borrowing factor was last updated
fn get_seconds_since_cumulative_borrowing_factor_updated(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u256 {
    let updated_at: u256 = get_cumulative_borrowing_factor_updated_at(data_store, market, is_long);
    if (updated_at == 0) {
        return 0;
    }
    let block_time_stamp = starknet::info::get_block_timestamp().into();
    block_time_stamp - updated_at
}

// Update the total borrowing amount after a position changes size
// `data_store` - the data store to use
// `market` - the market to check
// `is_long` - whether to check the long or short side
// `prev_position_size_in_usd` - the previous position size in USD
// `prev_position_borrowing_factor` - the previous position borrowing factor
// `next_position_size_in_usd` - the next position size in USD
// `next_position_borrowing_factor` - the next position borrowing factor
fn update_total_borrowing(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    is_long: bool,
    prev_position_size_in_usd: u256,
    prev_position_borrowing_factor: u256,
    next_position_size_in_usd: u256,
    next_position_borrowing_factor: u256
) {
    let total_borrowing: u256 = get_next_total_borrowing(
        data_store,
        market,
        is_long,
        prev_position_size_in_usd,
        prev_position_borrowing_factor,
        next_position_size_in_usd,
        next_position_borrowing_factor
    );

    set_total_borrowing(data_store, market, is_long, total_borrowing);
}

// Get the next total borrowing amount after a position changes size
// `data_store` - the data store to use
// `market` - the market to check
// `is_long` - whether to check the long or short side
// `prev_position_size_in_usd` - the previous position size in USD
// `prev_position_borrowing_factor` - the previous position borrowing factor
// `next_position_size_in_usd` - the next position size in USD
// `next_position_borrowing_factor` - the next position borrowing factor
fn get_next_total_borrowing(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    is_long: bool,
    prev_position_size_in_usd: u256,
    prev_position_borrowing_factor: u256,
    next_position_size_in_usd: u256,
    next_position_borrowing_factor: u256
) -> u256 {
    let mut total_borrowing: u256 = get_total_borrowing(data_store, market, is_long);
    total_borrowing -= apply_factor_u256(prev_position_size_in_usd, prev_position_borrowing_factor);
    total_borrowing += apply_factor_u256(next_position_size_in_usd, next_position_borrowing_factor);

    total_borrowing
}

// Get the next total borrowing amount after a position changes size
// `data_store` - the data store to use
// `market` - the market to check
// `is_long` - whether to check the long or short side
// `long_token` - the long token of the market
// `short_token` - the short token of the market
fn get_next_cumulative_borrowing_factor(
    data_store: IDataStoreDispatcher, market: Market, prices: MarketPrices, is_long: bool,
) -> (u256, u256) {
    let duration_in_seconds: u256 = get_seconds_since_cumulative_borrowing_factor_updated(
        data_store, market.market_token, is_long
    );
    let borrowing_factor_per_second: u256 = get_borrowing_factor_per_second(
        data_store, market, prices, is_long
    );

    let cumulative_borrowing_factor: u256 = get_cumulative_borrowing_factor(
        @data_store, market.market_token, is_long
    );

    let delta: u256 = duration_in_seconds * borrowing_factor_per_second;
    let next_cumulative_borrowing_factor: u256 = cumulative_borrowing_factor + delta;
    (next_cumulative_borrowing_factor, delta)
}

// Get the borrowing factor per second 
// `data_store` - the data store to use
// `market` - the market to get the borrowing factor per second for
// `prices` - prices the prices of the market tokens
// `is_long` - whether to get the factor for the long or short side
fn get_borrowing_factor_per_second(
    data_store: IDataStoreDispatcher, market: Market, prices: MarketPrices, is_long: bool
) -> u256 {
    let reserved_usd: u256 = get_reserved_usd(data_store, @market, @prices, is_long);

    if (reserved_usd == 0) {
        return 0;
    }

    // check if the borrowing fee for the smaller side should be skipped
    // if skipBorrowingFeeForSmallerSide is true, and the longOpenInterest is exactly the same as the shortOpenInterest
    // then the borrowing fee would be charged for both sides, this should be very rare
    let skip_borrowing_fee_for_smaller_side: bool = data_store
        .get_bool(keys::skip_borrowing_fee_for_smaller_side());

    let market_snap = @market;
    if (skip_borrowing_fee_for_smaller_side) {
        let long_open_interest: u256 = get_open_interest_for_market_is_long(
            data_store, market_snap, true
        );
        let short_open_interest: u256 = get_open_interest_for_market_is_long(
            data_store, market_snap, false
        );

        // if getting the borrowing factor for longs and if the longOpenInterest
        // is smaller than the shortOpenInterest, then return zero
        if (is_long && long_open_interest < short_open_interest) {
            return 0;
        }
        // if getting the borrowing factor for shorts and if the shortOpenInterest
        // is smaller than the longOpenInterest, then return zero
        if (!is_long && short_open_interest < long_open_interest) {
            return 0;
        }
    }
    let pool_usd: u256 = get_pool_usd_without_pnl(data_store, @market, @prices, is_long, false);

    if (pool_usd == 0) {
        MarketError::UNABLE_TO_GET_BORROWING_FACTOR_EMPTY_POOL_USD(pool_usd);
    }

    let borrowing_exponent_factor: u256 = get_borrowing_exponent_factor(
        data_store, market.market_token, is_long
    );
    let reserved_usd_after_exponent: u256 = apply_exponent_factor(
        reserved_usd, borrowing_exponent_factor
    );

    let reserved_usd_to_pool_factor: u256 = to_factor(reserved_usd_after_exponent, pool_usd);
    let borrowing_factor: u256 = get_borrowing_factor(data_store, market.market_token, is_long);

    apply_factor_u256(reserved_usd_to_pool_factor, borrowing_factor)
}

// Get the total pending borrowing fees
// `data_store` - the data store to use
// `market` - the market to get the borrowing factor per second for
// `long_token` - the long token of the market
// `short_token` - the short token of the market
// `is_long` - whether to get the factor for the long or short side
fn get_total_pending_borrowing_fees(
    data_store: IDataStoreDispatcher, market: Market, prices: MarketPrices, is_long: bool
) -> u256 {
    let open_interest: u256 = get_open_interest_for_market_is_long(data_store, @market, is_long);

    let (next_cumulative_borrowing_factor, _) = get_next_cumulative_borrowing_factor(
        data_store, market, prices, is_long
    );

    let total_borrowing: u256 = get_total_borrowing(data_store, market.market_token, is_long);

    apply_factor_u256(open_interest, next_cumulative_borrowing_factor) - total_borrowing
}

// Get the total borrowing value
// the total borrowing value is the sum of position.borrowingFactor * position.size / (10 ^ 30)
// for all positions of the market
// if borrowing APR is 1000% for 100 years, the cumulativeBorrowingFactor could be as high as 100 * 1000 * (10 ** 30)
// since position.size is a USD value with 30 decimals, under this scenario, there may be overflow issues
// if open interest exceeds (2 ** 256) / (10 ** 30) / (100 * 1000 * (10 ** 30)) => 1,157,920,900,000 USD
// `data_store` - the data store to use
// `market` - the market to get the borrowing factor per second for
// `is_long` - whether to get the factor for the long or short side
// #Return
// The total borrowing value
fn get_total_borrowing(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool
) -> u256 {
    data_store.get_u256(keys::total_borrowing_key(market, is_long))
}

// Set the total borrowing value
// `data_store` - the data store to use
// `market` - the market to get the borrowing factor per second for
// `is_long` - whether to get the factor for the long or short side
// `value` - the value to set to
fn set_total_borrowing(
    data_store: IDataStoreDispatcher, market: ContractAddress, is_long: bool, value: u256
) {
    data_store.set_u256(keys::total_borrowing_key(market, is_long), value)
}

// Convert a number of market tokens to its USD value
// `usd_value` - the input USD value
// `pool_value` - the value of the pool
// `supply` - the supply of the market tokens
fn usd_to_market_token_amount(usd_value: u256, pool_value: u256, supply: u256) -> u256 {
    // if the supply and poolValue is zero, use 1 USD as the token price
    if (supply == 0 && pool_value == 0) {
        return float_to_wei(usd_value);
    }

    // if the supply is zero and the poolValue is more than zero,
    // then include the poolValue for the amount of tokens minted so that
    // the market token price after mint would be 1 USD
    if (supply == 0 && pool_value > 0) {
        return float_to_wei(pool_value + usd_value);
    }

    // round market tokens down
    mul_div(supply, usd_value, pool_value)
}

// Set the total borrowing value
// `market_token_amount` - the input number of market tokens
// `pool_value` - the value of the pool
// `supply` - the supply of the market tokens
// #Return
// The USD value of the market tokens
fn market_token_amount_to_usd(market_token_amount: u256, pool_value: u256, supply: u256) -> u256 {
    if (supply == 0) {
        MarketError::EMPTY_MARKET_TOKEN_SUPPLY(supply);
    }

    mul_div(pool_value, market_token_amount, supply)
}

// Validate that the specified market exists and is enabled
// `data_store` - the data store to use
// `market_add` the address of the market
fn validate_enabled_market_check(
    data_store: IDataStoreDispatcher, market_address: ContractAddress
) {
    let market: Market = data_store.get_market(market_address);
    validate_enabled_market(data_store, market);
}

// Validate that the specified market exists and is enabled
// `data_store` - the data store to use
// `market` - the market to check
fn validate_enabled_market(data_store: IDataStoreDispatcher, market: Market) {
    assert(market.market_token != 0.try_into().unwrap(), MarketError::EMPTY_MARKET);

    let is_market_disabled: bool = data_store
        .get_bool(keys::is_market_disabled_key(market.market_token));

    if (is_market_disabled) {
        MarketError::DISABLED_MARKET(is_market_disabled);
    }
}

// Validate that the positions can be opened in the given market
// `market` - the market to check
fn validate_position_market_check(data_store: IDataStoreDispatcher, market: Market) {
    validate_enabled_market(data_store, market);

    assert(!is_swap_only_market(market), MarketError::INVALID_POSITION_MARKET);
}

fn validate_position_market(data_store: IDataStoreDispatcher, market_add: ContractAddress) {
    let market: Market = data_store.get_market(market_add);
    validate_position_market_check(data_store, market);
}

// Check if a market only supports swaps and not positions
// `market` - the market to check
fn is_swap_only_market(market: Market) -> bool {
    market.index_token.is_zero()
}

// Check if the given token is a collateral token of the market
// `market` - the market to check
// `token` - the token to check
fn is_market_collateral_token(market: Market, token: ContractAddress) -> bool {
    market.long_token == token || market.short_token == token
}

// Validate if the given token is a collateral token of the market
// `market` - the market to check
// `token` - the token to check
fn validate_market_collateral_token(market: Market, token: ContractAddress) {
    if (!is_market_collateral_token(market, token)) {
        MarketError::INVALID_MARKET_COLLATERAL_TOKEN(market.market_token, token);
    }
}

// Get the enabled market, revert if the market does not exist or is not enabled
// `data_store - DataStore
// `market_add` - the address of the market
fn get_enabled_market(data_store: IDataStoreDispatcher, market_add: ContractAddress) -> Market {
    let market: Market = data_store.get_market(market_add);
    validate_enabled_market(data_store, market);
    market
}

fn get_swap_path_market(data_store: IDataStoreDispatcher, market_add: ContractAddress) -> Market {
    let market: Market = data_store.get_market(market_add);
    validate_swap_market(data_store, market);
    market
}

// Get a list of market values based on an input array of market addresses
// `swap_path` - list of market addresses
fn get_swap_path_markets(
    data_store: IDataStoreDispatcher, swap_path: Span32<ContractAddress>
) -> Array<Market> {
    let mut markets: Array<Market> = ArrayTrait::new();
    let mut i: u32 = 0;
    let length: u32 = swap_path.len();

    loop {
        if i == length {
            break;
        }
        let market_adress_prev = swap_path.get(i);
        let market_adress: ContractAddress = *market_adress_prev.unwrap().unbox();
        markets.append(get_swap_path_market(data_store, market_adress));
        i += 1;
    };
    markets
}

fn validate_swap_path(data_store: IDataStoreDispatcher, token_swap_path: Span32<ContractAddress>) {
    let max_swap_path_length: u256 = data_store.get_u256(keys::max_swap_path_length());
    let token_swap_path_length: u32 = token_swap_path.len();

    if (token_swap_path_length.into() > max_swap_path_length) {
        MarketError::MAX_SWAP_PATH_LENGTH_EXCEEDED(token_swap_path_length, max_swap_path_length);
    }

    let mut i: u32 = 0;
    loop {
        if i == token_swap_path_length {
            break;
        }
        let market_prev = token_swap_path.get(i);
        let market: ContractAddress = *market_prev.unwrap().unbox();
        validate_swap_market_with_address(data_store, market);
        i += 1;
    };
}

// Validate that the pending pnl is below the allowed amount
// `data_store` - DataStore
// `market` - the market to check
// `prices` - the prices of the market tokens
// `pnl_factor_type` - the pnl factor type to check
fn validate_max_pnl(
    data_store: IDataStoreDispatcher,
    market: Market,
    prices: MarketPrices,
    pnl_factor_type_for_longs: felt252,
    pnl_factor_type_for_shorts: felt252
) {
    let (is_pnl_factor_exceeded_for_longs, pnl_to_pool_factor_for_longs, max_pnl_factor_for_longs) =
        is_pnl_factor_exceeded_check(
        data_store, market, prices, true, pnl_factor_type_for_longs,
    );

    if (is_pnl_factor_exceeded_for_longs) {
        MarketError::PNL_EXCEEDED_FOR_LONGS(is_pnl_factor_exceeded_for_longs);
    }

    let (
        is_pnl_factor_exceeded_for_shorts, pnl_to_pool_factor_for_shorts, max_pnl_factor_for_shorts
    ) =
        is_pnl_factor_exceeded_check(
        data_store, market, prices, false, pnl_factor_type_for_shorts,
    );

    if (is_pnl_factor_exceeded_for_shorts) {
        MarketError::PNL_EXCEEDED_FOR_SHORTS(is_pnl_factor_exceeded_for_shorts);
    }
}

// Check if the pending pnl exceeds the allowed amount
// `data_store` - DataStore
// `oracle` - Oracle
// `market` - the market to check
// `is_long` - whether to check the long or short side
// `pnl_factor_type` - the pnl factor type to check
fn is_pnl_factor_exceeded(
    data_store: IDataStoreDispatcher,
    oracle: IOracleDispatcher,
    market_add: ContractAddress,
    is_long: bool,
    pnl_factor_type: felt252
) -> (bool, i256, u256) {
    let market: Market = get_enabled_market(data_store, market_add);
    let prices: MarketPrices = get_market_prices(oracle, market);

    is_pnl_factor_exceeded_check(data_store, market, prices, is_long, pnl_factor_type)
}

// Check if the pending pnl exceeds the allowed amount
// `data_store` - DataStore
// `market` - the market to check
// `prices` - the prices of the market tokens
// `is_long` - whether to check the long or short side
// `pnl_factor_type` - the pnl factor type to check
fn is_pnl_factor_exceeded_check(
    data_store: IDataStoreDispatcher,
    market: Market,
    prices: MarketPrices,
    is_long: bool,
    pnl_factor_type: felt252
) -> (bool, i256, u256) {
    let pnl_to_pool_factor: i256 = get_pnl_to_pool_factor_from_prices(
        data_store, @market, @prices, is_long, true
    );
    let max_pnl_factor: u256 = get_max_pnl_factor(
        data_store, pnl_factor_type, market.market_token, is_long
    );

    let is_exceeded: bool = pnl_to_pool_factor > Zeroable::zero()
        && to_unsigned(pnl_to_pool_factor) > max_pnl_factor;

    (is_exceeded, pnl_to_pool_factor, max_pnl_factor)
}

fn get_ui_fee_factor(data_store: IDataStoreDispatcher, account: ContractAddress) -> u256 {
    let max_ui_fee_factor: u256 = data_store.get_u256(keys::max_ui_fee_factor());
    let ui_fee_factor: u256 = data_store.get_u256(keys::ui_fee_factor_key(account));

    if ui_fee_factor < max_ui_fee_factor {
        return ui_fee_factor;
    } else {
        return max_ui_fee_factor;
    }
}

fn set_ui_fee_factor(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    account: ContractAddress,
    ui_fee_factor: u256
) {
    let max_ui_fee_factor: u256 = data_store.get_u256(keys::max_ui_fee_factor());

    if (ui_fee_factor > max_ui_fee_factor) {
        MarketError::UI_FEE_FACTOR_EXCEEDED(ui_fee_factor, max_ui_fee_factor);
    }

    data_store.set_u256(keys::ui_fee_factor_key(account), ui_fee_factor);

    event_emitter.emit_ui_fee_factor_updated(account, ui_fee_factor);
}

fn validate_market_token_balance_array(data_store: IDataStoreDispatcher, markets: Array<Market>) {
    let length: u32 = markets.len();
    let mut i: u32 = 0;
    loop {
        if i == length {
            break;
        }
        validate_market_token_balance_check(data_store, *markets.at(i));
        i += 1;
    };
}

fn validate_market_token_balance_span(data_store: IDataStoreDispatcher, markets: Span<Market>) {
    let length: u32 = markets.len();
    let mut i: u32 = 0;
    loop {
        if i == length {
            break;
        }
        validate_market_token_balance_check(data_store, *markets.at(i));
        i += 1;
    };
}

fn validate_market_address_token_balance(
    data_store: IDataStoreDispatcher, market_add: ContractAddress
) {
    let market: Market = get_enabled_market(data_store, market_add);
    validate_market_token_balance_check(data_store, market);
}

fn validate_market_token_balance_check(data_store: IDataStoreDispatcher, market: Market) {
    validate_market_token_balance_with_token(data_store, market, market.long_token);

    if (market.long_token == market.short_token) {
        return;
    }
    validate_market_token_balance_with_token(data_store, market, market.short_token);
}

fn validate_market_token_balance_with_token(
    data_store: IDataStoreDispatcher, market: Market, token: ContractAddress
) {
    assert(
        market.market_token.is_non_zero() && token.is_non_zero(),
        MarketError::EMPTY_ADDRESS_IN_MARKET_TOKEN_BALANCE_VALIDATION
    );
    let balance: u256 = IERC20Dispatcher { contract_address: token }
        .balance_of(market.market_token)
        .low
        .into();
    'Issue here'.print();
    let expected_min_balance: u256 = get_expected_min_token_balance(data_store, market, token);
    assert(balance >= expected_min_balance, MarketError::INVALID_MARKET_TOKEN_BALANCE);

    // funding fees can be claimed even if the collateral for positions that should pay funding fees
    // hasn't been reduced yet
    // due to that, funding fees and collateral is excluded from the expectedMinBalance calculation
    // and validated separately

    // use 1 for the getCollateralSum divisor since getCollateralSum does not sum over both the
    // longToken and shortToken
    let mut collateral_amount: u256 = get_collateral_sum(
        data_store, market.market_token, token, true, 1
    );
    'before add collateral amount'.print();
    collateral_amount += get_collateral_sum(data_store, market.market_token, token, false, 1);
    'after add collateral amount'.print();

    if (balance < collateral_amount) {
        MarketError::INVALID_MARKET_TOKEN_BALANCE_FOR_COLLATERAL_AMOUNT(balance, collateral_amount);
    }

    let claimable_funding_fee_amount = data_store
        .get_u256(keys::claimable_funding_amount_key(market.market_token, token));

    // in case of late liquidations, it may be possible for the claimableFundingFeeAmount to exceed the market token balance
    // but this should be very rare
    if (balance < claimable_funding_fee_amount) {
        MarketError::INVALID_MARKET_TOKEN_BALANCE_FOR_CLAIMABLE_FUNDING(
            balance, claimable_funding_fee_amount
        );
    }
}

fn get_expected_min_token_balance(
    data_store: IDataStoreDispatcher, market: Market, token: ContractAddress
) -> u256 {
    // get the pool amount directly as MarketUtils.get_pool_amount will divide the amount by 2
    // for markets with the same long and short token
    let pool_amount: u256 = data_store.get_u256(keys::pool_amount_key(market.market_token, token));
    let swap_impact_pool_amount: u256 = get_swap_impact_pool_amount(
        data_store, market.market_token, token
    );
    let claimable_collateral_amount: u256 = data_store
        .get_u256(keys::claimable_collateral_amount_key(market.market_token, token));
    let claimable_fee_amount: u256 = data_store
        .get_u256(keys::claimable_fee_amount_key(market.market_token, token));
    let claimable_ui_fee_amount: u256 = data_store
        .get_u256(keys::claimable_ui_fee_amount_key(market.market_token, token));
    let affiliate_reward_amount: u256 = data_store
        .get_u256(keys::affiliate_reward_key(market.market_token, token));
    // funding fees are excluded from this summation as claimable funding fees
    // are incremented without a corresponding decrease of the collateral of
    // other positions, the collateral of other positions is decreased when
    // those positions are updated
    return pool_amount
        + swap_impact_pool_amount
        + claimable_collateral_amount
        + claimable_fee_amount
        + claimable_ui_fee_amount
        + affiliate_reward_amount;
}
