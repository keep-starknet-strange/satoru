//! Test file for `src/exchange/base_order_handler.cairo`.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};
use traits::Default;

// Local imports.
use satoru::role::role;
use satoru::tests_lib;

use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::bank::strict_bank::{IStrictBankDispatcher, IStrictBankDispatcherTrait};
use satoru::order::order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait};
use satoru::deposit::deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait};
use satoru::oracle::oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::exchange::base_order_handler::BaseOrderHandler::{
    IBaseOrderHandlerDispatcher, IBaseOrderHandlerDispatcherTrait
};


// *********************************************************************************************
// *                                      TEST LOGIC                                           *
// *********************************************************************************************
#[test]
#[should_panic(expected: ('already_initialized',))]
fn given_already_intialized_when_initialize_then_fails() {
    let (caller_address, role_store, data_store, event_emitter, base_order_handler) = setup();
    base_order_handler
        .initialize(
            data_store.contract_address,
            role_store.contract_address,
            event_emitter.contract_address,
            base_order_handler.order_vault.contract_address,
            base_order_handler.oracle.contract_address,
            base_order_handler.swap_handler.contract_address,
            base_order_handler.referral_storage.contract_address,
        );
    teardown(data_store, deposit_vault);
}


// *********************************************************************************************
// *                                      SETUP                                                *
// *********************************************************************************************
/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IDataStoreDispatcher` - The data store dispatcher.
/// * `IEventEmitterDispatcher` - The event emitter dispatcher.
/// * `IBaseOrderHandlerDispatcher` - The base order handler dispatcher.
fn setup() -> (
    ContractAddress, IDataStoreDispatcher, IEventEmitterDispatcher, IBaseOrderHandlerDispatcher
) {
    let (caller_address, role_store, data_store) = tests_lib::setup();

    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    let strict_bank_address = deploy_strict_bank(data_store_address, role_store_address);
    let order_vault_address = deploy_order_vault(strict_bank_address);

    let oracle_store_address = deploy_oracle_store(role_store_address, event_emitter_address);
    let oracle_address = deploy_oracle(oracle_store_address, role_store_address);

    let swap_handler_address = deploy_swap_handler(role_store_address);

    let referral_storage_address = deploy_referral_storage();

    let base_order_handler_address = deploy_base_order_handler(
        data_store_address,
        role_store_address,
        event_emitter_address,
        order_vault_address,
        oracle_address,
        swap_handler_address,
        referral_storage_address
    );
    let base_order_handler = IBaseOrderHandlerDispatcher {
        contract_address: base_order_handler_address
    };

    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);

    (caller_address, role_store, data_store, event_emitter, base_order_handler)
}

/// Utility function to deploy a `BaseOrderhandler` contract and return its address.
fn deploy_base_order_handler(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    order_vault_address: ContractAddress,
    oracle_address: ContractAddress,
    swap_handler_address: ContractAddress,
    referral_storage_address: ContractAddress
) -> ContractAddress {
    let contract = declare('BaseOrderHandler');
    let constructor_calldata = array![
        data_store_address.into(),
        role_store_address.into(),
        event_emitter_address.into(),
        order_vault_address.into(),
        oracle_address.into(),
        swap_handler_address.into(),
        referral_storage_address.into(),
    ];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy an `EventEmitter` contract and return its address.
fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    contract.deploy(@array![]).unwrap()
}

/// Utility function to deploy a `StrictBank` contract and return its address.
fn deploy_strict_bank(
    data_store_address: ContractAddress, role_store_address: ContractAddress,
) -> ContractAddress {
    let contract = declare('StrictBank');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy an `OrderVault` contract and return its address.
fn deploy_order_vault(order_vault_address: ContractAddress) -> ContractAddress {
    let contract = declare('OrderVault');
    let constructor_calldata = array![order_vault_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy an `OracleStore` contract and return its address.
fn deploy_oracle_store(
    role_store_address: ContractAddress, event_emitter_address: ContractAddress
) -> ContractAddress {
    let contract = declare('OracleStore');
    let constructor_calldata = array![role_store_address.into(), event_emitter_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy an `Oracle` contract and return its address.
fn deploy_oracle(
    oracle_store_address: ContractAddress, role_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('Oracle');
    let constructor_calldata = array![role_store_address.into(), oracle_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a `SwapHandler` contract and return its address.
fn deploy_swap_handler(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('SwapHandler');
    contract.deploy(@array![role_store_address.into()]).unwrap()
}

/// Utility function to deploy a `ReferralStorage` contract and return its address.
fn deploy_referral_storage() -> ContractAddress {
    let contract = declare('ReferralStorage');
    contract.deploy(@array![]).unwrap()
}
