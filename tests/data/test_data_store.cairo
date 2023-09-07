use starknet::{ ContractAddress,  contract_address_const};

use satoru::data::data_store::IDataStoreSafeDispatcherTrait;
use satoru::role::role_store::IRoleStoreSafeDispatcherTrait;
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
    data_store.set_bool(1, true).unwrap();
    // Safe to unwrap because we know that the key exists and if it doesn't the test should fail.
    let value = data_store.get_bool(1).unwrap().unwrap();
    // Check that the value read is true.
    assert(value == true, 'Invalid value');

    // Remove key 1.
    data_store.remove_bool(1).unwrap();
    // Check that the key was removed.
    assert(data_store.get_bool(1).unwrap() == Option::None, 'Key was not deleted');

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
    data_store.set_i128(1, 42).unwrap();
    let value = data_store.get_i128(1).unwrap();
    // Check that the value read is 42.
    assert(value == 42, 'Invalid value');

    // Increment key 1 by 5.
    let new_value = data_store.increment_i128(1, 5).unwrap();
    // Check that the new value is 47.
    assert(new_value == 47, 'Invalid value');
    let value = data_store.get_i128(1).unwrap();
    // Check that the value read is 47.
    assert(value == 47, 'Invalid value');

    // Decrement key 1 by 2.
    let new_value = data_store.decrement_i128(1, 2).unwrap();
    // Check that the new value is 45.
    assert(new_value == 45, 'Invalid value');
    let value = data_store.get_i128(1).unwrap();
    // Check that the value read is 45.
    assert(value == 45, 'Invalid value');

    // Remove key 1.
    data_store.remove_i128(1).unwrap();
    // Check that the key was removed.
    assert(data_store.get_i128(1).unwrap() == Default::default(), 'Key was not deleted');

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

    let order_data_store_key = 11111111;
    let order: Order = create_new_order(
        contract_address_const::<'account1'>(),
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        should_unwrap_native_token: false,
        is_frozen: false,
        order_no: 1
    );
    let order_snap = @order;

    // Set order
    data_store.set_order(order_data_store_key, order);

    // Retrieve the order.
    // We use `unwrap().unwrap()` because we know that the order exists.
    // If it panics the test should fail.
    let mut retrieved_order = data_store.get_order(order_data_store_key).unwrap().unwrap();

    // Check that the retrieved order is the same as the original order.
    assert_order_eq(order_snap, @retrieved_order);

    // Check order count
    let order_count = data_store.get_order_count().unwrap();
    assert(order_count == 1, 'invalid order count1');

    // Check key index for given key
    let key_index = data_store.get_key_index(order_data_store_key).unwrap();
    assert(key_index.unwrap() == 0, 'invalid key index');

    // Create new orders
    let order_data_store_key2 = 222222222;
    let order2: Order = create_new_order(
        contract_address_const::<'account2'>(),
        contract_address_const::<'receiver2'>(),
        contract_address_const::<'market2'>(),
        contract_address_const::<'token2'>(),
        is_long: true,
        should_unwrap_native_token: false,
        is_frozen: true,
        order_no: 2
    );

    let order_snap2 = @order2;

    let order_data_store_key3 = 3333333333;
    let order3: Order = create_new_order(
        contract_address_const::<'account3'>(),
        contract_address_const::<'receiver3'>(),
        contract_address_const::<'market3'>(),
        contract_address_const::<'token3'>(),
        is_long: false,
        should_unwrap_native_token: true,
        is_frozen: true,
        order_no: 3
    );
    let order_snap3 = @order3;

    // Store the new orders to index 1 and 2
    data_store.set_order(order_data_store_key2, order2);
    data_store.set_order(order_data_store_key3, order3);

    // Check order count
    let order_count3 = data_store.get_order_count().unwrap();
    assert(order_count3 == 3, 'invalid order count3');

    // Retrieve the orders and assert values
    let mut retrieved_order2 = data_store.get_order(order_data_store_key2).unwrap().unwrap();
    assert_order_eq(order_snap2, @retrieved_order2);
    let mut retrieved_order3 = data_store.get_order(order_data_store_key3).unwrap().unwrap();
    assert_order_eq(order_snap3, @retrieved_order3);

    // Check key indexes for given keys
    let key_index2 = data_store.get_key_index(order_data_store_key2).unwrap();
    assert(key_index2.unwrap() == 1, 'invalid key index2');
    let key_index3 = data_store.get_key_index(order_data_store_key3).unwrap();
    assert(key_index3.unwrap() == 2, 'invalid key index3');

    // Retrieve the keys for start and end indexes
    let start_ind = 1;
    let end_ind = 2;
    let order_keys = data_store.get_order_keys(start_ind, end_ind).unwrap();
    assert(*order_keys.at(0) == order_data_store_key2, 'invalid key1');
    assert(*order_keys.at(1) == order_data_store_key3, 'invalid key2');

    // Create new order
    let order4: Order = create_new_order(
        contract_address_const::<'account4'>(),
        contract_address_const::<'receiver4'>(),
        contract_address_const::<'market4'>(),
        contract_address_const::<'token4'>(),
        is_long: false,
        should_unwrap_native_token: true,
        is_frozen: true,
        order_no: 4
    );
    let order_snap4 = @order4;

    // Set order to assigned key and  overwrite previous order
    data_store.set_order(order_data_store_key2, order4);

    // Retrieve the order and check previous order overwritten
    let mut retrieved_order4 = data_store.get_order(order_data_store_key2).unwrap().unwrap();
    assert_order_eq(order_snap4, @retrieved_order4);

    // Remove  order
    data_store.remove_order(order_data_store_key2);

    // Check order count
    let order_count4 = data_store.get_order_count().unwrap();
    assert(order_count4 == 2, 'invalid order count4');

    // Check key index decreased
    let key_index4 = data_store.get_key_index(order_data_store_key3).unwrap();
    assert(key_index4.unwrap() == 1, 'invalid key index4');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}


