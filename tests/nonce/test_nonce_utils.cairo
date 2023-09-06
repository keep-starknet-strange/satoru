use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};

use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
use satoru::role::role;
use satoru::nonce::nonce_utils::{get_current_nonce, increment_nonce, get_next_key};

#[test]
fn test_nonce_utils() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let data_store = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let nonce = get_current_nonce(data_store).unwrap();
    assert(nonce == 0, 'Invalid nonce');

    let nonce = increment_nonce(data_store).unwrap();
    assert(nonce == 1, 'Invalid new nonce');

    let key = get_next_key(data_store).unwrap();
    assert(key == 0x3f84fbc06ce0aca2f042f92dbe31a1426167c15392bba1e905ec3c3f0c177f7, 'Invalid key');

    let nonce = get_current_nonce(data_store).unwrap();
    assert(nonce == 2, 'Invalid final nonce');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
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
