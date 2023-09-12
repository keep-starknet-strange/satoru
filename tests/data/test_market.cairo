use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::market::market::{Market};
use debug::PrintTrait;

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
fn test_set_market_new_and_override() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let address_zero: ContractAddress = 0.try_into().unwrap();

    let key: felt252 = 123456789;
    let mut market = Market {
        market_token: address_zero,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };

    // Test logic

    // Test set_market function with a new key.
    data_store.set_market(key, market);

    let market_by_key = data_store.get_market(key).unwrap();
    assert(market_by_key == market, 'Invalid market by key');

    // Update the market using the set_market function and then retrieve it to check the update was successful
    let address_one: ContractAddress = 1.try_into().unwrap();
    market.index_token = address_one;
    data_store.set_market(key, market);

    let market_by_key = data_store.get_market(key).unwrap();
    assert(market_by_key == market, 'Invalid market by key');
    assert(market_by_key.index_token == address_one, 'Invalid market value');

    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn test_set_market_should_panic_not_market_keeper() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::MARKET_KEEPER);
    let address_zero: ContractAddress = 0.try_into().unwrap();

    let key: felt252 = 123456789;
    let mut market = Market {
        market_token: address_zero,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };

    // Test logic

    // Test set_market function without permission
    data_store.set_market(key, market);

    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn test_get_market_keys() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::CONTROLLER);
    let address_zero: ContractAddress = 0.try_into().unwrap();

    let key: felt252 = 123456789;
    let mut market = Market {
        market_token: address_zero,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };
    data_store.set_market(key, market);

    // Given
    data_store.remove_market(key);

    // Then
    let market_by_key = data_store.get_market(key);
    assert(market_by_key.is_none(), 'market should be removed');

    teardown(data_store.contract_address);
}

#[test]
fn test_remove_only_market() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let address_zero: ContractAddress = 0.try_into().unwrap();

    let key: felt252 = 123456789;
    let mut market = Market {
        market_token: address_zero,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };

    data_store.set_market(key, market);

    // Given
    data_store.remove_market(key);

    // Then
    let market_by_key = data_store.get_market(key);
    assert(market_by_key.is_none(), 'market should be removed');

    teardown(data_store.contract_address);
}

#[test]
fn test_remove_1_of_n_market() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let address_zero: ContractAddress = 0.try_into().unwrap();
    let address_one: ContractAddress = 1.try_into().unwrap();

    let key: felt252 = 123456789;
    let mut market = Market {
        market_token: address_zero,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };

    let key_2: felt252 = 987654321;
    let mut market_2 = Market {
        market_token: address_one,
        index_token: address_one,
        long_token: address_one,
        short_token: address_one,
    };

    data_store.set_market(key, market);
    data_store.set_market(key_2, market_2);

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
fn test_remove_market_should_panic_not_controller() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::CONTROLLER);
    let address_zero: ContractAddress = 0.try_into().unwrap();

    let key: felt252 = 123456789;
    let mut market = Market {
        market_token: address_zero,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    };
    data_store.set_market(key, market);

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
