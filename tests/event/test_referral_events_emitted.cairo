use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};

#[test]
fn test_emit_affiliate_reward_updated() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a dummy data.
    let market = contract_address_const::<'market'>();
    let token = contract_address_const::<'token'>();
    let affiliate = contract_address_const::<'affiliate'>();
    let delta: u128 = 100;
    let next_value: u128 = 200;
    let next_pool_value: u128 = 300;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(),
        token.into(),
        affiliate.into(),
        delta.into(),
        next_value.into(),
        next_pool_value.into()
    ];

    // Emit the event.
    event_emitter
        .emit_affiliate_reward_updated(
            market, token, affiliate, delta, next_value, next_pool_value
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'AffiliateRewardUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_affiliate_reward_claimed() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a dummy data.
    let market = contract_address_const::<'market'>();
    let token = contract_address_const::<'token'>();
    let affiliate = contract_address_const::<'affiliate'>();
    let receiver = contract_address_const::<'receiver'>();
    let amount: u128 = 100;
    let next_pool_value: u128 = 200;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(),
        token.into(),
        affiliate.into(),
        receiver.into(),
        amount.into(),
        next_pool_value.into()
    ];

    // Emit the event.
    event_emitter
        .emit_affiliate_reward_claimed(market, token, affiliate, receiver, amount, next_pool_value);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'AffiliateRewardClaimed',
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
/// * `IEventEmitterSafeDispatcher` - The event emitter store dispatcher.
fn setup() -> (ContractAddress, IEventEmitterSafeDispatcher) {
    let contract = declare('EventEmitter');
    let contract_address = contract.deploy(@array![]).unwrap();
    let event_emitter = IEventEmitterSafeDispatcher { contract_address };
    return (contract_address, event_emitter);
}
