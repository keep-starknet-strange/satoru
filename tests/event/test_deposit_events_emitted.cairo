use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};
use satoru::utils::span32::{Span32, Array32Trait};

use satoru::event::event_emitter::{
    EventEmitter, IEventEmitterDispatcher, IEventEmitterDispatcherTrait
};
use satoru::event::event_emitter::EventEmitter::{DepositCreated, DepositExecuted, DepositCancelled};

use satoru::deposit::{
    deposit::Deposit, deposit_utils::CreateDepositParams, deposit_utils::create_deposit,
    deposit_utils::cancel_deposit,
    deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait}
};

// satoru::tests_lib::setup_event_emitter;

#[test]
fn given_normal_conditions_when_emit_deposit_created_then_works() {
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
    let dummy_deposit: Deposit = create_dummy_deposit(key);

    // Emit the event.
    event_emitter.emit_deposit_created(key, dummy_deposit);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::DepositCreated(
                        DepositCreated {
                            key: key,
                            account: dummy_deposit.account,
                            receiver: dummy_deposit.receiver,
                            callback_contract: dummy_deposit.callback_contract,
                            // ui_fee_receiver: dummy_deposit.ui_fee_receiver.span(),
                            market: dummy_deposit.market,
                            initial_long_token: dummy_deposit.initial_long_token,
                            initial_short_token: dummy_deposit.initial_short_token,
                            long_token_swap_path: dummy_deposit.long_token_swap_path,
                            short_token_swap_path: dummy_deposit.short_token_swap_path,
                            initial_long_token_amount: dummy_deposit.initial_long_token_amount,
                            initial_short_token_amount: dummy_deposit.initial_short_token_amount,
                            min_market_tokens: dummy_deposit.min_market_tokens,
                            updated_at_block: dummy_deposit.updated_at_block,
                            execution_fee: dummy_deposit.execution_fee,
                            callback_gas_limit: dummy_deposit.callback_gas_limit,
                        }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_deposit_executed_then_works() {
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
    let long_token_amount: u128 = 10;
    let short_token_amount: u128 = 20;
    let received_market_tokens: u128 = 30;

    // Emit the event.
    event_emitter
        .emit_deposit_executed(key, long_token_amount, short_token_amount, received_market_tokens);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::DepositExecuted(
                        DepositExecuted {
                            key: key,
                            long_token_amount: long_token_amount,
                            short_token_amount: short_token_amount,
                            received_market_tokens: received_market_tokens,
                        }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

fn given_normal_conditions_when_emit_deposit_cancelled_then_works() {
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
    let reason: felt252 = 10;
    let reason_bytes = array!['0x00', '0x01'];

    // Emit the event.
    event_emitter.emit_deposit_cancelled(key, reason, reason_bytes.span());

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::DepositCancelled(
                        DepositCancelled {
                            key: key, reason: reason, reason_bytes: reason_bytes.span(),
                        }
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

fn create_dummy_deposit(key: felt252) -> Deposit {
    Deposit {
        key,
        account: contract_address_const::<'account'>(),
        receiver: contract_address_const::<'receiver'>(),
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'fee_receiver'>(),
        market: contract_address_const::<'market'>(),
        initial_long_token: contract_address_const::<'long_token'>(),
        initial_short_token: contract_address_const::<'short_token'>(),
        long_token_swap_path: array![contract_address_const::<'long_swap'>()].span32(),
        short_token_swap_path: array![contract_address_const::<'short_swap'>()].span32(),
        initial_long_token_amount: 10,
        initial_short_token_amount: 20,
        min_market_tokens: 30,
        updated_at_block: 40,
        execution_fee: 50,
        callback_gas_limit: 60,
    }
}
