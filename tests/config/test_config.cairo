// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use starknet::{ContractAddress, get_caller_address, contract_address_const, ClassHash, };
use cheatcodes::PreparedContract;
use debug::PrintTrait;

// Local imports.
use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::data::keys;
use gojo::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
use gojo::role::role;
use gojo::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use gojo::config::config::{IConfigSafeDispatcher, IConfigSafeDispatcherTrait};

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
    config.set_bool(base_key_holding_address, data, value).unwrap();

    // Perform assertions.

    // Check that the value was set correctly.
    // FIXME: #18 https://github.com/keep-starknet-strange/gojo/issues/18
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
    config.set_address(base_key_holding_address, data, value).unwrap();

    // Perform assertions.

    // Read the value from the data store.
    let actual_value = data_store.get_address(data_store_entry_key).unwrap();
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

    // Actual test case.
    match config.set_address(not_allowed_key, data, value) {
        Result::Ok(_) => panic_with_felt252('should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'invalid_base_key', *panic_data.at(0));
        }
    }

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
    config.set_felt252(base_key_holding_address, data, value).unwrap();

    // Perform assertions.

    // Read the value from the data store.
    let actual_value = data_store.get_felt252(data_store_entry_key).unwrap();
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
    role_store: IRoleStoreSafeDispatcher,
    data_store: IDataStoreSafeDispatcher,
    config: IConfigSafeDispatcher
) {
    // Grant the caller the CONTROLLER role. This is necessary for the caller to have the permissions
    // to perform certain actions in the tests.
    role_store.grant_role(caller_address, role::CONTROLLER).unwrap();

    // Grant the caller the CONFIG_KEEPER role. This is necessary for the caller to have the permissions
    // to perform certain actions in the tests.
    role_store.grant_role(caller_address, role::CONFIG_KEEPER).unwrap();

    // Start pranking the data store contract. This is necessary to mock the behavior of the contract
    // for testing purposes.
    start_prank(data_store.contract_address, caller_address);

    // Start pranking the config contract. This is necessary to mock the behavior of the contract
    // for testing purposes.
    start_prank(config.contract_address, caller_address);
}

/// Utility function to teardown the test environment.
fn teardown(data_store: IDataStoreSafeDispatcher, config: IConfigSafeDispatcher) {
    // Stop pranking contracts.
    stop_prank(data_store.contract_address);
    stop_prank(config.contract_address);
}

/// Utility function to setup the test environment.
fn setup() -> (
    ContractAddress,
    IConfigSafeDispatcher,
    IRoleStoreSafeDispatcher,
    IDataStoreSafeDispatcher,
    IEventEmitterSafeDispatcher
) {
    // Setup contracts.
    let (caller_address, config, role_store, data_store, event_emitter, ) = setup_contracts();
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
    IConfigSafeDispatcher,
    // Interface to interact with the `RoleStore` contract.
    IRoleStoreSafeDispatcher,
    // Interface to interact with the `DataStore` contract.
    IDataStoreSafeDispatcher,
    // Interface to interact with the `EventEmitter` contract.
    IEventEmitterSafeDispatcher,
) {
    // Deploy the role store contract.
    let role_store_address = deploy_role_store();

    // Create a role store dispatcher.
    let role_store = IRoleStoreSafeDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let data_store_address = deploy_data_store(role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let data_store = IDataStoreSafeDispatcher { contract_address: data_store_address };

    // Deploy the `EventEmitter` contract.
    let event_emitter_address = deploy_event_emitter();
    // Create a safe dispatcher to interact with the contract.
    let event_emitter = IEventEmitterSafeDispatcher { contract_address: event_emitter_address };

    // Deploy the `Config` contract.
    let config_address = deploy_config(
        data_store_address, role_store_address, event_emitter_address
    );

    // Create a safe dispatcher to interact with the contract.
    let config = IConfigSafeDispatcher { contract_address: config_address };

    (contract_address_const::<'caller'>(), config, role_store, data_store, event_emitter, )
}

/// Utility function to deploy a market factory contract and return its address.
fn deploy_config(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
) -> ContractAddress {
    let class_hash = declare('Config');
    let mut constructor_calldata = array![];
    constructor_calldata.append(role_store_address.into());
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(event_emitter_address.into());
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @constructor_calldata
    };
    deploy(prepared).unwrap()
}


/// Utility function to deploy a data store contract and return its address.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let class_hash = declare('DataStore');
    let mut constructor_calldata = array![];
    constructor_calldata.append(role_store_address.into());
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @constructor_calldata
    };
    deploy(prepared).unwrap()
}

/// Utility function to deploy a data store contract and return its address.
/// Copied from `tests/role/test_role_store.rs`.
/// TODO: Find a way to share this code.
fn deploy_role_store() -> ContractAddress {
    let class_hash = declare('RoleStore');
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @array![] };
    deploy(prepared).unwrap()
}

/// Utility function to deploy a `EventEmitter` contract and return its address.
fn deploy_event_emitter() -> ContractAddress {
    let class_hash = declare('EventEmitter');
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @array![] };
    deploy(prepared).unwrap()
}
