// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// Local imports.

use gojo::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use gojo::order::order::OrderType;
use gojo::position::{position_utils::DecreasePositionCollateralValues, position::Position,};
use gojo::price::price::Price;
use gojo::pricing::position_pricing_utils::PositionFees;

/// Struct to store a position increase parameters.
#[derive(Drop, starknet::Store, Serde)]
struct PositionIncreaseParams {
    /// The main event emitter contract.
    event_emitter: IEventEmitterSafeDispatcher,
    /// The key linked to the position increase order.
    order_key: felt252,
    /// The key linked to the position.
    position_key: felt252,
    /// The position struct.
    position: Position,
    /// The market index token price.
    index_token_price: Price,
    /// The position index token price.
    collateral_token_price: Price,
    /// The execution price.
    execution_price: u128,
    /// The position increase amount in usd.
    size_delta_usd: u128,
    /// The position increase amount in tokens.
    size_delta_in_tokens: u128,
    /// The collateral variation amount in usd.
    collateral_delta_amount: u128, // TODO i128 when storeable
    /// The position increase price impact in usd.
    price_impact_usd: u128, // TODO i128 when storeable
    /// The position increase price impact in tokens.
    price_impact_amount: u128, // TODO i128 when storeable
    /// The type of the order.
    order_type: OrderType
}

/// Emit events linked to a position increase.
/// # Arguments
/// * `params` - The position increase parameters.
#[inline(always)]
fn emit_position_increase(params: PositionIncreaseParams) { // TODO
}

/// Emit events linked to a position decrease.
/// # Arguments
/// * `event_emitter` - The main event emitter contract.
/// * `order_key` - The key linked to the position decrease order.
/// * `position_key` - The key linked to the position.
/// * `position` - The position struct.
/// * `size_delta_usd` - The position decrease amount in usd.
/// * `collateral_delta_amount` - The collateral variation amount in usd.
/// * `order_type` - The type of the order.
/// * `values` - The parameters linked to the decrease of collateral.
/// * `index_token_price` - The price of the index token.
/// * `collateral_token_price` - The price of the collateral token.
#[inline(always)]
fn emit_position_decrease(
    event_emitter: IEventEmitterSafeDispatcher,
    order_key: felt252,
    position_key: felt252,
    position: Position,
    size_delta_usd: u128,
    collateral_delta_amount: u128,
    order_type: OrderType,
    values: DecreasePositionCollateralValues,
    index_token_price: Price,
    collateral_token_price: Price
) { // TODO
}

/// Emit events linked to an insolvent position close.
/// # Arguments
/// * `event_emitter` - The main event emitter contract.
/// * `order_key` - The key linked to the position decrease order.
/// * `position_collateral_amount` - The amount of collateral tokens of the position.
/// * `base_pnl_usd` - The base pnl amount in usd.
/// * `remaining_cost_usd` - The remaining costs.
fn emit_insolvent_close_info(
    event_emitter: IEventEmitterSafeDispatcher,
    order_key: felt252,
    position_collateral_amount: u128,
    base_pnl_usd: i128,
    remaining_cost_usd: u128
) { // TODO
}

/// Emit events linked to an insolvent funding fee payment.
/// # Arguments
/// * `event_emitter` - The main event emitter contract.
/// * `market` - The market concerned.
/// * `token` - The token used for payment.
/// * `expected_amount` - The expected paid amount.
/// * `amount_paid_in_collateral_token` - The amount paid in collateral token.
/// * `amount_paid_in_secondary_output_token` - The amount paid in secondary output token.
fn emit_insufficient_funding_fee_payment(
    event_emitter: IEventEmitterSafeDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    expected_amount: u128,
    amount_paid_in_collateral_token: u128,
    amount_paid_in_secondary_output_token: u128
) { // TODO
}

/// Emit events linked to collect of position fees.
/// # Arguments
/// * `event_emitter` - The main event emitter contract.
/// * `order_key` - The key linked to the position decrease order.
/// * `position_key` - The key linked to the position.
/// * `market` - The market where fees were collected.
/// * `collateral_token` - The collateral token.
/// * `trade_size_usd` - The trade size in usd.
/// * `is_increase` - Wether it is an increase.
/// * `fees` - The struct storing position fees.
fn emit_position_fees_collected(
    event_emitter: IEventEmitterSafeDispatcher,
    order_key: felt252,
    position_key: felt252,
    market: ContractAddress,
    collateral_token: ContractAddress,
    trade_size_usd: u128,
    is_increase: bool,
    fees: PositionFees
) { // TODO
}

/// Emit events linked to position fees info.
/// # Arguments
/// * `event_emitter` - The main event emitter contract.
/// * `order_key` - The key linked to the position decrease order.
/// * `position_key` - The key linked to the position.
/// * `market` - The market where fees were collected.
/// * `collateral_token` - The collateral token.
/// * `trade_size_usd` - The trade size in usd.
/// * `is_increase` - Wether it is an increase.
/// * `fees` - The struct storing position fees.
fn emit_position_fees_info(
    event_emitter: IEventEmitterSafeDispatcher,
    order_key: felt252,
    position_key: felt252,
    market: ContractAddress,
    collateral_token: ContractAddress,
    trade_size_usd: u128,
    is_increase: bool,
    fees: PositionFees
) { // TODO
}

/// Emit events linked to position fees. 
/// # Arguments
/// * `event_emitter` - The main event emitter contract.
/// * `order_key` - The key linked to the position decrease order.
/// * `position_key` - The key linked to the position.
/// * `market` - The market where fees were collected.
/// * `collateral_token` - The collateral token.
/// * `trade_size_usd` - The trade size in usd.
/// * `is_increase` - Wether it is an increase.
/// * `fees` - The struct storing position fees.
/// * `event_name` - The name of the event.
fn emit_position_fees(
    event_emitter: IEventEmitterSafeDispatcher,
    order_key: felt252,
    position_key: felt252,
    market: ContractAddress,
    collateral_token: ContractAddress,
    trade_size_usd: u128,
    is_increase: bool,
    fees: PositionFees,
    event_name: felt252
) { // TODO
}
