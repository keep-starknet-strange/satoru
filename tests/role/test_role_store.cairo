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
fn given_normal_conditions_when_has_role_after_grant_then_works() {
    let role_store = setup();

    // Use the address that has been used to deploy role_store.
    start_prank(role_store.contract_address, admin());

    // Check that the account address does not have the admin role.
    assert(!role_store.has_role(account_1(), ROLE_ADMIN), 'Invalid role');
    // Grant admin role to account address.
    role_store.grant_role(account_1(), ROLE_ADMIN);
    // Check that the account address has the admin role.
    assert(role_store.has_role(account_1(), ROLE_ADMIN), 'Invalid role');
}

#[test]
fn given_normal_conditions_when_has_role_after_revoke_then_works() {
    let role_store = setup();

    // Use the address that has been used to deploy role_store.
    start_prank(role_store.contract_address, admin());

    // Grant admin role to account address.
    role_store.grant_role(account_1(), ROLE_ADMIN);
    // Check that the account address has the admin role.
    assert(role_store.has_role(account_1(), ROLE_ADMIN), 'Invalid role');
    // Revoke admin role from account address.
    role_store.revoke_role(account_1(), ROLE_ADMIN);
    // Check that the account address does not have the admin role.
    assert(!role_store.has_role(account_1(), ROLE_ADMIN), 'Invalid role');
}
#[test]
#[should_panic]
fn given_normal_conditions_when_revoke_role_on_1_ROLE_ADMIN_panics() {
    let role_store = setup();

    // Use the address that has been used to deploy role_store.
    start_prank(role_store.contract_address, admin());
    // assert that there is only one role ROLE_ADMIN present
    assert(role_store.get_role_member_count(ROLE_ADMIN) == 1, 'members count != 1');

   
    // Check that the account address has the admin role.
    assert(role_store.has_role(admin(), ROLE_ADMIN), 'Invalid role');
    // Revoke role_admin should panic.
    role_store.revoke_role(admin(), ROLE_ADMIN);
    
    
}


#[test]
fn given_normal_conditions_when_get_role_count_then_works() {
    let role_store = setup();

    // Use the address that has been used to deploy role_store.
    start_prank(role_store.contract_address, admin());

    // Here, we will test the role count. Initially, it should be 1.
    assert(role_store.get_role_count() == 1, 'Initial role count should be 1');

    // Grant CONTROLLER role to account address.
    role_store.grant_role(account_1(), CONTROLLER);
    // After granting the role CONTROLLER, the count should be 2.
    assert(role_store.get_role_count() == 2, 'Role count should be 2');
    // Grant MARKET_KEEPER role to account address.
    role_store.grant_role(account_1(), MARKET_KEEPER);
    // After granting the role MARKET_KEEPER, the count should be 3. 
    assert(role_store.get_role_count() == 3, 'Role count should be 3');

    // The ROLE_ADMIN role is already assigned, let's try to reassign it to see if duplicates are managed.
    // Grant ROLE_ADMIN role to account address.
    role_store.grant_role(account_1(), ROLE_ADMIN);
    // Duplicates, the count should be 3.
    assert(role_store.get_role_count() == 3, 'Role count should be 3');

    // Revoke a MARKET_KEEPER role, since the role has now no members the roles count
    // is decreased.
    role_store.revoke_role(account_1(), MARKET_KEEPER);
    assert(role_store.get_role_count() == 2, 'Role count should be 2');
}

#[test]
fn given_normal_conditions_when_get_roles_then_works() {
    let role_store = setup();

    // Use the address that has been used to deploy role_store.
    start_prank(role_store.contract_address, admin());

    // Grant CONTROLLER role to account address.
    role_store.grant_role(account_1(), CONTROLLER);

    // Grant MARKET_KEEPER role to account address.
    role_store.grant_role(account_1(), MARKET_KEEPER);

    // Get roles from index 1 to 2 (should return ROLE_ADMIN and CONTROLLER).
    // Note: Starknet's storage starts at 1, for this reason storage index 0 will
    // always be empty.
    let roles_0_to_2 = role_store.get_roles(1, 2);
    let first_role = roles_0_to_2.at(0);
    let second_role = roles_0_to_2.at(1);
    assert(*first_role == ROLE_ADMIN, '1 should be ROLE_ADMIN');
    assert(*second_role == CONTROLLER, '2 should be CONTROLLER');

    // Get roles from index 2 to 3 (should return CONTROLLER and MARKET_KEEPER).
    let roles_1_to_3 = role_store.get_roles(2, 3);
    let first_role = roles_1_to_3.at(0);
    let second_role = roles_1_to_3.at(1);
    assert(*first_role == CONTROLLER, '3 should be CONTROLLER');
    assert(*second_role == MARKET_KEEPER, '4 should be MARKET_KEEPER');
}

#[test]
fn given_normal_conditions_when_get_role_member_count_then_works() {
    let role_store = setup();

    // Use the address that has been used to deploy role_store.
    start_prank(role_store.contract_address, admin());
    // Grant CONTROLLER role to account address.
    role_store.grant_role(account_1(), CONTROLLER);
    role_store.grant_role(account_2(), CONTROLLER);
    role_store.grant_role(account_3(), CONTROLLER);

    assert(role_store.get_role_member_count(CONTROLLER) == 3, 'members count != 3');

    role_store.revoke_role(account_3(), CONTROLLER);
    assert(role_store.get_role_member_count(CONTROLLER) == 2, 'members count != 2');

    role_store.revoke_role(account_2(), CONTROLLER);
    assert(role_store.get_role_member_count(CONTROLLER) == 1, 'members count != 1');
}

#[test]
fn given_normal_conditions_when_get_role_members_then_works() {
    let role_store = setup();

    // Use the address that has been used to deploy role_store.
    start_prank(role_store.contract_address, admin());
    // Grant CONTROLLER role to accounts.
    role_store.grant_role(account_1(), CONTROLLER);
    role_store.grant_role(account_2(), CONTROLLER);
    role_store.grant_role(account_3(), CONTROLLER);

    let members = role_store.get_role_members(CONTROLLER, 1, 3);
    assert(*members.at(0) == account_1(), 'should be acc_1');
    assert(*members.at(1) == account_2(), 'should be acc_2');
    assert(*members.at(2) == account_3(), 'should be acc_3');

    role_store.revoke_role(account_2(), CONTROLLER);
    let members = role_store.get_role_members(CONTROLLER, 1, 2);
    assert(*members.at(0) == account_1(), 'should be acc_1');
    assert(*members.at(1) == account_3(), 'should be acc_3');

    role_store.revoke_role(account_1(), CONTROLLER);
    let members = role_store.get_role_members(CONTROLLER, 1, 2);
    assert(*members.at(0) == account_3(), 'should be acc_3');
}

fn admin() -> ContractAddress {
    contract_address_const::<0x101>()
}

fn account_1() -> ContractAddress {
    contract_address_const::<1>()
}

fn account_2() -> ContractAddress {
    contract_address_const::<2>()
}

fn account_3() -> ContractAddress {
    contract_address_const::<3>()
}

/// Utility function to setup the test environment.
fn setup() -> IRoleStoreDispatcher {
    IRoleStoreDispatcher { contract_address: deploy_role_store() }
}

// Utility function to deploy a role store contract and return its address.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@ArrayTrait::new()).unwrap()
}

