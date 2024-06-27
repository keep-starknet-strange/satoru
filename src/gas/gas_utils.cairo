// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::data::keys;
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::bank::strict_bank::{IStrictBankDispatcher, IStrictBankDispatcherTrait};
use satoru::order::{
    order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait},
    order::{Order, DecreasePositionSwapType},
    base_order_utils::{is_increase_order, is_decrease_order, is_swap_order, OrderError}
};
use satoru::deposit::deposit::Deposit;
use satoru::withdrawal::{
    withdrawal::Withdrawal,
    withdrawal_vault::{IWithdrawalVaultDispatcher, IWithdrawalVaultDispatcherTrait}
};
use satoru::deposit::deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait};
use satoru::utils::{precision, starknet_utils::{sn_gasleft, sn_gasprice}};
use satoru::utils::span32::{Span32, Span32Trait};
use satoru::token::token_utils;
use satoru::gas::error::GasError;

/// Get the minimal gas to handle execution.
/// # Arguments
/// * `data_store` - The data storage dispatcher.
/// # Returns
/// The MIN_HANDLE_EXECUTION_ERROR_GAS.
fn get_min_handle_execution_error_gas(data_store: IDataStoreDispatcher) -> u256 {
    data_store.get_u256(keys::min_handle_execution_error_gas())
}

/// Check that starting gas is higher than min handle execution gas and return starting.
/// gas minus min_handle_error_gas.
fn get_execution_gas(data_store: IDataStoreDispatcher, starting_gas: u256) -> u256 {
    let min_handle_error_gas = get_min_handle_execution_error_gas(data_store);
    if starting_gas < min_handle_error_gas {
        panic(array![GasError::INSUFF_EXEC_GAS]);
    }
    starting_gas - min_handle_error_gas
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
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    bank: IBankDispatcher,
    execution_fee: u256,
    starting_gas: u256,
    keeper: ContractAddress,
    refund_receiver: ContractAddress
) {
    let fee_token: ContractAddress = token_utils::fee_token(data_store);

    // 63/64 gas is forwarded to external calls, reduce the startingGas to account for this
    let reduced_starting_gas = starting_gas - sn_gasleft(array![]) / 63;
    let gas_used = reduced_starting_gas - sn_gasleft(array![]);

    // each external call forwards 63/64 of the remaining gas
    let mut execution_fee_for_keeper = adjust_gas_usage(data_store, gas_used)
        * sn_gasprice(array![10]);

    if (execution_fee_for_keeper > execution_fee) {
        execution_fee_for_keeper = execution_fee;
    }

    bank.transfer_out(bank.contract_address, fee_token, keeper, execution_fee_for_keeper);

    event_emitter.emit_keeper_execution_fee(keeper, execution_fee_for_keeper);

    let refund_fee_amount = execution_fee - execution_fee_for_keeper;

    let refund_fee_amount = execution_fee - execution_fee_for_keeper;
    if (refund_fee_amount == 0) {
        return;
    }

    bank.transfer_out(bank.contract_address, fee_token, refund_receiver, refund_fee_amount);

    event_emitter.emit_execution_fee_refund(refund_receiver, refund_fee_amount);
}

fn pay_execution_fee_deposit(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    bank: IDepositVaultDispatcher,
    execution_fee: u256,
    starting_gas: u256,
    keeper: ContractAddress,
    refund_receiver: ContractAddress
) {
    let fee_token: ContractAddress = token_utils::fee_token(data_store);

    // 63/64 gas is forwarded to external calls, reduce the startingGas to account for this
    // let reduced_starting_gas = starting_gas - sn_gasleft(array![100]) / 63;
    // let gas_used = reduced_starting_gas - sn_gasleft(array![100]);

    let gas_used = 0;
    // each external call forwards 63/64 of the remaining gas
    let mut execution_fee_for_keeper = adjust_gas_usage(data_store, gas_used)
        * sn_gasprice(array![10]);

    if (execution_fee_for_keeper > execution_fee) {
        execution_fee_for_keeper = execution_fee;
    }

    bank.transfer_out(bank.contract_address, fee_token, keeper, execution_fee_for_keeper);

    event_emitter.emit_keeper_execution_fee(keeper, execution_fee_for_keeper);

    let refund_fee_amount = execution_fee - execution_fee_for_keeper;

    let refund_fee_amount = execution_fee - execution_fee_for_keeper;
    if (refund_fee_amount == 0) {
        return;
    }

    bank.transfer_out(bank.contract_address, fee_token, refund_receiver, refund_fee_amount);

    event_emitter.emit_execution_fee_refund(refund_receiver, refund_fee_amount);
}

