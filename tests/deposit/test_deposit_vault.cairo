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
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::deposit::deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::tests_lib;
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// let (caller_address, deposit_vault, role_store, data_store) = setup();

// *************************************************************************
//                          UNIT TESTS
// *************************************************************************
#[test]
#[should_panic(expected: ('already_initialized',))]
fn given_already_intialized_when_initialize_then_fails() {
    let (_, deposit_vault, role_store, data_store) = setup();
    deposit_vault.initialize(data_store.contract_address, role_store.contract_address);
    teardown(data_store, deposit_vault);
}

#[test]
fn given_normal_conditions_when_record_transfer_in_then_works() {
    let (_, deposit_vault, _, data_store) = setup();

    let token: ContractAddress = 'MyToken'.try_into().unwrap();
    let recorded_amount: u128 = deposit_vault.record_transfer_in(token);

    assert(recorded_amount == 0, 'should be 0');

    teardown(data_store, deposit_vault);
}


// *************************************************************************
//                          SETUP FUNCTIONS
// *************************************************************************

/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IDepositVaultDispatcher` - The deposit vault dispatcher.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
fn setup() -> (
    ContractAddress, IDepositVaultDispatcher, IRoleStoreDispatcher, IDataStoreDispatcher,
) {
    let (caller_address, role_store, data_store) = tests_lib::setup();

    let deposit_vault_address = deploy_deposit_vault(
        data_store.contract_address, role_store.contract_address
    );
    let deposit_vault = IDepositVaultDispatcher { contract_address: deposit_vault_address };

    start_prank(deposit_vault.contract_address, caller_address);

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


// *********************************************************************************************
// *                              TEARDOWN                                                     *
// *********************************************************************************************
fn teardown(data_store: IDataStoreDispatcher, deposit_vault: IDepositVaultDispatcher) {
    tests_lib::teardown(data_store.contract_address);
    stop_prank(deposit_vault.contract_address);
}
