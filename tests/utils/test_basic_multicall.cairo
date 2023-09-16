use satoru::utils::basic_multicall::multicall;
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
    contract_address_to_felt252, account::Call, SyscallResultTrait
};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::{role, role_store::IRoleStoreDispatcher, role_store::IRoleStoreDispatcherTrait};
use satoru::tests_lib::{setup, teardown};
use debug::PrintTrait;


#[test]
fn test_simple_multicall() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (_, _, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let mut calls = array![];
    let mut calldata_param = array![1, 42];
    let first_call = Call {
        to: data_store.contract_address,
        selector: selector!("set_felt252"), /// generate keccak hash for 'set_felt252' in cairo
        calldata: calldata_param
    };
    calls.append(first_call);

    let result: Array<Span<felt252>> = multicall(calls);

    // check first call result
    assert(data_store.get_felt252(1) == 42, 'Invalid value');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}


#[test]
fn test_multicall() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (_, role_store, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let mut calls = array![];

    // build first call to data_store_address
    let mut calldata_param = array![1, 42];
    let first_call = Call {
        to: data_store.contract_address,
        selector: selector!("set_felt252"), // generate keccak hash for 'set_felt252'
        calldata: calldata_param
    };
    calls.append(first_call);

    // build second call to role_store
    let account_address: ContractAddress = contract_address_const::<1>();
    let felt_account_address = contract_address_to_felt252(account_address);
    let mut calldata2_param = array![felt_account_address, role::ROLE_ADMIN];
    let second_call = Call {
        to: role_store.contract_address,
        selector: selector!("grant_role"), // generate keccak hash for 'grant_role'
        calldata: calldata2_param
    };
    calls.append(second_call);

    // perform multicall operation
    let result: Array<Span<felt252>> = multicall(calls);

    // check first call result
    assert(data_store.get_felt252(1) == 42, 'Invalid value after first call');

    // check second call result
    assert(
        role_store.has_role(account_address, role::ROLE_ADMIN), 'Invalid role after second call'
    );

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('no data for multicall',))]
fn test_no_data_for_multicall() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (_, _, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let mut calls = array![];
    let mut calldata_param = array![1, 42];
    let first_call = Call {
        to: data_store.contract_address,
        selector: selector!("set_felt25"), /// generate keccak hash for 'set_felt252' in cairo
        calldata: calldata_param
    };

    // should panic due to empty calls. Notice that calls has no append()
    let result: Array<Span<felt252>> = multicall(calls);

    // check first call result
    assert(data_store.get_felt252(1) == 42, 'Invalid value');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}
