use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::tests_lib::setup_event_emitter;

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::market::market_pool_value_info::MarketPoolValueInfo;

#[test]
fn given_normal_conditions_when_emit_market_pool_value_info_then_works() {
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
    let market_tokens_supply: u128 = 1;

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![market.into()];
    market_pool_value_info.serialize(ref expected_data);
    expected_data.append(market_tokens_supply.into());

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

#[test]
fn given_normal_conditions_when_emit_pool_amount_updated_then_works() {
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
    let token = contract_address_const::<'token'>();
    let delta: i128 = 1;
    let next_value: u128 = 2;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(), token.into(), delta.into(), next_value.into()
    ];

    // Emit the event.
    event_emitter.emit_pool_amount_updated(market, token, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'PoolAmountUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_swap_impact_pool_amount_updated_then_works() {
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
    let token = contract_address_const::<'token'>();
    let delta: u128 = 1;
    let next_value: u128 = 2;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(), token.into(), delta.into(), next_value.into()
    ];

    // Emit the event.
    event_emitter.emit_swap_impact_pool_amount_updated(market, token, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'SwapImpactPoolAmountUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_position_impact_pool_amount_updated_then_works() {
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
    let delta: u128 = 1;
    let next_value: u128 = 2;

    // Create the expected data.
    let expected_data: Array<felt252> = array![market.into(), delta.into(), next_value.into()];

    // Emit the event.
    event_emitter.emit_position_impact_pool_amount_updated(market, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'PositionImpactPoolAmountUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_open_interest_in_tokens_updated_then_works() {
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
    let collateral_token = contract_address_const::<'collateral_token'>();
    let is_long: bool = true;
    let delta: i128 = 1;
    let next_value: u128 = 2;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(), collateral_token.into(), is_long.into(), delta.into(), next_value.into()
    ];

    // Emit the event.
    event_emitter
        .emit_open_interest_in_tokens_updated(market, collateral_token, is_long, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'OpenInterestInTokensUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_open_interest_updated_then_works() {
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
    let collateral_token = contract_address_const::<'collateral_token'>();
    let is_long: bool = true;
    let delta: u128 = 1;
    let next_value: u128 = 2;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(), collateral_token.into(), is_long.into(), delta.into(), next_value.into()
    ];

    // Emit the event.
    event_emitter.emit_open_interest_updated(market, collateral_token, is_long, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'OpenInterestUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_virtual_swap_inventory_updated_then_works() {
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
    let is_long_token: bool = true;
    let virtual_market_id = 'virtual_market_id';
    let delta: u128 = 1;
    let next_value: u128 = 2;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(), is_long_token.into(), virtual_market_id, delta.into(), next_value.into()
    ];

    // Emit the event.
    event_emitter
        .emit_virtual_swap_inventory_updated(
            market, is_long_token, virtual_market_id, delta, next_value
        );
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'VirtualSwapInventoryUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_virtual_position_inventory_updated_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let token = contract_address_const::<'token'>();
    let virtual_token_id = 'virtual_token_id';
    let delta: u128 = 1;
    let next_value: u128 = 2;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        token.into(), virtual_token_id, delta.into(), next_value.into()
    ];

    // Emit the event.
    event_emitter
        .emit_virtual_position_inventory_updated(token, virtual_token_id, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'VirtualPositionInventoryUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_collateral_sum_updated_then_works() {
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
    let collateral_token = contract_address_const::<'collateral_token'>();
    let is_long: bool = true;
    let delta: i128 = 1;
    let next_value: u128 = 2;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(), collateral_token.into(), is_long.into(), delta.into(), next_value.into()
    ];

    // Emit the event.
    event_emitter.emit_collateral_sum_updated(market, collateral_token, is_long, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'CollateralSumUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_cumulative_borrowing_factor_updated_then_works() {
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

    let is_long: bool = true;
    let delta: u128 = 1;
    let next_value: u128 = 2;

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![
        market.into(), is_long.into(), delta.into(), next_value.into()
    ];

    // Emit the event.
    event_emitter.emit_cumulative_borrowing_factor_updated(market, is_long, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'CumulativeBorrowingFactorUpdatd',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_funding_fee_amount_per_size_updated_then_works() {
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
    let collateral_token = contract_address_const::<'collateral_token'>();

    let is_long: bool = true;
    let delta: u128 = 1;
    let next_value: u128 = 2;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(), collateral_token.into(), is_long.into(), delta.into(), next_value.into()
    ];

    // Emit the event.
    event_emitter
        .emit_funding_fee_amount_per_size_updated(
            market, collateral_token, is_long, delta, next_value
        );
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'FundingFeeAmountPerSizeUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_claimable_funding_amount_per_size_updated_then_works() {
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
    let collateral_token = contract_address_const::<'collateral_token'>();
    let is_long: bool = true;
    let delta: u128 = 1;
    let next_value: u128 = 2;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(), collateral_token.into(), is_long.into(), delta.into(), next_value.into()
    ];

    // Emit the event.
    event_emitter
        .emit_claimable_funding_amount_per_size_updated(
            market, collateral_token, is_long, delta, next_value
        );
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'ClaimableFundingPerSizeUpdatd',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_claimable_funding_updated_then_works() {
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
    let token = contract_address_const::<'token'>();
    let account = contract_address_const::<'account'>();
    let delta: u128 = 1;
    let next_value: u128 = 2;
    let next_pool_value: u128 = 2;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(),
        token.into(),
        account.into(),
        delta.into(),
        next_value.into(),
        next_pool_value.into()
    ];

    // Emit the event.
    event_emitter
        .emit_claimable_funding_updated(market, token, account, delta, next_value, next_pool_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'ClaimableFundingUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_funding_fees_claimed_then_works() {
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
    let token = contract_address_const::<'token'>();
    let account = contract_address_const::<'account'>();
    let receiver = contract_address_const::<'receiver'>();
    let amount: u128 = 1;
    let next_pool_value: u128 = 2;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(),
        token.into(),
        account.into(),
        receiver.into(),
        amount.into(),
        next_pool_value.into()
    ];

    // Emit the event.
    event_emitter
        .emit_funding_fees_claimed(market, token, account, receiver, amount, next_pool_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'FundingFeesClaimed',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_claimable_collateral_updated_then_works() {
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
    let token = contract_address_const::<'token'>();
    let account = contract_address_const::<'account'>();

    let time_key: u128 = 1;
    let delta: u128 = 2;
    let next_value: u128 = 3;
    let next_pool_value: u128 = 4;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(),
        token.into(),
        account.into(),
        time_key.into(),
        delta.into(),
        next_value.into(),
        next_pool_value.into()
    ];

    // Emit the event.
    event_emitter
        .emit_claimable_collateral_updated(
            market, token, account, time_key, delta, next_value, next_pool_value
        );
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'ClaimableCollateralUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_collateral_claimed_then_works() {
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
    let token = contract_address_const::<'token'>();
    let account = contract_address_const::<'account'>();
    let receiver = contract_address_const::<'receiver'>();

    let time_key: u128 = 1;
    let amount: u128 = 2;
    let next_pool_value: u128 = 3;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(),
        token.into(),
        account.into(),
        receiver.into(),
        time_key.into(),
        amount.into(),
        next_pool_value.into()
    ];

    // Emit the event.
    event_emitter
        .emit_collateral_claimed(
            market, token, account, receiver, time_key, amount, next_pool_value
        );
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'CollateralClaimed',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_ui_fee_factor_updated_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let account = contract_address_const::<'account'>();
    let ui_fee_factor: u128 = 1;

    // Create the expected data.
    let expected_data: Array<felt252> = array![account.into(), ui_fee_factor.into()];

    // Emit the event.
    event_emitter.emit_ui_fee_factor_updated(account, ui_fee_factor);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'UiFeeFactorUpdated',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_market_created_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create dummy data.
    let creator = contract_address_const::<'creator'>();
    let market_token = contract_address_const::<'market_token'>();
    let index_token = contract_address_const::<'index_token'>();
    let long_token = contract_address_const::<'long_token'>();
    let short_token = contract_address_const::<'short_token'>();
    let market_type = 'type';

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        creator.into(),
        market_token.into(),
        index_token.into(),
        long_token.into(),
        short_token.into(),
        market_type
    ];

    // Emit the event.
    event_emitter
        .emit_market_created(
            creator, market_token, index_token, long_token, short_token, market_type
        );
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'MarketCreated',
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
