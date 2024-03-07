use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::tests_lib::setup_event_emitter;

use satoru::event::event_emitter::{
    EventEmitter, IEventEmitterDispatcher, IEventEmitterDispatcherTrait
};

use satoru::event::event_emitter::EventEmitter::{
    SignalAddOracleSigner, AddOracleSigner, SignalSetFeeReceiver, SignalRemoveOracleSigner,
    RemoveOracleSigner, SetFeeReceiver, SignalGrantRole, GrantRole, SignalRevokeRole, RevokeRole,
    SignalSetPriceFeed, SetPriceFeed, SignalPendingAction, ClearPendingAction
};


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

    // Emit the event.
    event_emitter.emit_signal_add_oracle_signer(action_key, account);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::SignalAddOracleSigner(
                        SignalAddOracleSigner { action_key: action_key, account: account }
                    )
                )
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

    // Emit the event.
    event_emitter.emit_add_oracle_signer(action_key, account);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::AddOracleSigner(
                        AddOracleSigner { action_key: action_key, account: account }
                    )
                )
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

    // Emit the event.
    event_emitter.emit_signal_remove_oracle_signer(action_key, account);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::SignalRemoveOracleSigner(
                        SignalRemoveOracleSigner { action_key: action_key, account: account }
                    )
                )
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

    // Emit the event.
    event_emitter.emit_remove_oracle_signer(action_key, account);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::RemoveOracleSigner(
                        RemoveOracleSigner { action_key: action_key, account: account }
                    )
                )
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

    // Emit the event.
    event_emitter.emit_signal_set_fee_receiver(action_key, account);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::SignalSetFeeReceiver(
                        SignalSetFeeReceiver { action_key: action_key, account: account }
                    )
                )
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

    // Emit the event.
    event_emitter.emit_set_fee_receiver(action_key, account);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::SetFeeReceiver(
                        SetFeeReceiver { action_key: action_key, account: account }
                    )
                )
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

    // Emit the event.
    event_emitter.emit_signal_grant_role(action_key, account, role_key);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::SignalGrantRole(
                        SignalGrantRole {
                            action_key: action_key, account: account, role_key: role_key
                        }
                    )
                )
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

    // Emit the event.
    event_emitter.emit_grant_role(action_key, account, role_key);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::GrantRole(
                        GrantRole { action_key: action_key, account: account, role_key: role_key }
                    )
                )
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

    // Emit the event.
    event_emitter.emit_signal_revoke_role(action_key, account, role_key);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::SignalRevokeRole(
                        SignalRevokeRole {
                            action_key: action_key, account: account, role_key: role_key
                        }
                    )
                )
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

    // Emit the event.
    event_emitter.emit_revoke_role(action_key, account, role_key);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::RevokeRole(
                        RevokeRole { action_key: action_key, account: account, role_key: role_key }
                    )
                )
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
    let price_feed_multiplier: u256 = 1;
    let price_feed_heartbeat_duration: u256 = 2;
    let stable_price: u256 = 3;

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
                (
                    contract_address,
                    EventEmitter::Event::SignalSetPriceFeed(
                        SignalSetPriceFeed {
                            action_key: action_key,
                            token: token,
                            price_feed: price_feed,
                            price_feed_multiplier: price_feed_multiplier,
                            price_feed_heartbeat_duration: price_feed_heartbeat_duration,
                            stable_price: stable_price
                        }
                    )
                )
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
    let price_feed_multiplier: u256 = 1;
    let price_feed_heartbeat_duration: u256 = 2;
    let stable_price: u256 = 3;

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
                (
                    contract_address,
                    EventEmitter::Event::SetPriceFeed(
                        SetPriceFeed {
                            action_key: action_key,
                            token: token,
                            price_feed: price_feed,
                            price_feed_multiplier: price_feed_multiplier,
                            price_feed_heartbeat_duration: price_feed_heartbeat_duration,
                            stable_price: stable_price
                        }
                    )
                )
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

    // Emit the event.
    event_emitter.emit_signal_pending_action(action_key, action_label);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::SignalPendingAction(
                        SignalPendingAction { action_key: action_key, action_label: action_label }
                    )
                )
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

    // Emit the event.
    event_emitter.emit_clear_pending_action(action_key, action_label);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::ClearPendingAction(
                        ClearPendingAction { action_key: action_key, action_label: action_label }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}
