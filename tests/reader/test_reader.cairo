use starknet::{ContractAddress, contract_address_const};

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::reader::reader::{IReaderDispatcher, IReaderDispatcherTrait};

use satoru::role::role;
use satoru::order::order::{Order, OrderType, OrderTrait, DecreasePositionSwapType};
use satoru::tests_lib::{setup, teardown};
use satoru::utils::span32::{Span32, Array32Trait};
use satoru::market::market::{Market};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};
use poseidon::poseidon_hash_span;
use satoru::deposit::deposit::{Deposit};
use satoru::withdrawal::withdrawal::{Withdrawal};
use satoru::position::position::{Position};
use satoru::data::keys;
use satoru::price::price::{Price, PriceTrait};
use satoru::utils::i128::{i128, i128_new};

#[test]
fn given_normal_conditions_when_get_market_then_works() {
    //
    // Setup
    //
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();

    let key: ContractAddress = 123456789.try_into().unwrap();
    let mut market = Market {
        market_token: key,
        index_token: 11111.try_into().unwrap(),
        long_token: 22222.try_into().unwrap(),
        short_token: 33333.try_into().unwrap(),
    };
    start_prank(role_store.contract_address, caller_address);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);
    stop_prank(role_store.contract_address);

    // Test logic

    data_store.set_market(key, 0, market);

    let market_by_key = reader.get_market(data_store, key);
    assert(market_by_key == market, 'Invalid market by key');

    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_get_market_by_salt_then_works() {
    //
    // Setup
    //
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();

    let key: ContractAddress = 123456789.try_into().unwrap();
    let mut market = Market {
        market_token: key,
        index_token: 11111.try_into().unwrap(),
        long_token: 22222.try_into().unwrap(),
        short_token: 33333.try_into().unwrap(),
    };
    let key2: ContractAddress = 222222222222.try_into().unwrap();

    let mut market2 = Market {
        market_token: key,
        index_token: 12345.try_into().unwrap(),
        long_token: 56678.try_into().unwrap(),
        short_token: 8901234.try_into().unwrap(),
    };

    start_prank(role_store.contract_address, caller_address);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);
    stop_prank(role_store.contract_address);

    let salt: felt252 = 'satoru_market';
    let salt2: felt252 = 'satoru_market2';

    // Test logic

    data_store.set_market(key, salt, market);
    data_store.set_market(key2, salt2, market2);

    let market_by_key = reader.get_market_by_salt(data_store, salt);
    assert(market_by_key == market, 'Invalid market by key');

    let market_by_key2 = reader.get_market_by_salt(data_store, salt2);
    assert(market_by_key2 == market2, 'Invalid market2 by key');

    teardown(data_store.contract_address);
}


#[test]
fn given_normal_conditions_when_get_deposit_then_works() {
    //
    // Setup
    //
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();

    let key = 123456789;
    // Create random deposit
    let mut deposit: Deposit = Default::default();
    deposit.key = 123456789;
    deposit.account = 'account'.try_into().unwrap();
    deposit.receiver = 'receiver'.try_into().unwrap();
    deposit.initial_long_token_amount = 1000000;
    deposit.initial_short_token_amount = 2222222;

    // Test logic

    data_store.set_deposit(key, deposit);

    let deposit_by_key = reader.get_deposit(data_store, key);
    assert(deposit_by_key == deposit, 'Invalid deposit by key');

    teardown(data_store.contract_address);
}


#[test]
fn given_normal_conditions_when_get_withdrawal_then_works() {
    //
    // Setup
    //
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();

    let key = 123456789;
    // Create random withdrawal
    let mut withdrawal: Withdrawal = Default::default();
    withdrawal.key = 123456789;
    withdrawal.account = 'account'.try_into().unwrap();
    withdrawal.receiver = 'receiver'.try_into().unwrap();
    withdrawal.market_token_amount = 1000000;
    withdrawal.min_short_token_amount = 2222222;

    // Test logic

    data_store.set_withdrawal(key, withdrawal);

    let withdrawal_by_key = reader.get_withdrawal(data_store, key);
    assert(withdrawal_by_key == withdrawal, 'Invalid withdrawal by key');

    teardown(data_store.contract_address);
}


#[test]
fn given_normal_conditions_when_get_position_then_works() {
    //
    // Setup
    //
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();
    let key = 123456789;
    // Create random position
    let mut position: Position = Default::default();
    position.key = 123456789;
    position.account = 'account'.try_into().unwrap();
    position.market = 'market'.try_into().unwrap();
    position.size_in_usd = 1000000;
    position.funding_fee_amount_per_size = 3333333333;

    // Test logic

    data_store.set_position(key, position);

    let position_by_key = reader.get_position(data_store, key);
    assert(position_by_key == position, 'Invalid position by key');

    teardown(data_store.contract_address);
}


