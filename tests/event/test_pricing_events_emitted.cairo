use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};
use satoru::tests_lib::{setup_event_emitter};
use satoru::position::{
    position_event_utils::PositionIncreaseParams, position::Position,
    position_utils::DecreasePositionCollateralValues,
    position_utils::DecreasePositionCollateralValuesOutput
};
use satoru::pricing::position_pricing_utils::{
    PositionFees, PositionUiFees, PositionBorrowingFees, PositionReferralFees, PositionFundingFees
};
use satoru::order::order::OrderType;
use satoru::price::price::Price;
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};

#[test]
fn test_emit_swap_info() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a dummy data.
    let order_key = 'swap';
    let market = contract_address_const::<'market'>();
    let receiver = contract_address_const::<'receiver'>();
    let token_in = contract_address_const::<'token_in'>();
    let token_out = contract_address_const::<'token_out'>();
    let token_in_price: u128 = 1;
    let token_out_price: u128 = 2;
    let amount_in: u128 = 3;
    let amount_in_after_fees: u128 = 4;
    let amount_out: u128 = 5;
    let price_impact_usd: u128 = 6;
    let price_impact_amount: u128 = 7;

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![
        order_key,
        market.into(),
        receiver.into(),
        token_in.into(),
        token_out.into(),
        token_in_price.into(),
        token_out_price.into(),
        amount_in.into(),
        amount_in_after_fees.into(),
        amount_out.into(),
        price_impact_usd.into(),
        price_impact_amount.into()
    ];

    // Emit the event.
    event_emitter
        .emit_swap_info(
            order_key,
            market,
            receiver,
            token_in,
            token_out,
            token_in_price,
            token_out_price,
            amount_in,
            amount_in_after_fees,
            amount_out,
            price_impact_usd,
            price_impact_amount
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address, name: 'SwapInfo', keys: array![], data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}
