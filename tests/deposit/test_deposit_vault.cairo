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
use satoru::tests_lib;

#[test]
fn initialize_deposit_vault_test() {
    let (caller_address, deposit_vault, role_store, data_store) = setup();
    tests_lib::teardown(data_store.contract_address);
}


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IDepositVaultDispatcher` - The deposit vault dispatcher.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
fn setup() -> (
    ContractAddress,
    IDepositVaultDispatcher,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
) {
    // Setup the contracts.
    let (caller_address, role_store, data_store) = tests_lib::setup();

    let deposit_vault_address = deploy_deposit_vault(
        data_store.contract_address, role_store.contract_address
    );
    let deposit_vault = IDepositVaultDispatcher {
        contract_address: deposit_vault_address
    };

    // Grant roles and prank the caller address.
    start_prank(deposit_vault.contract_address, caller_address);
    // Return the caller address and the contract interfaces.
    (caller_address, deposit_vault, role_store, data_store)
}

/// Utility function to deploy a deposit vault.
/// # Arguments
///
/// * `data_store_address` - The address of the data store contract.
/// * `role_store_address` - The address of the role store contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the deposit vault.
fn deploy_deposit_vault(
    data_store_address: ContractAddress, role_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('DepositVault');
    contract.deploy(@array![data_store_address.into(), role_store_address.into()]).unwrap()
}
