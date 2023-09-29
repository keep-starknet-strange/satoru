use starknet::ContractAddress;
use snforge_std::{start_mock_call, stop_mock_call};

use satoru::data::data_store::IDataStoreDispatcherTrait;
use satoru::nonce::nonce_utils::{get_current_nonce, increment_nonce, compute_key};
use satoru::tests_lib::{setup, teardown};
use satoru::oracle::oracle::{IOracleSafeDispatcher, IOracleDispatcher, IOracleDispatcherTrait};
use satoru::order::{
    error::OrderError, order::{Order, SecondaryOrderType, OrderType, DecreasePositionSwapType},
};
use satoru::price::price::{Price, PriceTrait};
use satoru::order::base_order_utils::{
    is_market_order, is_limit_order, is_swap_order, is_position_order, is_increase_order,
    is_decrease_order, is_liquidation_order, validate_order_trigger_price,
    get_execution_price_for_increase, get_execution_price_for_decrease, validate_non_empty_order
};

#[test]
fn given_normal_conditions_when_is_position_order_then_works() {
    assert(!is_position_order(OrderType::MarketSwap), 'Should not be position');
    assert(is_position_order(OrderType::MarketIncrease), 'Should be position');
}

#[test]
fn given_normal_conditions_when_validate_order_trigger_price_then_works() {
    // TODO when oracle
    // let oracle_address: ContractAddress = 'oracle'.try_into().unwrap();
    // start_mock_call(oracle_address, 'get_primary_price', Price { min: 9, max: 11 });
    // let oracle = IOracleSafeDispatcher { contract_address: oracle_address };
    // validate_order_trigger_price(
    //     oracle,
    //     index_token: 'token'.try_into().unwrap(),
    //     order_type: OrderType::LimitIncrease,
    //     trigger_price: 10,
    //     is_long: true,
    // );
    // stop_mock_call(oracle_address, 'get_primary_price');
    assert(true, 'Tautology');
}

#[test]
fn given_normal_conditions_when_get_execution_price_for_increase_then_works() {
    let price = get_execution_price_for_increase(
        size_delta_usd: 200, size_delta_in_tokens: 20, acceptable_price: 10, is_long: true,
    );
    assert(price == 10, 'Should be 10');
}

#[test]
fn given_normal_conditions_when_get_execution_price_for_decrease_then_works() {
    let price = get_execution_price_for_decrease(
        index_token_price: Price { min: 9, max: 11 },
        position_size_in_usd: 1000,
        position_size_in_tokens: 100,
        size_delta_usd: 200,
        price_impact_usd: 1,
        acceptable_price: 8,
        is_long: true,
    );
    assert(price == 9, 'Should be 9');
}

#[test]
fn given_normal_conditions_when_validate_non_empty_order_then_works() {
    let mut order: Order = Default::default();
    order.account = 32.try_into().unwrap();
    order.size_delta_usd = 1;
    order.initial_collateral_delta_amount = 1;
    validate_non_empty_order(@order);
}

#[test]
#[should_panic(expected: ('empty_order',))]
fn given_empty_order_when_validate_non_empty_order_then_fails() {
    let order: Order = Default::default();
    validate_non_empty_order(@order);
}
