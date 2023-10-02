use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};
use poseidon::poseidon_hash_span;
use debug::PrintTrait;

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::market::market::{Market};


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
fn setup() -> (ContractAddress, IRoleStoreDispatcher, IDataStoreDispatcher) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);
    role_store.grant_role(caller_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    (caller_address, role_store, data_store)
}

/// Utility function to deploy a data store contract and return its address.
///
/// # Arguments
///
/// * `role_store_address` - The address of the role store contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the deployed data store contract.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a role store contract and return its address.
///
/// # Returns
///
/// * `ContractAddress` - The address of the deployed role store contract.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@array![]).unwrap()
}

#[test]
fn given_normal_conditions_when_set_market_new_and_override_then_works() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let address_zero = contract_address_const::<0>();

    let key = contract_address_const::<123456789>();
    let mut market = Market {
        market_token: key,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };

    // Test logic

    // Test set_market function with a new key.
    data_store.set_market(key, 0, market);

    let market_by_key = data_store.get_market(key).unwrap();
    assert(market_by_key == market, 'Invalid market by key');

    // Update the market using the set_market function and then retrieve it to check the update was successful
    let address_one: ContractAddress = 1.try_into().unwrap();
    market.index_token = address_one;
    data_store.set_market(key, 0, market);

    let market_by_key = data_store.get_market(key).unwrap();
    assert(market_by_key == market, 'Invalid market by key');
    assert(market_by_key.index_token == address_one, 'Invalid market value');

    teardown(data_store.contract_address);
}

fn given_normal_conditions_when_set_market_and_get_by_salt_then_works() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let address_zero = contract_address_const::<0>();

    let key = contract_address_const::<123456789>();
    let mut market = Market {
        market_token: key,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };

    let salt = poseidon_hash_span(array!['SATORU_MARKET', 0, 0, 0, 0].span());

    // Test logic

    // Test set_market function with a new key.
    data_store.set_market(key, salt, market);

    let market_by_key = data_store.get_by_salt_market(salt).unwrap();
    assert(market_by_key == market, 'Invalid market by key');

    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_not_market_keeper_when_set_market_then_fails() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::MARKET_KEEPER);
    let address_zero = contract_address_const::<0>();

    let key = contract_address_const::<123456789>();
    let mut market = Market {
        market_token: key,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };

    // Test logic

    // Test set_market function without permission
    data_store.set_market(key, 0, market);

    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_get_market_keys_then_works() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let address_zero = contract_address_const::<0>();

    let key = contract_address_const::<123456789>();
    let mut market = Market {
        market_token: key,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };

    let key_2: ContractAddress = 987654321.try_into().unwrap();
    let mut market_2 = Market {
        market_token: key_2,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };

    data_store.set_market(key, 0, market);
    data_store.set_market(key_2, 1, market_2);

    // Then
    let market_keys = data_store.get_market_keys(0, 2);
    assert(*market_keys.at(0) == key, 'market should be removed');
    assert(*market_keys.at(1) == key_2, 'market should be removed');

    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_remove_only_one_market_then_works() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let address_zero = contract_address_const::<0>();

    let key = contract_address_const::<123456789>();
    let mut market = Market {
        market_token: key,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };

    data_store.set_market(key, 0, market);

    // Given
    data_store.remove_market(key);

    // Then
    let market_by_key = data_store.get_market(key);
    assert(market_by_key.is_none(), 'market should be removed');

    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_remove_1_of_n_market_then_works() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let address_zero = contract_address_const::<0>();
    let address_one: ContractAddress = 1.try_into().unwrap();

    let key = contract_address_const::<123456789>();
    let mut market = Market {
        market_token: key,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };

    let key_2: ContractAddress = 987654321.try_into().unwrap();
    let mut market_2 = Market {
        market_token: key_2,
        index_token: address_one,
        long_token: address_one,
        short_token: address_one,
    };

    data_store.set_market(key, 0, market);
    data_store.set_market(key_2, 0, market_2);

    // Given
    data_store.remove_market(key);

    // Then
    let market_by_key = data_store.get_market(key);
    assert(market_by_key.is_none(), 'market1 shouldnt be removed');

    let market_2_by_key = data_store.get_market(key_2);
    assert(market_2_by_key.is_some(), 'market2 shouldnt be removed');

    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_caller_not_market_keeper_when_remove_market_then_fails() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::MARKET_KEEPER);
    let address_zero = contract_address_const::<0>();

    let key = contract_address_const::<123456789>();
    let mut market = Market {
        market_token: key,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };

    data_store.set_market(key, 0, market);

    // Given
    data_store.remove_market(key);

    // Then
    teardown(data_store.contract_address);
}


/// Utility function to teardown the test environment.
///
/// # Arguments
///
/// * `data_store_address` - The address of the data store contract.
fn teardown(data_store_address: ContractAddress) {
    stop_prank(data_store_address);
}
