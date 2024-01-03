use starknet::{ContractAddress, contract_address_const};
use debug::PrintTrait;

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::reader::reader::{IReaderDispatcher, IReaderDispatcherTrait, MarketInfo};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::market::market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait};
use satoru::tests_lib::{deploy_data_store, deploy_role_store, setup_oracle_and_store};

use satoru::reader::{
    reader_utils::PositionInfo, reader_utils::BaseFundingValues,
    reader_pricing_utils::ExecutionPriceResult, reader::VirtualInventory
};
use satoru::role::role;
use satoru::order::order::{Order, OrderType, OrderTrait, DecreasePositionSwapType};
use satoru::tests_lib::{setup, teardown};
use satoru::utils::span32::{Span32, Array32Trait};
use satoru::market::market::{Market};
use satoru::market::market_pool_value_info::{MarketPoolValueInfo};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};
use poseidon::poseidon_hash_span;
use satoru::deposit::deposit::{Deposit};
use satoru::withdrawal::withdrawal::{Withdrawal};
use satoru::position::position::{Position};
use satoru::data::keys;
use satoru::price::price::{Price, PriceTrait};
use satoru::utils::i128::{i128, i128_new};
use satoru::market::market_utils::{get_capped_pnl, MarketPrices};


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


#[test]
fn given_normal_conditions_when_get_position_pnl_usd_then_works() {
    //
    // Setup
    //
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();

    let key: ContractAddress = 123456789.try_into().unwrap();
    let account = 'account'.try_into().unwrap();
    let market = Market {
        market_token: key,
        index_token: 12345.try_into().unwrap(),
        long_token: 56678.try_into().unwrap(),
        short_token: 8901234.try_into().unwrap(),
    };
    let price1 = Price { min: 1, max: 200 };
    let price2 = Price { min: 1, max: 300 };
    let price3 = Price { min: 1, max: 400 };
    //create random prices
    let prices = MarketPrices {
        index_token_price: price1, long_token_price: price2, short_token_price: price3
    };
    // Create random position
    let key_1 = 1234311;
    let mut position: Position = Default::default();
    position.key = 1234311;
    position.market = 'market'.try_into().unwrap();
    position.size_in_usd = 1000000;
    position.account = account;
    position.is_long = true;
    position.size_in_tokens = 10000;

    start_prank(role_store.contract_address, caller_address);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);
    stop_prank(role_store.contract_address);

    //test logic

    data_store.set_market(key, 1, market);
    data_store.set_position(key_1, position);

    let (data1, data2, data3) = reader
        .get_position_pnl_usd(data_store, market, prices, key_1, 1000000);
    let data3_felt: felt252 = data3.into();

    assert(data3_felt == 10000, 'Invalid');
    teardown(data_store.contract_address);
}


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

// error `Option::unwrap()` on a `None` value
// #[test]
// fn given_normal_conditions_when_get_position_info_then_works() {
//     let (caller_address, role_store, data_store) = setup();
//     let (reader_address, reader) = setup_reader();
//     let (referral_storage_address, referral) = setup_referral_storage();
//     //create random position
//     let key_4: felt252 = 44444444444;
//     let mut position: Position = Default::default();
//     position.key = key_4;
//     position.market = 'market4'.try_into().unwrap();
//     position.size_in_usd = 4000000;
//     position.account = 'account'.try_into().unwrap();
//     position.is_long = true;
//     position.size_in_tokens = 10000;

//     let key: ContractAddress = 123456789.try_into().unwrap();
//     let ui_fee_receiver: ContractAddress = 5746789.try_into().unwrap();
//     let market = Market {
//         market_token: key,
//         index_token: 12345.try_into().unwrap(),
//         long_token: 56678.try_into().unwrap(),
//         short_token: 8901234.try_into().unwrap(),
//     };
//     let price1 = Price { min: 1, max: 200 };
//     let price2 = Price { min: 1, max: 300 };
//     let price3 = Price { min: 1, max: 400 };
//     //create random prices
//     let prices = MarketPrices {
//         index_token_price: price1, long_token_price: price2, short_token_price: price3
//     };
//     start_prank(role_store.contract_address, caller_address);
//     role_store.grant_role(caller_address, role::MARKET_KEEPER);
//     stop_prank(role_store.contract_address);

