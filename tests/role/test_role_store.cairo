use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use cheatcodes::PreparedContract;

use gojo::role::role::ROLE_ADMIN;
use gojo::role::role_store::IRoleStoreSafeDispatcher;
use gojo::role::role_store::IRoleStoreSafeDispatcherTrait;

#[test]
fn test_grant_role() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let role_store = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let account_address: ContractAddress = contract_address_const::<1>();

    // Check that the account address does not have the admin role.
    assert(!role_store.has_role(account_address, ROLE_ADMIN).unwrap(), 'Invalid role');
    // Grant admin role to account address.
    role_store.grant_role(account_address, ROLE_ADMIN).unwrap();
    // Check that the account address has the admin role.
    assert(role_store.has_role(account_address, ROLE_ADMIN).unwrap(), 'Invalid role');

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

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant admin role to account address.
    role_store.grant_role(account_address, ROLE_ADMIN).unwrap();
    // Check that the account address has the admin role.
    assert(role_store.has_role(account_address, ROLE_ADMIN).unwrap(), 'Invalid role');
    // Revoke admin role from account address.
    role_store.revoke_role(account_address, ROLE_ADMIN).unwrap();
    // Check that the account address does not have the admin role.
    assert(!role_store.has_role(account_address, ROLE_ADMIN).unwrap(), 'Invalid role');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

/// Utility function to setup the test environment.
fn setup() -> IRoleStoreSafeDispatcher {
    IRoleStoreSafeDispatcher { contract_address: deploy_role_store() }
}

/// Utility function to teardown the test environment.
fn teardown() {}

// Utility function to deploy a data store contract and return its address.
fn deploy_role_store() -> ContractAddress {
    let class_hash = declare('RoleStore');
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @array![] };
    deploy(prepared).unwrap()
}
