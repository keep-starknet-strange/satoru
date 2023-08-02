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

// Utility function to deploy a data store contract and return its address.
fn deploy_role_store() -> ContractAddress {
    let class_hash = declare('RoleStore');
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @ArrayTrait::new()
    };
    deploy(prepared).unwrap()
}

#[test]
fn test_grant_role() {
    // Deploy the contract.
    let role_store_address = deploy_role_store();
    // Create a safe dispatcher to interact with the contract.
    let role_store = IRoleStoreSafeDispatcher { contract_address: role_store_address };

    let account_address: ContractAddress = contract_address_const::<1>();

    // Check that the account address does not have the admin role.
    assert(!role_store.has_role(account_address, ROLE_ADMIN).unwrap(), 'Invalid role');
    // Grant admin role to account address.
    role_store.grant_role(account_address, ROLE_ADMIN).unwrap();
    // Check that the account address has the admin role.
    assert(role_store.has_role(account_address, ROLE_ADMIN).unwrap(), 'Invalid role');
}

#[test]
fn test_revoke_role() {
    // Deploy the contract.
    let role_store_address = deploy_role_store();
    // Create a safe dispatcher to interact with the contract.
    let role_store = IRoleStoreSafeDispatcher { contract_address: role_store_address };

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant admin role to account address.
    role_store.grant_role(account_address, ROLE_ADMIN).unwrap();
    // Check that the account address has the admin role.
    assert(role_store.has_role(account_address, ROLE_ADMIN).unwrap(), 'Invalid role');
    // Revoke admin role from account address.
    role_store.revoke_role(account_address, ROLE_ADMIN).unwrap();
    // Check that the account address does not have the admin role.
    assert(!role_store.has_role(account_address, ROLE_ADMIN).unwrap(), 'Invalid role');
}
