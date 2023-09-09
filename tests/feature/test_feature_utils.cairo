use result::ResultTrait;
use traits::{TryInto, Into};
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use debug::PrintTrait;
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::feature::feature_utils::{is_feature_disabled, validate_feature};

#[test]
fn test_nonexist_feature() {
    let (caller_address, role_store, data_store) = setup();

    let nonexist_feature = is_feature_disabled(
        data_store, 'NONEXIST_FEATURE'
    ); // Returns false because feature does not exist so cannot be disabled.
    assert(!nonexist_feature, 'Nonexist feature wrong');
}

#[test]
fn test_exist_disable_feature() {
    let (caller_address, role_store, data_store) = setup();

    data_store.set_bool('EXIST_FEATURE', true);

    let exist_feature = is_feature_disabled(
        data_store, 'EXIST_FEATURE'
    ); // Returns true because feature is disabled
    assert(exist_feature, 'Exist feature wrong');
}

#[test]
fn test_nonexist_feature_validate() {
    let (caller_address, role_store, data_store) = setup();

    validate_feature(
        data_store, 'NONEXIST_FEATURE'
    ); // Should not revert because feature does not exist
}

#[test]
#[should_panic(expected: ('FeatureUtils: disabled feature',))]
fn test_exist_feature_validate() {
    let (caller_address, role_store, data_store) = setup();

    data_store.set_bool('EXIST_FEATURE', true);

    validate_feature(data_store, 'EXIST_FEATURE'); // Should revert because feature is disabled
}

#[test]
fn test_exist_enabled_feature_validate() {
    let (caller_address, role_store, data_store) = setup();

    data_store.set_bool('EXIST_FEATURE', false);

    validate_feature(data_store, 'EXIST_FEATURE'); // Should work because feature is enabled
}

/// Utility function to deploy a data store contract and return its address.
///
/// # Arguments
///
/// * `role_store_address` - The address of the role store contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the deployed data store contract.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let mut constructor_calldata = array![];
    constructor_calldata.append(role_store_address.into());
    contract.deploy(@constructor_calldata)
}

/// Utility function to deploy a role store contract and return its address.
///
/// # Returns
///
/// * `ContractAddress` - The address of the deployed role store contract.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let constructor_arguments: @Array::<felt252> = @ArrayTrait::new();
    contract.deploy(constructor_arguments)
}

/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
fn setup() -> (ContractAddress, IRoleStoreDispatcher, IDataStoreDispatcher) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    (caller_address, role_store, data_store)
}
