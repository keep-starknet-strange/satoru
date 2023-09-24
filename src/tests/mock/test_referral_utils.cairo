use starknet::{ContractAddress, contract_address_const};

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::mock::governable::{IGovernableDispatcher, IGovernableDispatcherTrait};

use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions, start_prank
};
use satoru::role::role;
use satoru::deposit::deposit::Deposit;
use satoru::tests_lib::teardown;
use satoru::utils::span32::{Span32, Array32Trait};
use satoru::referral::referral_utils;

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
fn setup() -> (
    ContractAddress,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IEventEmitterDispatcher,
    IReferralStorageDispatcher,
    IGovernableDispatcher
) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();

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

#[test]
fn given_normal_conditions_when_trader_referral_codes_then_works() {
    // Setup
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();

    //Set the referral code for a trader and getting it from the storage.
    referral_storage.set_handler(caller_address, true);
    let account: ContractAddress = contract_address_const::<111>();
    let referral_code: felt252 = 'QWERTY';
    let x = referral_utils::set_trader_referral_code(referral_storage, account, referral_code);
    let answer = referral_storage.trader_referral_codes(account);

    assert(answer == referral_code, 'this is not the correct code');

    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('forbidden',))]
fn given_forbidden_when_trader_referral_codes_then_fails() {
    // Setup
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();

    //forbidden access
    let account: ContractAddress = contract_address_const::<111>();
    let referral_code: felt252 = 'QWERTY';
    let x = referral_utils::set_trader_referral_code(referral_storage, account, referral_code);
    let answer = referral_storage.trader_referral_codes(account);
    assert(answer == referral_code, 'this is not the correct code');
    teardown(data_store.contract_address);
}


#[test]
fn given_normal_conditions_when_increment_affiliate_reward_then_works() {
    // Setup
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();

    //TODO be able to do it when you can read next_value and next_pool_value
    role_store.grant_role(caller_address, role::CONTROLLER);

    let market: ContractAddress = contract_address_const::<'market'>();
    let token: ContractAddress = contract_address_const::<'token'>();
    let affiliate: ContractAddress = contract_address_const::<'affiliate'>();

    let delta: u128 = 3;

    //    let expected_data: Array<felt252> = array![
    //         market.into(), token.into(), affiliate.into(), delta.into(), next_value.into(), next_pool_value.into()
    //     ];

    referral_utils::increment_affiliate_reward(
        data_store, event_emitter, market, token, affiliate, delta
    );

    // let mut spy = spy_events(SpyOn::One(caller_address));
    // spy
    //     .assert_emitted(
    //         @array![
    //             Event {
    //                 from: caller_address,
    //                 name: 'EmitAffiliateRewardUpdated',
    //                 keys: array![],
    //                 data: expected_data
    //             }
    //         ]
    //     );

    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_get_referral_info_then_works() {
    // Setup
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();

    //Get the referral information for a specified trader (code, the affiliate address, total_rebate, discount_share)
    referral_storage.set_handler(caller_address, true);
    //add referral code
    let code: felt252 = 'WISOQKW';
    referral_storage.set_trader_referral_code(caller_address, code);
    //set code owner gov
    referral_storage.gov_set_code_owner(code, caller_address);
    //set referrer tier
    referral_storage.set_referrer_tier(caller_address, 2);
    //set tier
    referral_storage.set_tier(2, 20, 30);
    //set referrer discount share
    referral_storage.set_referrer_discount_share(30);

    let (code, affiliate, total_rebate, discount_share) = referral_utils::get_referral_info(
        referral_storage, caller_address
    );

    assert(code == code, 'the code is wrong');
    assert(affiliate == caller_address, 'the affiliate is wrong');
    assert(total_rebate == 2000000000000000000000000000, 'the total_rebate is wrong');
    assert(discount_share == 3000000000000000000000000000, 'the discount_share is wrong');

    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_claim_affiliate_reward_then_works() {
    // Setup
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();

    //Get the referral information for a specified trader
    let market: ContractAddress = contract_address_const::<'market'>();
    let token: ContractAddress = contract_address_const::<'token'>();
    let account: ContractAddress = contract_address_const::<'account'>();
    let receiver: ContractAddress = contract_address_const::<'receiver'>();

    role_store.grant_role(caller_address, role::CONTROLLER);

    let reward_amount: u128 = referral_utils::claim_affiliate_reward(
        data_store, event_emitter, market, token, account, receiver
    );

    assert(reward_amount == 0, 'the reward amount is wrong');

    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_increment_affiliate_reward_and_claim_affiliate_reward_then_works() {
    // Setup
    let (caller_address, role_store, data_store, event_emitter, referral_storage, governable) =
        setup();

    //Get the referral information for a specified trader after incrementing the affiliate reward balance
    let market: ContractAddress = contract_address_const::<'market'>();
    let token: ContractAddress = contract_address_const::<'token'>();
    let affiliate: ContractAddress = contract_address_const::<'affiliate'>();
    let account: ContractAddress = contract_address_const::<'account'>();
    let receiver: ContractAddress = contract_address_const::<'receiver'>();
    let delta: u128 = 10;

    role_store.grant_role(caller_address, role::CONTROLLER);
    referral_utils::increment_affiliate_reward(
        data_store, event_emitter, market, token, affiliate, delta
    );

    let reward_amount: u128 = referral_utils::claim_affiliate_reward(
        data_store, event_emitter, market, token, affiliate, receiver
    );

    assert(reward_amount == 10, 'the reward amount is wrong');

    teardown(data_store.contract_address);
}
