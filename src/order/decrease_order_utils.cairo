// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::oracle::oracle_utils;
use satoru::position::decrease_position_utils::DecreasePositionResult;
use satoru::order::{
    base_order_utils::ExecuteOrderParams, order::Order, order::OrderType, error::OrderError, order
};
use satoru::utils::arrays;

// This function should return an EventLogData cause the callback_utils
// needs it. We need to find a solution for that case.
#[inline(always)]
fn process_order(params: ExecuteOrderParams) { //TODO check with refactor with callback_utils
}


/// Validate the oracle block numbers used for the prices in the oracle.
/// # Arguments
/// * `min_oracle_block_numbers` - The min oracle block numbers.
/// * `max_oracle_block_numbers` - The max oracle block numbers.
/// * `order_type` - The order type.
/// * `order_updated_at_block` - The block at which the order was last updated.
/// * `position_increased_at_block` - The block at which the position was last increased.
/// * `position_decrease_at_block` - The block at which the position was last decreased.
#[inline(always)]
fn validate_oracle_block_numbers(
    min_oracle_block_numbers: Span<u64>,
    max_oracle_block_numbers: Span<u64>,
    order_type: OrderType,
    order_updated_at_block: u64,
    position_increased_at_block: u64,
    position_decreased_at_block: u64
) {
    if order_type == OrderType::MarketDecrease {
        oracle_utils::validate_block_number_within_range(
            min_oracle_block_numbers, max_oracle_block_numbers, order_updated_at_block
        );
        return;
    }

    if (order_type == OrderType::LimitDecrease || order_type == OrderType::StopLossDecrease) {
        let mut latest_updated_at_block: u64 = position_increased_at_block;
        if (order_updated_at_block > position_increased_at_block) {
            latest_updated_at_block = order_updated_at_block
        }
        if (!arrays::u64_are_gte(min_oracle_block_numbers, latest_updated_at_block)) {
            OrderError::ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED(
                min_oracle_block_numbers, latest_updated_at_block
            );
        }
        return;
    }
    if (order_type == OrderType::Liquidation) {
        let mut latest_updated_at_block: u64 = position_decreased_at_block;
        if (position_increased_at_block > position_decreased_at_block) {
            latest_updated_at_block = position_increased_at_block
        }
        if (!arrays::u64_are_gte(min_oracle_block_numbers, latest_updated_at_block)) {
            OrderError::ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED(
                min_oracle_block_numbers, latest_updated_at_block
            );
        }
        return;
    }
    OrderError::UNSUPPORTED_ORDER_TYPE;
    return;
}

// Note: that min_output_amount is treated as a USD value for this validation
fn validate_output_amount(
    oracle: IOracleDispatcher,
    output_token: ContractAddress,
    output_amount: u128,
    min_output_amount: u128
) {
    let output_token_price: u128 = oracle.get_primary_price(output_token).min;
    let output_usd: u128 = output_amount * output_token_price;

    if (output_usd < min_output_amount) {
        OrderError::INSUFFICIENT_OUTPUT_AMOUNT(output_usd, output_token_price);
    }
}

// Note: that min_output_amount is treated as a USD value for this validation
fn validate_output_amount_secondary(
    oracle: IOracleDispatcher,
    output_token: ContractAddress,
    output_amount: u128,
    secondary_output_token: ContractAddress,
    secondary_output_amount: u128,
    min_output_amount: u128
) {
    let output_token_price: u128 = oracle.get_primary_price(output_token).min;
    let output_usd: u128 = output_amount * output_token_price;

    let secondary_output_token_price: u128 = oracle.get_primary_price(secondary_output_token).min;
    let seconday_output_usd: u128 = secondary_output_amount * secondary_output_token_price;

    let total_output_usd: u128 = output_usd + seconday_output_usd;

    if (total_output_usd < min_output_amount) {
        OrderError::INSUFFICIENT_OUTPUT_AMOUNT(output_usd, output_token_price);
    }
}

#[inline(always)]
fn handle_swap_error(
    oracle: IOracleDispatcher,
    order: Order,
    result: DecreasePositionResult,
    reason: felt252,
    reason_bytes: Span<felt252>,
    event_emitter: IEventEmitterDispatcher
) {
    event_emitter.emit_swap_reverted(reason, reason_bytes);

    validate_output_amount(
        oracle, result.output_token, result.output_amount, order.min_output_amount
    );
//TODO Call this when its implemented
//Need to call transfer_out function when its implemented
}

// This function should return an EventLogData cause the callback_utils
// needs it. We need to find a solution for that case.
fn get_output_event_data(
    output_token: ContractAddress,
    output_amount: u128,
    secondary_output_token: ContractAddress,
    secondary_output_amount: u128
) { //TODO check with refactor with callback_utils
}
