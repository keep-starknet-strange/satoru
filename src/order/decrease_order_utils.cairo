// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::position::decrease_position_utils::DecreasePositionResult;
use satoru::order::{base_order_utils::ExecuteOrderParams, order::Order};

// This function should return an EventLogData cause the callback_utils
// needs it. We need to find a solution for that case.
#[inline(always)]
fn process_order(params: ExecuteOrderParams) { //TODO
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
    min_oracle_block_numbers: Array<u128>,
    max_oracle_block_numbers: Array<u128>,
    order_type: Order,
    order_updated_at_block: u128,
    position_increased_at_block: u128,
    position_decrease_at_block: u128
) { //TODO
}

// Note: that min_output_amount is treated as a USD value for this validation
fn validate_output_amount(
    oracle: IOracleDispatcher,
    output_token: ContractAddress,
    output_amount: u128,
    min_output_amount: u128,
    max_output_amount: u128
) { //TODO
}

// Note: that min_output_amount is treated as a USD value for this validation
fn validate_output_amount_secondary(
    oracle: IOracleDispatcher,
    output_token: ContractAddress,
    output_amount: u128,
    min_output_amount: u128,
    secondary_output_token: u128,
    secondary_output_amount: u128,
    max_output_amount: u128
) { //TODO
}

#[inline(always)]
fn handle_swap_error(
    oracle: IOracleDispatcher,
    order: Order,
    result: DecreasePositionResult,
    reason: felt252,
    reason_bytes: Array<felt252>
) { //TOO
}

// This function should return an EventLogData cause the callback_utils
// needs it. We need to find a solution for that case.
fn get_output_event_data(
    output_token: ContractAddress,
    output_amount: u128,
    secondary_output_token: ContractAddress,
    secondary_output_amount: u128
) { //TODO
}
