use starknet::{ContractAddress, contract_address_const};

use satoru::data::data_store::IDataStoreSafeDispatcherTrait;
use satoru::role::role_store::IRoleStoreSafeDispatcherTrait;
use satoru::order::order::{Order, OrderType, OrderTrait};
use satoru::tests_lib::{setup, teardown};

use snforge_std::PrintTrait;

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
    let account1 = contract_address_const::<'account1'>();
    let order: Order = create_new_order(
        account1,
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

    // Check account data index and count
    let acount_key = data_store.get_account_key_index(account1, order_data_store_key).unwrap();
    assert(acount_key.unwrap() == 0, 'invalid account key');

    let acount_count = data_store.get_account_order_count(account1).unwrap();
    assert(acount_count == 1, 'invalid acc1 count');

    // Create new orders
    let order_data_store_key2 = 222222222;
    let account2 = contract_address_const::<'account2'>();
    let order2: Order = create_new_order(
        account2,
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
        account1,
        contract_address_const::<'receiver3'>(),
        contract_address_const::<'market3'>(),
        contract_address_const::<'token3'>(),
        is_long: false,
        should_unwrap_native_token: true,
        is_frozen: true,
        order_no: 3
    );
    let order_snap3 = @order3;

    // Create new order
    let order_data_store_key4 = 4444444444;
    let order4: Order = create_new_order(
        account1,
        contract_address_const::<'receiver4'>(),
        contract_address_const::<'market4'>(),
        contract_address_const::<'token4'>(),
        is_long: false,
        should_unwrap_native_token: true,
        is_frozen: true,
        order_no: 4
    );
    let order_snap4 = @order4;

    // Store the new orders to index 1 and 2
    data_store.set_order(order_data_store_key2, order2);
    data_store.set_order(order_data_store_key3, order3);
    data_store.set_order(order_data_store_key4, order4);

    // Check order count
    let order_count3 = data_store.get_order_count().unwrap();
    assert(order_count3 == 4, 'invalid order count3');

    // Retrieve the orders and assert values
    let mut retrieved_order2 = data_store.get_order(order_data_store_key2).unwrap().unwrap();
    assert_order_eq(order_snap2, @retrieved_order2);
    let mut retrieved_order3 = data_store.get_order(order_data_store_key3).unwrap().unwrap();
    assert_order_eq(order_snap3, @retrieved_order3);
    let mut retrieved_order4 = data_store.get_order(order_data_store_key4).unwrap().unwrap();
    assert_order_eq(order_snap4, @retrieved_order4);

    // Check key indexes for given keys
    let key_index2 = data_store.get_key_index(order_data_store_key2).unwrap();
    assert(key_index2.unwrap() == 1, 'invalid key index2');
    let key_index3 = data_store.get_key_index(order_data_store_key3).unwrap();
    assert(key_index3.unwrap() == 2, 'invalid key index3');
    let key_index4 = data_store.get_key_index(order_data_store_key4).unwrap();
    assert(key_index4.unwrap() == 3, 'invalid key index4');

    // Check account data index and count
    let acount_key = data_store.get_account_key_index(account1, order_data_store_key4).unwrap();
    assert(acount_key.unwrap() == 2, 'invalid account key2');
    let acount_count = data_store.get_account_order_count(account1).unwrap();
    assert(acount_count == 3, 'invalid acc count2');
    let acount_count = data_store.get_account_order_count(account2).unwrap();
    assert(acount_count == 1, 'invalid acc count3');

    // Retrieve the keys for start and end indexes
    let order_keys = data_store.get_order_keys(1, 2).unwrap();
    assert(order_keys.len() == 2, 'invalid key len');
    assert(*order_keys.at(0) == order_data_store_key2, 'invalid key1');
    assert(*order_keys.at(1) == order_data_store_key3, 'invalid key2');

    let account_keys = data_store.get_account_order_keys(account1, 1, 10).unwrap();
    assert(account_keys.len() == 2, 'invalid key len2');
    assert(*account_keys.at(0) == order_data_store_key3, 'invalid acc key3');
    assert(*account_keys.at(1) == order_data_store_key4, 'invalid acc key4');

    let account_keys2 = data_store.get_account_order_keys(account2, 0, 10).unwrap();
    assert(account_keys2.len() == 1, 'invalid key len3');
    assert(*account_keys2.at(0) == order_data_store_key2, 'invalid acc key5');

    let order5: Order = create_new_order(
        account1,
        contract_address_const::<'receiver4'>(),
        contract_address_const::<'market4'>(),
        contract_address_const::<'token4'>(),
        is_long: false,
        should_unwrap_native_token: true,
        is_frozen: true,
        order_no: 5
    );
    let order_snap5 = @order5;

    // Set order to assigned key and  overwrite previous order
    data_store.set_order(order_data_store_key3, order5);

    // Retrieve the order and check previous order overwritten
    let mut retrieved_order5 = data_store.get_order(order_data_store_key3).unwrap().unwrap();
    assert_order_eq(order_snap5, @retrieved_order5);

    // Order has same account count should stay same
    let acount_count = data_store.get_account_order_count(account1).unwrap();
    assert(acount_count == 3, 'invalid acc count2');
    let acount2_count = data_store.get_account_order_count(account2).unwrap();
    assert(acount2_count == 1, 'invalid acc count3');

    let order6: Order = create_new_order(
        account2,
        contract_address_const::<'receiver4'>(),
        contract_address_const::<'market4'>(),
        contract_address_const::<'token4'>(),
        is_long: false,
        should_unwrap_native_token: true,
        is_frozen: true,
        order_no: 5
    );
    let order_snap6 = @order6;

    // Set order to assigned key and  overwrite previous order
    data_store.set_order(order_data_store_key3, order6);

    // Retrieve the order and check previous order overwritten
    let mut retrieved_order6 = data_store.get_order(order_data_store_key3).unwrap().unwrap();
    assert_order_eq(order_snap6, @retrieved_order6);

    // Order has different account count should change
    let acount_count = data_store.get_account_order_count(account1).unwrap();
    assert(acount_count == 2, 'invalid acc count4');
    let acount2_count = data_store.get_account_order_count(account2).unwrap();
    assert(acount2_count == 2, 'invalid acc count5');

    let account_keys = data_store.get_account_order_keys(account1, 0, 10).unwrap();
    assert(account_keys.len() == 2, 'invalid key len4');
    assert(*account_keys.at(0) == order_data_store_key, 'invalid acc key6');
    assert(*account_keys.at(1) == order_data_store_key4, 'invalid acc key7');

    let account_keys2 = data_store.get_account_order_keys(account2, 0, 10).unwrap();
    assert(account_keys2.len() == 2, 'invalid key len5');
    assert(*account_keys2.at(0) == order_data_store_key2, 'invalid acc key8');
    assert(*account_keys2.at(1) == order_data_store_key3, 'invalid acc key9');

    // Remove  order
    data_store.remove_order(order_data_store_key);

    // Check order count
    let order_count4 = data_store.get_order_count().unwrap();
    assert(order_count4 == 3, 'invalid order count4');

    let acount_count = data_store.get_account_order_count(account1).unwrap();
    assert(acount_count == 1, 'invalid acc count6');

    let account_keys = data_store.get_account_order_keys(account1, 0, 10).unwrap();
    assert(account_keys.len() == 1, 'invalid key len6');
    assert(*account_keys.at(0) == order_data_store_key4, 'invalid acc key10');

    let acount_key = data_store.get_account_key_index(account1, order_data_store_key4).unwrap();
    assert(acount_key.unwrap() == 0, 'invalid account key3');

    let key_index4 = data_store.get_key_index(order_data_store_key3).unwrap();
    assert(key_index4.unwrap() == 2, 'invalid key index5');

    // Last key moved to removed index
    let key_index = data_store.get_key_index(order_data_store_key4).unwrap();
    assert(key_index.unwrap() == 0, 'invalid key index5');
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
