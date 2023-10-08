use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};
use satoru::tests_lib::setup_event_emitter;

use satoru::pricing::position_pricing_utils::{
    PositionFees, PositionUiFees, PositionBorrowingFees, PositionReferralFees, PositionFundingFees
};

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};

#[test]
fn given_normal_conditions_when_emit_swap_reverted_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a dummy data.
    let reason = 'reverted';
    let reason_bytes = array!['0x01'];

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![reason];

    reason_bytes.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_swap_reverted(reason, reason_bytes.span());

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'SwapReverted',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}
