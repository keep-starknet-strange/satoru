use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::withdrawal::withdrawal::Withdrawal;
use satoru::tests_lib::{setup_event_emitter};

#[test]
fn test_emit_withdrawal_created() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key: felt252 = 100;
    let withdrawal: Withdrawal = create_dummy_withdrawal(key);

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![
        key,
        withdrawal.account.into(),
        withdrawal.receiver.into(),
        withdrawal.callback_contract.into(),
        withdrawal.market.into(),
        withdrawal.market_token_amount.into(),
        withdrawal.min_long_token_amount.into(),
        withdrawal.min_short_token_amount.into(),
        withdrawal.updated_at_block.into(),
        withdrawal.execution_fee.into(),
        withdrawal.callback_gas_limit.into(),
        withdrawal.should_unwrap_native_token.into(),
    ];

    // Emit the event.
    event_emitter.emit_withdrawal_created(key, withdrawal);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'WithdrawalCreated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_withdrawal_executed() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key: felt252 = 100;

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key];

    // Emit the event.
    event_emitter.emit_withdrawal_executed(key);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'WithdrawalExecuted',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_withdrawal_cancelled() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let key: felt252 = 100;
    let reason: felt252 = 'cancel';
    let reason_bytes = array!['0x00', '0x01'];

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![key, reason];
    reason_bytes.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_withdrawal_cancelled(key, reason, reason_bytes);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'WithdrawalCancelled',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

/// Utility function to create a dummy withdrawal.
fn create_dummy_withdrawal(key: felt252) -> Withdrawal {
    let account = contract_address_const::<'account'>();
    Withdrawal {
        key,
        account,
        receiver: account,
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'fee_receiver'>(),
        market: contract_address_const::<'market'>(),
        long_token_swap_path: Default::default(),
        short_token_swap_path: Default::default(),
        market_token_amount: 1,
        min_long_token_amount: 1,
        min_short_token_amount: 1,
        updated_at_block: 1,
        execution_fee: 1,
        callback_gas_limit: 1,
        should_unwrap_native_token: true,
    }
}
