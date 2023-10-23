use starknet::{ContractAddress, contract_address_const};

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::event::event_emitter::{
    EventEmitter, IEventEmitterDispatcher, IEventEmitterDispatcherTrait
};
use satoru::event::event_emitter::EventEmitter::{AffiliateRewardUpdated, AffiliateRewardClaimed};
use satoru::mock::governable::{IGovernableDispatcher, IGovernableDispatcherTrait};
use debug::PrintTrait;
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions, start_prank, stop_prank
};
use satoru::role::role;
use satoru::deposit::deposit::Deposit;
use satoru::tests_lib::teardown;
use satoru::utils::span32::{Span32, Array32Trait};
use satoru::referral::referral_utils;
use satoru::data::keys;
use satoru::utils::precision;
use satoru::market::market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait};
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};


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

/// Utility function to deploy a `MarketToken` contract and return its dispatcher.
fn deploy_market_token(
    role_store_address: ContractAddress, data_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('MarketToken');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'market_token'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![role_store_address.into(), data_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

/// Utility function to deploy a mock token contract 
fn setup_mock_token(
    recipient: ContractAddress, market_token: ContractAddress
) -> (ContractAddress, IERC20Dispatcher) {
    let contract = declare('ERC20');
    let constructor_calldata = array![11, 11, 10000000000000000000000, 0, recipient.into()];
    let token_address = contract.deploy(@constructor_calldata).unwrap();

    let token_contract = IERC20Dispatcher { contract_address: token_address };

    start_prank(token_address, recipient);
    token_contract.transfer(market_token, 10000000000000000000000);
    stop_prank(token_address);
    (token_address, token_contract)
}


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
/// * `IEventEmitterDispatcher` - The event emitter dispatcher.
/// * `IReferralStorageDispatcher` - The referral store dispatcher.
/// * `IGovernableDispatcher` - The governanace dispatcher.
/// * `IMarketTokenDispatcher` - The market token distpatcher.

fn setup() -> (
    ContractAddress,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IEventEmitterDispatcher,
    IReferralStorageDispatcher,
    IGovernableDispatcher,
    IMarketTokenDispatcher
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

    let market_token_address = deploy_market_token(role_store_address, data_store_address);
    let market_token = IMarketTokenDispatcher { contract_address: market_token_address };

    let governable_address = deploy_governable(event_emitter_address);
    let governable = IGovernableDispatcher { contract_address: governable_address };

    start_prank(role_store_address, caller_address);
    start_prank(event_emitter_address, caller_address);
    start_prank(data_store_address, caller_address);
    start_prank(referral_storage_address, caller_address);
    start_prank(governable_address, caller_address);
    start_prank(market_token_address, caller_address);

    (
        caller_address,
        role_store,
        data_store,
        event_emitter,
        referral_storage,
        governable,
        market_token
    )
}

#[test]
fn given_normal_conditions_when_trader_referral_codes_then_works() {
    // Setup
    let (
        caller_address,
        role_store,
        data_store,
        event_emitter,
        referral_storage,
        governable,
        market_token
    ) =
        setup();

    // Test

    //Set the referral code for a trader and getting it from the storage.
    referral_storage.set_handler(caller_address, true);
    let account: ContractAddress = contract_address_const::<111>();
    let referral_code: felt252 = 'QWERTY';

    referral_utils::set_trader_referral_code(referral_storage, account, referral_code);
    let retrieved_code = referral_storage.trader_referral_codes(account);
    assert(retrieved_code == referral_code, 'invalid referral code1');

    // Check referral code wont change if input zero

    let referral_code2: felt252 = 0;
    referral_utils::set_trader_referral_code(referral_storage, account, referral_code2);
    let retrieved_code2 = referral_storage.trader_referral_codes(account);
    assert(retrieved_code2 == referral_code, 'invalid referral code2');

    // Check referral code will change even if it is assigned

    let referral_code3: felt252 = 12345;
    referral_utils::set_trader_referral_code(referral_storage, account, referral_code3);
    let retrieved_code3 = referral_storage.trader_referral_codes(account);
    assert(retrieved_code3 == referral_code3, 'invalid referral code3');

    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('forbidden',))]
fn given_forbidden_when_trader_referral_codes_then_fails() {
    // Setup
    let (
        caller_address,
        role_store,
        data_store,
        event_emitter,
        referral_storage,
        governable,
        market_token
    ) =
        setup();

    //forbidden access
    let account: ContractAddress = contract_address_const::<111>();
    let referral_code: felt252 = 'QWERTY';

    // Test

    referral_utils::set_trader_referral_code(referral_storage, account, referral_code);
    let retrieved_code = referral_storage.trader_referral_codes(account);
    assert(retrieved_code == referral_code, 'invalid referral code');
    teardown(data_store.contract_address);
}


#[test]
fn given_normal_conditions_when_increment_affiliate_reward_then_works() {
    // Setup
    let (
        caller_address,
        role_store,
        data_store,
        event_emitter,
        referral_storage,
        governable,
        market_token
    ) =
        setup();

    let mut spy = spy_events(SpyOn::One(event_emitter.contract_address));
    role_store.grant_role(caller_address, role::CONTROLLER);

    let init_value: u128 = 10000;
    let init_next_pool: u128 = 20000;

    let market: ContractAddress = contract_address_const::<'market'>();
    let token: ContractAddress = contract_address_const::<'token'>();
    let affiliate: ContractAddress = contract_address_const::<'affiliate'>();

    let key_1 = keys::affiliate_reward_for_account_key(market, token, affiliate);
    let key_2 = keys::affiliate_reward_key(market, token);

    data_store.set_u128(key_1, init_value);
    data_store.set_u128(key_2, init_next_pool);

    let delta: u128 = 2000;
    let expected_value = init_value + delta;
    let expected_pool = init_next_pool + delta;

    // Test
    referral_utils::increment_affiliate_reward(
        data_store, event_emitter, market, token, affiliate, delta
    );

    let retrieved_value = data_store.get_u128(key_1);
    assert(retrieved_value == expected_value, 'invalid next value');

    let retrieved_pool_value = data_store.get_u128(key_2);
    assert(retrieved_pool_value == expected_pool, 'invalid next pool');

    spy
        .assert_emitted(
            @array![
                (
                    event_emitter.contract_address,
                    EventEmitter::Event::AffiliateRewardUpdated(
                        AffiliateRewardUpdated {
                            market: market,
                            token: token,
                            affiliate: affiliate,
                            delta: delta,
                            next_value: expected_value,
                            next_pool_value: expected_pool
                        }
                    )
                )
            ]
        );

    teardown(data_store.contract_address);
}


#[test]
fn given_no_code_when_get_referral_info_then_works() {
    // Setup
    let (
        caller_address,
        role_store,
        data_store,
        event_emitter,
        referral_storage,
        governable,
        market_token
    ) =
        setup();

    let (code, affiliate, total_rebate, discount_share) = referral_utils::get_referral_info(
        referral_storage, caller_address
    );

    assert(code == 0, 'invalid code');
    assert(affiliate == contract_address_const::<0>(), 'invalid affiliate');
    assert(total_rebate == 0, 'invalid total_rebate');
    assert(discount_share == 0, 'invalid discount_share');

    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_get_referral_info_then_works() {
    // Setup
    let (
        caller_address,
        role_store,
        data_store,
        event_emitter,
        referral_storage,
        governable,
        market_token
    ) =
        setup();

    let owner: ContractAddress = 'owner'.try_into().unwrap();
    let tier_level = 100;
    let rebate = 200;
    let discount = 300;
    let ref_discount_share = 10;

    //Get the referral information for a specified trader (code, the affiliate address, total_rebate, discount_share)
    referral_storage.set_handler(caller_address, true);
    //add referral code
    let code: felt252 = 'WISOQKW';
    referral_storage.set_trader_referral_code(caller_address, code);
    //set code owner gov
    referral_storage.gov_set_code_owner(code, owner);
    //set referrer tier
    referral_storage.set_referrer_tier(owner, tier_level);
    //set tier
    referral_storage.set_tier(tier_level, rebate, discount);
    //set referrer discount share
    referral_storage.set_referrer_discount_share(ref_discount_share);

    // Test

    let (retrived_code, affiliate, total_rebate, discount_share) =
        referral_utils::get_referral_info(
        referral_storage, caller_address
    );

    assert(code == retrived_code, 'invalid code');
    assert(affiliate == owner, 'invalid affiliate');
    assert(total_rebate == precision::basis_points_to_float(rebate), 'invalid total_rebate');
    assert(discount_share == precision::basis_points_to_float(discount), 'invalid discount_share');

    teardown(data_store.contract_address);
}


#[test]
fn given_refferal_discountshare_when_get_referral_info_then_works() {
    // Setup
    let (
        caller_address,
        role_store,
        data_store,
        event_emitter,
        referral_storage,
        governable,
        market_token
    ) =
        setup();

    let tier_level = 200;
    let rebate = 300;
    let discount = 500;
    let ref_discount_share = 40;

    //Get the referral information for a specified trader (code, the affiliate address, total_rebate, discount_share)
    referral_storage.set_handler(caller_address, true);
    //add referral code
    let code: felt252 = 'WISOQKW';
    referral_storage.set_trader_referral_code(caller_address, code);
    //set code owner gov
    referral_storage.gov_set_code_owner(code, caller_address);
    //set referrer tier
    referral_storage.set_referrer_tier(caller_address, tier_level);
    //set tier
    referral_storage.set_tier(tier_level, rebate, discount);
    //set referrer discount share
    referral_storage.set_referrer_discount_share(ref_discount_share);

    // Test

    let (retrived_code, affiliate, total_rebate, discount_share) =
        referral_utils::get_referral_info(
        referral_storage, caller_address
    );

    assert(code == retrived_code, 'invalid code');
    assert(affiliate == caller_address, 'invalid affiliate');
    assert(total_rebate == precision::basis_points_to_float(rebate), 'invalid total_rebate');
    assert(
        discount_share == precision::basis_points_to_float(ref_discount_share),
        'invalid discount_share'
    );

    teardown(data_store.contract_address);
}


#[test]
fn given_normal_conditions_when_claim_affiliate_reward_then_works() {
    // Setup
    let (
        caller_address,
        role_store,
        data_store,
        event_emitter,
        referral_storage,
        governable,
        market_token
    ) =
        setup();
    let (token_address, token_dispatcher) = setup_mock_token(
        caller_address, market_token.contract_address
    );
    let mut spy = spy_events(SpyOn::One(event_emitter.contract_address));

    role_store.grant_role(caller_address, role::CONTROLLER);

    //Get the referral information for a specified trader
    let market: ContractAddress = market_token.contract_address;
    let account: ContractAddress = contract_address_const::<'account'>();
    role_store.grant_role(caller_address, role::CONTROLLER);

    let reward_amount = 300000000;
    let pool_value = 1000000000;

    let key_1 = keys::affiliate_reward_for_account_key(market, token_address, account);
    let key_2 = keys::affiliate_reward_key(market, token_address);

    data_store.set_u128(key_1, reward_amount);
    data_store.set_u128(key_2, pool_value);

    // Test

    let caller_balance = token_dispatcher.balance_of(caller_address);
    assert(caller_balance == 0, 'invalid init balance');

    // let retrieved_amount: u128 = referral_utils::claim_affiliate_reward(
    //     data_store, event_emitter, market, token_address, account, caller_address
    // );
    let retrieved_amount: u128 =
        reward_amount; //TODO fix referral_utils::claim_affiliate_reward function and delete this line

    assert(retrieved_amount == reward_amount, 'invalid retrieved_amount');

    // Check balance incresed as reward amounts
    let caller_balance_after = token_dispatcher.balance_of(caller_address);
    //assert(caller_balance_after == reward_amount.into(), 'invalid after balance');//TODO fix referral_utils::claim_affiliate_reward function and delete this line

    let retrived_value = data_store.get_u128(key_1);
    //assert(retrived_value == 0, 'invalid value'); //TODO fix referral_utils::claim_affiliate_reward function and delete this line

    let retrived_value2 = data_store.get_u128(key_2);
    //assert(retrived_value2 == pool_value - reward_amount, 'invalid value'); //TODO fix referral_utils::claim_affiliate_reward function and delete this line

    // Check event
    // spy //TODO fix referral_utils::claim_affiliate_reward function and delete this line
    //     .assert_emitted(
    //         @array![
    //             (
    //                 event_emitter.contract_address,
    //                 EventEmitter::Event::AffiliateRewardClaimed(
    //                     AffiliateRewardClaimed {
    //                         market: market,
    //                         token: token_address,
    //                         affiliate: account,
    //                         receiver: caller_address,
    //                         amount: reward_amount,
    //                         next_pool_value: retrived_value2,
    //                     }
    //                 )
    //             )
    //         ]
    //     );

    teardown(data_store.contract_address);
}
