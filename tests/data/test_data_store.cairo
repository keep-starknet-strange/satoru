use starknet::contract_address_const;

use satoru::data::data_store::IDataStoreDispatcherTrait;
use satoru::role::role_store::IRoleStoreDispatcherTrait;
use satoru::order::order::{Order, OrderType, OrderTrait};
use satoru::tests_lib::{setup, teardown};

#[test]
fn given_normal_conditions_when_felt252_functions_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, role_store, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Set key 1 to value 42.
    data_store.set_felt252(1, 42);
    let value = data_store.get_felt252(1);
    // Check that the value read is 42.
    assert(value == 42, 'Invalid value');

    // Increment key 1 by 5.
    let new_value = data_store.increment_felt252(1, 5);
    // Check that the new value is 47.
    assert(new_value == 47, 'Invalid value');
    let value = data_store.get_felt252(1);
    // Check that the value read is 47.
    assert(value == 47, 'Invalid value');

    // Decrement key 1 by 2.
    let new_value = data_store.decrement_felt252(1, 2);
    // Check that the new value is 45.
    assert(new_value == 45, 'Invalid value');
    let value = data_store.get_felt252(1);
    // Check that the value read is 45.
    assert(value == 45, 'Invalid value');

    // Remove key 1.
    data_store.remove_felt252(1);
    // Check that the key was removed.
    assert(data_store.get_felt252(1) == Default::default(), 'Key was not deleted');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_bool_functions_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, role_store, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Set key 1 to value true.
    data_store.set_bool(1, true);
    // Safe to unwrap because we know that the key exists and if it doesn't the test should fail.
    let value = data_store.get_bool(1);
    // Check that the value read is true.
    assert(value.unwrap() == true, 'Invalid value');

    // Remove key 1.
    data_store.remove_bool(1);
    // Check that the key was removed.
    assert(data_store.get_bool(1) == Option::None, 'Key was not deleted');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}


#[test]
fn given_normal_conditions_when_u256_functions_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, role_store, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Set key 1 to value 42.
    data_store.set_u256(1, 42);
    let value = data_store.get_u256(1);
    // Check that the value read is 42.
    assert(value == 42, 'Invalid value');

    // Increment key 1 by 5.
    let new_value = data_store.increment_u256(1, 5);
    // Check that the new value is 47.
    assert(new_value == 47, 'Invalid value');
    let value = data_store.get_u256(1);
    // Check that the value read is 47.
    assert(value == 47, 'Invalid value');

    // Decrement key 1 by 2.
    let new_value = data_store.decrement_u256(1, 2);
    // Check that the new value is 45.
    assert(new_value == 45, 'Invalid value');
    let value = data_store.get_u256(1);
    // Check that the value read is 45.
    assert(value == 45, 'Invalid value');

    // Remove key 1.
    data_store.remove_u256(1);
    // Check that the key was removed.
    assert(data_store.get_u256(1) == Default::default(), 'Key was not removed');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_i128_functions_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, role_store, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Set key 1 to value 42.
    data_store.set_i128(1, 42);
    let value = data_store.get_i128(1);
    // Check that the value read is 42.
    assert(value == 42, 'Invalid value');

    // Increment key 1 by 5.
    let new_value = data_store.increment_i128(1, 5);
    // Check that the new value is 47.
    assert(new_value == 47, 'Invalid value');
    let value = data_store.get_i128(1);
    // Check that the value read is 47.
    assert(value == 47, 'Invalid value');

    // Decrement key 1 by 2.
    let new_value = data_store.decrement_i128(1, 2);
    // Check that the new value is 45.
    assert(new_value == 45, 'Invalid value');
    let value = data_store.get_i128(1);
    // Check that the value read is 45.
    assert(value == 45, 'Invalid value');

    // Remove key 1.
    data_store.remove_i128(1);
    // Check that the key was removed.
    assert(data_store.get_i128(1) == Default::default(), 'Key was not deleted');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_address_functions_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, role_store, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Set key 1 to value 42.
    data_store.set_address(1, caller_address);
    let value = data_store.get_address(1);
    // Check that the value read is the caller address.
    assert(value == caller_address, 'Invalid value');

    // Remove key 1.
    data_store.remove_address(1);
    // Check that the key was deleted.
    assert(data_store.get_address(1) == contract_address_const::<0>(), 'Key was not removed');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_order_functions_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, role_store, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test.
    let order_data_store_key = 1;
    let order_type = OrderType::StopLossDecrease;
    let account = contract_address_const::<'account'>();
    let receiver = contract_address_const::<'receiver'>();
    let callback_contract = contract_address_const::<'callback_contract'>();
    let ui_fee_receiver = contract_address_const::<'ui_fee_receiver'>();
    let market = contract_address_const::<'market'>();
    let initial_collateral_token = contract_address_const::<'initial_collateral_token'>();
    let mut swap_path = array![];
    swap_path.append(contract_address_const::<'swap_path_0'>());
    swap_path.append(contract_address_const::<'swap_path_1'>());
    let size_delta_usd = 1000;
    let initial_collateral_delta_amount = 500;
    let trigger_price = 2000;
    let acceptable_price = 2500;
    let execution_fee = 100;
    let callback_gas_limit = 300000;
    let min_output_amount = 100;
    let updated_at_block = 1;
    let is_long = true;
    let should_unwrap_native_token = false;
    let is_frozen = false;

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
        swap_path,
        size_delta_usd,
        initial_collateral_delta_amount,
        trigger_price,
        acceptable_price,
        execution_fee,
        callback_gas_limit,
        min_output_amount,
        updated_at_block,
        is_long,
        should_unwrap_native_token,
        is_frozen,
    };

    // Store the order.
    data_store.set_order(order_data_store_key, order);

    // Retrieve the order.
    // We use `unwrap().unwrap()` because we know that the order exists.
    // If it panics the test should fail.
    let mut retrieved_order = data_store.get_order(order_data_store_key).unwrap();

    // Check that the retrieved order is the same as the original order.
    // TODO: Add a proper equality check for orders by implementing `PartialEq` for `Order`.
    assert(retrieved_order.account == account, 'invalid order');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}
