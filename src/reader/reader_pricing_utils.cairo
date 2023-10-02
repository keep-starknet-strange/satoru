// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use core::traits::TryInto;

// Local imports.
use satoru::market::market::Market;
use satoru::market::market_utils::{
    MarketPrices, get_opposite_token, get_cached_token_price, get_swap_impact_amount_with_cap,
    validate_swap_market
};

use satoru::order::{
    order::{SecondaryOrderType, OrderType, Order, DecreasePositionSwapType},
    order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait},
    base_order_utils::{ExecuteOrderParams, ExecuteOrderParamsContracts}
};
use satoru::position::{
    position::Position, position_utils::UpdatePositionParams, increase_position_utils,
    decrease_position_collateral_utils,
};
use satoru::price::price::{Price, PriceTrait};
use satoru::pricing::{
    position_pricing_utils::{PositionFees},
    swap_pricing_utils::{SwapFees, get_swap_fees, get_price_impact_usd, GetPriceImpactUsdParams}
};
use satoru::reader::error::ReaderError;
use satoru::utils::calc;
use satoru::utils::span32::{Span32, Array32Trait};
use satoru::swap::{
    swap_utils::SwapCache, swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait}
};

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};

use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::utils::{i128::{I128Store, I128Serde, I128Div, I128Mul, I128Default}, error_utils};

#[derive(Default, Drop, starknet::Store, Serde)]
struct ExecutionPriceResult {
    price_impact_usd: i128,
    price_impact_diff_usd: u128,
    execution_price: u128,
}

#[derive(Drop, starknet::Store, Serde)]
struct PositionInfo {
    position: Position,
    fees: PositionFees,
    execution_price_result: ExecutionPriceResult,
    base_pnl_usd: i128,
    pnl_after_price_impact_usd: i128,
}

#[derive(Drop, starknet::Store, Serde)]
struct GetPositionInfoCache {
    market: Market,
    collateral_token_price: Price,
    pending_borrowing_fee_usd: u128,
    latest_long_token_funding_amount_per_size: i128,
    latest_short_token_funding_amount_per_size: i128,
}

/// Calculates the output amount and fees for a token swap operation.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Market to check.
/// * `prices` - Price of the market token.
/// * `token_in` - The input token.
/// * `amount_in` - The amount of the input token.
/// * `ui_fee_receiver` - The ui fee receiver.
/// # Returns
/// Returns The output amount of tokens after the swap, the amount impacted due to price changes and the swap fees associated with the swap
fn get_swap_amount_out(
    data_store: IDataStoreDispatcher,
    market: Market,
    prices: MarketPrices,
    token_in: ContractAddress,
    amount_in: u128,
    ui_fee_receiver: ContractAddress
) -> (u128, i128, SwapFees) {
    let mut cache: SwapCache = Default::default();

    if (token_in != market.long_token && token_in != market.short_token) {
        ReaderError::INVALID_TOKEN_IN(token_in, market.long_token);
    }

    validate_swap_market(data_store, market);

    cache.token_out = get_opposite_token(token_in, @market);
    cache.token_in_price = get_cached_token_price(token_in, market, prices);
    cache.token_out_price = get_cached_token_price(cache.token_out, market, prices);

    let param = GetPriceImpactUsdParams {
        data_store,
        market,
        token_a: token_in,
        token_b: cache.token_out,
        price_for_token_a: cache.token_in_price.mid_price(),
        price_for_token_b: cache.token_out_price.mid_price(),
        usd_delta_for_token_a: calc::to_signed(amount_in * cache.token_in_price.mid_price(), true),
        usd_delta_for_token_b: calc::to_signed(amount_in * cache.token_in_price.mid_price(), false)
    };

    let price_impact_usd: i128 = get_price_impact_usd(param);

    let fees: SwapFees = get_swap_fees(
        data_store, market.market_token, amount_in, price_impact_usd > 0, ui_fee_receiver
    );

    let mut impact_amount: i128 = 0;

    if (price_impact_usd > 0) {
        // when there is a positive price impact factor, additional tokens from the swap impact pool
        // are withdrawn for the user
        // for example, if 50,000 USDC is swapped out and there is a positive price impact
        // an additional 100 USDC may be sent to the user
        // the swap impact pool is decreased by the used amount

        cache.amount_in = fees.clone().amount_after_fees;
        //round amount_out down
        error_utils::check_division_by_zero(cache.token_out_price.max, 'token_out_price.max');
        cache.amount_out = cache.amount_in * cache.token_in_price.min / cache.token_out_price.max;
        cache.pool_amount_out = cache.amount_out;

        impact_amount =
            get_swap_impact_amount_with_cap(
                data_store,
                market.market_token,
                cache.token_out,
                cache.token_out_price,
                price_impact_usd
            );

        cache.amount_out += calc::to_unsigned(impact_amount);
    } else {
        // when there is a negative price impact factor,
        // less of the input amount is sent to the pool
        // for example, if 10 ETH is swapped in and there is a negative price impact
        // only 9.995 ETH may be swapped in
        // the remaining 0.005 ETH will be stored in the swap impact pool

        impact_amount =
            get_swap_impact_amount_with_cap(
                data_store, market.market_token, token_in, cache.token_in_price, price_impact_usd
            );

        cache.amount_in = fees.amount_after_fees - calc::to_unsigned(-impact_amount);
        error_utils::check_division_by_zero(cache.token_out_price.max, 'token_out_price.max');
        cache.amount_out = cache.amount_in * cache.token_in_price.min / cache.token_out_price.max;
        cache.pool_amount_out = cache.amount_out;
    }
    (cache.amount_out, impact_amount, fees)
}

