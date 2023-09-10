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
fn test_emit_position_increase() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a dummy data.
    let dummy_position_increase_params = create_dummy_position_increase_params(event_emitter);

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![
        dummy_position_increase_params.position.account.into(),
        dummy_position_increase_params.position.market.into(),
        dummy_position_increase_params.position.collateral_token.into(),
        dummy_position_increase_params.position.size_in_usd.into(),
        dummy_position_increase_params.position.size_in_tokens.into(),
        dummy_position_increase_params.position.collateral_amount.into(),
        dummy_position_increase_params.position.borrowing_factor.into(),
        dummy_position_increase_params.position.funding_fee_amount_per_size.into(),
        dummy_position_increase_params.position.long_token_claimable_funding_amount_per_size.into(),
        dummy_position_increase_params
            .position
            .short_token_claimable_funding_amount_per_size
            .into(),
        dummy_position_increase_params.execution_price.into(),
        dummy_position_increase_params.index_token_price.max.into(),
        dummy_position_increase_params.index_token_price.min.into(),
        dummy_position_increase_params.collateral_token_price.max.into(),
        dummy_position_increase_params.collateral_token_price.min.into(),
        dummy_position_increase_params.size_delta_usd.into(),
        dummy_position_increase_params.size_delta_in_tokens.into(),
    ];

    // serialize orderType enum then we have to serialize the other params event
    dummy_position_increase_params.order_type.serialize(ref expected_data);
    dummy_position_increase_params.collateral_delta_amount.serialize(ref expected_data);
    dummy_position_increase_params.price_impact_usd.serialize(ref expected_data);
    dummy_position_increase_params.price_impact_amount.serialize(ref expected_data);
    dummy_position_increase_params.position.is_long.serialize(ref expected_data);
    dummy_position_increase_params.order_key.serialize(ref expected_data);
    dummy_position_increase_params.position_key.serialize(ref expected_data);

    // Emit the event.
    event_emitter.emit_position_increase(dummy_position_increase_params);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'PositionIncrease',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_position_decrease() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a dummy data.
    let dummy_position = create_dummy_position();
    let order_key = 'order_key';
    let position_key = 'position_key';
    let size_delta_usd = 100;
    let collateral_delta_amount = 200;
    let order_type = OrderType::MarketSwap(());
    let index_token_price = Price { min: 100, max: 100 };
    let collateral_token_price = Price { min: 80, max: 85 };
    let dummy_collateral_values = create_dummy_dec_pos_collateral_values();

    // Create the expected data.
    let mut expected_data: Array<felt252> = array![
        dummy_position.account.into(),
        dummy_position.market.into(),
        dummy_position.collateral_token.into(),
        dummy_position.size_in_usd.into(),
        dummy_position.size_in_tokens.into(),
        dummy_position.collateral_amount.into(),
        dummy_position.borrowing_factor.into(),
        dummy_position.funding_fee_amount_per_size.into(),
        dummy_position.long_token_claimable_funding_amount_per_size.into(),
        dummy_position.short_token_claimable_funding_amount_per_size.into(),
        dummy_collateral_values.execution_price.into(),
        index_token_price.max.into(),
        index_token_price.min.into(),
        collateral_token_price.max.into(),
        collateral_token_price.min.into(),
        size_delta_usd.into(),
        dummy_collateral_values.size_delta_in_tokens.into(),
        collateral_delta_amount.into(),
        dummy_collateral_values.price_impact_diff_usd.into(),
    ];

    // serialize orderType enum then we have to serialize the other params event
    order_type.serialize(ref expected_data);
    dummy_collateral_values.price_impact_usd.serialize(ref expected_data);
    dummy_collateral_values.base_pnl_usd.serialize(ref expected_data);
    dummy_collateral_values.uncapped_base_pnl_usd.serialize(ref expected_data);
    dummy_position.is_long.serialize(ref expected_data);
    order_key.serialize(ref expected_data);
    position_key.serialize(ref expected_data);

    // Emit the event.
    event_emitter
        .emit_position_decrease(
            order_key,
            position_key,
            dummy_position,
            size_delta_usd,
            collateral_delta_amount,
            order_type,
            dummy_collateral_values,
            index_token_price,
            collateral_token_price
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'PositionDecrease',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}