#[test]
fn given_normal_conditions_when_get_order_then_works() {
    //
    // Setup
    //
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();

    let key = 123456789;
    // Create random order
    let mut order: Order = Default::default();
    order.key = 123456789;
    order.account = 'account'.try_into().unwrap();
    order.market = 'market'.try_into().unwrap();
    order.trigger_price = 1000000;
    order.callback_gas_limit = 3333333333;

    // Test logic

    data_store.set_order(key, order);

    let order_by_key = reader.get_order(data_store, key);
    assert(order_by_key == order, 'Invalid order by key');

    teardown(data_store.contract_address);
}

//TODO missing libraries market_utils::get_capped_pnl not implemented 
//fn given_normal_conditions_when_get_position_pnl_usd_then_works() 

#[test]
fn given_normal_conditions_when_get_account_positions_then_works() {
    //
    // Setup
    //
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();

    let key_1 = 1111111111;
    let account = 'account'.try_into().unwrap();
    // Create random position
    let mut position1: Position = Default::default();
    position1.key = key_1;
    position1.market = 'market1'.try_into().unwrap();
    position1.size_in_usd = 1000000;
    position1.account = account;

    let key_2 = 22222222222;
    let mut position2: Position = Default::default();
    position2.key = key_2;
    position2.market = 'market2'.try_into().unwrap();
    position2.size_in_usd = 2000000;
    position2.account = account;

    let key_3 = 33333333333;
    let mut position3: Position = Default::default();
    position3.key = key_3;
    position3.market = 'market3'.try_into().unwrap();
    position3.size_in_usd = 3000000;
    position3.account = account;

    let key_4 = 44444444444;
    let mut position4: Position = Default::default();
    position4.key = key_4;
    position4.market = 'market4'.try_into().unwrap();
    position4.size_in_usd = 4000000;
    position4.account = account;

    // Test logic

    data_store.set_position(key_1, position1);
    data_store.set_position(key_2, position2);
    data_store.set_position(key_3, position3);
    data_store.set_position(key_4, position4);

    let account_position = reader.get_account_positions(data_store, account, 0, 10);
    assert(account_position.len() == 4, 'invalid position len');
    assert(account_position.at(0) == @position1, 'invalid position1');
    assert(account_position.at(1) == @position2, 'invalid position2');
    assert(account_position.at(2) == @position3, 'invalid position3');
    assert(account_position.at(3) == @position4, 'invalid position4');

    teardown(data_store.contract_address);
}

//TODO missing libraries reader_utils::get_position_info not implemented 
//fn given_normal_conditions_when_get_position_info_then_works() 

//TODO missing libraries reader_utils::get_position_info not implemented 
//fn given_normal_conditions_when_get_account_position_info_list_then_works() 

#[test]
fn given_normal_conditions_when_get_account_orders_then_works() {
    //
    // Setup
    //
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();

    let key_1 = 1111111111;
    let account = 'account'.try_into().unwrap();
    // Create random order
    let mut order1: Order = Default::default();
    order1.key = key_1;
    order1.market = 'market1'.try_into().unwrap();
    order1.size_delta_usd = 1000000;
    order1.account = account;

    let key_2 = 22222222222;
    let mut order2: Order = Default::default();
    order2.key = key_2;
    order2.market = 'market2'.try_into().unwrap();
    order2.size_delta_usd = 2000000;
    order2.account = account;

    let key_3 = 33333333333;
    let mut order3: Order = Default::default();
    order3.key = key_3;
    order3.market = 'market3'.try_into().unwrap();
    order3.size_delta_usd = 3000000;
    order3.account = account;

    let key_4 = 44444444444;
    let mut order4: Order = Default::default();
    order4.key = key_4;
    order4.market = 'market4'.try_into().unwrap();
    order4.size_delta_usd = 4000000;
    order4.account = account;

    // Test logic

    data_store.set_order(key_1, order1);
    data_store.set_order(key_2, order2);
    data_store.set_order(key_3, order3);
    data_store.set_order(key_4, order4);

    let account_order = reader.get_account_orders(data_store, account, 0, 10);
    assert(account_order.len() == 4, 'invalid order len');
    assert(account_order.at(0) == @order1, 'invalid order1');
    assert(account_order.at(1) == @order2, 'invalid order2');
    assert(account_order.at(2) == @order3, 'invalid order3');
    assert(account_order.at(3) == @order4, 'invalid order4');

    teardown(data_store.contract_address);
}


