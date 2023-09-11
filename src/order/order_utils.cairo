// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::order::base_order_utils::{ExecuteOrderParams, CreateOrderParams};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::order::order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait};
use satoru::referral::referral_storage::interface::{
    IReferralStorageDispatcher, IReferralStorageDispatcherTrait
};

/// Creates an order in the order store.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `order_vault` - The `OrderVault` contract dispatcher.
/// * `referral_store` - The referral storage instance to use.
/// * `account` - The order account.
/// * `params` - The parameters used to create the order.
/// # Returns
/// Return the key of the created order.
fn create_order(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    order_vault: IOrderVaultDispatcher,
    referral_store: IReferralStorageDispatcher,
    account: ContractAddress,
    params: CreateOrderParams
) -> felt252 {
    0
//TODO
}

/// Executes an order.
/// # Arguments
/// * `params` - The parameters used to execute the order.
#[inline(always)]
fn execute_order(params: ExecuteOrderParams) { //TODO
}

/// Process an order execution.
/// # Arguments
/// * `params` - The parameters used to process the order.
#[inline(always)]
fn process_order(params: ExecuteOrderParams) { //TODO
}

/// Cancels an order.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `order_vault` - The `OrderVault` contract dispatcher.
/// * `key` - The key of the order to cancel
/// * `keeper` - The keeper sending the transaction.
/// * `starting_gas` - The starting gas of the transaction.
/// * `reason` - The reason for cancellation.
/// # Returns
/// Return the key of the created order.
fn cancel_order(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    order_vault: IOrderVaultDispatcher,
    key: felt252,
    keeper: ContractAddress,
    starting_gas: u128,
    reason: felt252,
    reason_bytes: felt252
) { //TODO
}

/// Freezes an order.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `order_vault` - The `OrderVault` contract dispatcher.
/// * `key` - The key of the order to freeze
/// * `keeper` - The keeper sending the transaction.
/// * `starting_gas` - The starting gas of the transaction.
/// * `reason` - The reason the order was frozen.
/// # Returns
/// Return the key of the created order.
fn freeze_order(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    order_vault: IOrderVaultDispatcher,
    key: felt252,
    keeper: ContractAddress,
    starting_gas: u128,
    reason: felt252,
    reason_bytes: Array<felt252>
) { //TODO
}
