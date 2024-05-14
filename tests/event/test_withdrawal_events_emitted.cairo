use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::event::event_emitter::{
    EventEmitter, IEventEmitterDispatcher, IEventEmitterDispatcherTrait
};

use satoru::event::event_emitter::EventEmitter::{
    WithdrawalCreated, WithdrawalExecuted, WithdrawalCancelled
};


use satoru::withdrawal::withdrawal::Withdrawal;
use satoru::tests_lib::setup_event_emitter;

#[test]
fn given_normal_conditions_when_emit_withdrawal_created_then_works() {
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

    // Emit the event.
    event_emitter.emit_withdrawal_created(key, withdrawal);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::WithdrawalCreated(
                        WithdrawalCreated {
                            key: key,
                            account: withdrawal.account,
                            receiver: withdrawal.receiver,
                            callback_contract: withdrawal.callback_contract,
                            market: withdrawal.market,
                            market_token_amount: withdrawal.market_token_amount,
                            min_long_token_amount: withdrawal.min_long_token_amount,
                            min_short_token_amount: withdrawal.min_short_token_amount,
                            updated_at_block: withdrawal.updated_at_block,
                            execution_fee: withdrawal.execution_fee,
                            callback_gas_limit: withdrawal.callback_gas_limit,
                        }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_withdrawal_executed_then_works() {
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

    // Emit the event.
    event_emitter.emit_withdrawal_executed(key);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::WithdrawalExecuted(WithdrawalExecuted { key: key, })
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_withdrawal_cancelled_then_works() {
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

    // Emit the event.
    event_emitter.emit_withdrawal_cancelled(key, reason, reason_bytes.span());

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::WithdrawalCancelled(
                        WithdrawalCancelled {
                            key: key, reason: reason, reason_bytes: reason_bytes.span()
                        }
                    )
                )
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
    }
}
