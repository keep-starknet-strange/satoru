//! Test file for `src/deposit/deposit_vault.cairo`.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.

use result::ResultTrait;
use traits::{TryInto, Into};
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
    ClassHash,
};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};


// Local imports.
use satoru::deposit::deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;

/// TODO: Implement actual test and change the name of this function.
// #[test]
// fn init_deposit_vault_test() {
//     // *********************************************************************************************
//     // *                              SETUP                                                        *
//     // *********************************************************************************************

//     let (caller_address, deposit_vault, role_store, data_store) = setup();
//     // *********************************************************************************************
//     // *                              TEST LOGIC                                                   *
//     // *********************************************************************************************

//     // Empty test for now.

//     // *********************************************************************************************
//     // *                              TEARDOWN                                                     *
//     // *********************************************************************************************
//     teardown(data_store, deposit_vault);
// }

/// Utility function to setup the test environment.
fn setup() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress, // Interface to interact with the `DepositVault` contract.
    IDepositVaultDispatcher, // Interface to interact with the `RoleStore` contract.
    IRoleStoreDispatcher, // Interface to interact with the `DataStore` contract.
    IDataStoreDispatcher,
) {
    // Setup the contracts.
    let (caller_address, deposit_vault, role_store, data_store) = setup_contracts();
    // Grant roles and prank the caller address.
    grant_roles_and_prank(caller_address, deposit_vault, role_store, data_store);
    // Return the caller address and the contract interfaces.
    (caller_address, deposit_vault, role_store, data_store)
}

// Utility function to grant roles and prank the caller address.
/// Grants roles and pranks the caller address.
///
/// # Arguments
///
/// * `caller_address` - The address of the caller.
/// * `deposit_vault` - The interface to interact with the `DepositVault` contract.
/// * `role_store` - The interface to interact with the `RoleStore` contract.
/// * `data_store` - The interface to interact with the `DataStore` contract.
fn grant_roles_and_prank(
    caller_address: ContractAddress,
    deposit_vault: IDepositVaultDispatcher,
    role_store: IRoleStoreDispatcher,
    data_store: IDataStoreDispatcher,
) {
    start_prank(role_store.contract_address, caller_address);

    // Grant the caller the `CONTROLLER` role.
    role_store.grant_role(caller_address, role::CONTROLLER);

    // Prank the caller address for calls to `DataStore` contract.
    // We need this so that the caller has the CONTROLLER role.
    start_prank(data_store.contract_address, caller_address);

    // Start pranking the `DepositVault` contract. This is necessary to mock the behavior of the contract
    // for testing purposes.
    start_prank(deposit_vault.contract_address, caller_address);
}

/// Utility function to teardown the test environment.
fn teardown(data_store: IDataStoreDispatcher, deposit_vault: IDepositVaultDispatcher) {
    stop_prank(data_store.contract_address);
    stop_prank(deposit_vault.contract_address);
}

/// Setup required contracts.
fn setup_contracts() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress, // Interface to interact with the `DepositVault` contract.
    IDepositVaultDispatcher, // Interface to interact with the `RoleStore` contract.
    IRoleStoreDispatcher, // Interface to interact with the `DataStore` contract.
    IDataStoreDispatcher,
) {
    let caller_address = 0x101.try_into().unwrap();
    // Deploy the role store contract.
    let role_store_address = deploy_role_store();

    // Create a role store dispatcher.
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let data_store_address = deploy_data_store(role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    // Deploy the `DepositVault` contract.
    let deposit_vault_address = deploy_deposit_vault(role_store_address, data_store_address);
    // Create a safe dispatcher to interact with the contract.
    let deposit_vault = IDepositVaultDispatcher { contract_address: deposit_vault_address };

    // Return the caller address and the contract interfaces.
    (caller_address, deposit_vault, role_store, data_store)
}


/// Utility function to deploy a `DepositVault` contract and return its address.
fn deploy_deposit_vault(
    role_store_address: ContractAddress, data_store_address: ContractAddress,
) -> ContractAddress {
    let contract = declare('DepositVault');
    let mut constructor_calldata = array![];
    constructor_calldata.append(role_store_address.into());
    contract.deploy(@constructor_calldata).unwrap()
}


/// Utility function to deploy a data store contract and return its address.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let mut constructor_calldata = array![];
    constructor_calldata.append(role_store_address.into());
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a data store contract and return its address.
/// Copied from `tests/role/test_role_store.rs`.
/// TODO: Find a way to share this code.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@ArrayTrait::new()).unwrap()
}
