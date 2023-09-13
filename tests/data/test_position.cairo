use starknet::{ContractAddress, contract_address_const};

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::position::position::Position;
use satoru::tests_lib::{setup, teardown};

use snforge_std::{PrintTrait, declare, start_prank, stop_prank, ContractClassTrait};

#[test]
fn test_set_position_new_and_override() {
    // Setup
    let (caller_address, role_store, data_store) = setup();

    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut position: Position = create_new_position(
        key,
        account,
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        position_no: 1
    );

    // Test logic

    // Test set_position function with a new key.
    data_store.set_position(key, position);

    let position_by_key = data_store.get_position(key).unwrap();
    assert(position_by_key == position, 'Invalid position by key');

    let position_count = data_store.get_position_count();
    assert(position_count == 1, 'Invalid key position count');

    let account_position_count = data_store.get_account_position_count(account);
    assert(account_position_count == 1, 'Invalid account position count');

    let account_position_keys = data_store.get_account_position_keys(account, 0, 10);
    assert(account_position_keys.len() == 1, 'Acc position # should be 1');

    // Update the position using the set_position function and then retrieve it to check the update was successful
    data_store.set_position(key, position);

    let position_by_key = data_store.get_position(key).unwrap();
    assert(position_by_key == position, 'Invalid position by key');

    let account_position_count = data_store.get_account_position_count(account);
    assert(account_position_count == 1, 'Invalid account position count');

    let position_count = data_store.get_position_count();
    assert(position_count == 1, 'Invalid key position count');

    let account_position_keys = data_store.get_account_position_keys(account, 0, 10);
    assert(account_position_keys.len() == 1, 'Acc position # should be 1');

    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('position account cant be 0',))]
fn test_set_position_should_panic_zero() {
    // Setup
    let (caller_address, role_store, data_store) = setup();

    let key: felt252 = 123456789;
    let account = 0.try_into().unwrap();
    let mut position: Position = create_new_position(
        key,
        account,
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        position_no: 1
    );

    // Test logic

    // Test set_position function with account 0
    data_store.set_position(key, position);

    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn test_set_position_should_panic_not_controller() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::CONTROLLER);

    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut position: Position = create_new_position(
        key,
        account,
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        position_no: 1
    );

    // Test logic

    // Test set_position function without permission
    data_store.set_position(key, position);

    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn test_get_position_keys() {
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::CONTROLLER);
    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut position: Position = create_new_position(
        key,
        account,
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        position_no: 1
    );

    data_store.set_position(key, position);

    // Given
    data_store.remove_position(key, account);

    // Then
    let position_by_key = data_store.get_position(key);
    assert(position_by_key.is_none(), 'position should be removed');

    let position_count = data_store.get_position_count();
    assert(position_count == 0, 'Invalid key position count');
    let account_position_count = data_store.get_account_position_count(account);
    assert(account_position_count == 0, 'Acc position # should be 0');
    let account_position_keys = data_store.get_account_position_keys(account, 0, 10);
    assert(account_position_keys.len() == 0, 'Acc position # not empty');

    teardown(data_store.contract_address);
}


#[test]
fn test_remove_only_position() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut position: Position = create_new_position(
        key,
        account,
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        position_no: 1
    );

    data_store.set_position(key, position);

    // Given
    data_store.remove_position(key, account);

    // Then
    let position_by_key = data_store.get_position(key);
    assert(position_by_key.is_none(), 'position should be removed');

    let position_count = data_store.get_position_count();
    assert(position_count == 0, 'Invalid key position count');

    let account_position_count = data_store.get_account_position_count(account);
    assert(account_position_count == 0, 'Acc position # should be 0');

    let account_position_keys = data_store.get_account_position_keys(account, 0, 10);
    assert(account_position_keys.len() == 0, 'Acc position # not empty');

    teardown(data_store.contract_address);
}


