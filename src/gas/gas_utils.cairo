// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use satoru::bank::strict_bank::{IStrictBankSafeDispatcher, IStrictBankSafeDispatcherTrait};
use satoru::order::order::Order;
use satoru::deposit::deposit::Deposit;
use satoru::withdrawal::withdrawal::Withdrawal;

/// Get the minimal gas to handle execution.
/// # Arguments
/// * `data_store` - The data storage dispatcher.
/// # Returns
/// The MIN_HANDLE_EXECUTION_ERROR_GAS.
fn get_min_handle_execution_error_gas(data_store: IDataStoreSafeDispatcher) -> u128 {
    // TODO
    0
}

/// Check that starting gas is higher than min handle execution gas and return starting.
/// gas minus min_handle_error_gas.
fn get_execution_gas(data_store: IDataStoreSafeDispatcher, starting_gas: u128) -> u128 {
    // TODO
    0
}

/// Pay the keeper the execution fee and refund any excess amount.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `event_emitter` - The event emitter contract dispatcher.
/// * `bank` - The StrictBank contract holding the execution fee.
/// * `execution_fee` - The executionFee amount.
/// * `starting_gas` - The starting gas.
/// * `keeper` - The keeper to pay.
/// * `refund_receiver` - The account that should receive any excess gas refunds.
/// # Returns
/// * The key for the account order list.
fn pay_execution_fee(
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    bank: IStrictBankSafeDispatcher,
    execution_fee: u128,
    starting_gas: u128,
    keeper: ContractAddress,
    refund_receiver: ContractAddress
) { // TODO
}

/// Validate that the provided executionFee is sufficient based on the estimated_gas_limit.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `estimated_gas_limit` - The estimated gas limit.
/// * `execution_fee` - The execution fee provided.
/// # Returns
/// * The key for the account order list.
fn validate_execution_fee(
    data_store: IDataStoreSafeDispatcher, estimated_gas_limit: u128, execution_fee: u256
) { // TODO
}

/// Adjust the gas usage to pay a small amount to keepers.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `gas_used` - The amount of gas used.
fn adjust_gas_usage(data_store: IDataStoreSafeDispatcher, gas_used: u128) -> u128 {
    // TODO
    0
}

/// Adjust the estimated gas limit to help ensure the execution fee is sufficient during the actual execution.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `estimated_gas_limit` - The estimated gas limit.
/// # Returns
/// The adjusted gas limit
fn adjust_gas_limit_for_estimate(
    data_store: IDataStoreSafeDispatcher, estimated_gas_limit: u128
) -> u128 {
    // TODO
    0
}

/// The estimated gas limit for deposits.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `deposit` - The deposit to estimate the gas limit for.
fn estimate_execute_deposit_gas_limit(
    data_store: IDataStoreSafeDispatcher, deposit: Deposit
) -> u128 {
    // TODO
    0
}

/// The estimated gas limit for withdrawals.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `withdrawal` - The withdrawal to estimate the gas limit for.
fn estimate_execute_withdrawal_gas_limit(
    data_store: IDataStoreSafeDispatcher, withdrawal: Withdrawal
) -> u128 {
    //TODO
    0
}

/// The estimated gas limit for orders.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `order` - The order to estimate the gas limit for.
fn estimate_execute_order_gas_limit(data_store: IDataStoreSafeDispatcher, order: @Order) -> u128 {
    // TODO
    0
}

/// The estimated gas limit for increase orders.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `order` - The order to estimate the gas limit for.
fn estimate_execute_increase_order_gas_limit(
    data_store: IDataStoreSafeDispatcher, order: Order
) -> u128 {
    // TODO
    0
}

/// The estimated gas limit for decrease orders.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `order` - The order to estimate the gas limit for.
fn estimate_execute_decrease_order_gas_limit(
    data_store: IDataStoreSafeDispatcher, order: Order
) -> u128 {
    // TODO
    0
}

/// The estimated gas limit for swap orders.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `order` - The order to estimate the gas limit for.
fn estimate_execute_swap_order_gas_limit(
    data_store: IDataStoreSafeDispatcher, order: Order
) -> u128 {
    // TODO
    0
}

/// Emit events related to keeper execution fee.
/// # Arguments
/// * `event_emitter` - The event emitter safe dispatcher.
/// * `keeper` - The keeper address.
/// * `refund_fee_amount` - The amount of execution fee for the keeper.
fn emit_keeper_execution_fee(
    event_emitter: IEventEmitterSafeDispatcher, keeper: ContractAddress, execution_fee_amount: u128
) { // TODO
}

/// Emit events related to execution fee refund.
/// # Arguments
/// * `event_emitter` - The event emitter safe dispatcher.
/// * `receiver` - The receiver of the fee refund.
/// * `refund_fee_amount` - The amount of fee refunded.
fn emit_execution_fee_refund(
    event_emitter: IEventEmitterSafeDispatcher, receiver: ContractAddress, refund_fee_amount: u128
) { // TODO
}
