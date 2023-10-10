//! Library for functions to help with increasing a position.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use result::ResultTrait;

// Local imports
use satoru::position::position_utils::UpdatePositionParams;
use satoru::pricing::position_pricing_utils::{
    PositionFees, PositionBorrowingFees, PositionFundingFees, PositionReferralFees, PositionUiFees,
};
use satoru::price::price::Price;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::{event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait},};
use satoru::market::market_utils;
use satoru::position::{
    position::Position, position_utils, position_utils::WillPositionCollateralBeSufficientValues,
    position_event_utils
};
use satoru::position::error::PositionError;
use satoru::utils::{
    calc::{to_unsigned, to_signed, sum_return_uint_128},
    i128::{I128Store, I128Serde, I128Div, I128Mul, I128Default}
};

#[derive(Drop, starknet::Store, Serde, Default, Copy)]
struct IncreasePositionCache {
    /// The change in collateral amount.
    collateral_delta_amount: i128, // TODO replace with i128 when storeable
    execution_price: u128,
    collateral_token_price: Price,
    /// The price impact of the position increase in USD.
    price_impact_usd: i128, // TODO replace with i128 when storeable
    /// The price impact of the position increase in tokens.
    price_impact_amount: i128, // TODO replace with i128 when storeable
    /// The change in position size in tokens.
    size_delta_in_tokens: u128,
    /// The new position size in USD.
    next_position_size_in_usd: u128,
    /// The new position borrowing factor.
    next_position_borrowing_factor: u128,
}

/// The increasePosition function is used to increase the size of a position
/// in a market. This involves updating the position's collateral amount,
/// calculating the price impact of the size increase, and updating the position's
/// size and borrowing factor. This function also applies fees to the position
/// and updates the market's liquidity pool based on the new position size.
fn increase_position(mut params: UpdatePositionParams, collateral_increment_amount: u128) {
    // get the market prices for the given position
    let prices = market_utils::get_market_prices(params.contracts.oracle, params.market);

    position_utils::update_funding_and_borrowing_state(params, prices);

    // create a new cache for holding intermediate results
    let mut cache: IncreasePositionCache = Default::default();

    cache
        .collateral_token_price =
            market_utils::get_cached_token_price(
                params.position.collateral_token, params.market, prices
            );

    if (params.position.size_in_usd == 0) {
        params
            .position
            .funding_fee_amount_per_size =
                market_utils::get_funding_fee_amount_per_size(
                    params.contracts.data_store,
                    params.market.market_token,
                    params.position.collateral_token,
                    params.position.is_long
                );
        params
            .position
            .long_token_claimable_funding_amount_per_size =
                market_utils::get_claimable_funding_amount_per_size(
                    params.contracts.data_store,
                    params.market.market_token,
                    params.market.long_token,
                    params.position.is_long
                );

        params
            .position
            .short_token_claimable_funding_amount_per_size =
                market_utils::get_claimable_funding_amount_per_size(
                    params.contracts.data_store,
                    params.market.market_token,
                    params.market.short_token,
                    params.position.is_long
                );
    }

    let (
        get_price_impact_usd, get_price_impact_amount, get_size_delta_in_tokens, get_execution_price
    ) =
        get_execution_price(
        params, prices.index_token_price
    );
    cache.price_impact_usd = get_price_impact_usd;
    cache.price_impact_amount = get_price_impact_amount;
    cache.size_delta_in_tokens = get_size_delta_in_tokens;
    cache.execution_price = get_execution_price;

    // process the collateral for the given position and order
    let mut fees: PositionFees = Default::default();
    let (processed_collateral_delta_amount, processed_fees) = process_collateral(
        params,
        cache.collateral_token_price,
        to_signed(collateral_increment_amount, true),
        cache.price_impact_usd
    );
    cache.collateral_delta_amount = processed_collateral_delta_amount;
    fees = processed_fees;

    // check if there is sufficient collateral for the position
    if (cache.collateral_delta_amount < 0
        && params.position.collateral_amount < to_unsigned(-cache.collateral_delta_amount)) {
        PositionError::INSUFFICIENT_COLLATERAL_AMOUNT(
            params.position.collateral_amount, cache.collateral_delta_amount
        )
    }
    params
        .position
        .collateral_amount =
            sum_return_uint_128(params.position.collateral_amount, cache.collateral_delta_amount);

    // if there is a positive impact, the impact pool amount should be reduced
    // if there is a negative impact, the impact pool amount should be increased
    market_utils::apply_delta_to_position_impact_pool(
        params.contracts.data_store,
        params.contracts.event_emitter,
        params.market.market_token,
        -cache.price_impact_amount
    );

    cache.next_position_size_in_usd = params.position.size_in_usd + params.order.size_delta_usd;
    cache
        .next_position_borrowing_factor =
            market_utils::get_cumulative_borrowing_factor(
                @params.contracts.data_store, params.market.market_token, params.position.is_long
            );

    position_utils::update_total_borrowing(
        params, cache.next_position_size_in_usd, cache.next_position_borrowing_factor
    );

    position_utils::increment_claimable_funding_amount(params, fees);

    params.position.size_in_usd = cache.next_position_size_in_usd;
    params.position.size_in_tokens = params.position.size_in_tokens + cache.size_delta_in_tokens;

    params.position.funding_fee_amount_per_size = fees.funding.latest_funding_fee_amount_per_size;
    params
        .position
        .long_token_claimable_funding_amount_per_size = fees
        .funding
        .latest_long_token_claimable_funding_amount_per_size;
    params
        .position
        .short_token_claimable_funding_amount_per_size = fees
        .funding
        .latest_short_token_claimable_funding_amount_per_size;

    params.position.borrowing_factor = cache.next_position_borrowing_factor;
    params.position.increased_at_block = starknet::info::get_block_number();

    params.contracts.data_store.set_position(params.position_key, params.position);

    position_utils::update_open_interest(
        params,
        to_signed(params.order.size_delta_usd, true),
        to_signed(cache.size_delta_in_tokens, true)
    );

    if (params.order.size_delta_usd > 0) {
        // reserves are only validated if the sizeDeltaUsd is more than zero
        // this helps to ensure that deposits of collateral into positions
        // should still succeed even if pool tokens are fully reserved
        market_utils::validate_reserve(
            params.contracts.data_store, @params.market, @prices, params.order.is_long
        );

        market_utils::validate_open_interest_reserve(
            params.contracts.data_store, @params.market, @prices, params.order.is_long
        );

        let position_values: WillPositionCollateralBeSufficientValues =
            WillPositionCollateralBeSufficientValues {
            position_size_in_usd: params.position.size_in_usd,
            position_collateral_amount: params.position.collateral_amount,
            realized_pnl_usd: 0,
            open_interest_delta: 0
        };

        let (will_be_sufficient, remaining_collateral_usd) =
            position_utils::will_position_collateral_be_sufficient(
            params.contracts.data_store,
            params.market,
            prices,
            params.position.collateral_token,
            params.position.is_long,
            position_values
        );

        if (!will_be_sufficient) {
            PositionError::INSUFFICIENT_COLLATERAL_USD(remaining_collateral_usd);
        }
    }

    position_utils::handle_referral(params, fees);

    // validatePosition should be called after open interest and all other market variables
    // have been updated
    position_utils::validate_position(
        params.contracts.data_store,
        params.contracts.referral_storage,
        params.position,
        params.market,
        prices,
        true,
        true
    );

    params
        .contracts
        .event_emitter
        .emit_position_fees_collected(
            params.order_key,
            params.position_key,
            params.market.market_token,
            params.position.collateral_token,
            params.order.size_delta_usd,
            true,
            fees
        );

    let event_params = position_event_utils::PositionIncreaseParams {
        event_emitter: params.contracts.event_emitter,
        order_key: params.order_key,
        position_key: params.position_key,
        position: params.position,
        index_token_price: prices.index_token_price,
        collateral_token_price: cache.collateral_token_price,
        execution_price: cache.execution_price,
        size_delta_usd: params.order.size_delta_usd,
        size_delta_in_tokens: cache.size_delta_in_tokens,
        collateral_delta_amount: cache.collateral_delta_amount,
        price_impact_usd: cache.price_impact_usd,
        price_impact_amount: cache.price_impact_amount,
        order_type: params.order.order_type
    };

    params.contracts.event_emitter.emit_position_increase(event_params);
}