/// Calculates the execution price for a position update operation.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Market to check.
/// * `index_token_price` - Price of the market's index token.
/// * `position_size_in_usd` - Representing the size of the position in USD.
/// * `position_size_in_token` - Representing the size of the position in tokens.
/// * `size_delta_usd` - Representing the change in position size in USD.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// # Returns
/// Returns the execution price and price impact information
fn get_execution_price(
    data_store: IDataStoreDispatcher,
    market: Market,
    index_token_price: Price,
    position_size_in_usd: u128,
    position_size_in_tokens: u128,
    size_delta_usd: i128,
    is_long: bool
) -> ExecutionPriceResult {
    let mut params: UpdatePositionParams = Default::default();

    params.contracts.data_store = data_store;
    params.market = market;

    let size_delta_usd_abs = if size_delta_usd > 0 {
        size_delta_usd
    } else {
        -size_delta_usd
    };
    params.order.size_delta_usd = calc::to_unsigned(size_delta_usd_abs);
    params.order.is_long = is_long;

    let is_increase: bool = size_delta_usd > 0;
    let should_execution_price_be_smaller = if is_increase {
        is_long
    } else {
        !is_long
    };
    params
        .order
        .acceptable_price =
            if should_execution_price_be_smaller {
                340282366920938463463374607431768211455
            } else {
                0
            };

    params.position.size_in_usd = position_size_in_usd;
    params.position.size_in_tokens = position_size_in_tokens;
    params.position.is_long = is_long;

    let mut result: ExecutionPriceResult = ExecutionPriceResult {
        price_impact_usd: 0, price_impact_diff_usd: 0, execution_price: 0,
    };
    if size_delta_usd > 0 {
        let (price_impact_usd, _, _, execution_price) =
            increase_position_utils::get_execution_price(
            params, index_token_price
        );

        result.price_impact_usd = price_impact_usd;
        result.execution_price = execution_price;
    } else {
        let (price_impact_usd, price_impact_diff_usd, execution_price) =
            decrease_position_collateral_utils::get_execution_price(
            params, index_token_price
        );
        result.price_impact_usd = price_impact_usd;
        result.price_impact_diff_usd = price_impact_diff_usd;
        result.execution_price = execution_price;
    }
    result
}


/// Calculates the execution price for a position update operation.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Market to check.
/// * `token_in` - The token being swapped in.
/// * `token_out` - The token being swapped out.
/// * `amount_in` -  The amount of the token being swapped in.
/// * `token_in_price` - The price of the token being swapped in.
/// * `token_out_price` - The price of the token being swapped out.
/// # Returns
/// Returns the price impact in USD before applying the cap and the price impact amount after applying the cap
fn get_swap_price_impact(
    data_store: IDataStoreDispatcher,
    market: Market,
    token_in: ContractAddress,
    token_out: ContractAddress,
    amount_in: u128,
    token_in_price: Price,
    token_out_price: Price
) -> (i128, i128) {
    let mut cache: SwapCache = Default::default();

    let param: GetPriceImpactUsdParams = GetPriceImpactUsdParams {
        data_store: data_store,
        market: market,
        token_a: token_in,
        token_b: token_out,
        price_for_token_a: token_in_price.mid_price(),
        price_for_token_b: token_out_price.mid_price(),
        usd_delta_for_token_a: calc::to_signed(amount_in * token_in_price.mid_price(), true),
        usd_delta_for_token_b: calc::to_signed(amount_in * token_in_price.mid_price(), false)
    };

    let price_impact_usd_before_cap: i128 = get_price_impact_usd(param);

    let mut price_impact_amount = 0;
    if price_impact_usd_before_cap > 0 {
        price_impact_amount =
            get_swap_impact_amount_with_cap(
                data_store,
                market.market_token,
                token_out,
                token_out_price,
                price_impact_usd_before_cap,
            );
    } else {
        price_impact_amount =
            get_swap_impact_amount_with_cap(
                data_store,
                market.market_token,
                token_in,
                token_in_price,
                price_impact_usd_before_cap,
            );
    }
    (price_impact_usd_before_cap, price_impact_amount)
}
