use starknet::{ContractAddress, contract_address_const};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};

use satoru::order::{order::{OrderType, Order},};
use satoru::price::price::{Price, PriceTrait};
use satoru::order::base_order_utils::{
    is_market_order, is_limit_order, is_swap_order, is_position_order, is_increase_order,
    is_decrease_order, is_liquidation_order, validate_order_trigger_price,
    get_execution_price_for_increase, get_execution_price_for_decrease, validate_non_empty_order
};

use satoru::data::data_store::{DataStore, IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{EventEmitter, IEventEmitterDispatcher};
use satoru::oracle::oracle::{Oracle, IOracleDispatcher, IOracleDispatcherTrait, SetPricesParams};
use satoru::oracle::oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait};
use satoru::oracle::price_feed::PriceFeed;
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::utils::i256::{i256, i256_new};

#[test]
fn given_normal_conditions_when_is_market_order_then_works() {
    // Test market orders
    assert(is_market_order(OrderType::MarketSwap), 'invalid market swap res');
    assert(is_market_order(OrderType::MarketIncrease), 'invalid market inc. res');
    assert(is_market_order(OrderType::MarketDecrease), 'invalid market dec. res');

    // Test other orders
    assert(!is_market_order(OrderType::LimitSwap), 'invalid limit swap res');
    assert(!is_market_order(OrderType::LimitIncrease), 'invalid limit inc. res');
    assert(!is_market_order(OrderType::StopLossDecrease), 'invalid stop loss res ');
}

#[test]
fn given_normal_conditions_when_is_limit_order_then_works() {
    // Test limit orders
    assert(is_limit_order(OrderType::LimitSwap), 'invalid limit swap res');
    assert(is_limit_order(OrderType::LimitIncrease), 'invalid limit inc. res');
    assert(is_limit_order(OrderType::LimitDecrease), 'invalid limit dec. res');

    // Test other orders
    assert(!is_limit_order(OrderType::MarketSwap), 'invalid market swap res');
    assert(!is_limit_order(OrderType::MarketIncrease), 'invalid market inc. res');
    assert(!is_limit_order(OrderType::StopLossDecrease), 'invalid stop loss res ');
}

#[test]
fn given_normal_conditions_when_is_swap_order_then_works() {
    // Test swap orders
    assert(is_swap_order(OrderType::MarketSwap), 'invalid market swap res');
    assert(is_swap_order(OrderType::LimitSwap), 'invalid limit swap res');

    // Test other orders
    assert(!is_swap_order(OrderType::MarketIncrease), 'invalid market inc. res');
    assert(!is_swap_order(OrderType::LimitIncrease), 'invalid limit inc. res ');
}


#[test]
fn given_normal_conditions_when_is_position_order_then_works() {
    // Test position orders
    assert(is_position_order(OrderType::MarketIncrease), 'invalid market inc. res');
    assert(is_position_order(OrderType::LimitIncrease), 'invalid limit inc. res');
    assert(is_position_order(OrderType::StopLossDecrease), 'invalid stop loss res');
    assert(is_position_order(OrderType::Liquidation), 'invalid liquidation res');

    // Test other orders
    assert(!is_position_order(OrderType::LimitSwap), 'invalid limit swap res');
    assert(!is_position_order(OrderType::MarketSwap), 'invalid market swap res ');
}


#[test]
fn given_normal_conditions_when_is_increase_order_then_works() {
    // Test position orders
    assert(is_increase_order(OrderType::MarketIncrease), 'invalid market inc. res');
    assert(is_increase_order(OrderType::LimitIncrease), 'invalid limit inc. res');

    // Test other orders
    assert(!is_increase_order(OrderType::MarketDecrease), 'invalid market dec. res');
    assert(!is_increase_order(OrderType::MarketSwap), 'invalid market swap res ');
}

#[test]
fn given_normal_conditions_when_is_decrease_order_then_works() {
    // Test position orders
    assert(is_decrease_order(OrderType::MarketDecrease), 'invalid market dec. res');
    assert(is_decrease_order(OrderType::LimitDecrease), 'invalid limit dec. res');
    assert(is_decrease_order(OrderType::StopLossDecrease), 'invalid stop loss res');
    assert(is_decrease_order(OrderType::Liquidation), 'invalid liquidation res');

    // Test other orders
    assert(!is_decrease_order(OrderType::MarketIncrease), 'invalid market inc. res');
    assert(!is_decrease_order(OrderType::LimitIncrease), 'invalid limit inc. res');
}

