use starknet::{ContractAddress, contract_address_const};

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::mock::governable::{IGovernableDispatcher, IGovernableDispatcherTrait};

use satoru::role::role;
use satoru::deposit::deposit::Deposit;
use satoru::tests_lib::teardown;
use satoru::utils::span32::{Span32, Array32Trait};
use satoru::referral::referral_utils;

use snforge_std::{declare, start_prank, ContractClassTrait};

/// Utility function to deploy a `DataStore` contract and return its dispatcher.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    contract.deploy(@array![]).unwrap()
}

/// Utility function to deploy a `ReferralStorage` contract and return its dispatcher.
fn deploy_referral_storage(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('ReferralStorage');
    let constructor_calldata = array![event_emitter_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_governable(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('Governable');
    let constructor_calldata = array![event_emitter_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a `RoleStore` contract and return its dispatcher.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@array![]).unwrap()
}

/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IDataStoreDispatcher` - The data store dispatcher.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
fn setup() -> (ContractAddress, IRoleStoreDispatcher, IDataStoreDispatcher,IEventEmitterDispatcher,IReferralStorageDispatcher, IGovernableDispatcher) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();

    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    let referral_storage_address = deploy_referral_storage(event_emitter_address);
    let referral_storage = IReferralStorageDispatcher { contract_address: referral_storage_address };
    
    let governable_address = deploy_governable(event_emitter_address);
    let governable = IGovernableDispatcher { contract_address: governable_address };

    start_prank(role_store_address, caller_address);
    start_prank(event_emitter_address, caller_address);
    start_prank(data_store_address, caller_address);
    start_prank(referral_storage_address, caller_address);
    start_prank(governable_address, caller_address);

    (caller_address, role_store, data_store, event_emitter, referral_storage, governable)
}

#[test]
fn given_normal_conditions_when_set_and_override_new_deposit_then_works() {
    // Setup
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) = setup();

    referral_storage.set_handler(caller_address, true);
    let account: ContractAddress = contract_address_const::<111>();
    let referral_code: felt252 = 'QWERTY';
    let x = referral_utils::set_trader_referral_code(referral_storage, account, referral_code);
    let answer = referral_storage.trader_referral_codes(account);

    assert(answer == referral_code, 'this is not the correct code');

    teardown(data_store.contract_address);
}