use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::tests_lib::setup_event_emitter;

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};


#[test]
fn given_normal_conditions_when_emit_signal_add_oracle_signer_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'SignalAddOracleSigner';
    let account = contract_address_const::<'account'>();

    // Create the expected data.
    let expected_data: Array<felt252> = array![action_key, account.into()];

    // Emit the event.
    event_emitter.emit_signal_add_oracle_signer(action_key, account);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'SignalAddOracleSigner',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_add_oracle_signer_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'AddOracleSigner';
    let account = contract_address_const::<'account'>();

    // Create the expected data.
    let expected_data: Array<felt252> = array![action_key, account.into()];

    // Emit the event.
    event_emitter.emit_add_oracle_signer(action_key, account);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'AddOracleSigner',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_signal_remove_oracle_signer_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'SignalRemoveOracleSigner';
    let account = contract_address_const::<'account'>();

    // Create the expected data.
    let expected_data: Array<felt252> = array![action_key, account.into()];

    // Emit the event.
    event_emitter.emit_signal_remove_oracle_signer(action_key, account);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'SignalRemoveOracleSigner',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_remove_oracle_signer_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'RemoveOracleSigner';
    let account = contract_address_const::<'account'>();

    // Create the expected data.
    let expected_data: Array<felt252> = array![action_key, account.into()];

    // Emit the event.
    event_emitter.emit_remove_oracle_signer(action_key, account);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'RemoveOracleSigner',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_signal_set_fee_receiver_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'SignalSetFeeReceiver';
    let account = contract_address_const::<'account'>();

    // Create the expected data.
    let expected_data: Array<felt252> = array![action_key, account.into()];

    // Emit the event.
    event_emitter.emit_signal_set_fee_receiver(action_key, account);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'SignalSetFeeReceiver',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_set_fee_receiver_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'SetFeeReceiver';
    let account = contract_address_const::<'account'>();

    // Create the expected data.
    let expected_data: Array<felt252> = array![action_key, account.into()];

    // Emit the event.
    event_emitter.emit_set_fee_receiver(action_key, account);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'SetFeeReceiver',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_signal_grant_role_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'SignalGrantRole';
    let account = contract_address_const::<'account'>();
    let role_key = 'Admin';

    // Create the expected data.
    let expected_data: Array<felt252> = array![action_key, account.into(), role_key];

    // Emit the event.
    event_emitter.emit_signal_grant_role(action_key, account, role_key);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'SignalGrantRole',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_grant_role_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'GrantRole';
    let account = contract_address_const::<'account'>();
    let role_key = 'Admin';

    // Create the expected data.
    let expected_data: Array<felt252> = array![action_key, account.into(), role_key];

    // Emit the event.
    event_emitter.emit_grant_role(action_key, account, role_key);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address, name: 'GrantRole', keys: array![], data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_signal_revoke_role_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'SignalRevokeRole';
    let account = contract_address_const::<'account'>();
    let role_key = 'Admin';

    // Create the expected data.
    let expected_data: Array<felt252> = array![action_key, account.into(), role_key];

    // Emit the event.
    event_emitter.emit_signal_revoke_role(action_key, account, role_key);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'SignalRevokeRole',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_revoke_role_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'RevokeRole';
    let account = contract_address_const::<'account'>();
    let role_key = 'Admin';

    // Create the expected data.
    let expected_data: Array<felt252> = array![action_key, account.into(), role_key];

    // Emit the event.
    event_emitter.emit_revoke_role(action_key, account, role_key);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address, name: 'RevokeRole', keys: array![], data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_signal_set_price_feed_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'SignalSetPriceFeed';
    let token = contract_address_const::<'token'>();
    let price_feed = contract_address_const::<'priceFeed'>();
    let price_feed_multiplier: u128 = 1;
    let price_feed_heartbeat_duration: u128 = 2;
    let stable_price: u128 = 3;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        action_key,
        token.into(),
        price_feed.into(),
        price_feed_multiplier.into(),
        price_feed_heartbeat_duration.into(),
        stable_price.into()
    ];

    // Emit the event.
    event_emitter
        .emit_signal_set_price_feed(
            action_key,
            token,
            price_feed,
            price_feed_multiplier,
            price_feed_heartbeat_duration,
            stable_price
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'SignalSetPriceFeed',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}


#[test]
fn given_normal_conditions_when_emit_set_price_feed_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'SetPriceFeed';
    let token = contract_address_const::<'token'>();
    let price_feed = contract_address_const::<'priceFeed'>();
    let price_feed_multiplier: u128 = 1;
    let price_feed_heartbeat_duration: u128 = 2;
    let stable_price: u128 = 3;

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![
        action_key,
        token.into(),
        price_feed.into(),
        price_feed_multiplier.into(),
        price_feed_heartbeat_duration.into(),
        stable_price.into()
    ];

    // Emit the event.
    event_emitter
        .emit_set_price_feed(
            action_key,
            token,
            price_feed,
            price_feed_multiplier,
            price_feed_heartbeat_duration,
            stable_price
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'SetPriceFeed',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_signal_pending_action_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'SignalPendingAction';
    let action_label = 'SignalPendingAction';

    // Create the expected data.
    let expected_data: Array<felt252> = array![action_key, action_label];

    // Emit the event.
    event_emitter.emit_signal_pending_action(action_key, action_label);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'SignalPendingAction',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_clear_pending_action_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let action_key = 'ClearPendingAction';
    let action_label = 'ClearPendingAction';

    // Create the expected data.
    let expected_data: Array<felt252> = array![action_key, action_label];

    // Emit the event.
    event_emitter.emit_clear_pending_action(action_key, action_label);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'ClearPendingAction',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}