//     data_store.set_market(key, 1, market);
//     data_store.set_position(key_4, position);

//     let size_delta: u128 = 1000000;
//     let res: PositionInfo = reader
//         .get_position_info(data_store, referral, key_4, prices, size_delta, ui_fee_receiver, true);
//     // assert(res.position.key == 44444444444, 'wrong_key');
//     teardown(data_store.contract_address);
// }

#[test]
fn given_normal_conditions_when_get_account_position_info_list_then_works() {
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();
    let (referral_storage_address, referral) = setup_referral_storage();
    //create random position
    let key_1: felt252 = 44444444444;
    let mut position1: Position = Default::default();
    position1.key = key_1;
    position1.market = 'market1'.try_into().unwrap();
    position1.size_in_usd = 4000000;
    position1.account = 'account1'.try_into().unwrap();
    position1.is_long = true;
    position1.size_in_tokens = 10000;

    let key_2: felt252 = 3333333333;
    let mut position2: Position = Default::default();
    position2.key = key_2;
    position2.market = 'market2'.try_into().unwrap();
    position2.size_in_usd = 3000000;
    position2.account = 'account2'.try_into().unwrap();
    position2.is_long = true;
    position2.size_in_tokens = 10000;

    let key_3: felt252 = 2222222222;
    let mut position3: Position = Default::default();
    position3.key = key_3;
    position3.market = 'market3'.try_into().unwrap();
    position3.size_in_usd = 3000000;
    position3.account = 'account3'.try_into().unwrap();
    position3.is_long = true;
    position3.size_in_tokens = 10000;

    let ui_fee_receiver: ContractAddress = 5746789.try_into().unwrap();
    let market_key_1: ContractAddress = 123456789.try_into().unwrap();
    let market_1 = Market {
        market_token: market_key_1,
        index_token: 12345.try_into().unwrap(),
        long_token: 56678.try_into().unwrap(),
        short_token: 8901234.try_into().unwrap(),
    };
    let market_key_2: ContractAddress = 67545356789.try_into().unwrap();
    let market_2 = Market {
        market_token: market_key_2,
        index_token: 122145.try_into().unwrap(),
        long_token: 236678.try_into().unwrap(),
        short_token: 34201234.try_into().unwrap(),
    };
    let market_key_3: ContractAddress = 67545356789.try_into().unwrap();
    let market_3 = Market {
        market_token: market_key_3,
        index_token: 222145.try_into().unwrap(),
        long_token: 536678.try_into().unwrap(),
        short_token: 671234.try_into().unwrap(),
    };

    let price1 = Price { min: 1, max: 200 };
    let price2 = Price { min: 1, max: 300 };
    let price3 = Price { min: 1, max: 400 };
    //create random prices
    let prices_1 = MarketPrices {
        index_token_price: price1, long_token_price: price2, short_token_price: price3
    };
    let prices_2 = MarketPrices {
        index_token_price: price3, long_token_price: price2, short_token_price: price1
    };

    let prices_3 = MarketPrices {
        index_token_price: price2, long_token_price: price1, short_token_price: price3
    };

    start_prank(role_store.contract_address, caller_address);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);
    stop_prank(role_store.contract_address);

    data_store.set_market(market_key_1, 1, market_1);
    data_store.set_market(market_key_2, 2, market_2);
    data_store.set_market(market_key_3, 3, market_3);

    data_store.set_position(key_1, position1);
    data_store.set_position(key_2, position2);
    data_store.set_position(key_3, position3);

    let mut position_key_arr = ArrayTrait::<felt252>::new();
    position_key_arr.append(key_1);
    position_key_arr.append(key_2);
    position_key_arr.append(key_3);

    let mut prices_arr = ArrayTrait::<MarketPrices>::new();
    prices_arr.append(prices_1);
    prices_arr.append(prices_2);
    prices_arr.append(prices_3);

    let mut res_arr: Array<PositionInfo> = reader
        .get_account_position_info_list(
            data_store, referral, position_key_arr, prices_arr, ui_fee_receiver
        );
    assert(*res_arr.at(0).position.key == key_1, 'invalid_key');
    assert(*res_arr.at(1).position.key == key_2, 'invalid_key');
    assert(*res_arr.at(2).position.key == key_3, 'invalid_key');
}

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

