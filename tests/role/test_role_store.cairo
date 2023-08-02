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
    let class_hash = declare('RoleStore').unwrap();
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @ArrayTrait::new()
    };
    let contract_address = deploy(prepared).unwrap();

    let contract_address: ContractAddress = contract_address.try_into().unwrap();

    contract_address
}

#[test]
fn test_grant_role() {
    // Deploy the contract.
    let contract_address = deploy_role_store();
    // Create a safe dispatcher to interact with the contract.
    let safe_dispatcher = IRoleStoreSafeDispatcher { contract_address };

    let account_address: ContractAddress = contract_address_const::<1>();

    // Check that the account address does not have the admin role.
    assert(!safe_dispatcher.has_role(account_address, ROLE_ADMIN).unwrap(), 'Invalid role');
    // Grant admin role to account address.
    safe_dispatcher.grant_role(account_address, ROLE_ADMIN).unwrap();
    // Check that the account address has the admin role.
    assert(safe_dispatcher.has_role(account_address, ROLE_ADMIN).unwrap(), 'Invalid role');
}

#[test]
fn test_revoke_role() {
    // Deploy the contract.
    let contract_address = deploy_role_store();
    // Create a safe dispatcher to interact with the contract.
    let safe_dispatcher = IRoleStoreSafeDispatcher { contract_address };

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant admin role to account address.
    safe_dispatcher.grant_role(account_address, ROLE_ADMIN).unwrap();
    // Check that the account address has the admin role.
    assert(safe_dispatcher.has_role(account_address, ROLE_ADMIN).unwrap(), 'Invalid role');
    // Revoke admin role from account address.
    safe_dispatcher.revoke_role(account_address, ROLE_ADMIN).unwrap();
    // Check that the account address does not have the admin role.
    assert(!safe_dispatcher.has_role(account_address, ROLE_ADMIN).unwrap(), 'Invalid role');
}