#[test]
fn test_remove_1_of_n_position() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let key_1: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut position_1: Position = create_new_position(
        key_1,
        account,
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        position_no: 1
    );

    let key_2: felt252 = 22222222222;
    let mut position_2: Position = create_new_position(
        key_2,
        account,
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        position_no: 1
    );

    data_store.set_position(key_1, position_1);
    data_store.set_position(key_2, position_2);

    let position_count = data_store.get_position_count();
    assert(position_count == 2, 'Invalid key position count');

    let account_position_count = data_store.get_account_position_count(account);
    assert(account_position_count == 2, 'Acc position # should be 2');
    // Given
    data_store.remove_position(key_1, account);

    // Then
    let position_1_by_key = data_store.get_position(key_1);
    assert(position_1_by_key.is_none(), 'position1 shouldnt be removed');

    let position_2_by_key = data_store.get_position(key_2);
    assert(position_2_by_key.is_some(), 'position2 shouldnt be removed');

    let position_count = data_store.get_position_count();
    assert(position_count == 1, 'position # should be 1');

    let account_position_count = data_store.get_account_position_count(account);
    assert(account_position_count == 1, 'Acc position # should be 1');

    let account_position_keys = data_store.get_account_position_keys(account, 0, 10);
    assert(account_position_keys.len() == 1, 'Acc position # not 1');

    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn test_remove_position_should_panic_not_controller() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    role_store.revoke_role(caller_address, role::CONTROLLER);
    let key: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut position: Position = create_new_position(
        key,
        account,
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        position_no: 1
    );

    data_store.set_position(key, position);

    // Given
    data_store.remove_position(key, account);

    // Then
    let position_by_key = data_store.get_position(key);
    assert(position_by_key.is_none(), 'position should be removed');
    let account_position_count = data_store.get_account_position_count(account);
    assert(account_position_count == 0, 'Acc position # should be 0');
    let account_position_keys = data_store.get_account_position_keys(account, 0, 10);
    assert(account_position_keys.len() == 0, 'Acc position # not empty');

    teardown(data_store.contract_address);
}


#[test]
fn test_multiple_account_keys() {
    // Setup

    let (caller_address, role_store, data_store) = setup();
    let key_1: felt252 = 123456789;
    let account = 'account'.try_into().unwrap();
    let mut position_1: Position = create_new_position(
        key_1,
        account,
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        position_no: 1
    );

    let key_2: felt252 = 22222222222;
    let account_2 = 'account2222'.try_into().unwrap();
    let mut position_2: Position = create_new_position(
        key_2,
        account_2,
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        position_no: 2
    );
    let key_3: felt252 = 3333344455667;
    let mut position_3: Position = create_new_position(
        key_3,
        account,
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        position_no: 1
    );
    let key_4: felt252 = 444445556777889;
    let mut position_4: Position = create_new_position(
        key_4,
        account,
        contract_address_const::<'market1'>(),
        contract_address_const::<'token1'>(),
        is_long: false,
        position_no: 1
    );

    data_store.set_position(key_1, position_1);
    data_store.set_position(key_2, position_2);
    data_store.set_position(key_3, position_3);
    data_store.set_position(key_4, position_4);

    let position_by_key3 = data_store.get_position(key_3).unwrap();
    assert(position_by_key3 == position_3, 'Invalid position by key3');

    let position_by_key4 = data_store.get_position(key_4).unwrap();
    assert(position_by_key4 == position_4, 'Invalid position by key4');

    let position_count = data_store.get_position_count();
    assert(position_count == 4, 'Invalid key position count');

    let account_position_count = data_store.get_account_position_count(account);
    assert(account_position_count == 3, 'Acc position # should be 3');

    let account_position_count2 = data_store.get_account_position_count(account_2);
    assert(account_position_count2 == 1, 'Acc2 position # should be 1');

    let position_keys = data_store.get_position_keys(0, 10);
    assert(position_keys.len() == 4, 'invalid key len');
    assert(position_keys.at(0) == @key_1, 'invalid key1');
    assert(position_keys.at(1) == @key_2, 'invalid key2');
    assert(position_keys.at(2) == @key_3, 'invalid key3');
    assert(position_keys.at(3) == @key_4, 'invalid key4');

    let position_keys2 = data_store.get_position_keys(1, 3);
    assert(position_keys2.len() == 2, '2:invalid key len');
    assert(position_keys2.at(0) == @key_2, '2:invalid key2');
    assert(position_keys2.at(1) == @key_3, '2:invalid key3');

    let account_keys = data_store.get_account_position_keys(account, 0, 10);
    assert(account_keys.len() == 3, '3:invalid key len');
    assert(account_keys.at(0) == @key_1, '3:invalid key1');
    assert(account_keys.at(1) == @key_3, '3:invalid key3');
    assert(account_keys.at(2) == @key_4, '3:invalid key4');

    let account_keys2 = data_store.get_account_position_keys(account_2, 0, 10);
    assert(account_keys2.len() == 1, '4:invalid key len');
    assert(account_keys2.at(0) == @key_2, '4:invalid key2');

    // Given
    data_store.remove_position(key_1, account);

    teardown(data_store.contract_address);
}

