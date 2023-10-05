//! Test file for `src/deposit/deposit_vault.cairo`.

// *********************************************************************************************
// *                                       IMPORTS                                             *
// *********************************************************************************************
// Core lib imports.
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};
use starknet::{ContractAddress, contract_address_const};

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::deposit::deposit::Deposit;
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::mock::governable::{IGovernableDispatcher, IGovernableDispatcherTrait};
use satoru::referral::referral_utils;
use satoru::role::role;
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::tests_lib;
use satoru::utils::span32::{Span32, Array32Trait};


// *********************************************************************************************
// *                                      TEST LOGIC                                           *
// *********************************************************************************************
#[test]
fn given_normal_conditions_when_setting_and_fetching_code_owner_from_storage_then_works() {
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();

    //setting the code_owner and fetching it from storage
    let code: felt252 = 'EBDW';
    let new_account: ContractAddress = contract_address_const::<'new_account'>();

    referral_storage.gov_set_code_owner(code, new_account);
    let res: ContractAddress = referral_storage.code_owners(code);
    assert(res == new_account, 'the address is wrong');

    teardown(data_store, event_emitter, referral_storage, governable);
}

#[test]
fn given_normal_conditions_when_fetching_code_owner_from_storage_before_setting_then_works() {
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();

    //fetching the code owner from storage before setting it
    let code: felt252 = 'EBDW';
    let new_account: ContractAddress = contract_address_const::<'new_account'>();

    let res: ContractAddress = referral_storage.code_owners(code);
    assert(res == contract_address_const::<0>(), 'the address is wrong');

    teardown(data_store, event_emitter, referral_storage, governable);
}

#[test]
fn given_normal_conditions_when_setting_and_fetching_referrer_tiers_from_storage_then_works() {
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();

    //setting the referrer_id and fetching it from storage
    let tier_id: u128 = 3;
    let new_account: ContractAddress = contract_address_const::<'new_account'>();

    referral_storage.set_referrer_tier(new_account, tier_id);
    let res: u128 = referral_storage.referrer_tiers(new_account);
    assert(res == tier_id, 'the tier_id is wrong');

    teardown(data_store, event_emitter, referral_storage, governable);
}

#[test]
fn given_normal_conditions_when_fetching_referrer_tiers_from_storage_before_setting_then_works() {
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();

    //fetching the referrer_tier from storage before setting it
    let tier_id: u128 = 3;
    let new_account: ContractAddress = contract_address_const::<'new_account'>();

    let res: u128 = referral_storage.referrer_tiers(new_account);
    assert(res == 0, 'the tier_id is wrong');

    teardown(data_store, event_emitter, referral_storage, governable);
}

// *********************************************************************************************
// *                                      SETUP                                                *
// *********************************************************************************************
fn setup() -> (
    ContractAddress,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IEventEmitterDispatcher,
    IReferralStorageDispatcher,
    IGovernableDispatcher
) {
    let (caller_address, role_store, data_store) = tests_lib::setup();

    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    let referral_storage_address = deploy_referral_storage(event_emitter_address);
    let referral_storage = IReferralStorageDispatcher {
        contract_address: referral_storage_address
    };

    let governable_address = deploy_governable(event_emitter_address);
    let governable = IGovernableDispatcher { contract_address: governable_address };

    start_prank(event_emitter_address, caller_address);
    start_prank(referral_storage_address, caller_address);
    start_prank(governable_address, caller_address);

    return (caller_address, role_store, data_store, event_emitter, referral_storage, governable);
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    contract.deploy(@array![]).unwrap()
}

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

// *********************************************************************************************
// *                                     TEARDOWN                                              *
// *********************************************************************************************
fn teardown(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    referral_storage: IReferralStorageDispatcher,
    governable: IGovernableDispatcher
) {
    tests_lib::teardown(data_store.contract_address);
    stop_prank(event_emitter.contract_address);
    stop_prank(referral_storage.contract_address);
    stop_prank(governable.contract_address);
}