#[test]
fn given_normal_conditions_when_get_market_info_then_works() {
    //
    // Setup
    //
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();

    let key: ContractAddress = 123456789.try_into().unwrap();

    let market = Market {
        market_token: key,
        index_token: 12345.try_into().unwrap(),
        long_token: 56678.try_into().unwrap(),
        short_token: 8901234.try_into().unwrap(),
    };
    let price1 = Price { min: 1, max: 200 };
    let price2 = Price { min: 1, max: 300 };
    let price3 = Price { min: 1, max: 400 };
    //create random prices
    let prices = MarketPrices {
        index_token_price: price1, long_token_price: price2, short_token_price: price3
    };

    start_prank(role_store.contract_address, caller_address);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);
    stop_prank(role_store.contract_address);

    data_store.set_market(key, 1, market);
    data_store.set_bool(keys::is_market_disabled_key(key), true);

    let res: MarketInfo = reader.get_market_info(data_store, prices, key);
    assert(res.market.market_token == key, 'invalid_info');
    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_get_market_info_list_then_works() {
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();

    let market_key_1: ContractAddress = 123456789.try_into().unwrap();
    let market_1 = Market {
        market_token: market_key_1,
        index_token: 12345.try_into().unwrap(),
        long_token: 56678.try_into().unwrap(),
        short_token: 8901234.try_into().unwrap(),
    };
    let market_key_2: ContractAddress = 67545356789.try_into().unwrap();
    let market_2 = Market {
        market_token: market_key_2,
        index_token: 122145.try_into().unwrap(),
        long_token: 236678.try_into().unwrap(),
        short_token: 34201234.try_into().unwrap(),
    };
    let market_key_3: ContractAddress = 67545356789.try_into().unwrap();
    let market_3 = Market {
        market_token: market_key_3,
        index_token: 222145.try_into().unwrap(),
        long_token: 536678.try_into().unwrap(),
        short_token: 671234.try_into().unwrap(),
    };

    let price1 = Price { min: 1, max: 200 };
    let price2 = Price { min: 1, max: 300 };
    let price3 = Price { min: 1, max: 400 };
    //create random prices
    let prices_1 = MarketPrices {
        index_token_price: price1, long_token_price: price2, short_token_price: price3
    };
    let prices_2 = MarketPrices {
        index_token_price: price3, long_token_price: price2, short_token_price: price1
    };

    let prices_3 = MarketPrices {
        index_token_price: price2, long_token_price: price1, short_token_price: price3
    };

    start_prank(role_store.contract_address, caller_address);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);
    stop_prank(role_store.contract_address);

    data_store.set_market(market_key_1, 0, market_1);
    data_store.set_market(market_key_2, 1, market_2);
    data_store.set_market(market_key_3, 2, market_3);

    let mut prices_arr = ArrayTrait::<MarketPrices>::new();
    prices_arr.append(prices_1);
    prices_arr.append(prices_2);
    prices_arr.append(prices_3);

    data_store.set_bool(keys::is_market_disabled_key(market_key_1), true);
    data_store.set_bool(keys::is_market_disabled_key(market_key_2), true);
    data_store.set_bool(keys::is_market_disabled_key(market_key_3), true);

    let start: usize = 0;
    let end: usize = 2;
    let res: Array<MarketInfo> = reader.get_market_info_list(data_store, prices_arr, start, end);
    assert(*res.at(0).market.market_token == market_key_1, 'wrong_key');
    assert(*res.at(1).market.market_token == market_key_2, 'wrong_key');
    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_get_market_token_price_then_works() {
    let (caller_address, role_store, data_store) = setup();
    let role_store_address: ContractAddress = contract_address_const::<'role_store'>();
    let data_store_address: ContractAddress = contract_address_const::<'data_store'>();
    let (reader_address, reader) = setup_reader();
    let market_address = deploy_market_token(role_store_address, data_store_address);

    let key: ContractAddress = market_address;
    let mut market = Market {
        market_token: key,
        index_token: 11111.try_into().unwrap(),
        long_token: 22222.try_into().unwrap(),
        short_token: 33333.try_into().unwrap(),
    };

    let index_prices_one = Price { min: 1, max: 200 };
    let index_prices_two = Price { min: 1, max: 300 };
    let index_prices_three = Price { min: 1, max: 400 };

    let pnl_factor = 10000;
    start_prank(role_store.contract_address, caller_address);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);
    stop_prank(role_store.contract_address);

    // Test logic

    data_store.set_market(key, 0, market);

    let (market_token_price_, pool_val_info) = reader
        .get_market_token_price(
            data_store,
            market,
            index_prices_one,
            index_prices_two,
            index_prices_three,
            pnl_factor,
            true
        );
    let market_token_price_felt: felt252 = market_token_price_.into();
    let expected_price = 100000000000000000000;
    assert(market_token_price_felt == expected_price, 'invalid_token_price');
    teardown(data_store.contract_address);
}