/// Utility function to create new Position  struct
fn create_new_position(
    key: felt252,
    account: ContractAddress,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    position_no: u128
) -> Position {
    let size_in_usd = 1000 * position_no;
    let size_in_tokens = 1000 * position_no;
    let collateral_amount = 1000 * position_no;
    let borrowing_factor = 10 * position_no;
    let funding_fee_amount_per_size = 10 * position_no;
    let long_token_claimable_funding_amount_per_size = 10 * position_no;
    let short_token_claimable_funding_amount_per_size = 10 * position_no;
    let increased_at_block = 1;
    let decreased_at_block = 2;

    // Create an position.
    Position {
        key,
        account,
        market,
        collateral_token,
        size_in_usd,
        size_in_tokens,
        collateral_amount,
        borrowing_factor,
        funding_fee_amount_per_size,
        long_token_claimable_funding_amount_per_size,
        short_token_claimable_funding_amount_per_size,
        increased_at_block,
        decreased_at_block,
        is_long,
    }
}

/// Utility function to assert position structs
/// This function will panic if any of the following fields do not match between the two positions:
/// # Arguments
///
/// * `position1` - First position struct 
/// * `position2` - Second position struct.
fn assert_position_eq(position1: @Position, position2: @Position) {
    assert(position1.account == position2.account, 'invalid account ');
    assert(position1.size_in_tokens == position2.size_in_tokens, 'invalid size_in_tokens ');
    assert(position1.collateral_token == position2.collateral_token, 'invalid collateral_token ');
    assert(position1.size_in_usd == position2.size_in_usd, 'invalid size_in_usd ');
    assert(position1.market == position2.market, 'invalid market ');
    assert(
        position1.collateral_amount == position2.collateral_amount, 'invalid collateral_amount '
    );

    assert(position1.borrowing_factor == position2.borrowing_factor, 'invalid borrowing_factor ');
    assert(
        position1.funding_fee_amount_per_size == position2.funding_fee_amount_per_size,
        'invalid funding_fee_amount '
    );
    assert(
        position1
            .long_token_claimable_funding_amount_per_size == position2
            .long_token_claimable_funding_amount_per_size,
        'invalid long_token_claimable '
    );
    assert(
        position1
            .short_token_claimable_funding_amount_per_size == position2
            .short_token_claimable_funding_amount_per_size,
        'invalid short_token_claimabl '
    );
    assert(
        position1.increased_at_block == position2.increased_at_block, 'invalid increased_at_block '
    );
    assert(
        position1.decreased_at_block == position2.decreased_at_block, 'invalid decreased_at_block '
    );
    assert(position1.is_long == position2.is_long, 'invalid is_long ');
}