#[test]
fn given_normal_conditions_when_is_liquidation_order_then_works() {
    // Test position orders
    assert(is_liquidation_order(OrderType::Liquidation), 'invalid liquidation inc. res');
    // Test other orders
    assert(!is_liquidation_order(OrderType::MarketDecrease), 'invalid market dec. res');
    assert(!is_liquidation_order(OrderType::MarketSwap), 'invalid market swap res ');
}


#[test]
fn given_normal_conditions_when_validate_order_trigger_price_then_works() {
    // Setup
    let (_, _, _, oracle) = setup();
    let index_token = contract_address_const::<'ETH'>();
    let price = Price { min: 100000, max: 200000 };
    oracle.set_primary_price(index_token, price);

    // Test

    // Test swap orders validates
    validate_order_trigger_price(oracle, index_token, OrderType::MarketSwap, 100, true);

    // Test limit increase orders
    validate_order_trigger_price(
        oracle, index_token, OrderType::LimitIncrease, price.max + 1, true
    );

    validate_order_trigger_price(
        oracle, index_token, OrderType::LimitIncrease, price.min - 1, false
    );

    // Test limit decrease orders
    validate_order_trigger_price(
        oracle, index_token, OrderType::LimitDecrease, price.min - 1, true
    );

    validate_order_trigger_price(
        oracle, index_token, OrderType::LimitDecrease, price.max + 1, false
    );

    // Test stop loss orders
    validate_order_trigger_price(
        oracle, index_token, OrderType::StopLossDecrease, price.min + 1, true
    );

    validate_order_trigger_price(
        oracle, index_token, OrderType::StopLossDecrease, price.max - 1, false
    );

    assert(true, 'e');
}

#[test]
#[should_panic(
    expected: ('invalid_order_price', 100000, 200000, 199999, 6053968548023263173723725853541)
)]
fn given_limit_increase_price_higher_than_trigger_when_validate_order_trigger_price_then_fails() {
    // Setup
    let (_, _, _, oracle) = setup();
    let index_token = contract_address_const::<'ETH'>();
    let price = Price { min: 100000, max: 200000 };
    oracle.set_primary_price(index_token, price);

    // Test
    validate_order_trigger_price(
        oracle, index_token, OrderType::LimitIncrease, price.max - 1, true
    );
}


#[test]
#[should_panic(
    expected: ('invalid_order_price', 100000, 200000, 199999, 6053968548022900352478745817957)
)]
fn given_limit_decrease_price_lower_than_trigger_when_validate_order_trigger_price_then_fails() {
    // Setup
    let (_, _, _, oracle) = setup();
    let index_token = contract_address_const::<'ETH'>();
    let price = Price { min: 100000, max: 200000 };
    oracle.set_primary_price(index_token, price);

    // Test
    validate_order_trigger_price(
        oracle, index_token, OrderType::LimitDecrease, price.max - 1, false
    );
}

#[test]
#[should_panic(
    expected: (
        'invalid_order_price', 100000, 200000, 99999, 110930490330413861099797394456752255845
    )
)]
fn given_stop_loss_price_lower_than_trigger_when_validate_order_trigger_price_then_fails() {
    // Setup
    let (_, _, _, oracle) = setup();
    let index_token = contract_address_const::<'ETH'>();
    let price = Price { min: 100000, max: 200000 };
    oracle.set_primary_price(index_token, price);

    // Test
    validate_order_trigger_price(
        oracle, index_token, OrderType::StopLossDecrease, price.min - 1, true
    );
}


#[test]
fn given_normal_conditions_when_get_execution_price_for_increase_then_works() {
    let price = get_execution_price_for_increase(
        size_delta_usd: 200, size_delta_in_tokens: 20, acceptable_price: 10, is_long: true,
    );
    assert(price == 10, 'invalid price');

    let price = get_execution_price_for_increase(
        size_delta_usd: 400, size_delta_in_tokens: 10, acceptable_price: 20, is_long: false,
    );
    assert(price == 40, 'invalid price2');
}


#[test]
#[should_panic(expected: ('order_unfulfillable_at_price', 500, 10))]
fn given_order_not_fullfillable_when_get_execution_price_for_increase_then_fails() {
    let price = get_execution_price_for_increase(
        size_delta_usd: 5000, size_delta_in_tokens: 10, acceptable_price: 10, is_long: true,
    );
}