#[test]
fn given_normal_conditions_when_get_net_pnl_then_works() {
    //
    // Setup
    //
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();

    let market_token_address: ContractAddress = 123456789.try_into().unwrap();
    let mut market = Market {
        market_token: market_token_address,
        index_token: 11111.try_into().unwrap(),
        long_token: 22222.try_into().unwrap(),
        short_token: 33333.try_into().unwrap(),
    };

    let price = Price { min: 10, max: 50 };
    let is_long = true;
    let maximize = true;
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

    start_prank(role_store.contract_address, caller_address);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);
    stop_prank(role_store.contract_address);

    data_store.set_market(market_token_address, 0, market);
    let net_pnl: i128 = reader.get_net_pnl(data_store, market, price, maximize);

    assert(net_pnl == i128_new(9750, false), 'wrong net_pnl');
    teardown(data_store.contract_address);
}

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
#[test]
fn given_normal_conditions_when_get_open_interest_with_pnl_then_works() {
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
    let res = reader.get_open_interest_with_pnl(data_store, market, price, is_long, maximize);
    assert(res == i128_new(22500, false), 'incorrect open_interest');
    teardown(data_store.contract_address);
}
// audit, return value is 0x0
// TODO missing libraries  'market_utils::get_pnl_to_pool_factor' not implemented 
// #[test]
// fn given_normal_conditions_when_get_pnl_to_pool_factor_then_works() {
//     let (reader_address, reader) = setup_reader();
//     let (caller_address, role_store, data_store, event_emitter, oracle) = setup_oracle_and_store();

//     let market_token_address = contract_address_const::<'market_token'>();
//     let market = Market {
//         market_token: market_token_address,
//         index_token: contract_address_const::<'index_token'>(),
//         long_token: contract_address_const::<'long_token'>(),
//         short_token: contract_address_const::<'short_token'>(),
//     };
//     let price1 = Price {
//             min: 1,  
//             max: 200
//     };
//     let price2 = Price {
//             min: 1,  
//             max: 300
//     };
//      let price3 = Price {
//             min: 1,  
//             max: 400
//     };
//         //create random prices
//     let prices = MarketPrices {
//         index_token_price: price1,
//         long_token_price: price2,
//         short_token_price: price3
//     };
//     let key_1 = 1234311;
//     let mut position: Position = Default::default();
//     position.key = 1234311;
//     position.market = 'market'.try_into().unwrap();
//     position.size_in_usd = 1000000;
//     position.account = 'account'.try_into().unwrap();
//     position.is_long = true;
//     position.size_in_tokens = 10000;
//     let is_long = true;
//     let maximize = true;

//     start_prank(role_store.contract_address, caller_address);
//     role_store.grant_role(caller_address, role::MARKET_KEEPER);
//     stop_prank(role_store.contract_address);

//     data_store.set_market(market_token_address, 0, market);
//     data_store.set_position(key_1, position);

//     let res : i128 = reader.get_pnl_to_pool_factor(data_store,market_token_address,prices,is_long,maximize);
//     let resfelt : felt252 = res.into();
//     resfelt.print();
//     teardown(data_store.contract_address);
// }

