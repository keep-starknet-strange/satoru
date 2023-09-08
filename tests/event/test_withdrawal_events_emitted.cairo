use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::withdrawal::withdrawal::Withdrawal;

#[test]
fn test_emit_withdrawal_created() {
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
        market_token_amount: 1,
        min_long_token_amount: 1,
        min_short_token_amount: 1,
        updated_at_block: 1,
        execution_fee: 1,
        callback_gas_limit: 1,
        should_unwrap_native_token: true,
    }
}
