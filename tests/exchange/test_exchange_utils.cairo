use starknet::{
    ContractAddress, get_caller_address, get_contract_address, Felt252TryIntoContractAddress, contract_address_const
};
use snforge_std::{declare, start_prank, stop_prank, start_roll, ContractClassTrait};

use satoru::data::keys;
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
use satoru::role::role;
use satoru::exchange::exchange_utils::validate_request_cancellation;

#[test]
fn test_exchange_utils() {
    // Setup
    let data_store = setup();
    let contract_address = contract_address_const::<0>();

    // Test
    let expiration_age = 5;
    data_store.set_u128(keys::request_expiration_block_age(), expiration_age);

    let created_at_block = 10;

    start_roll(contract_address, 9);
    validate_request_cancellation(data_store, created_at_block, 'SOME_REQUEST_TYPE');

    start_roll(contract_address, 10);
    validate_request_cancellation(data_store, created_at_block, 'SOME_REQUEST_TYPE');

    start_roll(contract_address, 14);
    validate_request_cancellation(data_store, created_at_block, 'SOME_REQUEST_TYPE');

    // Teardown
    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('request_not_yet_cancellable', 'SOME_REQUEST_TYPE'))]
fn test_exchange_utils_fail() {
    // Setup
    let data_store = setup();
    let contract_address = contract_address_const::<0>();

    // Test
    let expiration_age = 5;
    data_store.set_u128(keys::request_expiration_block_age(), expiration_age);

    let created_at_block = 10;

    start_roll(contract_address, 16);
    validate_request_cancellation(data_store, created_at_block, 'SOME_REQUEST_TYPE');
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

/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `IDataStoreSafeDispatcher` - The data store dispatcher.
fn setup() -> IDataStoreSafeDispatcher {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreSafeDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreSafeDispatcher { contract_address: data_store_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER).unwrap();
    start_prank(data_store_address, caller_address);
    data_store
}

/// Utility function to teardown the test environment.
///
/// # Arguments
///
/// * `data_store_address` - The address of the data store contract.
fn teardown(data_store_address: ContractAddress) {
    stop_prank(data_store_address);
}
