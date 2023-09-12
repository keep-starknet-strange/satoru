use satoru::data::data_store::IDataStoreDispatcherTrait;
use satoru::nonce::nonce_utils::{get_current_nonce, increment_nonce, compute_key};
use satoru::tests_lib::{setup, teardown};
use satoru::order::{
    error::OrderError, order::{Order, SecondaryOrderType, OrderType, DecreasePositionSwapType},
};
use satoru::order::base_order_utils::{
    is_market_order, is_limit_order, is_swap_order, is_position_order, is_increase_order,
    is_decrease_order, is_liquidation_order, validate_order_trigger_price,
    get_execution_price_for_increase, get_execution_price_for_decrease, validate_non_empty_order
};

use debug::PrintTrait;

#[test]
fn test_base_order_utils_is_position_order() {
    assert(!is_position_order(OrderType::MarketSwap), 'Should not be position');
    assert(is_position_order(OrderType::MarketIncrease), 'Should be position');
}

#[test]
fn test_base_order_utils_validate_order_trigger_price() {
    // TODO: need oracle
    assert(true, 'Should be true');
}

#[test]
fn test_base_order_utils_get_execution_price_for_increase() {
    let size_delta_usd = 200;
    let size_delta_in_tokens = 20;
    let acceptable_price = 10;
    let is_long = true;
    let price = get_execution_price_for_increase(
        size_delta_usd, size_delta_in_tokens, acceptable_price, is_long
    );
    'price is'.print();
    price.print();
    assert(price == 10, 'Should be 10');
}

#[test]
fn test_base_order_utils_get_execution_price_for_decrease() {
    // TODO
    assert(true, 'Should be true');
}

#[test]
fn test_base_order_utils_validate_non_empty_order() {
    let mut order: Order = Default::default();
    order.account = 32.try_into().unwrap();
    order.size_delta_usd = 1;
    order.initial_collateral_delta_amount = 1;
    validate_non_empty_order(order);
}

#[test]
#[should_panic(expected: ('empty_order',))]
fn test_base_order_utils_validate_non_empty_order_fail() {
    let order: Order = Default::default();
    validate_non_empty_order(order);
}