#[test]
fn given_normal_conditions_when_get_execution_price_for_decrease_then_works() {
    let price = get_execution_price_for_decrease(
        index_token_price: Price { min: 9, max: 11 },
        position_size_in_usd: 1000,
        position_size_in_tokens: 100,
        size_delta_usd: 200,
        price_impact_usd: i256_new(1, false),
        acceptable_price: 8,
        is_long: true,
    );
    assert(price == 9, 'invalid price1');

    let price = get_execution_price_for_decrease(
        index_token_price: Price { min: 1000, max: 1100 },
        position_size_in_usd: 200000000,
        position_size_in_tokens: 30000,
        size_delta_usd: 50000,
        price_impact_usd: i256_new(15, false),
        acceptable_price: 1001,
        is_long: true,
    );
    assert(price == 1002, 'invalid price2');

    let price = get_execution_price_for_decrease(
        index_token_price: Price { min: 1000, max: 1100 },
        position_size_in_usd: 200000000,
        position_size_in_tokens: 30000,
        size_delta_usd: 50000,
        price_impact_usd: i256_new(15, false),
        acceptable_price: 1100,
        is_long: false,
    );
    assert(price == 1098, 'invalid price');
}


#[test]
#[should_panic(
    expected: (
        'price_impact_too_large',
        3618502788666131213697322783095070105623107215331596699973092056135872020466,
        1
    )
)]
fn given_price_impact_larger_than_order_when_get_execution_price_for_decrease_then_fails() {
    let price = get_execution_price_for_decrease(
        index_token_price: Price { min: 1000, max: 1100 },
        position_size_in_usd: 200000000,
        position_size_in_tokens: 30000,
        size_delta_usd: 1,
        price_impact_usd: i256_new(15, false),
        acceptable_price: 1100,
        is_long: false,
    );
}

#[test]
#[should_panic(
    expected: (
        'negative_execution_price',
        3618502788666131213697322783095070105623107215331596699973092056135872020480,
        1,
        200000000,
        3618502788666131213697322783095070105623107215331596699973092056135872020466,
        50000
    )
)]
fn given_negative_execution_price_than_order_when_get_execution_price_for_decrease_then_fails() {
    let price = get_execution_price_for_decrease(
        index_token_price: Price { min: 1, max: 1 },
        position_size_in_usd: 200000000,
        position_size_in_tokens: 30000,
        size_delta_usd: 50000,
        price_impact_usd: i256_new(15, false),
        acceptable_price: 1100,
        is_long: false,
    );
}


#[test]
#[should_panic(expected: ('order_unfulfillable_at_price', 1002, 10000,))]
fn given_not_acceptable_price_when_get_execution_price_for_decrease_then_fails() {
    let price = get_execution_price_for_decrease(
        index_token_price: Price { min: 1000, max: 1100 },
        position_size_in_usd: 200000000,
        position_size_in_tokens: 30000,
        size_delta_usd: 50000,
        price_impact_usd: i256_new(15, false),
        acceptable_price: 10000,
        is_long: true,
    );
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


// *********************************************************************************************
// *                              SETUP                                                        *
// *********************************************************************************************

fn setup() -> (ContractAddress, IDataStoreDispatcher, IEventEmitterDispatcher, IOracleDispatcher) {
    let caller_address = contract_address_const::<'caller'>();
    let order_keeper = contract_address_const::<0x2233>();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };
    let oracle_store_address = deploy_oracle_store(role_store_address, event_emitter_address);
    let oracle_store = IOracleStoreDispatcher { contract_address: oracle_store_address };
    let pragma_address = deploy_price_feed();
    let oracle_address = deploy_oracle(oracle_store_address, role_store_address, pragma_address);
    let oracle = IOracleDispatcher { contract_address: oracle_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    role_store.grant_role(order_keeper, role::ORDER_KEEPER);
    oracle_store.add_signer(contract_address_const::<'signer'>());
    start_prank(data_store_address, caller_address);
    start_prank(oracle_address, caller_address);

    (caller_address, data_store, event_emitter, oracle)
}

fn deploy_price_feed() -> ContractAddress {
    let contract = declare('PriceFeed');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'price_feed'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![], deployed_contract_address).unwrap()
}

fn deploy_oracle(
    oracle_store_address: ContractAddress,
    role_store_address: ContractAddress,
    pragma_address: ContractAddress
) -> ContractAddress {
    let contract = declare('Oracle');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'oracle'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![
        role_store_address.into(), oracle_store_address.into(), pragma_address.into()
    ];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_oracle_store(
    role_store_address: ContractAddress, event_emitter_address: ContractAddress
) -> ContractAddress {
    let contract = declare('OracleStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'oracle_store'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![role_store_address.into(), event_emitter_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'data_store'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'role_store'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![caller_address.into()], deployed_contract_address).unwrap()
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'event_emitter'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![], deployed_contract_address).unwrap()
}
