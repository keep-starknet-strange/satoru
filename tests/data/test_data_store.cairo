use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use starknet::{ContractAddress, get_caller_address, Felt252TryIntoContractAddress};
use cheatcodes::PreparedContract;

use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
use gojo::role::role;

/// Utility function to deploy a data store contract and return its address.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let class_hash = declare('DataStore').unwrap();
    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append(role_store_address.into());
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @constructor_calldata
    };
    let contract_address = deploy(prepared).unwrap();

    let contract_address: ContractAddress = contract_address.try_into().unwrap();

    contract_address
}

/// Utility function to deploy a data store contract and return its address.
/// Copied from `tests/role/test_role_store.rs`.
/// TODO: Find a way to share this code.
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
fn test_get_and_set_felt252() {
    // TODO: Find a way to get the caller address programmatically.
    let caller_address: ContractAddress = 257.try_into().unwrap();

    // Deploy the role store contract.
    let role_store_address = deploy_role_store();
    // Create a role store dispatcher.
    let role_store_dispatcher = IRoleStoreSafeDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let contract_address = deploy_data_store(role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let safe_dispatcher = IDataStoreSafeDispatcher { contract_address };
    // Grant the caller the CONTROLLER role.
    role_store_dispatcher.grant_role(caller_address, role::CONTROLLER).unwrap();
    // Set key 1 to value 42.
    safe_dispatcher.set_felt252(1, 42).unwrap();
    let value = safe_dispatcher.get_felt252(1).unwrap();
    // Check that the value read is 42.
    assert(value == 42, 'Invalid value');
}

#[test]
fn test_get_and_set_u256() {
    // TODO: Find a way to get the caller address programmatically.
    let caller_address: ContractAddress = 257.try_into().unwrap();

    // Deploy the role store contract.
    let role_store_address = deploy_role_store();
    // Create a role store dispatcher.
    let role_store_dispatcher = IRoleStoreSafeDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let contract_address = deploy_data_store(role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let safe_dispatcher = IDataStoreSafeDispatcher { contract_address };
    // Grant the caller the CONTROLLER role.
    // TODO: For some reason, this fails with the following error:
    // `Failure reason: \"RoleStore: missing role\"`
    // Commenting out for now.
    // role_store_dispatcher.grant_role(caller_address, role::CONTROLLER).unwrap();

    // Set key 1 to value 42.
    safe_dispatcher.set_u256(1, 42).unwrap();
    let value = safe_dispatcher.get_u256(1).unwrap();
    // Check that the value read is 42.
    assert(value == 42, 'Invalid value');
}

