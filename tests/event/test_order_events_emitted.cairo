use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use satoru::order::order::{Order, OrderType, SecondaryOrderType};

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


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the event emitter contract.
/// * `IEventEmitterSafeDispatcher` - The event emitter store dispatcher.
fn setup() -> (ContractAddress, IEventEmitterSafeDispatcher) {
    let contract = declare('EventEmitter');
    let contract_address = contract.deploy(@array![]).unwrap();
    let event_emitter = IEventEmitterSafeDispatcher { contract_address };
    return (contract_address, event_emitter);
}


/// Utility function to create a dummy order.
fn create_dummy_order() -> Order {
    let mut swap_path = array![];
    swap_path.append(contract_address_const::<'swap_path_0'>());
    swap_path.append(contract_address_const::<'swap_path_1'>());
    Order {
        order_type: OrderType::StopLossDecrease,
        account: contract_address_const::<'account'>(),
        receiver: contract_address_const::<'receiver'>(),
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
        market: contract_address_const::<'market'>(),
        initial_collateral_token: contract_address_const::<'initial_collateral_token'>(),
        swap_path,
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
