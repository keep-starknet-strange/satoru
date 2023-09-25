use starknet::ContractAddress;
use snforge_std::{start_mock_call, stop_mock_call};

use satoru::data::data_store::IDataStoreDispatcherTrait;
use satoru::nonce::nonce_utils::{get_current_nonce, increment_nonce, compute_key};
use satoru::tests_lib::{setup, teardown};
use satoru::oracle::oracle::{IOracleSafeDispatcher, IOracleDispatcher, IOracleDispatcherTrait};
use satoru::order::{
    error::OrderError, order::{Order, SecondaryOrderType, OrderType, DecreasePositionSwapType},
};
use satoru::order::increase_order_utils::{validate_oracle_block_numbers};

// TODO - Add tests for process_order

#[test]
#[available_gas(100_000)]
fn given_normal_conditions_when_validate_oracle_block_numbers_then_works() {
    // Given
    let min_oracle_block_numbers = array![0, 1, 2, 3, 4].span();
    let max_oracle_block_numbers = array![6, 7, 8, 9, 10].span();
    let order_type = OrderType::MarketIncrease;
    let order_updated_at_block = 5;

    // When
    validate_oracle_block_numbers(
        min_oracle_block_numbers, max_oracle_block_numbers, order_type, order_updated_at_block,
    );
}

#[test]
#[available_gas(100_000)]
#[should_panic(expected: ('block numbers too small', 5, 0, 1, 2, 3, 4, 2))]
fn given_smaller_oracle_block_numbers_when_validate_oracle_block_numbers_then_throw_error() {
    // Given
    let min_oracle_block_numbers = array![0, 1, 2, 3, 4].span();
    let max_oracle_block_numbers = array![6, 7, 8, 9, 10].span();
    let order_type = OrderType::LimitIncrease;
    let order_updated_at_block = 2;

    // When
    validate_oracle_block_numbers(
        min_oracle_block_numbers, max_oracle_block_numbers, order_type, order_updated_at_block,
    );
}


#[test]
#[should_panic(expected: ('unsupported_order_type',))]
fn given_unsupported_order_type_when_validate_oracle_block_numbers_then_throw_error() {
    // Given
    let min_oracle_block_numbers = array![].span();
    let max_oracle_block_numbers = array![].span();
    let order_type = OrderType::MarketSwap;
    let order_updated_at_block = 0;

    // When
    validate_oracle_block_numbers(
        min_oracle_block_numbers, max_oracle_block_numbers, order_type, order_updated_at_block,
    );
}
