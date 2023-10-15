// Core lib imports.
use starknet::{ContractAddress, Felt252TryIntoContractAddress, contract_address_const};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};
use debug::PrintTrait;
// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::role::role;

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
    let constructor_calldata = array![role_store_address.into()];
    let data_store_address = contract_address_const::<'data_store'>();
    start_prank(data_store_address, contract_address_const::<'caller'>());
    contract.deploy_at(@constructor_calldata, data_store_address).unwrap()
}

/// Utility function to deploy a `SwapHandler` contract and return its dispatcher.
///
/// # Arguments
///
/// * `role_store_address` - The address of the role store contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the deployed data store contract.
fn deploy_swap_handler_address(
    role_store_address: ContractAddress, data_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('SwapHandler');
    let constructor_calldata = array![role_store_address.into()];
    let swap_handler_address = contract_address_const::<'swap_handler'>();
    start_prank(swap_handler_address, contract_address_const::<'caller'>());
    contract.deploy_at(@constructor_calldata, swap_handler_address).unwrap()
}

/// Utility function to deploy a role store contract and return its address.
///
/// # Returns
///
/// * `ContractAddress` - The address of the deployed role store contract.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let role_store_address = contract_address_const::<'role_store'>();
    start_prank(role_store_address, contract_address_const::<'caller'>());
    contract.deploy_at(@array![], role_store_address).unwrap()
}

/// Utility function to deploy a `EventEmitter` contract and return its dispatcher.
fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    let event_emitter_address = contract_address_const::<'event_emitter'>();
    start_prank(event_emitter_address, contract_address_const::<'caller'>());
    contract.deploy(@array![]).unwrap()
}

/// Utility function to deploy a `EventEmitter` contract and return its dispatcher.
fn deploy_oracle_store(
    role_store_address: ContractAddress, event_emitter_address: ContractAddress,
) -> ContractAddress {
    let contract = declare('OracleStore');
    let oracle_address = contract_address_const::<'oracle_store'>();
    start_prank(role_store_address, contract_address_const::<'caller'>());
    let constructor_calldata = array![role_store_address.into(), event_emitter_address.into()];
    contract.deploy_at(@constructor_calldata, oracle_address).unwrap()
}

/// Utility function to deploy a `EventEmitter` contract and return its dispatcher.
fn deploy_oracle(
    role_store_address: ContractAddress,
    oracle_store_address: ContractAddress,
    pragma_address: ContractAddress
) -> ContractAddress {
    let contract = declare('Oracle');
    let constructor_calldata = array![
        role_store_address.into(), oracle_store_address.into(), pragma_address.into()
    ];
    let oracle_address = contract_address_const::<'oracle'>();
    start_prank(oracle_address, contract_address_const::<'caller'>());
    contract.deploy_at(@constructor_calldata, oracle_address).unwrap()
}


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
fn setup() -> (ContractAddress, IRoleStoreDispatcher, IDataStoreDispatcher) {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    (caller_address, role_store, data_store)
}

/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the event emitter contract.
/// * `IEventEmitterDispatcher` - The event emitter store dispatcher.
fn setup_event_emitter() -> (ContractAddress, IEventEmitterDispatcher) {
    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };
    (event_emitter_address, event_emitter)
}


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
/// * `IEventEmitterDispatcher` - The event emitter store dispatcher.
/// * `IOracleDispatcher` - The oracle dispatcher.
fn setup_oracle_and_store() -> (
    ContractAddress,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IEventEmitterDispatcher,
    IOracleDispatcher
) {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    let (event_emitter_address, event_emitter) = setup_event_emitter();
    let oracle_store_address = deploy_oracle_store(role_store_address, event_emitter_address);
    let oracle_address = deploy_oracle(
        role_store_address, oracle_store_address, contract_address_const::<'pragma'>()
    );
    let oracle = IOracleDispatcher { contract_address: oracle_address };
    (caller_address, role_store, data_store, event_emitter, oracle)
}

/// Utility function to teardown the test environment.
///
/// # Arguments
///
/// * `data_store_address` - The address of the data store contract.
fn teardown(data_store_address: ContractAddress) {
    stop_prank(data_store_address);
}