// audit //panic error, unwrap failed
// TODO missing libraries reader_pricing_utils::get_swap_amount_out  use not implemented functions
// #[test]
// fn given_normal_conditions_when_get_swap_amount_out_then_works() {
//     let (caller_address, role_store, data_store) = setup();
//     let (reader_address, reader) = setup_reader();
//     let market_token_address = contract_address_const::<'market_token'>();
//     let token_ = contract_address_const::<'_token'>();
//     let ui_fee_receiver : ContractAddress = 5746789.try_into().unwrap();
//     let market = Market {
//         market_token: market_token_address,
//         index_token: contract_address_const::<'index_token'>(),
//         long_token: token_,
//         short_token: token_,
//     };
//     let price1 = Price {
//             min: 1,  
//             max: 200
//     };
//     let price2 = Price {
//             min: 1,  
//             max: 300
//     };
//      let price3 = Price {
//             min: 1,  
//             max: 400
//     };
//         //create random prices
//     let prices = MarketPrices {
//         index_token_price: price1,
//         long_token_price: price2,
//         short_token_price: price3
//     };

//     start_prank(role_store.contract_address, caller_address);
//     role_store.grant_role(caller_address, role::MARKET_KEEPER);
//     stop_prank(role_store.contract_address);

//     data_store.set_market(market_token_address, 0, market);
//     let amount_in : u128 = 20000;
//     // reader.get_swap_amount_out(data_store,market,prices,token_,amount_in,ui_fee_receiver);
//     teardown(data_store.contract_address);
// }

// // audit, function call returns 0x0
// TODO missing libraries 'market_utils::get_virtual_inventory_for_swaps' and 'market_utils::get_virtual_inventory_for_positions' not implemented 
// #[test]
// fn given_normal_conditions_when_get_virtual_inventory_then_works() {
//     let (caller_address, role_store, data_store) = setup();
//     let (reader_address, reader) = setup_reader();
//     let market_token_address = contract_address_const::<'market_token'>();
//     let market = Market {
//         market_token: market_token_address,
//         index_token: contract_address_const::<'index_token'>(),
//         long_token: contract_address_const::<'long_token'>(),
//         short_token: contract_address_const::<'short_token'>(),
//     };
//     start_prank(role_store.contract_address, caller_address);
//     role_store.grant_role(caller_address, role::MARKET_KEEPER);
//     stop_prank(role_store.contract_address);

//     data_store.set_market(market_token_address, 0, market);
//     let virtual_inventory : VirtualInventory = reader.get_virtual_inventory(data_store, market);
//     virtual_inventory.virtual_pool_amount_for_long_token.print();
//     teardown(data_store.contract_address);
// }

#[test]
fn given_normal_conditions_when_get_execution_price_then_works() {
    let (caller_address, role_store, data_store) = setup();
    let (reader_address, reader) = setup_reader();
    let market_key_1: ContractAddress = 123456789.try_into().unwrap();
    let market_1 = Market {
        market_token: market_key_1,
        index_token: 12345.try_into().unwrap(),
        long_token: 56678.try_into().unwrap(),
        short_token: 8901234.try_into().unwrap(),
    };
    let price1 = Price { min: 1, max: 200 };
    let key_2: felt252 = 3333333333;
    let mut position2: Position = Default::default();
    position2.key = key_2;
    position2.market = 'market2'.try_into().unwrap();
    position2.size_in_usd = 3000000;
    position2.account = 'account2'.try_into().unwrap();
    position2.is_long = true;
    position2.size_in_tokens = 10000;

    let size: i128 = 20000.try_into().unwrap();
    let is_long = true;

    start_prank(role_store.contract_address, caller_address);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);
    stop_prank(role_store.contract_address);

    data_store.set_market(market_key_1, 1, market_1);
    data_store.set_position(key_2, position2);

    let res: ExecutionPriceResult = reader
        .get_execution_price(
            data_store,
            market_key_1,
            price1,
            position2.size_in_usd,
            position2.size_in_tokens,
            size,
            is_long
        );
    assert(res.execution_price == 200, 'incorrect execution_price');
    teardown(data_store.contract_address);
}

