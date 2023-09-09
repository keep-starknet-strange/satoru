use result::ResultTrait;
use traits::TryInto;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use snforge_std::{declare, start_prank, ContractClassTrait};


use satoru::role::role::ROLE_ADMIN;
use satoru::role::role_store::IRoleStoreDispatcher;
use satoru::role::role_store::IRoleStoreDispatcherTrait;

#[test]
fn test_grant_role() {
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
fn test_revoke_role() {
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

