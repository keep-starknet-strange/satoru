// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::event::event_emitter::{
    IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait
};
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
}