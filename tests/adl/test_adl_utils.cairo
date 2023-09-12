use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::role::role;
use satoru::order::order::{Order, OrderType, OrderTrait, DecreasePositionSwapType};
use satoru::tests_lib::{setup, setup_event_emitter, setup_oracle_and_store, teardown};
use satoru::position::position::{Position};

use snforge_std::{
    PrintTrait, declare, start_prank, stop_prank, ContractClassTrait, spy_events, SpyOn, EventSpy,
    EventFetcher, event_name_hash, Event, EventAssertions, start_mock_call
};
use satoru::adl::adl_utils;


#[test]
fn test_set_latest_adl_block() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let market = 'market'.try_into().unwrap();
    let is_long = false;

    // Test logic
    // Default should return 0
    let latest_block = adl_utils::get_latest_adl_block(data_store, market, is_long);
    assert(latest_block == 0, 'Invalid lates_block');

    // Set block value
    let block_value = 1234_u64;
    adl_utils::set_latest_adl_block(data_store, market, is_long, block_value);

    let latest_block_after = adl_utils::get_latest_adl_block(data_store, market, is_long);
    assert(latest_block_after == block_value, 'Invalid lates_block2');

    // Update block value
    let block_value2 = 222222_u64;
    adl_utils::set_latest_adl_block(data_store, market, is_long, block_value2);

    let block_updated = adl_utils::get_latest_adl_block(data_store, market, is_long);
    assert(block_updated == block_value2, 'Invalid lates_block3');

    // For different parameter block shouldnt change
    let is_long2 = true;
    let block_default = adl_utils::get_latest_adl_block(data_store, market, is_long2);
    assert(block_default == 0, 'Invalid lates_block4');

    teardown(data_store.contract_address);
}


#[test]
fn test_set_enabled() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let market = 'market'.try_into().unwrap();
    let is_long = false;

    // Test logic
    // Default should return false
    let is_enabled = adl_utils::get_adl_enabled(data_store, market, is_long);
    assert(!is_enabled, 'Invalid enabled result');

    let enabled_value = true;
    adl_utils::set_adl_enabled(data_store, market, is_long, enabled_value);

    let is_enabled_after = adl_utils::get_adl_enabled(data_store, market, is_long);
    assert(is_enabled_after == enabled_value, 'Invalid enabled result2');

    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('adl_not_enabled',))]
fn test_validate_not_enabled() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let market = 'market'.try_into().unwrap();
    let block_numbers = array![10_u64, 8_u64];
    // Test logic
    adl_utils::validate_adl(data_store, market, false, block_numbers.span());

    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('block_no_smaller_than_required',))]
fn test_validate_block_numbers_are_small() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let market = 'market'.try_into().unwrap();
    let is_long = false;

    // Test logic
    let enabled_value = true;
    adl_utils::set_adl_enabled(data_store, market, is_long, enabled_value);

    let block_value = 1234_u64;
    adl_utils::set_latest_adl_block(data_store, market, is_long, block_value);

    let block_numbers = array![10_u64, 11_u64];
    adl_utils::validate_adl(data_store, market, is_long, block_numbers.span());

    teardown(data_store.contract_address);
}

#[test]
fn test_validate() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let market = 'market'.try_into().unwrap();
    let is_long = false;

    // Test logic
    let enabled_value = true;
    adl_utils::set_adl_enabled(data_store, market, is_long, enabled_value);

    let block_value = 1234_u64;
    adl_utils::set_latest_adl_block(data_store, market, is_long, block_value);

    let block_numbers = array![11111111_u64, 12111111_u64];
    adl_utils::validate_adl(data_store, market, is_long, block_numbers.span());

    teardown(data_store.contract_address);
}

