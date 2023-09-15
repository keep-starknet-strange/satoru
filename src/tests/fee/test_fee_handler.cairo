use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::fee::fee_handler::{IFeeHandlerDispatcher, IFeeHandlerDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::data::keys::{
    claim_fee_amount_key, claim_ui_fee_amount_key, claim_ui_fee_amount_for_account_key
};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;

#[test]
fn test_fee_handler_normal() {
    let (caller_address, data_store, event_emitter, fee_handler) = setup();

    let markets: Array<ContractAddress> = array![
        0x777.try_into().unwrap(), 0x888.try_into().unwrap(), 0x999.try_into().unwrap()
    ];
    let tokens: Array<ContractAddress> = array![
        0x123.try_into().unwrap(), 0x234.try_into().unwrap(), 0x345.try_into().unwrap()
    ];

    fee_handler.claim_fees(markets, tokens);
}

#[test]
#[should_panic(expected: ('invalid_claim_fees_input',))]
fn test_fee_handler_wrong_inputs() {
    let (caller_address, data_store, event_emitter, fee_handler) = setup();

    let markets: Array<ContractAddress> = array![
        0x777.try_into().unwrap(), 0x888.try_into().unwrap(), 0x999.try_into().unwrap()
    ];
    let tokens: Array<ContractAddress> = array![
        0x123.try_into().unwrap(), 0x234.try_into().unwrap()
    ];

    fee_handler.claim_fees(markets, tokens);
}

fn deploy_fee_handler(
    role_store_address: ContractAddress,
    data_store_address: ContractAddress,
    event_emitter_address: ContractAddress
) -> ContractAddress {
    let contract = declare('FeeHandler');
    let constructor_calldata = array![
        data_store_address.into(), role_store_address.into(), event_emitter_address.into()
    ];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@array![]).unwrap()
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    contract.deploy(@array![]).unwrap()
}

fn setup() -> (
    ContractAddress, IDataStoreDispatcher, IEventEmitterDispatcher, IFeeHandlerDispatcher
) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };
    let fee_handler_address = deploy_fee_handler(
        role_store_address, data_store_address, event_emitter_address
    );
    let fee_handler = IFeeHandlerDispatcher { contract_address: fee_handler_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    (caller_address, data_store, event_emitter, fee_handler)
}
