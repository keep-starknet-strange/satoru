// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use core::traits::TryInto;

// Local imports.
use satoru::position::position::Position;
use satoru::market::market::Market;
use satoru::market::market_utils::MarketPrices;
use satoru::price::price::Price;
use satoru::pricing::position_pricing_utils::PositionFees;
use satoru::pricing::swap_pricing_utils::SwapFees;
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};

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
    data_store: IDataStoreSafeDispatcher,
    market: Market,
    prices: MarketPrices,
    token_in: ContractAddress,
    amount_in: u128,
    ui_fee_receiver: ContractAddress
) -> (u128, i128, SwapFees) {
    // TODO
    (
        0,
        0,
        SwapFees {
            fee_receiver_amount: 0,
            fee_amount_for_pool: 0,
            amount_after_fees: 0,
            ui_fee_receiver: 0.try_into().unwrap(),
            ui_fee_receiver_factor: 0,
            ui_fee_amount: 0,
        }
    )
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
    data_store: IDataStoreSafeDispatcher,
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
    data_store: IDataStoreSafeDispatcher,
    market: Market,
    token_in: ContractAddress,
    token_out: ContractAddress,
    amount_in: u128,
    token_in_price: Price,
    token_out_price: Price
) -> (i128, i128) { // TODO
    (0, 0)
}