/// Utility function to create new Order  struct
///
/// # Arguments
///
/// * `account` - The account of the order.
/// * `receiver` - The receiver for any token transfers.
/// * `market` - The trading market.
/// * `initial_collateral_token` - The initial collateral token for increase orders.
/// * `is_long` - Whether the order is for a long or short.
/// * `should_unwrap_native_token` - Whether to unwrap native tokens before transferring to the user.
/// * `is_frozen` - Whether the order is frozen.
/// * `order_no` - Random number to change values
fn create_new_order(
    account: ContractAddress,
    receiver: ContractAddress,
    market: ContractAddress,
    initial_collateral_token: ContractAddress,
    is_long: bool,
    should_unwrap_native_token: bool,
    is_frozen: bool,
    order_no: u128
) -> Order {
    let order_type = OrderType::StopLossDecrease;
    let callback_contract = contract_address_const::<'callback_contract'>();
    let ui_fee_receiver = contract_address_const::<'ui_fee_receiver'>();
    let mut swap_path = array![];
    swap_path.append(contract_address_const::<'swap_path_0'>());
    swap_path.append(contract_address_const::<'swap_path_1'>());
    let size_delta_usd = 1000 * order_no;
    let initial_collateral_delta_amount = 1000 * order_no;
    let trigger_price = 11111 * order_no;
    let acceptable_price = 11111 * order_no;
    let execution_fee = 10 * order_no;
    let min_output_amount = 10 * order_no;
    let updated_at_block = 1;

    let callback_gas_limit = 300000;

    // Create an order.
    Order {
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
    }
}

/// Utility function to assert order structs
/// This function will panic if any of the following fields do not match between the two orders:
/// # Arguments
///
/// * `order1` - First order struct 
/// * `order2` - Second order struct.
fn assert_order_eq(order1: @Order, order2: @Order) {
    assert(order1.account == order2.account, 'invalid account ');
    assert(order1.receiver == order2.receiver, 'invalid receiver ');
    assert(order1.callback_contract == order2.callback_contract, 'invalid callback_contract ');
    assert(order1.ui_fee_receiver == order2.ui_fee_receiver, 'invalid ui_fee_receiver ');
    assert(order1.market == order2.market, 'invalid market ');
    assert(
        order1.initial_collateral_token == order2.initial_collateral_token,
        'invalid collateral_token '
    );

    assert(order1.size_delta_usd == order2.size_delta_usd, 'invalid size_delta_usd ');
    assert(
        order1.initial_collateral_delta_amount == order2.initial_collateral_delta_amount,
        'invalid col_delta_amount '
    );
    assert(order1.trigger_price == order2.trigger_price, 'invalid trigger_price ');
    assert(order1.acceptable_price == order2.acceptable_price, 'invalid acceptable_price ');
    assert(order1.execution_fee == order2.execution_fee, 'invalid execution_fee ');
    assert(order1.callback_gas_limit == order2.callback_gas_limit, 'invalid callback_gas_limit ');
    assert(order1.min_output_amount == order2.min_output_amount, 'invalid min_output_amount ');
    assert(order1.updated_at_block == order2.updated_at_block, 'invalid updated_at_block ');
    assert(order1.is_long == order2.is_long, 'invalid is_long ');
    assert(
        order1.should_unwrap_native_token == order2.should_unwrap_native_token,
        'invalid unwrap_native_token '
    );
    assert(order1.is_frozen == order2.is_frozen, 'invalid is_frozen ');
}
