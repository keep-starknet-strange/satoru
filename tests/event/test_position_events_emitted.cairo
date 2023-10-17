use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};
use satoru::tests_lib::setup_event_emitter;
use satoru::position::{
    position_event_utils::PositionIncreaseParams, position::Position,
    position_utils::{DecreasePositionCollateralValues, DecreasePositionCollateralValuesOutput}
};
use satoru::pricing::position_pricing_utils::{
    PositionFees, PositionUiFees, PositionBorrowingFees, PositionReferralFees, PositionFundingFees
};
use satoru::order::order::OrderType;
use satoru::price::price::Price;

use satoru::event::event_emitter::{
    EventEmitter, IEventEmitterDispatcher, IEventEmitterDispatcherTrait
};

use satoru::event::event_emitter::EventEmitter::{
    PositionIncrease, PositionDecrease, InsolventClose, InsufficientFundingFeePayment,
    PositionFeesInfo, PositionFeesCollected
};


use satoru::utils::i128::{i128, i128_new};

#[test]
fn given_normal_conditions_when_emit_position_increase_then_works() {
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

    // Emit the event.
    event_emitter.emit_position_increase(dummy_position_increase_params);

    // Refetch the data for expected since dummy_position_increase_params was moved
    let dummy_position_increase_params = create_dummy_position_increase_params(event_emitter);

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::PositionIncrease(
                        PositionIncrease {
                            account: dummy_position_increase_params.position.account,
                            market: dummy_position_increase_params.position.market,
                            collateral_token: dummy_position_increase_params
                                .position
                                .collateral_token,
                            size_in_usd: dummy_position_increase_params.position.size_in_usd,
                            size_in_tokens: dummy_position_increase_params.position.size_in_tokens,
                            collateral_amount: dummy_position_increase_params
                                .position
                                .collateral_amount,
                            borrowing_factor: dummy_position_increase_params
                                .position
                                .borrowing_factor,
                            funding_fee_amount_per_size: dummy_position_increase_params
                                .position
                                .funding_fee_amount_per_size,
                            long_token_claimable_funding_amount_per_size: dummy_position_increase_params
                                .position
                                .long_token_claimable_funding_amount_per_size,
                            short_token_claimable_funding_amount_per_size: dummy_position_increase_params
                                .position
                                .short_token_claimable_funding_amount_per_size,
                            execution_price: dummy_position_increase_params.execution_price,
                            index_token_price_max: dummy_position_increase_params
                                .index_token_price
                                .max,
                            index_token_price_min: dummy_position_increase_params
                                .index_token_price
                                .min,
                            collateral_token_price_max: dummy_position_increase_params
                                .collateral_token_price
                                .max,
                            collateral_token_price_min: dummy_position_increase_params
                                .collateral_token_price
                                .min,
                            size_delta_usd: dummy_position_increase_params.size_delta_usd,
                            size_delta_in_tokens: dummy_position_increase_params
                                .size_delta_in_tokens,
                            order_type: dummy_position_increase_params.order_type,
                            collateral_delta_amount: dummy_position_increase_params
                                .collateral_delta_amount,
                            price_impact_usd: dummy_position_increase_params.price_impact_usd,
                            price_impact_amount: dummy_position_increase_params.price_impact_amount,
                            is_long: dummy_position_increase_params.position.is_long,
                            order_key: dummy_position_increase_params.order_key,
                            position_key: dummy_position_increase_params.position_key,
                        }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_position_decrease_then_works() {
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
                (
                    contract_address,
                    EventEmitter::Event::PositionDecrease(
                        PositionDecrease {
                            account: dummy_position.account,
                            market: dummy_position.market,
                            collateral_token: dummy_position.collateral_token,
                            size_in_usd: dummy_position.size_in_usd,
                            size_in_tokens: dummy_position.size_in_tokens,
                            collateral_amount: dummy_position.collateral_amount,
                            borrowing_factor: dummy_position.borrowing_factor,
                            funding_fee_amount_per_size: dummy_position.funding_fee_amount_per_size,
                            long_token_claimable_funding_amount_per_size: dummy_position
                                .long_token_claimable_funding_amount_per_size,
                            short_token_claimable_funding_amount_per_size: dummy_position
                                .short_token_claimable_funding_amount_per_size,
                            execution_price: dummy_collateral_values.execution_price,
                            index_token_price_max: index_token_price.max,
                            index_token_price_min: index_token_price.min,
                            collateral_token_price_max: collateral_token_price.max,
                            collateral_token_price_min: collateral_token_price.min,
                            size_delta_usd: size_delta_usd,
                            size_delta_in_tokens: dummy_collateral_values.size_delta_in_tokens,
                            collateral_delta_amount: collateral_delta_amount,
                            price_impact_diff_usd: dummy_collateral_values.price_impact_diff_usd,
                            order_type: order_type,
                            price_impact_usd: dummy_collateral_values.price_impact_usd,
                            base_pnl_usd: dummy_collateral_values.base_pnl_usd,
                            uncapped_base_pnl_usd: dummy_collateral_values.uncapped_base_pnl_usd,
                            is_long: dummy_position.is_long,
                            order_key: order_key,
                            position_key: position_key,
                        }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}


#[test]
fn given_normal_conditions_when_emit_insolvent_close_then_works() {
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
    let base_pnl_usd = i128_new(50, false);
    let remaining_cost_usd = 75;

    // Emit the event.
    event_emitter
        .emit_insolvent_close_info(
            order_key, position_collateral_amount, base_pnl_usd, remaining_cost_usd
        );

    // Assert the event was emitted.
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    EventEmitter::Event::InsolventClose(
                        InsolventClose {
                            order_key: order_key,
                            position_collateral_amount: position_collateral_amount,
                            base_pnl_usd: base_pnl_usd,
                            remaining_cost_usd: remaining_cost_usd
                        }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}


#[test]
fn given_normal_conditions_when_emit_insufficient_funding_fee_payment_then_works() {
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
                (
                    contract_address,
                    EventEmitter::Event::InsufficientFundingFeePayment(
                        InsufficientFundingFeePayment {
                            market: market,
                            token: token,
                            expected_amount: expected_amount,
                            amount_paid_in_collateral_token: amount_paid_in_collateral_token,
                            amount_paid_in_secondary_output_token: amount_paid_in_secondary_output_token
                        }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}


#[test]
fn given_normal_conditions_when_emit_position_fees_collected_then_works() {
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
                (
                    contract_address,
                    EventEmitter::Event::PositionFeesCollected(
                        PositionFeesCollected {
                            order_key: order_key,
                            position_key: position_key,
                            referral_code: dummy_position_fees.referral.referral_code,
                            market: market,
                            collateral_token: collateral_token,
                            affiliate: dummy_position_fees.referral.affiliate,
                            trader: dummy_position_fees.referral.trader,
                            ui_fee_receiver: dummy_position_fees.ui.ui_fee_receiver,
                            collateral_token_price_min: dummy_position_fees
                                .collateral_token_price
                                .min,
                            collateral_token_price_max: dummy_position_fees
                                .collateral_token_price
                                .max,
                            trade_size_usd: trade_size_usd,
                            total_rebate_factor: dummy_position_fees.referral.total_rebate_factor,
                            trader_discount_factor: dummy_position_fees
                                .referral
                                .trader_discount_factor,
                            total_rebate_amount: dummy_position_fees.referral.total_rebate_amount,
                            trader_discount_amount: dummy_position_fees
                                .referral
                                .trader_discount_amount,
                            affiliate_reward_amount: dummy_position_fees
                                .referral
                                .affiliate_reward_amount,
                            funding_fee_amount: dummy_position_fees.funding.funding_fee_amount,
                            claimable_long_token_amount: dummy_position_fees
                                .funding
                                .claimable_long_token_amount,
                            claimable_short_token_amount: dummy_position_fees
                                .funding
                                .claimable_short_token_amount,
                            latest_funding_fee_amount_per_size: dummy_position_fees
                                .funding
                                .latest_funding_fee_amount_per_size,
                            latest_long_token_claimable_funding_amount_per_size: dummy_position_fees
                                .funding
                                .latest_long_token_claimable_funding_amount_per_size,
                            latest_short_token_claimable_funding_amount_per_size: dummy_position_fees
                                .funding
                                .latest_short_token_claimable_funding_amount_per_size,
                            borrowing_fee_usd: dummy_position_fees.borrowing.borrowing_fee_usd,
                            borrowing_fee_amount: dummy_position_fees
                                .borrowing
                                .borrowing_fee_amount,
                            borrowing_fee_receiver_factor: dummy_position_fees
                                .borrowing
                                .borrowing_fee_receiver_factor,
                            borrowing_fee_amount_for_fee_receiver: dummy_position_fees
                                .borrowing
                                .borrowing_fee_amount_for_fee_receiver,
                            position_fee_factor: dummy_position_fees.position_fee_factor,
                            protocol_fee_amount: dummy_position_fees.protocol_fee_amount,
                            position_fee_receiver_factor: dummy_position_fees
                                .position_fee_receiver_factor,
                            fee_receiver_amount: dummy_position_fees.fee_receiver_amount,
                            fee_amount_for_pool: dummy_position_fees.fee_amount_for_pool,
                            position_fee_amount_for_pool: dummy_position_fees
                                .position_fee_amount_for_pool,
                            position_fee_amount: dummy_position_fees.position_fee_amount,
                            total_cost_amount: dummy_position_fees.total_cost_amount,
                            ui_fee_receiver_factor: dummy_position_fees.ui.ui_fee_receiver_factor,
                            ui_fee_amount: dummy_position_fees.ui.ui_fee_amount,
                            is_increase: is_increase
                        }
                    )
                )
            ]
        );
    // Assert there are no more events.
    assert(spy.events.len() == 0, 'There should be no events');
}

#[test]
fn given_normal_conditions_when_emit_position_fees_info_then_works() {
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
                (
                    contract_address,
                    EventEmitter::Event::PositionFeesInfo(
                        PositionFeesInfo {
                            order_key: order_key,
                            position_key: position_key,
                            referral_code: dummy_position_fees.referral.referral_code,
                            market: market,
                            collateral_token: collateral_token,
                            affiliate: dummy_position_fees.referral.affiliate,
                            trader: dummy_position_fees.referral.trader,
                            ui_fee_receiver: dummy_position_fees.ui.ui_fee_receiver,
                            collateral_token_price_min: dummy_position_fees
                                .collateral_token_price
                                .min,
                            collateral_token_price_max: dummy_position_fees
                                .collateral_token_price
                                .max,
                            trade_size_usd: trade_size_usd,
                            total_rebate_factor: dummy_position_fees.referral.total_rebate_factor,
                            trader_discount_factor: dummy_position_fees
                                .referral
                                .trader_discount_factor,
                            total_rebate_amount: dummy_position_fees.referral.total_rebate_amount,
                            trader_discount_amount: dummy_position_fees
                                .referral
                                .trader_discount_amount,
                            affiliate_reward_amount: dummy_position_fees
                                .referral
                                .affiliate_reward_amount,
                            funding_fee_amount: dummy_position_fees.funding.funding_fee_amount,
                            claimable_long_token_amount: dummy_position_fees
                                .funding
                                .claimable_long_token_amount,
                            claimable_short_token_amount: dummy_position_fees
                                .funding
                                .claimable_short_token_amount,
                            latest_funding_fee_amount_per_size: dummy_position_fees
                                .funding
                                .latest_funding_fee_amount_per_size,
                            latest_long_token_claimable_funding_amount_per_size: dummy_position_fees
                                .funding
                                .latest_long_token_claimable_funding_amount_per_size,
                            latest_short_token_claimable_funding_amount_per_size: dummy_position_fees
                                .funding
                                .latest_short_token_claimable_funding_amount_per_size,
                            borrowing_fee_usd: dummy_position_fees.borrowing.borrowing_fee_usd,
                            borrowing_fee_amount: dummy_position_fees
                                .borrowing
                                .borrowing_fee_amount,
                            borrowing_fee_receiver_factor: dummy_position_fees
                                .borrowing
                                .borrowing_fee_receiver_factor,
                            borrowing_fee_amount_for_fee_receiver: dummy_position_fees
                                .borrowing
                                .borrowing_fee_amount_for_fee_receiver,
                            position_fee_factor: dummy_position_fees.position_fee_factor,
                            protocol_fee_amount: dummy_position_fees.protocol_fee_amount,
                            position_fee_receiver_factor: dummy_position_fees
                                .position_fee_receiver_factor,
                            fee_receiver_amount: dummy_position_fees.fee_receiver_amount,
                            fee_amount_for_pool: dummy_position_fees.fee_amount_for_pool,
                            position_fee_amount_for_pool: dummy_position_fees
                                .position_fee_amount_for_pool,
                            position_fee_amount: dummy_position_fees.position_fee_amount,
                            total_cost_amount: dummy_position_fees.total_cost_amount,
                            ui_fee_receiver_factor: dummy_position_fees.ui.ui_fee_receiver_factor,
                            ui_fee_amount: dummy_position_fees.ui.ui_fee_amount,
                            is_increase: is_increase
                        }
                    )
                )
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
        key: 1,
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
        base_pnl_usd: i128_new(10, false),
        uncapped_base_pnl_usd: i128_new(10, false),
        size_delta_in_tokens: 10,
        price_impact_usd: i128_new(10, false),
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
