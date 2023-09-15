// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use core::traits::TryInto;

// Local imports.
use satoru::position::position::Position;
use satoru::market::market::Market;
use satoru::market::market_utils::{MarketPrices, get_opposite_token, get_cached_token_price, get_swap_impact_amount_with_cap, validate_swap_market};
use satoru::price::price::{Price, PriceTrait};
use satoru::pricing::position_pricing_utils::{PositionFees};
use satoru::pricing::swap_pricing_utils::{SwapFees, get_swap_fees, get_price_impact_usd, GetPriceImpactUsdParams};
use satoru::swap::swap_utils::SwapCache;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};

#[derive(Drop, starknet::Store, Serde)]
struct ExecutionPriceResult {
    price_impact_usd: u128, // TODO replace with i128 when it derives Store
    price_impact_diff_usd: u128,
    execution_price: u128,
}

#[derive(Drop, starknet::Store, Serde)]
struct PositionInfo {
    position: Position,
    fees: PositionFees,
    execution_price_result: ExecutionPriceResult,
    base_pnl_usd: u128, // TODO replace with i128 when it derives Store
    pnl_after_price_impact_usd: u128, // TODO replace with i128 when it derives Store
}

#[derive(Drop, starknet::Store, Serde)]
struct GetPositionInfoCache {
    market: Market,
    collateral_token_price: Price,
    pending_borrowing_fee_usd: u128,
    latest_long_token_funding_amount_per_size: u128, // TODO replace with i128 when it derives Store
    latest_short_token_funding_amount_per_size: u128, // TODO replace with i128 when it derives Store
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
) -> (u128, u128, SwapFees) { //Todo : change to (u128, i128, SwapFees)
    let mut cache: SwapCache = SwapCache {
        token_out: 0.try_into().unwrap(),
        token_in_price: Price { min: 0, max: 0 },
        token_out_price: Price { min: 0, max: 0 },
        amount_in: 0,
        amount_out: 0,
        pool_amount_out: 0,
        price_impact_usd: 0,
        price_impact_amount: 0,
    };

    if (token_in != market.long_token
        && token_in != market.short_token) { //Implement the error
    }

    validate_swap_market(data_store, @market);

    cache.token_out = get_opposite_token(token_in, market);
    cache.token_in_price = get_cached_token_price(token_in, market, prices);
    cache.token_out_price = get_cached_token_price(cache.token_out, market, prices);

    let param : GetPriceImpactUsdParams = GetPriceImpactUsdParams {
            dataStore : data_store,
            market : market,
            token_a : token_in,
            token_b : cache.token_out,
            price_for_token_a : cache.token_in_price.mid_price(),
            price_for_token_b : cache.token_out_price.mid_price(),
            usd_delta_for_token_a : (amount_in * cache.token_in_price.mid_price()), //to int256?
            usd_delta_for_token_b : (amount_in * cache.token_in_price.mid_price()) //todo : add `-` when i128 will implement Store
        };

    let price_impact_usd: u128 = get_price_impact_usd(param); //todo : check u128 to i128
        
    

    let fees: SwapFees = get_swap_fees(
        data_store, market.market_token, amount_in, price_impact_usd > 0, ui_fee_receiver
    );

    let mut impact_amount: u128 = 0; //todo : change to i128

    if (price_impact_usd > 0) {
        // when there is a positive price impact factor, additional tokens from the swap impact pool
        // are withdrawn for the user
        // for example, if 50,000 USDC is swapped out and there is a positive price impact
        // an additional 100 USDC may be sent to the user
        // the swap impact pool is decreased by the used amount

        cache.amount_in = fees.clone().amount_after_fees;
        //round amount_out down
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

        cache.amount_out += impact_amount; //todo : u256?
    } else {
        // when there is a negative price impact factor,
        // less of the input amount is sent to the pool
        // for example, if 10 ETH is swapped in and there is a negative price impact
        // only 9.995 ETH may be swapped in
        // the remaining 0.005 ETH will be stored in the swap impact pool

        impact_amount =
            get_swap_impact_amount_with_cap(
                data_store,
                market.market_token,
                token_in,
                cache.token_in_price,
                price_impact_usd
            );

        //cache.amount_in = fees.amount_after_fees - (-impact_amount).into(); //TODO : when i128 will implement Store;
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
    // TODO
    ExecutionPriceResult { price_impact_usd: 0, price_impact_diff_usd: 0, execution_price: 0, }
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
) -> (i128, i128) { // TODO
    (0, 0)
}
