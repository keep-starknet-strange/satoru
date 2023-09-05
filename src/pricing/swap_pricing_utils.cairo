//! Library for pricing functions

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;

// Local imports.
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use satoru::market::market::Market;

/// Struct used in get_price_impact_usd.
#[derive(Drop, starknet::Store, Serde)]
struct GetPriceImpactUsdParams {
    /// The `DataStore` contract dispatcher.
    dataStore: IDataStoreSafeDispatcher,
    /// The market to check.
    market: Market,
    /// The token to check balance for.
    token_a: ContractAddress,
    /// The token to check balance for.
    token_b: ContractAddress,
    price_for_token_a: u128,
    price_for_token_b: u128,
    // The USD change in amount of token_a.
    usd_delta_for_token_a: u128, // TODO i128 when it will implement Store
    // The USD change in amount of token_b.
    usd_delta_for_token_b: u128, // TODO i128 when it will implement Store
}

/// Struct to contain pool values.
#[derive(Drop, starknet::Store, Serde)]
struct PoolParams {
    /// The USD value of token_a in the pool.
    pool_usd_for_token_a: u128,
    /// The USD value of token_b in the pool.
    pool_usd_for_token_b: u128,
    /// The next USD value of token_a in the pool.
    next_pool_usd_for_token_a: u128,
    /// The next USD value of token_b in the pool.
    next_pool_usd_for_token_b: u128,
}

/// Struct to contain swap fee values.
#[derive(Drop, starknet::Store, Serde)]
struct SwapFees {
    /// The fee amount for the fee receiver.
    fee_receiver_amount: u128,
    /// The fee amount for the pool.
    fee_amount_for_pool: u128,
    /// The output amount after fees.
    amount_after_fees: u128,
    /// The ui fee receiver.
    ui_fee_receiver: ContractAddress,
    /// The factor for receiver.
    ui_fee_receiver_factor: u128,
    /// The ui fee amount.
    ui_fee_amount: u128,
}

/// Called by get_price_impact_usd().
/// # Returns
/// The price impact in USD.
fn get_price_impact_usd_(params: GetPriceImpactUsdParams) -> i128 {
    // TODO
    0
}

/// Get the price impact in USD
///
/// Note that there will be some difference between the pool amounts used for
/// calculating the price impact and fees vs the actual pool amounts after the
/// swap is done, since the pool amounts will be increased / decreased by an amount
/// after factoring in the calculated price impact and fees.
///
/// Since the calculations are based on the real-time prices values of the tokens
/// if a token price increases, the pool will incentivise swapping out more of that token
/// this is useful if prices are ranging, if prices are strongly directional, the pool may
/// be selling tokens as the token price increases.
/// # Arguments
/// * `params` - The necessary params to compute next pool amount in USD.
/// # Returns
/// New pool amount.
fn get_next_pool_amount_usd(params: GetPriceImpactUsdParams) -> PoolParams {
    // TODO
    PoolParams {
        pool_usd_for_token_a: 0,
        pool_usd_for_token_b: 0,
        next_pool_usd_for_token_a: 0,
        next_pool_usd_for_token_b: 0,
    }
}

/// Get the new pool values.
/// # Arguments
/// * `params` - The necessary params to compute price impact.
/// * `pool_amount_for_token_a` - The pool amount of token a.
/// * `pool_amount_for_token_b` - The pool amount of token b.
/// # Returns
/// New pool values.
fn get_next_pool_amount_params(
    params: GetPriceImpactUsdParams, pool_amount_for_token_a: u128, pool_amount_for_token_b: u128
) -> PoolParams {
    // TODO
    PoolParams {
        pool_usd_for_token_a: 0,
        pool_usd_for_token_b: 0,
        next_pool_usd_for_token_a: 0,
        next_pool_usd_for_token_b: 0,
    }
}

/// Get the swap fees.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market_token` - The address of market token.
/// * `amount` - The total swap fee amount.
/// * `for_positive_impact` - Wether it is for a positive impact.
/// * `ui_fee_receiver` - The ui fee receiver.
/// # Returns
/// New swap fees.
fn get_swap_fees(
    data_store: IDataStoreSafeDispatcher,
    market_token: ContractAddress,
    amount: u128,
    for_positive_impact: bool,
    ui_fee_receiver: ContractAddress,
) -> SwapFees {
    // TODO
    let address_zero: ContractAddress = 0.try_into().unwrap();
    SwapFees {
        fee_receiver_amount: 0,
        fee_amount_for_pool: 0,
        amount_after_fees: 0,
        ui_fee_receiver: address_zero,
        ui_fee_receiver_factor: 0,
        ui_fee_amount: 0,
    }
}

/// Note that the priceImpactUsd may not be entirely accurate since it is the
/// base calculation and the actual price impact may be capped by the available
/// amount in the swap impact pool.
fn emit_swap_info(
    event_emitter: IEventEmitterSafeDispatcher,
    order_key: felt252,
    market: ContractAddress,
    receiver: ContractAddress,
    token_in: ContractAddress,
    token_out: ContractAddress,
    token_in_price: u128,
    token_out_price: u128,
    amount_in: u128,
    amount_in_after_fees: u128,
    amount_out: u128,
    price_impact_usd: i128,
    price_impact_amount: i128,
) { // TODO
}

/// Emit event about collected swap fees.
fn emit_swap_fees_collected(
    event_emitter: IEventEmitterSafeDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    token_price: u128,
    action: felt252,
    fees: SwapFees,
) { // TODO
}