#[test]
fn given_normal_conditions_when_get_markets_then_works() {
    //
    // Setup
    //
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();

    let key_1: ContractAddress = 1111111111.try_into().unwrap();
    let key_2: ContractAddress = 22222222222.try_into().unwrap();
    let key_3: ContractAddress = 33333333333.try_into().unwrap();
    let key_4: ContractAddress = 44444444444.try_into().unwrap();
    // Create random market
    let mut market1: Market = Default::default();
    market1.market_token = key_1;
    market1.index_token = 'index1'.try_into().unwrap();

    let mut market2: Market = Default::default();
    market2.market_token = key_2;
    market2.index_token = 'index2'.try_into().unwrap();

    let mut market3: Market = Default::default();
    market3.market_token = key_3;
    market3.index_token = 'index3'.try_into().unwrap();

    let mut market4: Market = Default::default();
    market4.market_token = key_4;
    market4.index_token = 'index4'.try_into().unwrap();

    start_prank(role_store.contract_address, caller_address);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);
    stop_prank(role_store.contract_address);

    // Test logic

    data_store.set_market(key_1, 1, market1);
    data_store.set_market(key_2, 2, market2);
    data_store.set_market(key_3, 3, market3);
    data_store.set_market(key_4, 4, market4);

    let markets = reader.get_markets(data_store, 0, 10);
    assert(markets.len() == 4, 'invalid market len');
    assert(markets.at(0) == @market1, 'invalid market1');
    assert(markets.at(1) == @market2, 'invalid market2');
    assert(markets.at(2) == @market3, 'invalid market3');
    assert(markets.at(3) == @market4, 'invalid market4');

    teardown(data_store.contract_address);
}

// TODO missing libraries  'market_utils::get_borrowing_factor_per_second', 'reader_utils::get_base_funding_values' not implemented 
//fn given_normal_conditions_when_get_market_info_then_works() 

// TODO missing libraries  'market_utils::get_borrowing_factor_per_second', 'reader_utils::get_base_funding_values' not implemented 
//fn given_normal_conditions_when_get_market_info_list_then_works() 

// TODO missing libraries  'market_utils::get_market_token_price' not implemented 
//fn given_normal_conditions_when_get_market_token_price_then_works() 

// TODO missing libraries  'market_utils::get_net_pnl' not implemented 
//fn given_normal_conditions_when_get_net_pnl_then_works() 

#[test]
fn given_normal_conditions_when_get_pnl_then_works() {
    //
    // Setup
    //
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();

    let market_token_address = contract_address_const::<'market_token'>();
    let market = Market {
        market_token: market_token_address,
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };
    let is_long = true;
    let maximize = true;
    let price = Price { min: 10, max: 50 };

    // Test logic

    // Set open interest for long token.
    let open_interest_key_for_long = keys::open_interest_key(
        market_token_address, market.long_token, is_long
    );
    data_store.set_u128(open_interest_key_for_long, 100);
    // Set open interest for short token.
    let open_interest_key_for_short = keys::open_interest_key(
        market_token_address, market.short_token, is_long
    );
    data_store.set_u128(open_interest_key_for_short, 150);

    // Set open interest in tokens for long token.
    let open_interest_in_tokens_key_for_long = keys::open_interest_in_tokens_key(
        market_token_address, market.long_token, is_long
    );
    data_store.set_u128(open_interest_in_tokens_key_for_long, 200);

    // Set open interest in tokens for short token.
    let open_interest_in_tokens_key_for_short = keys::open_interest_in_tokens_key(
        market_token_address, market.short_token, is_long
    );
    data_store.set_u128(open_interest_in_tokens_key_for_short, 250);

    // Actual test case.
    let pnl = reader.get_pnl(data_store, market, price, is_long, maximize);

    // Perform assertions.
    assert(pnl == i128_new(22250, false), 'wrong pnl');

    teardown(data_store.contract_address);
}
// TODO missing libraries  'market_utils::get_open_interest_with_pnl' not implemented 
//fn given_normal_conditions_when_get_open_interest_with_pnl_then_works() 

// TODO missing libraries  'market_utils::get_pnl_to_pool_factor' not implemented 
//fn given_normal_conditions_when_get_pnl_to_pool_factor_then_works() 

// TODO missing libraries reader_pricing_utils::get_swap_amount_out  use not implemented functions
//fn given_normal_conditions_when_get_swap_amount_out_then_works() {

// TODO missing libraries 'market_utils::get_virtual_inventory_for_swaps' and 'market_utils::get_virtual_inventory_for_positions' not implemented 
//fn given_normal_conditions_when_get_virtual_inventory_then_works() {

// TODO missing libraries 'increase_position_utils::get_execution_price' and 'decrease_position_collateral_utils::get_execution_price' not implemented 
//fn given_normal_conditions_when_get_execution_price_then_works() {

// TODO missing libraries 'swap_pricing_utils::get_price_impact_usd' and 'market_utils::get_swap_impact_amount_with_cap' not implemented 
//fn given_normal_conditions_when_get_swap_price_impact_then_works() {

// TODO missing libraries 'market_utils::is_pnl_factor_exceeded_direct' and 'market_utils::get_enabled_market' not implemented 
//fn given_normal_conditions_when_get_adl_state_then_works() {

// *************************************************************************
//                          SETUP READER
// *************************************************************************

fn setup_reader() -> (ContractAddress, IReaderDispatcher) {
    let contract = declare('Reader');
    let reader_address = contract.deploy(@array![]).unwrap();
    let reader = IReaderDispatcher { contract_address: reader_address };
    (reader_address, reader)
}
