use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::tests_lib::{setup_event_emitter};

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};


#[test]
fn test_emit_set_bool() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 'set_bool';
    let data = array!['0x01'];
    let value = true;

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    data.serialize(ref expected_data);
    expected_data.append(value.into());

    // Emit the event.
    event_emitter.emit_set_bool(key, data, value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address, name: 'SetBool', keys: array![], data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_set_address() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 'set_address';
    let data = array!['0x01'];
    let value = contract_address_const::<'dummy_address'>();

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    data.serialize(ref expected_data);
    expected_data.append(value.into());

    // Emit the event.
    event_emitter.emit_set_address(key, data, value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address, name: 'SetAddress', keys: array![], data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_set_bytes32() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 'set_address';
    let data = array!['0x01'];
    let value = 'bytes32';

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    data.serialize(ref expected_data);
    expected_data.append(value.into());

    // Emit the event.
    event_emitter.emit_set_bytes32(key, data, value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address, name: 'SetBytes32', keys: array![], data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_set_uint() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key = 'set_address';
    let data = array!['0x01'];
    let value: u256 = 10;

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    data.serialize(ref expected_data);
    value.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_set_uint(key, data, value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address, name: 'SetUint', keys: array![], data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}
