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
    // Setup required contracts.
    let (caller_address, config, role_store, data_store, event_emitter, ) = setup();

    // Grant the caller the `CONTROLLER` role.
    // We use the same account to deploy data_store and role_store, so we can grant the role
    // because the caller is the owner of role_store contract.
    role_store.grant_role(caller_address, role::CONTROLLER).unwrap();
    role_store.grant_role(caller_address, role::CONFIG_KEEPER).unwrap();

    // Prank the caller address for calls to data_store contract.
    // We need this so that the caller has the CONTROLLER role.
    start_prank(data_store.contract_address, caller_address);

    // Prank the caller address for calls to market_factory contract.
    // We need this so that the caller has the CONFIG_KEEPER role.
    start_prank(config.contract_address, caller_address);

    // ****** LOGIC STARTS HERE ******

    // Define variables to be used in the test.
    let base_key_holding_address = keys::holding_address();
    let mut data = ArrayTrait::new();
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

    // ****** LOGIC ENDS HERE ******

    // Stop pranking the caller address.
    stop_prank(data_store.contract_address);
    stop_prank(config.contract_address);
}

/// Setup required contracts.
fn setup() -> (
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
    let mut constructor_calldata = ArrayTrait::new();
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
    let mut constructor_calldata = ArrayTrait::new();
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
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @ArrayTrait::new()
    };
    deploy(prepared).unwrap()
}

/// Utility function to deploy a `EventEmitter` contract and return its address.
fn deploy_event_emitter() -> ContractAddress {
    let class_hash = declare('EventEmitter');
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @ArrayTrait::new()
    };
    deploy(prepared).unwrap()
}
