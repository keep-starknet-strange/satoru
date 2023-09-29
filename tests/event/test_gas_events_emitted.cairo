use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::tests_lib::setup_event_emitter;

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};


#[test]
fn given_normal_conditions_when_emit_execution_fee_refund_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let receiver = contract_address_const::<'receiver'>();
    let refund_fee_amount: u128 = 1;

    // Create the expected data.
    let expected_data: Array<felt252> = array![receiver.into(), refund_fee_amount.into()];

    // Emit the event.
    event_emitter.emit_execution_fee_refund(receiver, refund_fee_amount);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'ExecutionFeeRefund',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_keeper_execution_fee_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let keeper = contract_address_const::<'keeper'>();
    let execution_fee_amount: u128 = 1;

    // Create the expected data.
    let expected_data: Array<felt252> = array![keeper.into(), execution_fee_amount.into()];

    // Emit the event.
    event_emitter.emit_keeper_execution_fee(keeper, execution_fee_amount);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'KeeperExecutionFee',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}
