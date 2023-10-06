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
use satoru::referral::referral_tier::ReferralTier;
use satoru::referral::referral_utils;
use satoru::role::role;
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::tests_lib;
use satoru::utils::span32::{Span32, Array32Trait};

// *********************************************************************************************
// *                                      TEST LOGIC                                           *
// *********************************************************************************************
#[test]
fn given_initialize_when_already_intialized_then_works() {
    let (_, _, data_store, event_emitter, referral_storage, _) = setup();
    referral_storage.initialize(event_emitter.contract_address);
    referral_storage.initialize(event_emitter.contract_address);
    referral_storage.initialize(event_emitter.contract_address);
    referral_storage.initialize(event_emitter.contract_address);
    tests_lib::teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_setting_handler_from_storage_than_work() {
    let (caller_address, _, data_store, _, referral_storage, _) = setup();

    referral_storage.set_handler(caller_address, true);
    // Should execute without any panic
    referral_storage.only_handler();

    tests_lib::teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('Unauthorized gov caller',))]
fn given_caller_has_no_gov_role_then_fails() {
    let (caller_address, _, data_store, _, referral_storage, _) = setup();
    stop_prank(referral_storage.contract_address);

    let dummy_address: ContractAddress = contract_address_const::<'dummy'>();
    start_prank(referral_storage.contract_address, dummy_address);
    referral_storage.set_handler(caller_address, true);
    tests_lib::teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('forbidden',))]
fn given_handler_not_set_than_fails() {
    let (_, _, data_store, _, referral_storage, _) = setup();

    referral_storage.only_handler();

    tests_lib::teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_setting_and_fetching_code_owner_from_storage_then_works() {
    let (caller_address, _, data_store, _, referral_storage, _) = setup();

    let code: felt252 = 'EBDW';
    referral_storage.gov_set_code_owner(code, caller_address);

    let res: ContractAddress = referral_storage.code_owners(code);
    assert(res == caller_address, 'address should be set');

    tests_lib::teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_fetching_code_owner_from_storage_before_setting_then_works() {
    let (_, _, data_store, _, referral_storage, _) = setup();

    let code: felt252 = 'EBDW';

    let res: ContractAddress = referral_storage.code_owners(code);
    assert(res == contract_address_const::<0>(), 'address should not be set');

    tests_lib::teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_setting_and_fetching_tier_from_storage_then_works() {
    let (_, _, data_store, _, referral_storage, _) = setup();

    let tier_id: u128 = 3;
    let total_rebate: u128 = 10;
    let discount_share: u128 = 10;
    referral_storage.set_tier(tier_id, total_rebate, discount_share);

    let mut referral_tier: ReferralTier = referral_storage.tiers(tier_id);
    assert(referral_tier.total_rebate == total_rebate, 'total rebate not set');
    assert(referral_tier.discount_share == discount_share, 'discount share not set');

    tests_lib::teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('invalid total_rebate',))]
fn given_total_rebate_too_high_when_setting_and_fetching_tier_from_storage_then_fails() {
    let (_, _, data_store, _, referral_storage, _) = setup();

    let tier_id: u128 = 3;
    let total_rebate: u128 = 10001;
    let discount_share: u128 = 10;
    referral_storage.set_tier(tier_id, total_rebate, discount_share);

    tests_lib::teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('invalid discount_share',))]
fn given_discount_share_too_high_when_setting_and_fetching_tier_from_storage_then_fails() {
    let (_, _, data_store, _, referral_storage, _) = setup();

    let tier_id: u128 = 3;
    let total_rebate: u128 = 10;
    let discount_share: u128 = 10001;
    referral_storage.set_tier(tier_id, total_rebate, discount_share);

    tests_lib::teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_setting_and_fetching_referrer_tiers_from_storage_then_works() {
    let (caller_address, _, data_store, _, referral_storage, _) = setup();

    let tier_id: u128 = 3;
    referral_storage.set_referrer_tier(caller_address, tier_id);

    let res: u128 = referral_storage.referrer_tiers(caller_address);
    assert(res == tier_id, 'the tier_id is wrong');

    tests_lib::teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_fetching_referrer_tiers_from_storage_before_setting_then_works() {
    let (caller_address, _, data_store, _, referral_storage, _) = setup();

    let tier_id: u128 = 3;

    let res: u128 = referral_storage.referrer_tiers(caller_address);
    assert(res == 0, 'the tier_id is wrong');

    tests_lib::teardown(data_store.contract_address);
}

// *********************************************************************************************
// *                                      SETUP                                                *
// *********************************************************************************************
/// Utility function to setup the test environment
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
    start_prank(governable_address, caller_address);
    start_prank(referral_storage_address, caller_address);

    start_prank(role_store.contract_address, caller_address);
    start_prank(event_emitter_address, caller_address);
    start_prank(data_store.contract_address, caller_address);
    start_prank(referral_storage_address, caller_address);
    start_prank(governable_address, caller_address);

    return (caller_address, role_store, data_store, event_emitter, referral_storage, governable);
}

/// Deploy an `EventEmitter` contract and return its dispatcher.
fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    contract.deploy(@array![]).unwrap()
}

/// Deploy a `ReferralStorage` contract and return its dispatcher.
fn deploy_referral_storage(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('ReferralStorage');
    let constructor_calldata = array![event_emitter_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Deploy a `Governable` contract and return its dispatcher.
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
) {}
