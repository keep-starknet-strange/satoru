use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::event::event_emitter::{
    EventEmitter, IEventEmitterDispatcher, IEventEmitterDispatcherTrait
};

use satoru::event::event_emitter::EventEmitter::{
    OrderCreated, OrderExecuted, OrderUpdated, OrderSizeDeltaAutoUpdated,
    OrderCollateralDeltaAmountAutoUpdated, OrderCancelled, OrderFrozen,
};


use satoru::order::order::{Order, OrderType, SecondaryOrderType, DecreasePositionSwapType};
use satoru::tests_lib::setup_event_emitter;
use satoru::utils::span32::{Span32, Array32Trait};

#[test]
fn given_normal_conditions_when_emit_order_created_then_works() {
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
    let order: Order = create_dummy_order(key);

    // Emit the event.
    event_emitter.emit_order_created(key, order);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::OrderCreated(OrderCreated { key: key, order: order })
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_order_executed_then_works() {
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

    // Emit the event.
    event_emitter.emit_order_executed(key, secondary_order_type);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::OrderExecuted(
                        OrderExecuted { key: key, secondary_order_type: secondary_order_type }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_order_updated_then_works() {
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

    // Emit the event.
    event_emitter
        .emit_order_updated(
            key, size_delta_usd, acceptable_price, trigger_price, min_output_amount
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::OrderUpdated(
                        OrderUpdated {
                            key: key,
                            size_delta_usd: size_delta_usd,
                            acceptable_price: acceptable_price,
                            trigger_price: trigger_price,
                            min_output_amount: min_output_amount
                        }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_order_size_delta_auto_updated_then_works() {
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

    // Emit the event.
    event_emitter.emit_order_size_delta_auto_updated(key, size_delta_usd, next_size_delta_usd);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::OrderSizeDeltaAutoUpdated(
                        OrderSizeDeltaAutoUpdated {
                            key: key,
                            size_delta_usd: size_delta_usd,
                            next_size_delta_usd: next_size_delta_usd,
                        }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_order_collateral_delta_amount_auto_updated_then_works() {
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

    // Emit the event.
    event_emitter
        .emit_order_collateral_delta_amount_auto_updated(
            key, collateral_delta_amount, next_collateral_delta_amount
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::OrderCollateralDeltaAmountAutoUpdated(
                        OrderCollateralDeltaAmountAutoUpdated {
                            key: key,
                            collateral_delta_amount: collateral_delta_amount,
                            next_collateral_delta_amount: next_collateral_delta_amount,
                        }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_order_cancelled_then_works() {
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

    // Emit the event.
    event_emitter.emit_order_cancelled(key, reason, reason_bytes.span());

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::OrderCancelled(
                        OrderCancelled {
                            key: key, reason: reason, reason_bytes: reason_bytes.span(),
                        }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_order_frozen_then_works() {
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

    // Emit the event.
    event_emitter.emit_order_frozen(key, reason, reason_bytes.span());

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::OrderFrozen(
                        OrderFrozen { key: key, reason: reason, reason_bytes: reason_bytes.span(), }
                    )
                )
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
fn create_dummy_order(key: felt252) -> Order {
    let swap_path: Span32<ContractAddress> = array![
        contract_address_const::<'swap_path_0'>(), contract_address_const::<'swap_path_1'>()
    ]
        .span32();
    Order {
        key,
        order_type: OrderType::StopLossDecrease,
        decrease_position_swap_type: DecreasePositionSwapType::SwapPnlTokenToCollateralToken(()),
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
        is_frozen: false,
    }
}
