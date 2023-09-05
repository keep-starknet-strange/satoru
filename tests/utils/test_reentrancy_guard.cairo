use result::ResultTrait;
use traits::TryInto;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use snforge_std::{declare, start_prank, ContractClassTrait};

use satoru::role::role::CONTROLLER;
use satoru::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::utils::global_reentrancy_guard::{non_reentrant_before, non_reentrant_after};

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
    let mut constructor_calldata = array![];
    constructor_calldata.append(role_store_address.into());
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a role store contract and return its address.
///
/// # Returns
///
/// * `ContractAddress` - The address of the deployed role store contract.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let constructor_arguments: @Array::<felt252> = @ArrayTrait::new();
    contract.deploy(constructor_arguments).unwrap()
}

/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreSafeDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
fn setup() -> (ContractAddress, IRoleStoreSafeDispatcher, IDataStoreDispatcher) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreSafeDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, CONTROLLER).unwrap();
    start_prank(data_store_address, caller_address);
    (caller_address, role_store, data_store)
}

#[test]
fn test_reentrancy_values() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, role_store, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Gets initial value as like in contract. It will revert if we directly try to unwrap()
    let initial_value: bool = match data_store.get_bool('REENTRANCY_GUARD_STATUS') {
        Option::Some(v) => v,
        Option::None => false,
    };

    assert(!initial_value, 'Initial value wrong'); // Initial value should be false.

    non_reentrant_before(data_store); // Sets value to true

    // Gets value after non_reentrant_before call
    let entrant: bool = match data_store.get_bool('REENTRANCY_GUARD_STATUS') {
        Option::Some(v) => v,
        Option::None => false,
    }; // We don't really need to use match, unwrap() should work but however let's keep the same way.
    assert(entrant, 'Entered value wrong'); // Value should be true.

    non_reentrant_after(data_store); // This should set value false.

    // Gets final value
    let after: bool = match data_store.get_bool('REENTRANCY_GUARD_STATUS') {
        Option::Some(v) => v,
        Option::None => false,
    }; // We don't really need to use match, unwrap() should work but however let's keep the same way.
    assert(!after, 'Final value wrong');
}

#[test]
#[should_panic(expected: ('ReentrancyGuard: reentrant call',))]
fn test_reentrancy_revert() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, role_store, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    non_reentrant_before(data_store); // Sets value to true

    // Gets value after non_reentrant_before
    let entraant: bool = match data_store.get_bool('REENTRANCY_GUARD_STATUS') {
        Option::Some(v) => v,
        Option::None => false,
    };
    assert(entraant, 'Entered value wrong'); // Value should be true.

    non_reentrant_before(data_store); // This should revert, means reentrant call happened.
}
