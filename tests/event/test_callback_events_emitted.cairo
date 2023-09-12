use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};
use option::OptionTrait;
use satoru::tests_lib::setup_event_emitter;

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::deposit::deposit::Deposit;
use satoru::withdrawal::withdrawal::Withdrawal;
use satoru::order::order::{Order, OrderType, SecondaryOrderType, DecreasePositionSwapType};

#[test]
fn test_emit_after_deposit_execution_error() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 'deposit_execution_error';
    let deposit_data: Deposit = create_dummy_deposit();

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    deposit_data.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_after_deposit_execution_error(key, deposit_data);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'AfterDepositExecutionError',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_after_deposit_cancellation_error() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 'deposit_cancellation_error';
    let deposit_data: Deposit = create_dummy_deposit();

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    deposit_data.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_after_deposit_cancellation_error(key, deposit_data);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'AfterDepositCancellationError',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_after_withdrawal_execution_error() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 'withdrawal_execution_error';
    let withdrawal_data: Withdrawal = create_dummy_withdrawal();

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    withdrawal_data.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_after_withdrawal_execution_error(key, withdrawal_data);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'AfterWithdrawalExecutionError',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_after_withdrawal_cancellation_error() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 'withdrawal_cancel_error';
    let withdrawal_data: Withdrawal = create_dummy_withdrawal();

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    withdrawal_data.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_after_withdrawal_cancellation_error(key, withdrawal_data);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'AfterWithdrawalCancelError',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_after_order_execution_error() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 'order_execution_error';
    let order_data: Order = create_dummy_order(key);

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    order_data.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_after_order_execution_error(key, order_data);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'AfterOrderExecutionError',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_after_order_cancellation_error() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 'order_cancellation_error';
    let order_data: Order = create_dummy_order(key);

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    order_data.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_after_order_cancellation_error(key, order_data);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'AfterOrderCancellationError',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_after_order_frozen_error() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 'order_frozen_error';
    let order_data: Order = create_dummy_order(key);

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    order_data.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_after_order_frozen_error(key, order_data);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'AfterOrderFrozenError',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}


fn create_dummy_deposit() -> Deposit {
    Deposit {
        account: contract_address_const::<'account'>(),
        receiver: contract_address_const::<'receiver'>(),
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'fee_receiver'>(),
        market: contract_address_const::<'market'>(),
        initial_long_token: contract_address_const::<'long_token'>(),
        initial_short_token: contract_address_const::<'short_token'>(),
        long_token_swap_path: array![contract_address_const::<'long_swap'>()],
        short_token_swap_path: array![contract_address_const::<'short_swap'>()],
        initial_long_token_amount: 10,
        initial_short_token_amount: 20,
        min_market_tokens: 30,
        updated_at_block: 40,
        execution_fee: 50,
        callback_gas_limit: 60,
    }
}

fn create_dummy_withdrawal() -> Withdrawal {
    Withdrawal {
        key: 'withdraw',
        account: contract_address_const::<'account'>(),
        receiver: contract_address_const::<'receiver'>(),
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'fee_receiver'>(),
        market: contract_address_const::<'market'>(),
        long_token_swap_path: Default::default(),
        short_token_swap_path: Default::default(),
        market_token_amount: 10,
        min_long_token_amount: 20,
        min_short_token_amount: 30,
        updated_at_block: 40,
        execution_fee: 50,
        callback_gas_limit: 60,
        should_unwrap_native_token: false,
    }
}

fn create_dummy_order(key: felt252) -> Order {
    let mut swap_path = array![];
    swap_path.append(contract_address_const::<'swap_path_0'>());
    swap_path.append(contract_address_const::<'swap_path_1'>());
    Order {
        key,
        decrease_position_swap_type: DecreasePositionSwapType::SwapPnlTokenToCollateralToken(()),
        order_type: OrderType::StopLossDecrease,
        account: contract_address_const::<'account'>(),
        receiver: contract_address_const::<'receiver'>(),
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
        market: contract_address_const::<'market'>(),
        initial_collateral_token: contract_address_const::<'initial_collateral_token'>(),
        // swap_path,
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