fn pay_execution_fee_order(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    bank: IOrderVaultDispatcher,
    execution_fee: u256,
    starting_gas: u256,
    keeper: ContractAddress,
    refund_receiver: ContractAddress
) {
    let fee_token: ContractAddress = token_utils::fee_token(data_store);

    // 63/64 gas is forwarded to external calls, reduce the startingGas to account for this
    let reduced_starting_gas = starting_gas - sn_gasleft(array![100]) / 63;
    let gas_used = reduced_starting_gas - sn_gasleft(array![0]);

    // each external call forwards 63/64 of the remaining gas
    let mut execution_fee_for_keeper = adjust_gas_usage(data_store, gas_used)
        * sn_gasprice(array![10]);

    if (execution_fee_for_keeper > execution_fee) {
        execution_fee_for_keeper = execution_fee;
    }

    bank.transfer_out(bank.contract_address, fee_token, keeper, execution_fee_for_keeper);

    event_emitter.emit_keeper_execution_fee(keeper, execution_fee_for_keeper);

    let refund_fee_amount = execution_fee - execution_fee_for_keeper;

    let refund_fee_amount = execution_fee - execution_fee_for_keeper;
    if (refund_fee_amount == 0) {
        return;
    }

    bank.transfer_out(bank.contract_address, fee_token, refund_receiver, refund_fee_amount);

    event_emitter.emit_execution_fee_refund(refund_receiver, refund_fee_amount);
}

fn pay_execution_fee_withdrawal(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    bank: IWithdrawalVaultDispatcher,
    execution_fee: u256,
    starting_gas: u256,
    keeper: ContractAddress,
    refund_receiver: ContractAddress
) {
    let fee_token: ContractAddress = token_utils::fee_token(data_store);

    // 63/64 gas is forwarded to external calls, reduce the startingGas to account for this
    let reduced_starting_gas = starting_gas - sn_gasleft(array![100]) / 63;
    let gas_used = reduced_starting_gas - sn_gasleft(array![100]);

    // each external call forwards 63/64 of the remaining gas
    let mut execution_fee_for_keeper = adjust_gas_usage(data_store, gas_used)
        * sn_gasprice(array![10]);

    if (execution_fee_for_keeper > execution_fee) {
        execution_fee_for_keeper = execution_fee;
    }

    bank.transfer_out(bank.contract_address, fee_token, keeper, execution_fee_for_keeper);

    event_emitter.emit_keeper_execution_fee(keeper, execution_fee_for_keeper);

    let refund_fee_amount = execution_fee - execution_fee_for_keeper;

    let refund_fee_amount = execution_fee - execution_fee_for_keeper;
    if (refund_fee_amount == 0) {
        return;
    }

    bank.transfer_out(bank.contract_address, fee_token, refund_receiver, refund_fee_amount);

    event_emitter.emit_execution_fee_refund(refund_receiver, refund_fee_amount);
}

/// Validate that the provided executionFee is sufficient based on the estimated_gas_limit.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `estimated_gas_limit` - The estimated gas limit.
/// * `execution_fee` - The execution fee provided.
/// # Returns
/// * The key for the account order list.
fn validate_execution_fee(
    data_store: IDataStoreDispatcher, estimated_gas_limit: u256, execution_fee: u256
) {
    let gas_limit = adjust_gas_limit_for_estimate(data_store, estimated_gas_limit);
    let min_execution_fee = gas_limit * sn_gasprice(array![10]);
    if (execution_fee < min_execution_fee) {
        panic(array![GasError::INSUFF_EXEC_FEE]);
    }
}

/// Adjust the gas usage to pay a small amount to keepers.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `gas_used` - The amount of gas used.
fn adjust_gas_usage(data_store: IDataStoreDispatcher, gas_used: u256) -> u256 {
    // gas measurements are done after the call to with_oracle_prices
    // with_oracle_prices may consume a significant amount of gas
    // the base_gas_limit used to calculate the execution cost
    // should be adjusted to account for this
    // additionally, a transaction could fail midway through an execution transaction
    // before being cancelled, the possibility of this additional gas cost should
    // be considered when setting the base_gas_limit
    let base_gas_limit = data_store.get_u256(keys::execution_gas_fee_base_amount());
    // the gas cost is estimated based on the gasprice of the request txn
    // the actual cost may be higher if the gasprice is higher in the execution txn
    // the multiplier_factor should be adjusted to account for this
    let multiplier_factor = data_store.get_u256(keys::execution_gas_fee_multiplier_factor());
    base_gas_limit + precision::apply_factor_u256(gas_used, multiplier_factor)
}