/// Handle the collateral changes of the position.
/// # Arguments
/// * `collateral_delta_amount` - The change in the position's collateral.
fn process_collateral(
    params: UpdatePositionParams,
    collateral_token_price: Price,
    collateral_delta_amount: i128,
    price_impact_usd: i128,
) -> (i128, PositionFees) {
    // TODO
    let position_referral_fees = PositionReferralFees {
        referral_code: 0,
        affiliate: contract_address_const::<0>(),
        trader: contract_address_const::<0>(),
        total_rebate_factor: 0,
        trader_discount_factor: 0,
        total_rebate_amount: 0,
        trader_discount_amount: 0,
        affiliate_reward_amount: 0,
    };
    let position_funding_fees = PositionFundingFees {
        funding_fee_amount: 0,
        claimable_long_token_amount: 0,
        claimable_short_token_amount: 0,
        latest_funding_fee_amount_per_size: 0,
        latest_long_token_claimable_funding_amount_per_size: 0,
        latest_short_token_claimable_funding_amount_per_size: 0,
    };
    let position_borrowing_fees = PositionBorrowingFees {
        borrowing_fee_usd: 0,
        borrowing_fee_amount: 0,
        borrowing_fee_receiver_factor: 0,
        borrowing_fee_amount_for_fee_receiver: 0,
    };
    let position_ui_fees = PositionUiFees {
        ui_fee_receiver: contract_address_const::<0>(), ui_fee_receiver_factor: 0, ui_fee_amount: 0,
    };
    let price = Price { min: 0, max: 0, };
    let position_fees = PositionFees {
        referral: position_referral_fees,
        funding: position_funding_fees,
        borrowing: position_borrowing_fees,
        ui: position_ui_fees,
        collateral_token_price: price,
        position_fee_factor: 0,
        protocol_fee_amount: 0,
        position_fee_receiver_factor: 0,
        fee_receiver_amount: 0,
        fee_amount_for_pool: 0,
        position_fee_amount_for_pool: 0,
        position_fee_amount: 0,
        total_cost_amount_excluding_funding: 0,
        total_cost_amount: 0,
    };
    (0, position_fees)
}

/// # Returns
/// price_impact_usd, price_impact_amount, size_delta_in_tokens, execution_price
fn get_execution_price(
    params: UpdatePositionParams, index_token_price: Price
) -> (i128, i128, u128, u128) {
    // TODO
    (0, 0, 0, 0)
}