#[test]
fn test_adl_state_event() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let (event_emitter_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(event_emitter_address));

    let market: ContractAddress = 'market'.try_into().unwrap();
    let is_long = true;
    let pnl_to_pool_factor: i128 = 12345;
    let max_pnl_factor: u128 = 100;
    let should_enable_adl: bool = true;

    // Emit event
    start_prank(event_emitter_address, caller_address);
    adl_utils::emit_adl_state_updated(
        event_emitter, market, is_long, pnl_to_pool_factor, max_pnl_factor, should_enable_adl
    );
    stop_prank(event_emitter_address);

    spy.fetch_events();
    assert(spy.events.len() == 1, 'There should be one event');
    assert(spy.events.at(0).name == @event_name_hash('EventLog1'), 'Wrong event name');
    assert(spy.events.at(0).keys.len() == 0, 'There should be no keys');
    let event_name: felt252 = 'AdlStateUpdated';
    let sender: felt252 = caller_address.into();
    let market_felt = market.into();
    assert(*spy.events.at(0).data.at(0) == sender, 'Invalid data0');
    assert(*spy.events.at(0).data.at(1) == event_name, 'Invalid data1');
    assert(*spy.events.at(0).data.at(2) == market_felt, 'Invalid data2');
    assert(*spy.events.at(0).data.at(3) == 0, 'Invalid data3');
    assert(*spy.events.at(0).data.at(4) == 0, 'Invalid data4');
    assert(*spy.events.at(0).data.at(5) == 1, 'Invalid data5');
    assert(*spy.events.at(0).data.at(6) == 'max_pnl_factor', 'Invalid data6');
    assert(*spy.events.at(0).data.at(7) == max_pnl_factor.into(), 'Invalid data7');
    assert(*spy.events.at(0).data.at(8) == 0, 'Invalid data8');
    assert(*spy.events.at(0).data.at(9) == 1, 'Invalid data9');
    assert(*spy.events.at(0).data.at(10) == 'pnl_to_pool_factor', 'Invalid data10');
    assert(*spy.events.at(0).data.at(11) == pnl_to_pool_factor.into(), 'Invalid data11');
    assert(*spy.events.at(0).data.at(12) == 0, 'Invalid data12');
    assert(*spy.events.at(0).data.at(13) == 2, 'Invalid data13');
    assert(*spy.events.at(0).data.at(14) == 'is_long', 'Invalid data14');
    assert(*spy.events.at(0).data.at(15) == is_long.into(), 'Invalid data15');
    assert(*spy.events.at(0).data.at(16) == 'should_enable_adl', 'Invalid data16');
    assert(*spy.events.at(0).data.at(17) == should_enable_adl.into(), 'Invalid data17');
    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('block_no_smaller_than_required',))]
fn test_update_adl_state_fail() {
    // Setup
    let (caller_address, role_store, data_store, event_emitter, oracle) = setup_oracle_and_store();
    let market = 'market'.try_into().unwrap();
    let is_long = false;
    let block_value = 1234_u64;
    adl_utils::set_latest_adl_block(data_store, market, is_long, block_value);

    let block_numbers = array![10_u64, 11_u64];
    adl_utils::update_adl_state(
        data_store, event_emitter, oracle, market, is_long, block_numbers.span()
    );

    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('position_not_valid',))]
fn test_create_adl_position_panic() {
    // Setup

    let (caller_address, role_store, data_store, event_emitter, oracle) = setup_oracle_and_store();
    let accoun1 = 'accoun1'.try_into().unwrap();
    let market = 'market'.try_into().unwrap();
    let collateral_token = 'token'.try_into().unwrap();
    let params = adl_utils::CreateAdlOrderParams {
        data_store: data_store,
        event_emitter: event_emitter,
        account: accoun1,
        market: market,
        collateral_token: collateral_token,
        is_long: false,
        size_delta_usd: 100,
        updated_at_block: 100
    };
    adl_utils::create_adl_order(params);
}


#[test]
fn test_create_adl_order() { // Setup
    //let (caller_address, role_store, data_store, event_emitter, oracle) = setup_oracle_and_store();
    // TODO 
    // For testing "position_utils::get_position_key",  ".data_store.get_position" should be implmented
    assert(true, 'e');
}


#[test]
fn test_update_adl_state() { // Setup
    //let (caller_address, role_store, data_store, event_emitter, oracle) = setup_oracle_and_store();
    // TODO 
    // For testing "get_enabled_market",  "get_market_prices" and "is_pnl_factor_exceeded_direct" should be implmented
    assert(true, 'e');
}
