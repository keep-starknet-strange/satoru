use result::ResultTrait;
use traits::TryInto;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use snforge_std::{declare, start_prank, ContractClassTrait};
//use array::ArrayTrait;

use satoru::role::role::ROLE_ADMIN;
use satoru::role::role::CONTROLLER;
use satoru::role::role::MARKET_KEEPER;
use satoru::role::role_store::IRoleStoreDispatcher;
use satoru::role::role_store::IRoleStoreDispatcherTrait;

#[test]
fn given_normal_conditions_when_grant_role_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let role_store = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);

    let account_address: ContractAddress = contract_address_const::<1>();

    // Check that the account address does not have the admin role.
    assert(!role_store.has_role(account_address, ROLE_ADMIN), 'Invalid role');
    // Grant admin role to account address.
    role_store.grant_role(account_address, ROLE_ADMIN);
    // Check that the account address has the admin role.
    assert(role_store.has_role(account_address, ROLE_ADMIN), 'Invalid role');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn given_normal_conditions_when_revoke_role_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let role_store = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant admin role to account address.
    role_store.grant_role(account_address, ROLE_ADMIN);
    // Check that the account address has the admin role.
    assert(role_store.has_role(account_address, ROLE_ADMIN), 'Invalid role');
    // Revoke admin role from account address.
    role_store.revoke_role(account_address, ROLE_ADMIN);
    // Check that the account address does not have the admin role.
    assert(!role_store.has_role(account_address, ROLE_ADMIN), 'Invalid role');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn test_get_role_count() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let role_store = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);

    let account_address: ContractAddress = contract_address_const::<1>();

    // Here, we will test the role count. Initially, it should be 1.
    assert(role_store.get_role_count() == 1, 'Initial role count should be 1');

    // Grant CONTROLLER role to account address.
    role_store.grant_role(account_address, CONTROLLER);
    // After granting the role CONTROLLER, the count should be 2.
    assert(role_store.get_role_count() == 2, 'Role count should be 2');
    // Grant MARKET_KEEPER role to account address.
    role_store.grant_role(account_address, MARKET_KEEPER);
    // After granting the role MARKET_KEEPER, the count should be 3. 
    assert(role_store.get_role_count() == 3, 'Role count should be 3');

    // The ROLE_ADMIN role is already assigned, let's try to reassign it to see if duplicates are managed.
    // Grant ROLE_ADMIN role to account address.
    role_store.grant_role(account_address, ROLE_ADMIN);
    // Duplicates, the count should be 3.
    assert(role_store.get_role_count() == 3, 'Role count should be 3');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

//#[test]
//fn test_get_roles() {
// *********************************************************************************************
// *                              SETUP                                                        *
// *********************************************************************************************
//let role_store = setup();

// *********************************************************************************************
// *                              TEST LOGIC                                                   *
// *********************************************************************************************

// Use the address that has been used to deploy role_store.
//let caller_address: ContractAddress = 0x101.try_into().unwrap();
//start_prank(role_store.contract_address, caller_address);

//let account_address: ContractAddress = contract_address_const::<1>();

// Grant CONTROLLER role to account address.
//role_store.grant_role(account_address, CONTROLLER);

// Grant MARKET_KEEPER role to account address.
//role_store.grant_role(account_address, MARKET_KEEPER);

// Get roles from index 0 to 2 (should return ROLE_ADMIN and CONTROLLER).
//let roles_0_to_2 = role_store.get_roles(0, 2);
//let first_role = roles_0_to_2.at(0);
//let second_role = roles_0_to_2.at(1);
//assert(*first_role == ROLE_ADMIN, '1 should be ROLE_ADMIN');
//assert(*second_role == CONTROLLER, '2 should be CONTROLLER');

// Get roles from index 1 to 3 (should return CONTROLLER and MARKET_KEEPER).
//let roles_1_to_3 = role_store.get_roles(1, 3);
//let first_role = roles_1_to_3.at(0);
//let second_role = roles_1_to_3.at(1);
//assert(*first_role == CONTROLLER, '3 should be CONTROLLER');
//assert(*second_role == MARKET_KEEPER, '4 should be MARKET_KEEPER');

// *********************************************************************************************
// *                              TEARDOWN                                                     *
// *********************************************************************************************
//teardown();
//}

/// Utility function to setup the test environment.
fn setup() -> IRoleStoreDispatcher {
    IRoleStoreDispatcher { contract_address: deploy_role_store() }
}

/// Utility function to teardown the test environment.
fn teardown() {}

// Utility function to deploy a role store contract and return its address.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@ArrayTrait::new()).unwrap()
}

