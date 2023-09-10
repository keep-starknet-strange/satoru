use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::order::order::{Order, OrderType, SecondaryOrderType};
use satoru::tests_lib::{setup_event_emitter};

//TODO: OrderCollatDeltaAmountAutoUpdtd must be renamed back to OrderCollateralDeltaAmountAutoUpdated when string will be allowed as event argument

#[test]
fn test_emit_order_created() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key: felt252 = 100;
    let order: Order = create_dummy_order();

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    order.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_order_created(key, order);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'OrderCreated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_order_executed() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key: felt252 = 100;
    let secondary_order_type: SecondaryOrderType = SecondaryOrderType::None(());

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    secondary_order_type.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_order_executed(key, secondary_order_type);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'OrderExecuted',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_order_updated() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 100;
    let size_delta_usd: u128 = 200;
    let acceptable_price: u128 = 300;
    let trigger_price: u128 = 400;
    let min_output_amount: u128 = 500;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        key,
        size_delta_usd.into(),
        acceptable_price.into(),
        trigger_price.into(),
        min_output_amount.into()
    ];

    // Emit the event.
    event_emitter
        .emit_order_updated(
            key, size_delta_usd, acceptable_price, trigger_price, min_output_amount
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'OrderUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_order_size_delta_auto_updated() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 100;
    let size_delta_usd: u128 = 200;
    let next_size_delta_usd: u128 = 300;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        key, size_delta_usd.into(), next_size_delta_usd.into(),
    ];

    // Emit the event.
    event_emitter.emit_order_size_delta_auto_updated(key, size_delta_usd, next_size_delta_usd);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'OrderSizeDeltaAutoUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_order_collateral_delta_amount_auto_updated() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 100;
    let collateral_delta_amount: u128 = 200;
    let next_collateral_delta_amount: u128 = 300;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        key, collateral_delta_amount.into(), next_collateral_delta_amount.into(),
    ];

    // Emit the event.
    event_emitter
        .emit_order_collateral_delta_amount_auto_updated(
            key, collateral_delta_amount, next_collateral_delta_amount
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'OrderCollatDeltaAmountAutoUpdtd',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_order_cancelled() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 100;
    let reason = 'none';
    let reason_bytes = array!['0x00', '0x01'];

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key, reason.into()];
    reason_bytes.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_order_cancelled(key, reason, reason_bytes);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'OrderCancelled',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_order_frozen() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 100;
    let reason = 'frozen';
    let reason_bytes = array!['0x00', '0x01'];

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key, reason.into()];
    reason_bytes.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_order_frozen(key, reason, reason_bytes);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address, name: 'OrderFrozen', keys: array![], data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the event emitter contract.
/// * `IEventEmitterDispatcher` - The event emitter store dispatcher.
fn setup() -> (ContractAddress, IEventEmitterDispatcher) {
    let contract = declare('EventEmitter');
    let contract_address = contract.deploy(@array![]).unwrap();
    let event_emitter = IEventEmitterDispatcher { contract_address };
    return (contract_address, event_emitter);
}


/// Utility function to create a dummy order.
fn create_dummy_order() -> Order {
    let mut swap_path = array![];
    swap_path.append(contract_address_const::<'swap_path_0'>());
    swap_path.append(contract_address_const::<'swap_path_1'>());
    Order {
        key: 1,
        order_type: OrderType::StopLossDecrease,
        account: contract_address_const::<'account'>(),
        receiver: contract_address_const::<'receiver'>(),
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
        market: contract_address_const::<'market'>(),
        initial_collateral_token: contract_address_const::<'initial_collateral_token'>(),
        //swap_path,
        size_delta_usd: 1000,
        initial_collateral_delta_amount: 500,
        trigger_price: 2000,
        acceptable_price: 2500,
        execution_fee: 100,
        callback_gas_limit: 300000,
        min_output_amount: 100,
        updated_at_block: 0,
        is_long: true,
        should_unwrap_native_token: false,
        is_frozen: false,
    }
}
