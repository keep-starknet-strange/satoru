// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.

use result::ResultTrait;
use traits::{TryInto, Into};
use starknet::{ContractAddress, get_caller_address, contract_address_const, ClassHash,};
use debug::PrintTrait;
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::data::keys;
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::config::config::{IConfigDispatcher, IConfigDispatcherTrait};

#[test]
fn given_normal_conditions_when_set_bool_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, config, role_store, data_store, event_emitter) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables to be used in the test.
    let base_key_holding_address = keys::holding_address();
    let mut data = array![];
    data.append('data_1');
    data.append('data_2');
    data.append('data_3');
    let value = true;

    // Actual test case.
    config.set_bool(base_key_holding_address, data, value);

    // Perform assertions.

    // Check that the value was set correctly.
    // FIXME: #18 https://github.com/keep-starknet-strange/satoru/issues/18
    // When `data_store::set_bool` is fixed, check that the value was set correctly.

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, config);
}

#[test]
fn given_normal_conditions_when_set_address_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, config, role_store, data_store, event_emitter) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables to be used in the test.
    let base_key_holding_address = keys::holding_address();
    let mut data = array![];
    data.append('data_1');
    data.append('data_2');
    data.append('data_3');
    let value = contract_address_const::<1>();
    let data_store_entry_key = 0xad83c0e73037c4b6af8d6dff599d1103e440a8f6b62ce0208b1999ec8a115e;

    // Actual test case.
    config.set_address(base_key_holding_address, data, value);

    // Perform assertions.

    // Read the value from the data store.
    let actual_value = data_store.get_address(data_store_entry_key);
    // Check that the value was set correctly.
    assert(actual_value == value, 'wrong_value');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, config);
}

#[test]
fn given_not_allowed_key_when_set_address_then_fails() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, config, role_store, data_store, event_emitter) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables to be used in the test.
    let not_allowed_key = 'not_allowed_key';
    let mut data = array![];
    data.append('data_1');
    data.append('data_2');
    data.append('data_3');
    let value = contract_address_const::<1>();

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, config);
}

#[test]
fn given_normal_conditions_when_set_felt252_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, config, role_store, data_store, event_emitter) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables to be used in the test.
    let base_key_holding_address = keys::holding_address();
    let mut data = array![];
    data.append('data_1');
    data.append('data_2');
    data.append('data_3');
    let value = 'felt252_value';
    let data_store_entry_key = 0xad83c0e73037c4b6af8d6dff599d1103e440a8f6b62ce0208b1999ec8a115e;

    // Actual test case.
    config.set_felt252(base_key_holding_address, data, value);

    // Perform assertions.

    // Read the value from the data store.
    let actual_value = data_store.get_felt252(data_store_entry_key);
    // Check that the value was set correctly.
    assert(actual_value == value, 'wrong_value');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, config);
}

// Utility function to grant roles and prank the caller address.
/// Grants roles and pranks the caller address.
///
/// # Arguments
///
/// * `caller_address` - The address of the caller.
/// * `role_store` - The role store dispatcher.
/// * `data_store` - The data store dispatcher.
/// * `config` - The config dispatcher.
fn grant_roles_and_prank(
    caller_address: ContractAddress,
    role_store: IRoleStoreDispatcher,
    data_store: IDataStoreDispatcher,
    config: IConfigDispatcher
) {
    start_prank(role_store.contract_address, caller_address);

    // Grant the caller the CONTROLLER role. This is necessary for the caller to have the permissions
    // to perform certain actions in the tests.
    role_store.grant_role(caller_address, role::CONTROLLER);

    // Grant the caller the CONFIG_KEEPER role. This is necessary for the caller to have the permissions
    // to perform certain actions in the tests.
    role_store.grant_role(caller_address, role::CONFIG_KEEPER);

    // Start pranking the data store contract. This is necessary to mock the behavior of the contract
    // for testing purposes.
    start_prank(data_store.contract_address, caller_address);

    // Start pranking the config contract. This is necessary to mock the behavior of the contract
    // for testing purposes.
    start_prank(config.contract_address, caller_address);
}

/// Utility function to teardown the test environment.
fn teardown(data_store: IDataStoreDispatcher, config: IConfigDispatcher) {
    // Stop pranking contracts.
    stop_prank(data_store.contract_address);
    stop_prank(config.contract_address);
}

/// Utility function to setup the test environment.
fn setup() -> (
    ContractAddress,
    IConfigDispatcher,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IEventEmitterDispatcher
) {
    // Setup contracts.
    let (caller_address, config, role_store, data_store, event_emitter) = setup_contracts();
    // Grant roles and prank the caller address.
    grant_roles_and_prank(caller_address, role_store, data_store, config);
    // Return the contracts.
    return (caller_address, config, role_store, data_store, event_emitter);
}


/// Setup required contracts.
fn setup_contracts() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress,
    // Interface to interact with the `Config` contract.
    IConfigDispatcher,
    // Interface to interact with the `RoleStore` contract.
    IRoleStoreDispatcher,
    // Interface to interact with the `DataStore` contract.
    IDataStoreDispatcher,
    // Interface to interact with the `EventEmitter` contract.
    IEventEmitterDispatcher,
) {
    // Deploy the role store contract.
    let role_store_address = deploy_role_store();

    // Create a role store dispatcher.
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let data_store_address = deploy_data_store(role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    // Deploy the `EventEmitter` contract.
    let event_emitter_address = deploy_event_emitter();
    // Create a safe dispatcher to interact with the contract.
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    // Deploy the `Config` contract.
    let config_address = deploy_config(
        data_store_address, role_store_address, event_emitter_address
    );

    // Create a safe dispatcher to interact with the contract.
    let config = IConfigDispatcher { contract_address: config_address };

    (0x101.try_into().unwrap(), config, role_store, data_store, event_emitter)
}

/// Utility function to deploy a market factory contract and return its address.
fn deploy_config(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
) -> ContractAddress {
    let contract = declare('Config');
    let mut constructor_calldata = array![];
    constructor_calldata.append(role_store_address.into());
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(event_emitter_address.into());
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
    let constructor_arguments: @Array::<felt252> = @ArrayTrait::new();
    contract.deploy(constructor_arguments).unwrap()
}

/// Utility function to deploy a `EventEmitter` contract and return its address.
fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    let constructor_arguments: @Array::<felt252> = @ArrayTrait::new();
    contract.deploy(constructor_arguments).unwrap()
}