/// Adjust the estimated gas limit to help ensure the execution fee is sufficient during the actual execution.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `estimated_gas_limit` - The estimated gas limit.
/// # Returns
/// The adjusted gas limit
fn adjust_gas_limit_for_estimate(
    data_store: IDataStoreDispatcher, estimated_gas_limit: u256
) -> u256 {
    let base_gas_limit = data_store.get_u256(keys::estimated_gas_fee_base_amount());
    let multiplier_factor = data_store.get_u256(keys::estimated_gas_fee_multiplier_factor());
    base_gas_limit + precision::apply_factor_u256(estimated_gas_limit, multiplier_factor)
}

/// The estimated gas limit for deposits.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `deposit` - The deposit to estimate the gas limit for.
fn estimate_execute_deposit_gas_limit(data_store: IDataStoreDispatcher, deposit: Deposit) -> u256 {
    let gas_per_swap = data_store.get_u256(keys::single_swap_gas_limit());
    let swap_count = deposit.long_token_swap_path.len() + deposit.short_token_swap_path.len();
    let gas_for_swaps = swap_count.into() * gas_per_swap;

    if (deposit.initial_long_token_amount == 0 || deposit.initial_short_token_amount == 0) {
        return data_store.get_u256(keys::deposit_gas_limit_key(true))
            + deposit.callback_gas_limit
            + gas_for_swaps;
    }

    return data_store.get_u256(keys::deposit_gas_limit_key(false))
        + deposit.callback_gas_limit
        + gas_for_swaps;
}

/// The estimated gas limit for withdrawals.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `withdrawal` - The withdrawal to estimate the gas limit for.
fn estimate_execute_withdrawal_gas_limit(
    data_store: IDataStoreDispatcher, withdrawal: Withdrawal
) -> u256 {
    let gas_per_swap = data_store.get_u256(keys::single_swap_gas_limit());
    let swap_count = withdrawal.long_token_swap_path.len() + withdrawal.short_token_swap_path.len();
    let gas_for_swaps = swap_count.into() * gas_per_swap;
    return data_store.get_u256(keys::withdrawal_gas_limit_key())
        + withdrawal.callback_gas_limit
        + gas_for_swaps;
}

/// The estimated gas limit for orders.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `order` - The order to estimate the gas limit for.
fn estimate_execute_order_gas_limit(data_store: IDataStoreDispatcher, order: @Order) -> u256 {
    if (is_increase_order(*order.order_type)) {
        return estimate_execute_increase_order_gas_limit(data_store, *order);
    }

    if (is_decrease_order(*order.order_type)) {
        return estimate_execute_decrease_order_gas_limit(data_store, *order);
    }

    if (is_swap_order(*order.order_type)) {
        return estimate_execute_swap_order_gas_limit(data_store, *order);
    }

    assert(false, OrderError::UNSUPPORTED_ORDER_TYPE);
    return 0;
}

/// The estimated gas limit for increase orders.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `order` - The order to estimate the gas limit for.
fn estimate_execute_increase_order_gas_limit(
    data_store: IDataStoreDispatcher, order: Order
) -> u256 {
    let gas_per_swap = data_store.get_u256(keys::single_swap_gas_limit_key());
    return data_store.get_u256(keys::increase_order_gas_limit_key())
        + gas_per_swap * order.swap_path.len().into()
        + order.callback_gas_limit;
}

/// The estimated gas limit for decrease orders.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `order` - The order to estimate the gas limit for.
fn estimate_execute_decrease_order_gas_limit(
    data_store: IDataStoreDispatcher, order: Order
) -> u256 {
    let mut gas_per_swap = data_store.get_u256(keys::single_swap_gas_limit_key());
    if (order.decrease_position_swap_type != DecreasePositionSwapType::NoSwap) {
        gas_per_swap += 1;
    }
    return data_store.get_u256(keys::decrease_order_gas_limit_key())
        + gas_per_swap * order.swap_path.len().into()
        + order.callback_gas_limit;
}

/// The estimated gas limit for swap orders.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `order` - The order to estimate the gas limit for.
fn estimate_execute_swap_order_gas_limit(data_store: IDataStoreDispatcher, order: Order) -> u256 {
    let gas_per_swap = data_store.get_u256(keys::single_swap_gas_limit_key());
    return data_store.get_u256(keys::swap_order_gas_limit_key())
        + gas_per_swap * order.swap_path.len().into()
        + order.callback_gas_limit;
}
