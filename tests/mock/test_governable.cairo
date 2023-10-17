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

fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'data_store'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'role_store'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![], deployed_contract_address).unwrap()
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'event_emitter'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![], deployed_contract_address).unwrap()
}

fn deploy_referral_storage(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('ReferralStorage');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'referral_storage'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![event_emitter_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_governable(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('Governable');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'governable'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![event_emitter_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn setup() -> (
    ContractAddress,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IEventEmitterDispatcher,
    IReferralStorageDispatcher,
    IGovernableDispatcher
) {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();

    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    let referral_storage_address = deploy_referral_storage(event_emitter_address);
    let referral_storage = IReferralStorageDispatcher {
        contract_address: referral_storage_address
    };

    let governable_address = deploy_governable(event_emitter_address);
    let governable = IGovernableDispatcher { contract_address: governable_address };

    start_prank(role_store_address, caller_address);
    start_prank(event_emitter_address, caller_address);
    start_prank(data_store_address, caller_address);
    start_prank(referral_storage_address, caller_address);
    start_prank(governable_address, caller_address);

    (caller_address, role_store, data_store, event_emitter, referral_storage, governable)
}

fn setup_with_other_address() -> (
    ContractAddress,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IEventEmitterDispatcher,
    IReferralStorageDispatcher,
    IGovernableDispatcher
) {
    let caller_address: ContractAddress = 0x102.try_into().unwrap();

    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    let referral_storage_address = deploy_referral_storage(event_emitter_address);
    let referral_storage = IReferralStorageDispatcher {
        contract_address: referral_storage_address
    };

    let governable_address = deploy_governable(event_emitter_address);
    let governable = IGovernableDispatcher { contract_address: governable_address };

    start_prank(role_store_address, caller_address);
    start_prank(event_emitter_address, caller_address);
    start_prank(data_store_address, caller_address);
    start_prank(referral_storage_address, caller_address);
    start_prank(governable_address, caller_address);

    (caller_address, role_store, data_store, event_emitter, referral_storage, governable)
}

//TODO add more tests

// This test checks the 'only_gov' function under normal conditions.
// It sets up the environment with the correct initial governance, then calls `only_gov`.
// The test expects the call to succeed without any errors.
#[test]
fn given_normal_conditions_when_only_gov_then_works() {
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();
    governable.only_gov();
    teardown(data_store.contract_address);
}

// This test checks the `only_gov` function when the governance condition is not met.
// It sets up the environment with a different governance, then calls `only_gov`.
// The test expects the call to panic with the error 'Unauthorized gov caller'.
#[test]
#[should_panic(expected: ('Unauthorized gov caller',))]
fn given_forbidden_when_only_gov_then_fails() {
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup_with_other_address();
    governable.only_gov();
    teardown(data_store.contract_address);
}

// This test checks the `transfer_ownership` function under normal conditions.
// It sets up the environment with the correct initial governance, then calls `transfer_ownership`
// with a new governance address.
// The test expects the call to succeed and the ownership to be transferred without any errors.
#[test]
fn given_normal_conditions_when_transfer_ownership_then_works() {
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();
    let new_caller_address: ContractAddress = 0x102.try_into().unwrap();
    governable.transfer_ownership(new_caller_address);
    teardown(data_store.contract_address);
}

/// This test case verifies the `transfer_ownership` function behavior when called by an unauthorized address.
/// The expected outcome is a panic with the error message "Unauthorized gov caller" which corresponds
/// to the `UNAUTHORIZED_GOV` error in the `MockError` module.
#[test]
#[should_panic(expected: ('Unauthorized gov caller',))]
fn given_unauthorized_caller_when_transfer_ownership_then_fails() {
    // Setup the environment with a different caller address.
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup_with_other_address();

    // Try to transfer ownership to a new address.
    let new_uncaller_address: ContractAddress = 0x102.try_into().unwrap();
    governable.transfer_ownership(new_uncaller_address);
    teardown(data_store.contract_address);
}

/// This test checks the `accept_ownership` function under normal conditions.
/// It sets up the environment with the correct initial governance, then calls `transfer_ownership`
/// to a new governance address, followed by `accept_ownership` from the new governance address.
/// The test expects the call to succeed and the ownership to be accepted without any errors.
#[test]
fn given_normal_conditions_when_accept_ownership_then_works() {
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();
    let new_caller_address: ContractAddress = 0x102.try_into().unwrap();

    // Transfer the ownership to the new address.
    governable.transfer_ownership(new_caller_address);

    // Update the prank context to the new governance address, to simulate the new governor accepting the ownership.
    start_prank(governable.contract_address, new_caller_address);

    // Now call accept_ownership from the new governance address.
    governable.accept_ownership();
    teardown(data_store.contract_address);
}

/// This test checks the `accept_ownership` function under abnormal conditions.
/// It sets up the environment with the correct initial governance, then calls `transfer_ownership`
/// to a new governance address. However, `accept_ownership` is then called from an unauthorized address.
/// The test expects the call to panic with the error 'Unauthorized pending_gov caller'.
#[test]
#[should_panic(expected: ('Unauthorized pending_gov caller',))]
fn given_abnormal_conditions_when_accept_ownership_then_fails() {
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();
    let new_caller_address: ContractAddress = 0x102.try_into().unwrap();
    let unauthorized_address: ContractAddress = 0x103.try_into().unwrap();

    // Transfer the ownership to the new address.
    governable.transfer_ownership(new_caller_address);

    // Update the prank context to an unauthorized address, to simulate an unauthorized attempt to accept the ownership.
    start_prank(governable.contract_address, unauthorized_address);

    // Now call accept_ownership from the unauthorized address.
    governable.accept_ownership();
    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('already_initialized',))]
fn given_already_initialized_when_initialize_then_fails() {
    // Setup the environment.
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();

    // Assume that the contract has been initialized during setup.
    // Try to initialize it again with the same event emitter address.
    let event_emitter_address = event_emitter.contract_address;

    // This call should panic with the error 'already_initialized'.
    governable.initialize(event_emitter_address);
    teardown(data_store.contract_address);
}
