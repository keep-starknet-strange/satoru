use satoru::utils::basic_multicall::multicall;
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
    contract_address_to_felt252, account::Call, SyscallResultTrait
};
use debug::PrintTrait;
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
use satoru::role::role;

#[test]
fn test_simlple_multicall() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, data_store) = setup();

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
    assert(data_store.get_felt252(1).unwrap() == 42, 'Invalid value');

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
    let (role_store, data_store) = setup();

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
    assert(data_store.get_felt252(1).unwrap() == 42, 'Invalid value after first call');

    // check second call result
    assert(
        role_store.has_role(account_address, role::ROLE_ADMIN).unwrap(),
        'Invalid role after second call'
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
    let (role_store, data_store) = setup();

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
    assert(data_store.get_felt252(1).unwrap() == 42, 'Invalid value');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}

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
    let mut constructor_calldata = array![];
    constructor_calldata.append(role_store_address.into());
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a role store contract and return its address.
///
/// # Returns
///
/// * `ContractAddress` - The address of the deployed role store contract.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let constructor_arguments: @Array::<felt252> = @ArrayTrait::new();
    contract.deploy(constructor_arguments).unwrap()
}

/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreSafeDispatcher` - The role store dispatcher.
/// * `IDataStoreSafeDispatcher` - The data store dispatcher.
/// * `ContractAddress` - The role store contract address.
/// * `ContractAddress` - The data store contract address.
fn setup() -> (IRoleStoreSafeDispatcher, IDataStoreSafeDispatcher) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreSafeDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreSafeDispatcher { contract_address: data_store_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER).unwrap();
    start_prank(data_store_address, caller_address);
    (role_store, data_store)
}

/// Utility function to teardown the test environment.
///
/// # Arguments
///
/// * `data_store_address` - The address of the data store contract.
fn teardown(data_store_address: ContractAddress) {
    stop_prank(data_store_address);
}