#[test]
fn test_emit_insolvent_close() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a dummy data.
    let order_key = 'order_key';
    let position_collateral_amount = 100;
    let base_pnl_usd = 50;
    let remaining_cost_usd = 75;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        order_key,
        position_collateral_amount.into(),
        base_pnl_usd.into(),
        remaining_cost_usd.into(),
    ];

    // Emit the event.
    event_emitter
        .emit_insolvent_close_info(
            order_key, position_collateral_amount, base_pnl_usd, remaining_cost_usd
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'InsolventClose',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}


#[test]
fn test_emit_insufficient_funding_fee_payment() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a dummy data.
    let market = contract_address_const::<'market'>();
    let token = contract_address_const::<'token'>();
    let expected_amount = 100;
    let amount_paid_in_collateral_token = 50;
    let amount_paid_in_secondary_output_token = 75;

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        market.into(),
        token.into(),
        expected_amount.into(),
        amount_paid_in_collateral_token.into(),
        amount_paid_in_secondary_output_token.into(),
    ];

    // Emit the event.
    event_emitter
        .emit_insufficient_funding_fee_payment(
            market,
            token,
            expected_amount,
            amount_paid_in_collateral_token,
            amount_paid_in_secondary_output_token
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'InsufficientFundingFeePayment',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}