//audit, returns a panicked crates error
// TODO missing libraries 'swap_pricing_utils::get_price_impact_usd' and 'market_utils::get_swap_impact_amount_with_cap' not implemented 
// #[test]
// fn given_normal_conditions_when_get_swap_price_impact_then_works() {
//     let (caller_address, role_store, data_store) = setup();
//     let (reader_address, reader) = setup_reader();

//     let market_key_1: ContractAddress = 123456789.try_into().unwrap();
//     let market_1 = Market {
//         market_token: market_key_1,
//         index_token: 12345.try_into().unwrap(),
//         long_token: 56678.try_into().unwrap(),
//         short_token: 8901234.try_into().unwrap(),
//     };
//      let price1 = Price {
//             min: 1,  
//             max: 200
//     };
//     let price2 = Price {
//             min: 1,  
//             max: 400
//     };
//     let amount_in = 3000;
//     let token_in : ContractAddress = contract_address_const::<'token_in'>();
//     let token_out : ContractAddress = contract_address_const::<'token_out'>();

//     start_prank(role_store.contract_address, caller_address);
//     role_store.grant_role(caller_address, role::MARKET_KEEPER);
//     stop_prank(role_store.contract_address);

//     data_store.set_market(market_key_1, 1, market_1);
//     let (data1, data2) = reader.get_swap_price_impact(data_store,market_key_1,token_in,token_out,amount_in,price1,price2);
//     let datafel : felt252 = data1.into();
//     datafel.print();
//     teardown(data_store.contract_address);
// }

//audit, returns an unwrap failed error
// TODO missing libraries 'market_utils::is_pnl_factor_exceeded_direct' and 'market_utils::get_enabled_market' not implemented 
// #[test]
// fn given_normal_conditions_when_get_adl_state_then_works() {
//      let (caller_address, role_store, data_store) = setup();
//     let (reader_address, reader) = setup_reader();
//     let market_token_address = contract_address_const::<'market_token'>();
//     let market = Market {
//         market_token: market_token_address,
//         index_token: contract_address_const::<'index_token'>(),
//         long_token: contract_address_const::<'long_token'>(),
//         short_token: contract_address_const::<'short_token'>(),
//     };
//         let price1 = Price {
//             min: 1,  
//             max: 200
//     };
//     let price2 = Price {
//             min: 1,  
//             max: 300
//     };
//      let price3 = Price {
//             min: 1,  
//             max: 400
//     };
//         //create random prices
//     let prices = MarketPrices {
//         index_token_price: price1,
//         long_token_price: price2,
//         short_token_price: price3
//     };
//     start_prank(role_store.contract_address, caller_address);
//     role_store.grant_role(caller_address, role::MARKET_KEEPER);
//     stop_prank(role_store.contract_address);

//     data_store.set_market(market_token_address, 0, market);
//     let (data1, data2, data3, data4) = reader.get_adl_state(data_store,market_token_address,true,prices);
//     teardown(data_store.contract_address);
// }

// *************************************************************************
//                          SETUP READER
// *************************************************************************

fn setup_reader() -> (ContractAddress, IReaderDispatcher) {
    let contract = declare('Reader');
    let reader_address = contract.deploy(@array![]).unwrap();
    let reader = IReaderDispatcher { contract_address: reader_address };
    (reader_address, reader)
}
fn setup_referral_storage() -> (ContractAddress, IReferralStorageDispatcher) {
    let event_emitter_address = deploy_event_emitter();
    // Create a safe dispatcher to interact with the contract.
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    let contract = declare('ReferralStorage');
    let referral_storage_address = contract.deploy(@array![event_emitter_address.into()]).unwrap();
    let referral = IReferralStorageDispatcher { contract_address: referral_storage_address };
    (referral_storage_address, referral)
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'event_emitter'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![], deployed_contract_address).unwrap()
}

fn deploy_market_token(
    role_store: ContractAddress, data_store: ContractAddress
) -> ContractAddress {
    let contract = declare('MarketToken');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'market_token'>();
    start_prank(deployed_contract_address, caller_address);
    contract
        .deploy_at(@array![role_store.into(), data_store.into()], deployed_contract_address)
        .unwrap()
}

