use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::tests_lib::{setup_event_emitter};

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::market::market_pool_value_info::{MarketPoolValueInfo};

#[test]
fn test_emit_market_pool_value_info() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let market = contract_address_const::<'market'>();
    let market_pool_value_info: MarketPoolValueInfo = create_dummy_market_pool_value_info();
    let market_tokens_supply: u256 = 1;

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![market.into()];
    market_pool_value_info.serialize(ref expected_data);
    market_tokens_supply.serialize(ref expected_data);
    // Emit the event.
    event_emitter.emit_market_pool_value_info(market, market_pool_value_info, market_tokens_supply);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'MarketPoolValueInfoEvent',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

fn create_dummy_market_pool_value_info() -> MarketPoolValueInfo {
    MarketPoolValueInfo {
        pool_value: 1,
        long_pnl: 2,
        short_pnl: 3,
        net_pnl: 4,
        long_token_amount: 5,
        short_token_amount: 6,
        long_token_usd: 7,
        short_token_usd: 8,
        total_borrowing_fees: 9,
        borrowing_fee_pool_factor: 10,
        impact_pool_amount: 11,
    }
}