use satoru::tests_lib::{teardown};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use snforge_std::{declare, ContractClassTrait, start_prank};
use satoru::swap::swap_utils::SwapParams;
use core::traits::Into;
use satoru::role::role;
use satoru::market::market::Market;
use starknet::{get_caller_address, ContractAddress, contract_address_const,};
use array::ArrayTrait;

//TODO Tests need to be added after implementation of swap_utils

/// Utility function to deploy a `DataStore` contract and return its dispatcher.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a `EventEmitter` contract and return its dispatcher.
fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    contract.deploy(@array![]).unwrap()
}

/// Utility function to deploy a `Oracle` contract and return its dispatcher.
fn deploy_oracle(
    role_store_address: ContractAddress, oracle_address: ContractAddress
) -> ContractAddress {
    let contract = declare('Oracle');
    let mut constructor_calldata = array![];
    constructor_calldata.append(role_store_address.into());
    constructor_calldata.append(oracle_address.into());
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a `Bank` contract and return its dispatcher.
fn deploy_bank_address(
    data_store_address: ContractAddress, role_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('Bank');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    contract.deploy(@constructor_calldata).unwrap()
}


/// Utility function to deploy a `SwapHandler` contract and return its dispatcher.
fn deploy_swap_handler_address(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('SwapHandler');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a `RoleStore` contract and return its dispatcher.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@array![]).unwrap()
}


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IDataStoreDispatcher` - The data store dispatcher.
/// * `IEventEmitterDispatcher` - The event emitter dispatcher.
/// * `IOracleDispatcher` - The oracle dispatcher dispatcher.
/// * `IBankDispatcher` - The bank dispatcher.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `ISwapHandlerDispatcher` - The swap handler dispatcher.
fn setup() -> (
    ContractAddress,
    IDataStoreDispatcher,
    IEventEmitterDispatcher,
    IOracleDispatcher,
    IBankDispatcher,
    IRoleStoreDispatcher,
    ISwapHandlerDispatcher
) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();

    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    let oracle_address = deploy_oracle(role_store_address, contract_address_const::<'oracle'>());
    let oracle = IOracleDispatcher { contract_address: oracle_address };

    let bank_address = deploy_bank_address(data_store_address, role_store_address);
    let bank = IBankDispatcher { contract_address: bank_address };

    let swap_handler_address = deploy_swap_handler_address(role_store_address);
    let swap_handler = ISwapHandlerDispatcher { contract_address: swap_handler_address };

    start_prank(role_store_address, caller_address);
    start_prank(data_store_address, caller_address);
    start_prank(event_emitter_address, caller_address);
    start_prank(oracle_address, caller_address);
    start_prank(bank_address, caller_address);
    start_prank(swap_handler_address, caller_address);

    // Grant the caller the `CONTROLLER` role.
    role_store.grant_role(caller_address, role::CONTROLLER);

    (caller_address, data_store, event_emitter, oracle, bank, role_store, swap_handler)
}


#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn test_check_unauthorized_access_role() {
    let (caller_address, data_store, event_emitter, oracle, bank, role_store, swap_handler) =
        setup();

    // Revoke the caller the `CONTROLLER` role.
    role_store.revoke_role(caller_address, role::CONTROLLER);

    let mut market = Market {
        market_token: contract_address_const::<'market_token'>(),
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };

    let mut swap = SwapParams {
        data_store: data_store,
        event_emitter: event_emitter,
        oracle: oracle,
        bank: bank,
        key: 1,
        token_in: contract_address_const::<'token_in'>(),
        amount_in: 1,
        swap_path_markets: ArrayTrait::new(),
        min_output_amount: 1,
        receiver: contract_address_const::<'receiver'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
        should_unwrap_native_token: true,
    };

    swap_handler.swap(swap);
    teardown(data_store.contract_address);
}


#[test]
fn test_check_swap_called() {
    //Change that when swap_handler has been implemented
    let (caller_address, data_store, event_emitter, oracle, bank, role_store, swap_handler) =
        setup();

    let mut market = Market {
        market_token: contract_address_const::<'market_token'>(),
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };

    let mut swap = SwapParams {
        data_store: data_store,
        event_emitter: event_emitter,
        oracle: oracle,
        bank: bank,
        key: 1,
        token_in: contract_address_const::<'token_in'>(),
        amount_in: 1,
        swap_path_markets: ArrayTrait::new(),
        min_output_amount: 1,
        receiver: contract_address_const::<'receiver'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
        should_unwrap_native_token: true,
    };

    let swap_result = swap_handler.swap(swap);

    assert(swap_result == (0.try_into().unwrap(), 0), 'Error');

    teardown(role_store.contract_address);
}
//TODO add more tested when swap_handler has been implemented


