use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::tests_lib::setup_event_emitter;

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};


#[test]
fn given_normal_conditions_when_emit_set_bool_then_works() {
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
    event_emitter.emit_set_bool(key, data.span(), value);
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
fn given_normal_conditions_when_emit_set_address_then_works() {
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
    event_emitter.emit_set_address(key, data.span(), value);
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
fn given_normal_conditions_when_emit_set_felt252_then_works() {
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
    event_emitter.emit_set_felt252(key, data.span(), value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address, name: 'SetFelt252', keys: array![], data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_set_uint_then_works() {
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
    let value: u128 = 10;

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    data.serialize(ref expected_data);
    expected_data.append(value.into());

    // Emit the event.
    event_emitter.emit_set_uint(key, data.span(), value);
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

// TODO: update type when int will be supported.
#[test]
fn given_normal_conditions_when_emit_set_int_then_works() {
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
    let value = -10;

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];
    data.serialize(ref expected_data);
    expected_data.append(value);

    // Emit the event.
    event_emitter.emit_set_int(key, data.span(), value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address, name: 'SetInt', keys: array![], data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}
