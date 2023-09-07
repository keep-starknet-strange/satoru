// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use satoru::order::base_order_utils::ExecuteOrderParams;
use satoru::order::order_vault::{IOrderVaultSafeDispatcher, IOrderVaultSafeDispatcherTrait};
use satoru::referral::referral_storage::interface::{
    IReferralStorageSafeDispatcher, IReferralStorageSafeDispatcherTrait
};
use satoru::order::base_order_utils::CreateOrderParams;

/// Creates an order in the order store.
/// # Arguments
/// * `data_store` - DataStore
/// * `event_emitter` - EventEmitter
/// * `order_vault` - OrderVault
/// * `referral_storage` - ReferralStorage
/// * `account` - the order account
/// * `params` - create order params
fn create_order(
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    order_vault: IOrderVaultSafeDispatcher,
    referral_storage: IReferralStorageSafeDispatcher,
    account: ContractAddress,
    params: CreateOrderParams,
) -> felt252 {
    // TODO
    0
}

/// Cancels an order.
/// # Arguments
/// * `data_store` - DataStore
/// * `event_emitter` - EventEmitter
/// * `order_vault` - OrderVault
/// * `key` - the order key
/// * `keeper` - the order keeper
/// * `reason` - the order cancellation reason
fn cancel_order(
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    order_vault: IOrderVaultSafeDispatcher,
    key: felt252,
    keeper: ContractAddress,
    // starting_gas: u256,
    reason: felt252,
) -> felt252 {
    // TODO
    0
}

/// Executes an order.
/// # Arguments
/// * `params` - execute order params.
fn execute_order(params: ExecuteOrderParams) {// TODO
}