#[test]
fn test_emit_position_fees_collected() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a dummy data.
    let order_key = 'order_key';
    let position_key = 'position_key';
    let market = contract_address_const::<'market'>();
    let collateral_token = contract_address_const::<'collateral_token'>();
    let trade_size_usd = 100;
    let is_increase = true;
    let dummy_position_fees = create_dummy_position_fees();

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        order_key,
        position_key,
        dummy_position_fees.referral.referral_code,
        market.into(),
        collateral_token.into(),
        dummy_position_fees.referral.affiliate.into(),
        dummy_position_fees.referral.trader.into(),
        dummy_position_fees.ui.ui_fee_receiver.into(),
        dummy_position_fees.collateral_token_price.min.into(),
        dummy_position_fees.collateral_token_price.max.into(),
        trade_size_usd.into(),
        dummy_position_fees.referral.total_rebate_factor.into(),
        dummy_position_fees.referral.trader_discount_factor.into(),
        dummy_position_fees.referral.total_rebate_amount.into(),
        dummy_position_fees.referral.trader_discount_amount.into(),
        dummy_position_fees.referral.affiliate_reward_amount.into(),
        dummy_position_fees.funding.funding_fee_amount.into(),
        dummy_position_fees.funding.claimable_long_token_amount.into(),
        dummy_position_fees.funding.claimable_short_token_amount.into(),
        dummy_position_fees.funding.latest_funding_fee_amount_per_size.into(),
        dummy_position_fees.funding.latest_long_token_claimable_funding_amount_per_size.into(),
        dummy_position_fees.funding.latest_short_token_claimable_funding_amount_per_size.into(),
        dummy_position_fees.borrowing.borrowing_fee_usd.into(),
        dummy_position_fees.borrowing.borrowing_fee_amount.into(),
        dummy_position_fees.borrowing.borrowing_fee_receiver_factor.into(),
        dummy_position_fees.borrowing.borrowing_fee_amount_for_fee_receiver.into(),
        dummy_position_fees.position_fee_factor.into(),
        dummy_position_fees.protocol_fee_amount.into(),
        dummy_position_fees.position_fee_receiver_factor.into(),
        dummy_position_fees.fee_receiver_amount.into(),
        dummy_position_fees.fee_amount_for_pool.into(),
        dummy_position_fees.position_fee_amount_for_pool.into(),
        dummy_position_fees.position_fee_amount.into(),
        dummy_position_fees.total_cost_amount.into(),
        dummy_position_fees.ui.ui_fee_receiver_factor.into(),
        dummy_position_fees.ui.ui_fee_amount.into(),
        is_increase.into()
    ];

    // Emit the event.
    event_emitter
        .emit_position_fees_collected(
            order_key,
            position_key,
            market,
            collateral_token,
            trade_size_usd,
            is_increase,
            dummy_position_fees
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'PositionFeesCollected',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn test_emit_position_fees_info() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (contract_address, event_emitter) = setup_event_emitter();
    let mut spy = spy_events(SpyOn::One(contract_address));

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a dummy data.
    let order_key = 'order_key';
    let position_key = 'position_key';
    let market = contract_address_const::<'market'>();
    let collateral_token = contract_address_const::<'collateral_token'>();
    let trade_size_usd = 100;
    let is_increase = true;
    let dummy_position_fees = create_dummy_position_fees();

    // Create the expected data.
    let expected_data: Array<felt252> = array![
        order_key,
        position_key,
        dummy_position_fees.referral.referral_code,
        market.into(),
        collateral_token.into(),
        dummy_position_fees.referral.affiliate.into(),
        dummy_position_fees.referral.trader.into(),
        dummy_position_fees.ui.ui_fee_receiver.into(),
        dummy_position_fees.collateral_token_price.min.into(),
        dummy_position_fees.collateral_token_price.max.into(),
        trade_size_usd.into(),
        dummy_position_fees.referral.total_rebate_factor.into(),
        dummy_position_fees.referral.trader_discount_factor.into(),
        dummy_position_fees.referral.total_rebate_amount.into(),
        dummy_position_fees.referral.trader_discount_amount.into(),
        dummy_position_fees.referral.affiliate_reward_amount.into(),
        dummy_position_fees.funding.funding_fee_amount.into(),
        dummy_position_fees.funding.claimable_long_token_amount.into(),
        dummy_position_fees.funding.claimable_short_token_amount.into(),
        dummy_position_fees.funding.latest_funding_fee_amount_per_size.into(),
        dummy_position_fees.funding.latest_long_token_claimable_funding_amount_per_size.into(),
        dummy_position_fees.funding.latest_short_token_claimable_funding_amount_per_size.into(),
        dummy_position_fees.borrowing.borrowing_fee_usd.into(),
        dummy_position_fees.borrowing.borrowing_fee_amount.into(),
        dummy_position_fees.borrowing.borrowing_fee_receiver_factor.into(),
        dummy_position_fees.borrowing.borrowing_fee_amount_for_fee_receiver.into(),
        dummy_position_fees.position_fee_factor.into(),
        dummy_position_fees.protocol_fee_amount.into(),
        dummy_position_fees.position_fee_receiver_factor.into(),
        dummy_position_fees.fee_receiver_amount.into(),
        dummy_position_fees.fee_amount_for_pool.into(),
        dummy_position_fees.position_fee_amount_for_pool.into(),
        dummy_position_fees.position_fee_amount.into(),
        dummy_position_fees.total_cost_amount.into(),
        dummy_position_fees.ui.ui_fee_receiver_factor.into(),
        dummy_position_fees.ui.ui_fee_amount.into(),
        is_increase.into()
    ];

    // Emit the event.
    event_emitter
        .emit_position_fees_info(
            order_key,
            position_key,
            market,
            collateral_token,
            trade_size_usd,
            is_increase,
            dummy_position_fees
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                Event {
                    from: contract_address,
                    name: 'PositionFeesInfo',
                    keys: array![],
                    data: expected_data
                }
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

fn create_dummy_position_increase_params(
    event_emitter: IEventEmitterDispatcher
) -> PositionIncreaseParams {
    PositionIncreaseParams {
        event_emitter: event_emitter,
        order_key: 'order_key',
        position_key: 'position_key',
        position: create_dummy_position(),
        index_token_price: Price { min: 100, max: 100 },
        collateral_token_price: Price { min: 80, max: 85 },
        execution_price: 100,
        size_delta_usd: 3,
        size_delta_in_tokens: 1,
        collateral_delta_amount: 2,
        price_impact_usd: 1,
        price_impact_amount: 1,
        order_type: OrderType::MarketSwap(())
    }
}

fn create_dummy_position() -> Position {
    Position {
        account: contract_address_const::<'account'>(),
        market: contract_address_const::<'market'>(),
        collateral_token: contract_address_const::<'collateral_token'>(),
        size_in_usd: 100,
        size_in_tokens: 1,
        collateral_amount: 2,
        borrowing_factor: 3,
        funding_fee_amount_per_size: 4,
        long_token_claimable_funding_amount_per_size: 5,
        short_token_claimable_funding_amount_per_size: 6,
        increased_at_block: 15000,
        decreased_at_block: 15001,
        is_long: false
    }
}


fn create_dummy_dec_pos_collateral_values() -> DecreasePositionCollateralValues {
    let dummy_values_output = DecreasePositionCollateralValuesOutput {
        output_token: 0x102.try_into().unwrap(),
        output_amount: 5,
        secondary_output_token: 0x103.try_into().unwrap(),
        secondary_output_amount: 8,
    };

    DecreasePositionCollateralValues {
        execution_price: 10,
        remaining_collateral_amount: 10,
        base_pnl_usd: 10,
        uncapped_base_pnl_usd: 10,
        size_delta_in_tokens: 10,
        price_impact_usd: 10,
        price_impact_diff_usd: 10,
        output: dummy_values_output
    }
}

fn create_dummy_position_fees() -> PositionFees {
    let collateral_token_price = Price { min: 100, max: 102 };

    let dummy_pos_referral_fees = PositionReferralFees {
        /// The referral code used.
        referral_code: 'referral_code',
        /// The referral affiliate of the trader.
        affiliate: contract_address_const::<'affiliate'>(),
        /// The trader address.
        trader: contract_address_const::<'trader'>(),
        /// The total rebate factor.
        total_rebate_factor: 100,
        /// The trader discount factor.
        trader_discount_factor: 2,
        /// The total rebate amount.
        total_rebate_amount: 1,
        /// The discount amount for the trader.
        trader_discount_amount: 2,
        /// The affiliate reward amount.
        affiliate_reward_amount: 1,
    };

    let dummy_pos_funding_fees = PositionFundingFees {
        /// The amount of funding fees in tokens.
        funding_fee_amount: 10,
        /// The negative funding fee in long token that is claimable.
        claimable_long_token_amount: 10,
        /// The negative funding fee in short token that is claimable.
        claimable_short_token_amount: 10,
        /// The latest long token funding fee amount per size for the market.
        latest_funding_fee_amount_per_size: 10,
        /// The latest long token funding amount per size for the market.
        latest_long_token_claimable_funding_amount_per_size: 10,
        /// The latest short token funding amount per size for the market.
        latest_short_token_claimable_funding_amount_per_size: 10,
    };

    let dummy_pos_borrowing_fees = PositionBorrowingFees {
        /// The borrowing fees amount in USD.
        borrowing_fee_usd: 10,
        /// The borrowing fees amount in tokens.
        borrowing_fee_amount: 2,
        /// The borrowing fees factor for receiver.
        borrowing_fee_receiver_factor: 1,
        /// The borrowing fees amount in tokens for fee receiver.
        borrowing_fee_amount_for_fee_receiver: 3,
    };

    let dummy_pos_ui_fees = PositionUiFees {
        /// The ui fee receiver address
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
        /// The factor for fee receiver.
        ui_fee_receiver_factor: 2,
        /// The ui fee amount in tokens.
        ui_fee_amount: 3,
    };

    PositionFees {
        referral: dummy_pos_referral_fees,
        funding: dummy_pos_funding_fees,
        borrowing: dummy_pos_borrowing_fees,
        ui: dummy_pos_ui_fees,
        collateral_token_price: collateral_token_price,
        position_fee_factor: 7,
        protocol_fee_amount: 5,
        position_fee_receiver_factor: 5,
        fee_receiver_amount: 5,
        fee_amount_for_pool: 5,
        position_fee_amount_for_pool: 10,
        position_fee_amount: 10,
        total_cost_amount_excluding_funding: 10,
        total_cost_amount: 10
    }
}
