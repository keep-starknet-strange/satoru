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
use result::ResultTrait;
use traits::{Into, TryInto};
use option::OptionTrait;

// Local imports.
use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::event::event_utils::EventLogData;
use gojo::order::order::Order;
use gojo::deposit::deposit::Deposit;
use gojo::withdrawal::withdrawal::Withdrawal;

/// Validate that the callbackGasLimit is less than the max specified value.
/// This is to prevent callback gas limits which are larger than the max gas limits per block
/// as this would allow for callback contracts that can consume all gas.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `callback_gas_limit` - The callback gas limit.
fn validate_callback_gas_limit(
    data_store: IDataStoreSafeDispatcher, callback_gas_limit: u128
) { // TODO
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
    data_store: IDataStoreSafeDispatcher,
    account: ContractAddress,
    market: ContractAddress,
    callback_contract: ContractAddress
) { // TODO
}

/// It retrieves a previously stored callback contract address associated with a given account
/// and market from the data store.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `account` - The account to set callback contract for.
/// * `market` - The market to set callback contract for.
fn get_saved_callback_contract(
    data_store: IDataStoreSafeDispatcher, account: ContractAddress, market: ContractAddress
) -> ContractAddress { // TODO
    0.try_into().unwrap()
}

/// Called after a deposit execution.
/// # Arguments
/// * `key` - They key of the deposit.
/// * `deposit` - The deposit that was executed.
/// * `event_data` - The event log data.
fn after_deposit_execution(key: felt252, deposit: Deposit, event_data: EventLogData) { // TODO
}

/// Called after a deposit cancellation.
/// # Arguments
/// * `key` - They key of the deposit.
/// * `deposit` - The deposit that was cancelled.
/// * `event_data` - The event log data.
fn after_deposit_cancellation(key: felt252, deposit: Deposit, event_data: EventLogData) { // TODO
}

/// Called after a withdrawal execution.
/// # Arguments
/// * `key` - They key of the withdrawal.
/// * `withdrawal` - The withdrawal that was executed.
/// * `event_data` - The event log data.
fn after_withdrawal_execution(
    key: felt252, withdrawal: Withdrawal, event_data: EventLogData
) { // TODO + need to add withdrawal param also
}

/// Called after an withdrawal cancellation.
/// # Arguments
/// * `key` - They key of the withdrawal.
/// * `withdrawal` - The withdrawal that was cancelled.
/// * `event_data` - The event log data.
fn after_withdrawal_cancellation(
    key: felt252, withdrawal: Withdrawal, event_data: EventLogData
) { // TODO + need to add withdrawal param also
}

/// Called after an order execution.
/// # Arguments
/// * `key` - They key of the order.
/// * `order` - The order that was executed.
/// * `event_data` - The event log data.
fn after_order_execution(key: felt252, order: Order, event_data: EventLogData) { // TODO
}

/// Called after an order cancellation.
/// # Arguments
/// * `key` - They key of the order.
/// * `order` - The order that was cancelled.
/// * `event_data` - The event log data.
fn after_order_cancellation(key: felt252, order: Order, event_data: EventLogData) { // TODO
}

/// Called after an order cancellation.
/// # Arguments
/// * `key` - They key of the order.
/// * `order` - The order that was frozen.
/// * `event_data` - The event log data.
fn after_order_frozen(key: felt252, order: Order, event_data: EventLogData) { // TODO
}

/// Validates that the given address is a contract.
/// # Arguments
/// * `callback_contract` - The callback contract.
fn is_valid_callback_contract(callback_contract: ContractAddress) -> bool { // TODO
    true
}
