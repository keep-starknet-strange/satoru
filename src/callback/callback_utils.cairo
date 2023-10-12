//! Most features require a two step process to complete
//! the user first sends a request transaction, then a second transaction is sent
//! by a keeper to execute the request.
//!
//! To allow for better composability with other contracts, a callback contract
//! can be specified to be called after request executions or cancellations.
//!
//! In case it is necessary to add "before" callbacks, extra care should be taken
//! to ensure that important state cannot be changed during the before callback.
//! For example, if an order can be cancelled in the "before" callback during
//! order execution, it may lead to an order being executed even though the user
//! was already refunded for its cancellation.
//!
//! The details from callback errors are not processed to avoid cases where a malicious
//! callback contract returns a very large value to cause transactions to run out of gas.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::data::keys;
use satoru::event::event_utils::LogData;
use satoru::order::order::Order;
use satoru::deposit::deposit::Deposit;
use satoru::withdrawal::withdrawal::Withdrawal;
use satoru::callback::error::CallbackError;
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::callback::order_callback_receiver::interface::{
    IOrderCallbackReceiverDispatcher, IOrderCallbackReceiverDispatcherTrait
};
use satoru::callback::deposit_callback_receiver::interface::{
    IDepositCallbackReceiverDispatcher, IDepositCallbackReceiverDispatcherTrait
};
use satoru::callback::withdrawal_callback_receiver::interface::{
    IWithdrawalCallbackReceiverDispatcher, IWithdrawalCallbackReceiverDispatcherTrait
};

/// Validate that the callback_gas_limit is less than the max specified value.
/// This is to prevent callback gas limits which are larger than the max gas limits per block
/// as this would allow for callback contracts that can consume all gas.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `callback_gas_limit` - The callback gas limit.
fn validate_callback_gas_limit(data_store: IDataStoreDispatcher, callback_gas_limit: u128) {
    let max_callback_gas_limit = data_store.get_u128(keys::max_callback_gas_limit());
    if callback_gas_limit > max_callback_gas_limit {
        panic(
            array![
                CallbackError::MAX_CALLBACK_GAS_LIMIT_EXCEEDED,
                callback_gas_limit.into(),
                max_callback_gas_limit.into()
            ]
        );
    }
}

/// It allows an external entity to associate a callback contract address
/// with a specific account and market. This association is stored in a data store
/// using the provided keys, enabling efficient retrieval for later interactions involving callbacks.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `account` - The account to set callback contract for.
/// * `market` - The market to set callback contract for.
/// * `callback_contract` - The callback_contract address.
fn set_saved_callback_contract(
    data_store: IDataStoreDispatcher,
    account: ContractAddress,
    market: ContractAddress,
    callback_contract: ContractAddress
) {
    data_store.set_address(keys::saved_callback_contract_key(account, market), callback_contract);
}

/// It retrieves a previously stored callback contract address associated with a given account
/// and market from the data store.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `account` - The account to set callback contract for.
/// * `market` - The market to set callback contract for.
fn get_saved_callback_contract(
    data_store: IDataStoreDispatcher, account: ContractAddress, market: ContractAddress
) -> ContractAddress {
    data_store.get_address(keys::saved_callback_contract_key(account, market))
}

/// Called after a deposit execution.
/// # Arguments
/// * `key` - They key of the deposit.
/// * `deposit` - The deposit that was executed.
/// * `log_data` - The log data.
fn after_deposit_execution(key: felt252, deposit: Deposit, log_data: LogData) {
    if !is_valid_callback_contract(deposit.callback_contract) {
        return;
    }
    let dispatcher = IDepositCallbackReceiverDispatcher {
        contract_address: deposit.callback_contract
    };
    dispatcher.after_deposit_execution(key, deposit, log_data)
}

/// Called after a deposit cancellation.
/// # Arguments
/// * `key` - They key of the deposit.
/// * `deposit` - The deposit that was cancelled.
/// * `log_data` - The log data.
fn after_deposit_cancellation(key: felt252, deposit: Deposit, log_data: LogData) {
    if !is_valid_callback_contract(deposit.callback_contract) {
        return;
    }
    let dispatcher = IDepositCallbackReceiverDispatcher {
        contract_address: deposit.callback_contract
    };
    dispatcher.after_deposit_cancellation(key, deposit, log_data)
}

/// Called after a withdrawal execution.
/// # Arguments
/// * `key` - They key of the withdrawal.
/// * `withdrawal` - The withdrawal that was executed.
/// * `log_data` - The log data.
fn after_withdrawal_execution(key: felt252, withdrawal: Withdrawal, log_data: LogData) {
    if !is_valid_callback_contract(withdrawal.callback_contract) {
        return;
    }
    let dispatcher = IWithdrawalCallbackReceiverDispatcher {
        contract_address: withdrawal.callback_contract
    };
    dispatcher.after_withdrawal_execution(key, withdrawal, log_data)
}

/// Called after an withdrawal cancellation.
/// # Arguments
/// * `key` - They key of the withdrawal.
/// * `withdrawal` - The withdrawal that was cancelled.
/// * `log_data` - The log data.
fn after_withdrawal_cancellation(key: felt252, withdrawal: Withdrawal, log_data: LogData) {
    if !is_valid_callback_contract(withdrawal.callback_contract) {
        return;
    }
    let dispatcher = IWithdrawalCallbackReceiverDispatcher {
        contract_address: withdrawal.callback_contract
    };
    dispatcher.after_withdrawal_cancellation(key, withdrawal, log_data)
}

/// Called after an order execution.
/// # Arguments
/// * `key` - They key of the order.
/// * `order` - The order that was executed.
/// * `log_data` - The log data.
fn after_order_execution(key: felt252, order: Order, log_data: LogData) {
    if !is_valid_callback_contract(order.callback_contract) {
        return;
    }
    let dispatcher = IOrderCallbackReceiverDispatcher { contract_address: order.callback_contract };
    dispatcher.after_order_execution(key, order, log_data)
}

/// Called after an order cancellation.
/// # Arguments
/// * `key` - They key of the order.
/// * `order` - The order that was cancelled.
/// * `log_data` - The log data.
fn after_order_cancellation(key: felt252, order: Order, log_data: LogData) {
    if !is_valid_callback_contract(order.callback_contract) {
        return;
    }
    let dispatcher = IOrderCallbackReceiverDispatcher { contract_address: order.callback_contract };
    dispatcher.after_order_cancellation(key, order, log_data)
}

/// Called after an order cancellation.
/// # Arguments
/// * `key` - They key of the order.
/// * `order` - The order that was frozen.
/// * `log_data` - The log data.
fn after_order_frozen(key: felt252, order: Order, log_data: LogData) {
    if !is_valid_callback_contract(order.callback_contract) {
        return;
    }
    let dispatcher = IOrderCallbackReceiverDispatcher { contract_address: order.callback_contract };
    dispatcher.after_order_frozen(key, order, log_data)
}

/// Validates that the given address is a contract.
/// # Arguments
/// * `callback_contract` - The callback contract.
fn is_valid_callback_contract(callback_contract: ContractAddress) -> bool {
    callback_contract.is_non_zero()
}
