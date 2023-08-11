use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use cheatcodes::PreparedContract;

use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
use gojo::role::role;
use gojo::order::order::{Order, OrderType};

#[test]
fn given_test_environment_when_felt252_functions_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP TEST ENVIRONMENT                                       *
    // *********************************************************************************************
    let (caller_address, role_store, data_store) = setup_test_environment();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Set key 1 to value 42.
    data_store.set_felt252(1, 42).unwrap();
    let value = data_store.get_felt252(1).unwrap();
    // Check that the value read is 42.
    assert(value == 42, 'Invalid value');

    // Increment key 1 by 5.
    let new_value = data_store.increment_felt252(1, 5).unwrap();
    // Check that the new value is 47.
    assert(new_value == 47, 'Invalid value');
    let value = data_store.get_felt252(1).unwrap();
    // Check that the value read is 47.
    assert(value == 47, 'Invalid value');

    // Decrement key 1 by 2.
    let new_value = data_store.decrement_felt252(1, 2).unwrap();
    // Check that the new value is 45.
    assert(new_value == 45, 'Invalid value');
    let value = data_store.get_felt252(1).unwrap();
    // Check that the value read is 45.
    assert(value == 45, 'Invalid value');

    // Remove key 1.
    data_store.remove_felt252(1).unwrap();
    // Check that the key was removed.
    assert(data_store.get_felt252(1).unwrap() == Default::default(), 'Key was not deleted');

    // *********************************************************************************************
    // *                              TEARDOWN TEST ENVIRONMENT                                    *
    // *********************************************************************************************
    teardown_test_environment(data_store.contract_address);
}

#[test]
fn given_test_environment_when_u256_functions_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP TEST ENVIRONMENT                                       *
    // *********************************************************************************************
    let (caller_address, role_store, data_store) = setup_test_environment();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Set key 1 to value 42.
    data_store.set_u256(1, 42).unwrap();
    let value = data_store.get_u256(1).unwrap();
    // Check that the value read is 42.
    assert(value == 42, 'Invalid value');

    // Increment key 1 by 5.
    let new_value = data_store.increment_u256(1, 5).unwrap();
    // Check that the new value is 47.
    assert(new_value == 47, 'Invalid value');
    let value = data_store.get_u256(1).unwrap();
    // Check that the value read is 47.
    assert(value == 47, 'Invalid value');

    // Decrement key 1 by 2.
    let new_value = data_store.decrement_u256(1, 2).unwrap();
    // Check that the new value is 45.
    assert(new_value == 45, 'Invalid value');
    let value = data_store.get_u256(1).unwrap();
    // Check that the value read is 45.
    assert(value == 45, 'Invalid value');

    // Remove key 1.
    data_store.remove_u256(1).unwrap();
    // Check that the key was removed.
    assert(data_store.get_u256(1).unwrap() == Default::default(), 'Key was not removed');

    // *********************************************************************************************
    // *                              TEARDOWN TEST ENVIRONMENT                                    *
    // *********************************************************************************************
    teardown_test_environment(data_store.contract_address);
}

#[test]
fn given_test_environment_when_address_functions_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP TEST ENVIRONMENT                                       *
    // *********************************************************************************************
    let (caller_address, role_store, data_store) = setup_test_environment();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Set key 1 to value 42.
    data_store.set_address(1, caller_address).unwrap();
    let value = data_store.get_address(1).unwrap();
    // Check that the value read is the caller address.
    assert(value == caller_address, 'Invalid value');

    // Remove key 1.
    data_store.remove_address(1).unwrap();
    // Check that the key was deleted.
    assert(
        data_store.get_address(1).unwrap() == contract_address_const::<0>(), 'Key was not removed'
    );

    // *********************************************************************************************
    // *                              TEARDOWN TEST ENVIRONMENT                                    *
    // *********************************************************************************************
    teardown_test_environment(data_store.contract_address);
}

#[test]
fn given_test_environment_when_order_functions_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP TEST ENVIRONMENT                                       *
    // *********************************************************************************************
    let (caller_address, role_store, data_store) = setup_test_environment();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test.
    let order_type = OrderType::MarketSwap;
    let account = contract_address_const::<'account'>();
    let receiver = contract_address_const::<'receiver'>();
    let callback_contract = contract_address_const::<'callback_contract'>();
    let ui_fee_receiver = contract_address_const::<'ui_fee_receiver'>();
    let market = contract_address_const::<'market'>();
    let initial_collateral_token = contract_address_const::<'initial_collateral_token'>();
    let mut swap_path = ArrayTrait::new();
    swap_path.append(contract_address_const::<'swap_path_0'>());
    swap_path.append(contract_address_const::<'swap_path_1'>());

    let order_data_store_key = 1;

    // Create an order.
    let order = Order {
        order_type,
        account,
        receiver,
        callback_contract,
        ui_fee_receiver,
        market,
        initial_collateral_token,
        swap_path
    };

    // Store the order.
    data_store.set_order(order_data_store_key, order).unwrap();

    // Retrieve the order.
    // We use `unwrap().unwrap()` because we know that the order exists.
    // If it panics the test should fail.
    let retrieved_order = data_store.get_order(order_data_store_key).unwrap().unwrap();

    // Check that the retrieved order is the same as the original order.
    // TODO: Add a proper equality check for orders by implementing `PartialEq` for `Order`.
    assert(retrieved_order.account == account, 'invalid order');

    // *********************************************************************************************
    // *                              TEARDOWN TEST ENVIRONMENT                                    *
    // *********************************************************************************************
    teardown_test_environment(data_store.contract_address);
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
    let class_hash = declare('DataStore');
    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append(role_store_address.into());
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @constructor_calldata
    };
    deploy(prepared).unwrap()
}

/// Utility function to deploy a role store contract and return its address.
///
/// # Returns
///
/// * `ContractAddress` - The address of the deployed role store contract.
fn deploy_role_store() -> ContractAddress {
    let class_hash = declare('RoleStore');
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @ArrayTrait::new()
    };
    deploy(prepared).unwrap()
}

/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreSafeDispatcher` - The role store dispatcher.
/// * `IDataStoreSafeDispatcher` - The data store dispatcher.
fn setup_test_environment() -> (
    ContractAddress, IRoleStoreSafeDispatcher, IDataStoreSafeDispatcher
) {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreSafeDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreSafeDispatcher { contract_address: data_store_address };
    role_store.grant_role(caller_address, role::CONTROLLER).unwrap();
    start_prank(data_store_address, caller_address);
    (caller_address, role_store, data_store)
}

/// Utility function to teardown the test environment.
///
/// # Arguments
///
/// * `data_store_address` - The address of the data store contract.
fn teardown_test_environment(data_store_address: ContractAddress) {
    stop_prank(data_store_address);
}
