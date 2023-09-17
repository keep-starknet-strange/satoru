use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};
use option::OptionTrait;

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};

use satoru::tests_lib::setup_event_emitter;

#[test]
fn given_normal_conditions_when_emit_adl_state_updated_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let market: ContractAddress = contract_address_const::<'market'>();
    let is_long: bool = true;
    let pnl_to_pool_factor: felt252 = 1;
    let max_pnl_factor: u128 = 10;
    let should_enable_adl: bool = false;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(),
        is_long.into(),
        pnl_to_pool_factor,
        max_pnl_factor.into(),
        should_enable_adl.into()
    ];

    // Emit the event.
    event_emitter
        .emit_adl_state_updated(
            market, is_long, pnl_to_pool_factor, max_pnl_factor, should_enable_adl
        );
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'AdlStateUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}
