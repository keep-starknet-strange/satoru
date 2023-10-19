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
    MarketPoolValueInfoEvent, PoolAmountUpdated, SwapImpactPoolAmountUpdated,
    PositionImpactPoolAmountUpdated, OpenInterestInTokensUpdated, OpenInterestUpdated,
    VirtualSwapInventoryUpdated, VirtualPositionInventoryUpdated, CollateralSumUpdated,
    CumulativeBorrowingFactorUpdated, FundingFeeAmountPerSizeUpdated,
    ClaimableFundingAmountPerSizeUpdated, ClaimableFundingUpdated, FundingFeesClaimed,
    ClaimableCollateralUpdated, CollateralClaimed, UiFeeFactorUpdated, MarketCreated
};

use satoru::market::market_pool_value_info::MarketPoolValueInfo;
use satoru::utils::i128::{i128, i128_new};

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

    // Emit the event.
    event_emitter.emit_market_pool_value_info(market, market_pool_value_info, market_tokens_supply);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::MarketPoolValueInfoEvent(
                        MarketPoolValueInfoEvent {
                            market: market,
                            market_pool_value_info: market_pool_value_info,
                            market_tokens_supply: market_tokens_supply
                        }
                    )
                )
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
    let delta: i128 = i128_new(1, false);
    let next_value: u128 = 2;

    // Emit the event.
    event_emitter.emit_pool_amount_updated(market, token, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::PoolAmountUpdated(
                        PoolAmountUpdated {
                            market: market, token: token, delta: delta, next_value: next_value
                        }
                    )
                )
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
    let delta: i128 = i128_new(1, false);
    let next_value: u128 = 2;

    // Emit the event.
    event_emitter.emit_swap_impact_pool_amount_updated(market, token, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::SwapImpactPoolAmountUpdated(
                        SwapImpactPoolAmountUpdated {
                            market: market, token: token, delta: delta, next_value: next_value
                        }
                    )
                )
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
    let delta: i128 = i128_new(1, false);
    let next_value: u128 = 2;

    // Emit the event.
    event_emitter.emit_position_impact_pool_amount_updated(market, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::PositionImpactPoolAmountUpdated(
                        PositionImpactPoolAmountUpdated {
                            market: market, delta: delta, next_value: next_value
                        }
                    )
                )
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
    let delta: i128 = i128_new(1, false);
    let next_value: u128 = 2;

    // Emit the event.
    event_emitter
        .emit_open_interest_in_tokens_updated(market, collateral_token, is_long, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::OpenInterestInTokensUpdated(
                        OpenInterestInTokensUpdated {
                            market: market,
                            collateral_token: collateral_token,
                            is_long: is_long,
                            delta: delta,
                            next_value: next_value
                        }
                    )
                )
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
    let delta: i128 = i128_new(1, false);
    let next_value: u128 = 2;

    // Emit the event.
    event_emitter.emit_open_interest_updated(market, collateral_token, is_long, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::OpenInterestUpdated(
                        OpenInterestUpdated {
                            market: market,
                            collateral_token: collateral_token,
                            is_long: is_long,
                            delta: delta,
                            next_value: next_value
                        }
                    )
                )
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
    let delta: i128 = i128_new(1, false);
    let next_value: u128 = 2;

    // Emit the event.
    event_emitter
        .emit_virtual_swap_inventory_updated(
            market, is_long_token, virtual_market_id, delta, next_value
        );
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::VirtualSwapInventoryUpdated(
                        VirtualSwapInventoryUpdated {
                            market: market,
                            is_long_token: is_long_token,
                            virtual_market_id: virtual_market_id,
                            delta: delta,
                            next_value: next_value
                        }
                    )
                )
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
    let delta: i128 = i128_new(1, false);
    let next_value: i128 = i128_new(2, false);

    // Emit the event.
    event_emitter
        .emit_virtual_position_inventory_updated(token, virtual_token_id, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::VirtualPositionInventoryUpdated(
                        VirtualPositionInventoryUpdated {
                            token: token,
                            virtual_token_id: virtual_token_id,
                            delta: delta,
                            next_value: next_value,
                        }
                    )
                )
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
    let delta: i128 = i128_new(1, false);
    let next_value: u128 = 2;

    // Emit the event.
    event_emitter.emit_collateral_sum_updated(market, collateral_token, is_long, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::CollateralSumUpdated(
                        CollateralSumUpdated {
                            market: market,
                            collateral_token: collateral_token,
                            is_long: is_long,
                            delta: delta,
                            next_value: next_value
                        }
                    )
                )
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

    // Emit the event.
    event_emitter.emit_cumulative_borrowing_factor_updated(market, is_long, delta, next_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::CumulativeBorrowingFactorUpdated(
                        CumulativeBorrowingFactorUpdated {
                            market: market, is_long: is_long, delta: delta, next_value: next_value
                        }
                    )
                )
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

    // Emit the event.
    event_emitter
        .emit_funding_fee_amount_per_size_updated(
            market, collateral_token, is_long, delta, next_value
        );
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::FundingFeeAmountPerSizeUpdated(
                        FundingFeeAmountPerSizeUpdated {
                            market: market,
                            collateral_token: collateral_token,
                            is_long: is_long,
                            delta: delta,
                            next_value: next_value
                        }
                    )
                )
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

    // Emit the event.
    event_emitter
        .emit_claimable_funding_amount_per_size_updated(
            market, collateral_token, is_long, delta, next_value
        );
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::ClaimableFundingAmountPerSizeUpdated(
                        ClaimableFundingAmountPerSizeUpdated {
                            market: market,
                            collateral_token: collateral_token,
                            is_long: is_long,
                            delta: delta,
                            next_value: next_value
                        }
                    )
                )
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

    // Emit the event.
    event_emitter
        .emit_claimable_funding_updated(market, token, account, delta, next_value, next_pool_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::ClaimableFundingUpdated(
                        ClaimableFundingUpdated {
                            market: market,
                            token: token,
                            account: account,
                            delta: delta,
                            next_value: next_value,
                            next_pool_value: next_pool_value
                        }
                    )
                )
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

    // Emit the event.
    event_emitter
        .emit_funding_fees_claimed(market, token, account, receiver, amount, next_pool_value);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::FundingFeesClaimed(
                        FundingFeesClaimed {
                            market: market,
                            token: token,
                            account: account,
                            receiver: receiver,
                            amount: amount,
                            next_pool_value: next_pool_value
                        }
                    )
                )
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

    // Emit the event.
    event_emitter
        .emit_claimable_collateral_updated(
            market, token, account, time_key, delta, next_value, next_pool_value
        );
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::ClaimableCollateralUpdated(
                        ClaimableCollateralUpdated {
                            market: market,
                            token: token,
                            account: account,
                            time_key: time_key,
                            delta: delta,
                            next_value: next_value,
                            next_pool_value: next_pool_value
                        }
                    )
                )
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

    // Emit the event.
    event_emitter
        .emit_collateral_claimed(
            market, token, account, receiver, time_key, amount, next_pool_value
        );
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::CollateralClaimed(
                        CollateralClaimed {
                            market: market,
                            token: token,
                            account: account,
                            receiver: receiver,
                            time_key: time_key,
                            amount: amount,
                            next_pool_value: next_pool_value
                        }
                    )
                )
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

    // Emit the event.
    event_emitter.emit_ui_fee_factor_updated(account, ui_fee_factor);
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::UiFeeFactorUpdated(
                        UiFeeFactorUpdated { account: account, ui_fee_factor: ui_fee_factor }
                    )
                )
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

    // Emit the event.
    event_emitter
        .emit_market_created(
            creator, market_token, index_token, long_token, short_token, market_type
        );
    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::MarketCreated(
                        MarketCreated {
                            creator: creator,
                            market_token: market_token,
                            index_token: index_token,
                            long_token: long_token,
                            short_token: short_token,
                            market_type: market_type
                        }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

fn create_dummy_market_pool_value_info() -> MarketPoolValueInfo {
    MarketPoolValueInfo {
        pool_value: i128_new(1, false),
        long_pnl: i128_new(2, false),
        short_pnl: i128_new(3, false),
        net_pnl: i128_new(4, false),
        long_token_amount: 5,
        short_token_amount: 6,
        long_token_usd: 7,
        short_token_usd: 8,
        total_borrowing_fees: 9,
        borrowing_fee_pool_factor: 10,
        impact_pool_amount: 11,
    }
}
