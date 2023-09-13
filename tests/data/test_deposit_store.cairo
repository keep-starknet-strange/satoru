use starknet::{ContractAddress, contract_address_const};

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::deposit::deposit::Deposit;
use satoru::tests_lib::teardown;
use satoru::utils::span32::{Span32, Array32Trait};

use snforge_std::{PrintTrait, declare, start_prank, stop_prank, ContractClassTrait};

/// Utility function to deploy a `DataStore` contract and return its dispatcher.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a `RoleStore` contract and return its dispatcher.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@array![]).unwrap()
}


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IDataStoreDispatcher` - The data store dispatcher.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
fn setup() -> (ContractAddress, IRoleStoreDispatcher, IDataStoreDispatcher) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    (caller_address, role_store, data_store)
}

#[test]
fn test_set_deposit_new_and_override() {
    // Setup
    let (caller_address, role_store, data_store) = setup();

    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut deposit: Deposit = create_new_deposit(
        key,
        account,
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        deposit_no: 1
    );

    // Test logic

    // Test set_deposit function with a new key.
    data_store.set_deposit(key, deposit);

    let deposit_by_key = data_store.get_deposit(key).unwrap();
    assert(deposit_by_key == deposit, 'Invalid deposit by key');

    let deposit_count = data_store.get_deposit_count();
    assert(deposit_count == 1, 'Invalid key deposit count');

    let account_deposit_count = data_store.get_account_deposit_count(account);
    assert(account_deposit_count == 1, 'Invalid account deposit count');

    let account_deposit_keys = data_store.get_account_deposit_keys(account, 0, 10);
    assert(account_deposit_keys.len() == 1, 'Acc deposit # should be 1');

    // Update the deposit using the set_deposit function and then retrieve it to check the update was successful
    let market = 'market'.try_into().unwrap();
    deposit.market = market;
    data_store.set_deposit(key, deposit);

    let deposit_by_key = data_store.get_deposit(key).unwrap();
    assert(deposit_by_key == deposit, 'Invalid deposit by key');

    let account_deposit_count = data_store.get_account_deposit_count(account);
    assert(account_deposit_count == 1, 'Invalid account deposit count');

    let deposit_count = data_store.get_deposit_count();
    assert(deposit_count == 1, 'Invalid key deposit count');

    let account_deposit_keys = data_store.get_account_deposit_keys(account, 0, 10);
    assert(account_deposit_keys.len() == 1, 'Acc deposit # should be 1');

    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('deposit account cant be 0',))]
fn test_set_deposit_should_panic_zero() {
    // Setup
    let (caller_address, role_store, data_store) = setup();

    let key: felt252 = 123456789;
    let account = 0.try_into().unwrap();
    let mut deposit: Deposit = create_new_deposit(
        key,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        deposit_no: 1
    );

    // Test logic

    // Test set_deposit function with account 0
    data_store.set_deposit(key, deposit);

    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn test_set_deposit_should_panic_not_controller() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::CONTROLLER);

    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut deposit: Deposit = create_new_deposit(
        key,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        deposit_no: 1
    );

    // Test logic

    // Test set_deposit function without permission
    data_store.set_deposit(key, deposit);

    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn test_get_deposit_keys() {
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::CONTROLLER);
    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut deposit: Deposit = create_new_deposit(
        key,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        deposit_no: 1
    );

    data_store.set_deposit(key, deposit);

    // Given
    data_store.remove_deposit(key, account);

    // Then
    let deposit_by_key = data_store.get_deposit(key);
    assert(deposit_by_key.is_none(), 'deposit should be removed');

    let deposit_count = data_store.get_deposit_count();
    assert(deposit_count == 0, 'Invalid key deposit count');
    let account_deposit_count = data_store.get_account_deposit_count(account);
    assert(account_deposit_count == 0, 'Acc deposit # should be 0');
    let account_deposit_keys = data_store.get_account_deposit_keys(account, 0, 10);
    assert(account_deposit_keys.len() == 0, 'Acc withdraw # not empty');

    teardown(data_store.contract_address);
}


#[test]
fn test_remove_only_deposit() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut deposit: Deposit = create_new_deposit(
        key,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        deposit_no: 1
    );

    data_store.set_deposit(key, deposit);

    // Given
    data_store.remove_deposit(key, account);

    // Then
    let deposit_by_key = data_store.get_deposit(key);
    assert(deposit_by_key.is_none(), 'deposit should be removed');

    let deposit_count = data_store.get_deposit_count();
    assert(deposit_count == 0, 'Invalid key deposit count');

    let account_deposit_count = data_store.get_account_deposit_count(account);
    assert(account_deposit_count == 0, 'Acc deposit # should be 0');

    let account_deposit_keys = data_store.get_account_deposit_keys(account, 0, 10);
    assert(account_deposit_keys.len() == 0, 'Acc withdraw # not empty');

    teardown(data_store.contract_address);
}


#[test]
fn test_remove_1_of_n_deposit() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let key_1: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut deposit_1: Deposit = create_new_deposit(
        key_1,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        deposit_no: 1
    );

    let key_2: felt252 = 22222222222;

    let mut deposit_2: Deposit = create_new_deposit(
        key_2,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        deposit_no: 1
    );

    data_store.set_deposit(key_1, deposit_1);
    data_store.set_deposit(key_2, deposit_2);

    let deposit_count = data_store.get_deposit_count();
    assert(deposit_count == 2, 'Invalid key deposit count');

    let account_deposit_count = data_store.get_account_deposit_count(account);
    assert(account_deposit_count == 2, 'Acc deposit # should be 2');
    // Given
    data_store.remove_deposit(key_1, account);

    // Then
    let deposit_1_by_key = data_store.get_deposit(key_1);
    assert(deposit_1_by_key.is_none(), 'deposit1 shouldnt be removed');

    let deposit_2_by_key = data_store.get_deposit(key_2);
    assert(deposit_2_by_key.is_some(), 'deposit2 shouldnt be removed');

    let deposit_count = data_store.get_deposit_count();
    assert(deposit_count == 1, 'deposit # should be 1');

    let account_deposit_count = data_store.get_account_deposit_count(account);
    assert(account_deposit_count == 1, 'Acc deposit # should be 1');

    let account_deposit_keys = data_store.get_account_deposit_keys(account, 0, 10);
    assert(account_deposit_keys.len() == 1, 'Acc withdraw # not 1');

    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn test_remove_deposit_should_panic_not_controller() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::CONTROLLER);
    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut deposit: Deposit = create_new_deposit(
        key,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        deposit_no: 1
    );

    data_store.set_deposit(key, deposit);

    // Given
    data_store.remove_deposit(key, account);

    // Then
    let deposit_by_key = data_store.get_deposit(key);
    assert(deposit_by_key.is_none(), 'deposit should be removed');
    let account_deposit_count = data_store.get_account_deposit_count(account);
    assert(account_deposit_count == 0, 'Acc deposit # should be 0');
    let account_deposit_keys = data_store.get_account_deposit_keys(account, 0, 10);
    assert(account_deposit_keys.len() == 0, 'Acc withdraw # not empty');

    teardown(data_store.contract_address);
}

#[test]
fn test_multiple_account_keys() {
    // Setup

    let (caller_address, role_store, data_store) = setup();
    let key_1: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut deposit_1: Deposit = create_new_deposit(
        key_1,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        deposit_no: 1
    );

    let key_2: felt252 = 22222222222;
    let account_2 = 'account2222'.try_into().unwrap();
    let mut deposit_2: Deposit = create_new_deposit(
        key_2,
        account_2,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        deposit_no: 2
    );
    let key_3: felt252 = 3333344455667;
    let mut deposit_3: Deposit = create_new_deposit(
        key_3,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        deposit_no: 3
    );
    let key_4: felt252 = 444445556777889;
    let mut deposit_4: Deposit = create_new_deposit(
        key_4,
        account,
        contract_address_const::<'receiver1'>(),
        contract_address_const::<'market1'>(),
        deposit_no: 4
    );

    data_store.set_deposit(key_1, deposit_1);
    data_store.set_deposit(key_2, deposit_2);
    data_store.set_deposit(key_3, deposit_3);
    data_store.set_deposit(key_4, deposit_4);

    let deposit_by_key3 = data_store.get_deposit(key_3).unwrap();
    assert(deposit_by_key3 == deposit_3, 'Invalid deposit by key3');

    let deposit_by_key4 = data_store.get_deposit(key_4).unwrap();
    assert(deposit_by_key4 == deposit_4, 'Invalid deposit by key4');

    let deposit_count = data_store.get_deposit_count();
    assert(deposit_count == 4, 'Invalid key deposit count');

    let account_deposit_count = data_store.get_account_deposit_count(account);
    assert(account_deposit_count == 3, 'Acc deposit # should be 3');

    let account_deposit_count2 = data_store.get_account_deposit_count(account_2);
    assert(account_deposit_count2 == 1, 'Acc2 deposit # should be 1');

    let deposit_keys = data_store.get_deposit_keys(0, 10);
    assert(deposit_keys.len() == 4, 'invalid key len');
    assert(deposit_keys.at(0) == @key_1, 'invalid key1');
    assert(deposit_keys.at(1) == @key_2, 'invalid key2');
    assert(deposit_keys.at(2) == @key_3, 'invalid key3');
    assert(deposit_keys.at(3) == @key_4, 'invalid key4');

    let deposit_keys2 = data_store.get_deposit_keys(1, 3);
    assert(deposit_keys2.len() == 2, '2:invalid key len');
    assert(deposit_keys2.at(0) == @key_2, '2:invalid key2');
    assert(deposit_keys2.at(1) == @key_3, '2:invalid key3');

    let account_keys = data_store.get_account_deposit_keys(account, 0, 10);
    assert(account_keys.len() == 3, '3:invalid key len');
    assert(account_keys.at(0) == @key_1, '3:invalid key1');
    assert(account_keys.at(1) == @key_3, '3:invalid key3');
    assert(account_keys.at(2) == @key_4, '3:invalid key4');

    let account_keys2 = data_store.get_account_deposit_keys(account_2, 0, 10);
    assert(account_keys2.len() == 1, '4:invalid key len');
    assert(account_keys2.at(0) == @key_2, '4:invalid key2');

    // Given
    data_store.remove_deposit(key_1, account);

    teardown(data_store.contract_address);
}

/// Utility function to create new Deposit struct
fn create_new_deposit(
    key: felt252,
    account: ContractAddress,
    receiver: ContractAddress,
    market: ContractAddress,
    deposit_no: u128,
) -> Deposit {
    let callback_contract = contract_address_const::<'callback_contract'>();
    let ui_fee_receiver = contract_address_const::<'ui_fee_receiver'>();

    let initial_long_token = contract_address_const::<'initial_long_token'>();
    let initial_short_token = contract_address_const::<'initial_short_token'>();

    let long_token_swap_path: Span32<ContractAddress> = array![
        contract_address_const::<'long_token_swap_path_0'>(), contract_address_const::<'long_token_swap_path_1'>()
    ]
        .span32();

    let short_token_swap_path: Span32<ContractAddress> = array![
        contract_address_const::<'short_token_swap_path_0'>(), contract_address_const::<'short_token_swap_path_1'>()
    ]
        .span32();

    let initial_long_token_amount = 1000 * deposit_no;
    let initial_short_token_amount = 1000 * deposit_no;

    let min_market_tokens = 10 * deposit_no;
    let updated_at_block = 1;

    let execution_fee = 10 * deposit_no.into();
    let callback_gas_limit = 300000;

    // Create an deposit.
    Deposit {
        key,
        account,
        receiver,
        callback_contract,
        ui_fee_receiver,
        market,
        initial_long_token,
        initial_short_token,
        long_token_swap_path,
        short_token_swap_path,
        initial_long_token_amount,
        initial_short_token_amount,
        min_market_tokens,
        updated_at_block,
        execution_fee,
        callback_gas_limit
    }
}
