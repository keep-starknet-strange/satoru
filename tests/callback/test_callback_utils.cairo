use debug::PrintTrait;
use starknet::ContractAddress;
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};

use satoru::data::data_store::IDataStoreSafeDispatcherTrait;
use satoru::data::keys;
use satoru::deposit::deposit::Deposit;
use satoru::event::event_utils::EventLogData;
use satoru::callback::callback_utils::{
    validate_callback_gas_limit, set_saved_callback_contract, get_saved_callback_contract,
    after_deposit_execution
};
use satoru::callback::mocks::{ICallbackMockSafeDispatcherTrait, deploy_callback_mock};
use satoru::tests_lib::{setup, teardown, deploy_event_emitter};

#[test]
fn test_callback_utils_validate() {
    let (_, _, data_store) = setup();
    data_store.set_u128(keys::max_callback_gas_limit(), 100);

    validate_callback_gas_limit(data_store, 100);

    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('max_callback_gas_limit_exceeded', 101, 100))]
fn test_callback_utils_validate_fail() {
    let (_, _, data_store) = setup();
    data_store.set_u128(keys::max_callback_gas_limit(), 100);

    validate_callback_gas_limit(data_store, 101);

    teardown(data_store.contract_address);
}

#[test]
fn test_callback_utils_saved_callback() {
    let (_, _, data_store) = setup();
    let account: ContractAddress = 42.try_into().unwrap();
    let market: ContractAddress = 69.try_into().unwrap();
    let callback: ContractAddress = 123.try_into().unwrap();

    let address = get_saved_callback_contract(data_store, account, market).unwrap();
    assert(address.into() == 0, 'should be zero');

    set_saved_callback_contract(data_store, account, market, callback);

    let result = get_saved_callback_contract(data_store, account, market);
    assert(result.unwrap() == callback, 'should be ok');

    teardown(data_store.contract_address);
}

#[test]
fn test_callback_utils_callback_contract() {
    let (_, _, data_store) = setup();

    let mut deposit: Deposit = Default::default();
    let log_data = EventLogData { cant_be_empty: 0 };
    let event_emitter = deploy_event_emitter();

    let callback_mock = deploy_callback_mock();
    deposit.callback_contract = callback_mock.contract_address;

    assert(callback_mock.get_counter().unwrap() == 1, 'should be 1');
    after_deposit_execution(42, deposit, log_data, event_emitter);
    assert(callback_mock.get_counter().unwrap() == 2, 'should be 2');
}
