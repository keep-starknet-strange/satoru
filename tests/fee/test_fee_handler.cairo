use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::fee::fee_handler::{IFeeHandlerDispatcher, IFeeHandlerDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;

#[test]
fn given_normal_conditions_when_fee_handler_then_works() {
    let (caller_address, data_store, event_emitter, fee_handler) = setup();

    let markets: Array<ContractAddress> = array![
        0x777.try_into().unwrap(), 0x888.try_into().unwrap(), 0x999.try_into().unwrap()
    ];
    let tokens: Array<ContractAddress> = array![
        0x123.try_into().unwrap(), 0x234.try_into().unwrap(), 0x345.try_into().unwrap()
    ];
// fee_handler.claim_fees(markets, tokens); TODO wait for market_utils to be implemented
}

#[test]
#[should_panic(expected: ('invalid_claim_fees_input',))]
fn given_wrong_inputs_when_fee_handler_then_fails() {
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
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'fee_handler'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![
        data_store_address.into(), role_store_address.into(), event_emitter_address.into()
    ];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'data_store'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'role_store'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![caller_address.into()], deployed_contract_address).unwrap()
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'event_emitter'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![], deployed_contract_address).unwrap()
}

fn setup() -> (
    ContractAddress, IDataStoreDispatcher, IEventEmitterDispatcher, IFeeHandlerDispatcher
) {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
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
