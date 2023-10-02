//! Library for functions to help with decreasing a position.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use result::ResultTrait;

// Local imports
use satoru::position::{
    position_utils, decrease_position_collateral_utils, decrease_position_swap_utils,
    position_utils::{UpdatePositionParams, DecreasePositionCache}
};
use satoru::utils::calc::to_signed;
use satoru::data::{data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait}, keys};
use satoru::utils::precision;
use satoru::market::market_utils;
use satoru::order::order::{OrderType, DecreasePositionSwapType};
use satoru::order::base_order_utils;
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::position::error::PositionError;

/// Struct used as result for decrease_position_function output.
#[derive(Drop, Copy, starknet::Store, Serde)]
struct DecreasePositionResult {
    /// The output token address.
    output_token: ContractAddress,
    /// The output token amount.
    output_amount: u128,
    /// The secondary output token address.
    secondary_output_token: ContractAddress,
    /// The secondary output token amount.
    secondary_output_amount: u128,
}

/// The decrease_position function decreases the size of an existing position
/// in a market. It takes a UpdatePositionParams object as an input, which
/// includes information about the position to be decreased, the market in
/// which the position exists, and the order that is being used to decrease the position.
///
/// The function first calculates the prices of the tokens in the market, and then
/// checks whether the position is liquidatable based on the current market prices.
/// If the order is a liquidation order and the position is not liquidatable, the function reverts.
///
/// If there is not enough collateral in the position to complete the decrease,
/// the function reverts. Otherwise, the function updates the position's size and
/// collateral amount, and increments the claimable funding amount for
/// the market if necessary.
///
/// Finally, the function returns a DecreasePositionResult object containing
/// information about the outcome of the decrease operation, including the amount
/// of collateral removed from the position and any fees that were paid.
fn decrease_position(ref params: UpdatePositionParams) -> DecreasePositionResult {
    let mut cache: DecreasePositionCache = Default::default();
    cache.prices = market_utils::get_market_prices(params.contracts.oracle, params.market);
    cache
        .collateral_token_price =
            market_utils::get_cached_token_price(
                params.order.initial_collateral_token, params.market, cache.prices
            );

    // cap the order size to the position size
    if (params.order.size_delta_usd > params.position.size_in_usd) {
        if (params.order.order_type == OrderType::LimitDecrease
            || params.order.order_type == OrderType::StopLossDecrease) {
            params
                .contracts
                .event_emitter
                .emit_order_size_delta_auto_updated(
                    params.order_key, params.position.size_in_usd, params.position.size_in_usd
                );
            params.order.size_delta_usd = params.position.size_in_usd;
        } else {
            PositionError::INVALID_DECREASE_ORDER_SIZE(
                params.order.size_delta_usd, params.position.size_in_usd
            );
        }
    }
    // if the position will be partially decreased then do a check on the
    // remaining collateral amount and update the order attributes if needed
    if (params.order.size_delta_usd < params.position.size_in_usd) {
        let (estimated_position_pnl_usd, uncapped_base_pnl_usd, size_delta_in_tokens) =
            position_utils::get_position_pnl_usd(
            params.contracts.data_store,
            params.market,
            cache.prices,
            params.position,
            params.position.size_in_usd
        );
        cache.estimated_position_pnl_usd = estimated_position_pnl_usd;
        cache
            .estimated_realized_pnl_usd =
                precision::mul_div_ival(
                    cache.estimated_position_pnl_usd,
                    params.order.size_delta_usd,
                    params.position.size_in_usd
                );
        cache.estimated_remaining_pnl_usd = cache.estimated_position_pnl_usd
            - cache.estimated_realized_pnl_usd;

        let position_values = position_utils::WillPositionCollateralBeSufficientValues {
            position_size_in_usd: params.position.size_in_usd - params.order.size_delta_usd,
            position_collateral_amount: params.position.collateral_amount
                - params.order.initial_collateral_delta_amount,
            realized_pnl_usd: cache.estimated_realized_pnl_usd,
            open_interest_delta: to_signed(params.order.size_delta_usd, false),
        };

        let (will_be_sufficient, mut estimated_remaining_collateral_usd) =
            position_utils::will_position_collateral_be_sufficient(
            params.contracts.data_store,
            params.market,
            cache.prices,
            params.position.collateral_token,
            params.position.is_long,
            position_values
        );

        // do not allow withdrawal of collateral if it would lead to the position
        // having an insufficient amount of collateral
        // this helps to prevent gaming by opening a position then reducing collateral
        // to increase the leverage of the position
        if (!will_be_sufficient) {
            if (params.order.size_delta_usd == 0) {
                PositionError::UNABLE_TO_WITHDRAW_COLLATERAL(estimated_remaining_collateral_usd);
            }
            params
                .contracts
                .event_emitter
                .emit_order_collateral_delta_amount_auto_updated(
                    params.order_key, params.order.initial_collateral_delta_amount, 0
                );

            // the estimated_remaining_collateral_usd subtracts the initial_collateral_delta_amount
            // since the initial_collateral_delta_amount will be set to zero, the initial_collateral_delta_amount
            // should be added back to the estimated_remaining_collateral_usd

            estimated_remaining_collateral_usd +=
                to_signed(
                    params.order.initial_collateral_delta_amount * cache.collateral_token_price.min,
                    false
                );

            params.order.initial_collateral_delta_amount = 0;
        }

        // if the remaining collateral including position pnl will be below
        // the min collateral usd value, then close the position
        //
        // if the position has sufficient remaining collateral including pnl
        // then allow the position to be partially closed and the updated
        // position to remain open

        if ((estimated_remaining_collateral_usd
            + cache
                .estimated_remaining_pnl_usd) < to_signed(
                    params.contracts.data_store.get_u128(keys::min_collateral_usd()), false
                )) {
            params
                .contracts
                .event_emitter
                .emit_order_size_delta_auto_updated(
                    params.order_key, params.order.size_delta_usd, params.position.size_in_usd
                );
            params.order.size_delta_usd = params.position.size_in_usd;
        }

        if (params.position.size_in_usd > params.order.size_delta_usd
            && (params.position.size_in_usd - params.order.size_delta_usd) < params
                .contracts
                .data_store
                .get_u128(keys::min_collateral_usd())) {
            params
                .contracts
                .event_emitter
                .emit_order_size_delta_auto_updated(
                    params.order_key, params.order.size_delta_usd, params.position.size_in_usd
                );
            params.order.size_delta_usd = params.position.size_in_usd;
        }
    }

    // if the position will be closed, set the initial collateral delta amount
    // to zero to help ensure that the order can be executed
    if (params.order.size_delta_usd == params.position.size_in_usd
        && params.order.initial_collateral_delta_amount > 0) {
        params.order.initial_collateral_delta_amount = 0;
    }

    if (params.position.is_long) {
        cache.pnl_token = params.market.long_token;
        cache.pnl_token_price = cache.prices.long_token_price;
    } else {
        cache.pnl_token = params.market.short_token;
        cache.pnl_token_price = cache.prices.short_token_price;
    };

    if (params.order.decrease_position_swap_type != DecreasePositionSwapType::NoSwap
        && cache.pnl_token == params.position.collateral_token) {
        params.order.decrease_position_swap_type = DecreasePositionSwapType::NoSwap;
    }

    position_utils::update_funding_and_borrowing_state(params, cache.prices);

    if (base_order_utils::is_liquidation_order(params.order.order_type)) {
        let (is_liquidatable, liquidation_amount_usd) = position_utils::is_position_liquiditable(
            params.contracts.data_store,
            params.contracts.referral_storage,
            params.position,
            params.market,
            cache.prices,
            true
        );
        if (!is_liquidatable) {
            PositionError::POSITION_SHOULD_BE_LIQUIDATED();
        }
    }

    cache.initial_collateral_amount = params.position.collateral_amount;
    let (mut values, fees) = decrease_position_collateral_utils::process_collateral(params, cache);

    cache.next_position_size_in_usd = params.position.size_in_usd - params.order.size_delta_usd;
    cache
        .next_position_borrowing_factor =
            market_utils::get_cumulative_borrowing_factor(
                @params.contracts.data_store, params.market.market_token, params.position.is_long
            );

    position_utils::update_total_borrowing(
        params, cache.next_position_size_in_usd, cache.next_position_borrowing_factor
    );

    params.position.size_in_usd = cache.next_position_size_in_usd;
    params.position.size_in_tokens -= values.size_delta_in_tokens;
    params.position.collateral_amount = values.remaining_collateral_amount;
    params.position.decreased_at_block = starknet::info::get_block_number();

    position_utils::increment_claimable_funding_amount(params, fees);

    if (params.position.size_in_usd == 0 || params.position.size_in_tokens == 0) {
        // withdraw all collateral if the position will be closed
        values.output.output_amount += params.position.collateral_amount;

        params.position.size_in_usd = 0;
        params.position.size_in_tokens = 0;
        params.position.collateral_amount = 0;

        params.contracts.data_store.remove_position(params.position_key, params.order.account);
    } else {
        params.position.borrowing_factor = cache.next_position_borrowing_factor;
        params
            .position
            .funding_fee_amount_per_size = fees
            .funding
            .latest_funding_fee_amount_per_size;
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

        params.contracts.data_store.set_position(params.position_key, params.position);
    }

    market_utils::apply_delta_to_collateral_sum(
        params.contracts.data_store,
        params.contracts.event_emitter,
        params.position.market,
        params.position.collateral_token,
        params.position.is_long,
        to_signed(cache.initial_collateral_amount - params.position.collateral_amount, true)
    );

    position_utils::update_open_interest(
        params,
        to_signed(params.order.size_delta_usd, true),
        to_signed(values.size_delta_in_tokens, true)
    );

    // affiliate rewards are still distributed even if the order is a liquidation order
    // this is expected as a partial liquidation is considered the same as an automatic
    // closing of a position
    position_utils::handle_referral(params, fees);

    // validatePosition should be called after open interest and all other market variables
    // have been updated
    if (params.position.size_in_usd != 0 || params.position.size_in_tokens != 0) {
        // validate position which validates liquidation state is only called
        // if the remaining position size is not zero
        // due to this, a user can still manually close their position if
        // it is in a partially liquidatable state
        // this should not cause any issues as a liquidation is the same
        // as automatically closing a position
        // the only difference is that if the position has insufficient / negative
        // collateral a liquidation transaction should still complete
        // while a manual close transaction should revert
        position_utils::validate_position(
            params.contracts.data_store,
            params.contracts.referral_storage,
            params.position,
            params.market,
            cache.prices,
            false, // should_validate_min_position_size
            false // should_validate_min_collateral_usd
        );
    }

    params
        .contracts
        .event_emitter
        .emit_position_fees_collected(
            params.order_key,
            params.position_key,
            params.market.market_token,
            params.position.collateral_token,
            params.order.size_delta_usd,
            false,
            fees
        );

    params
        .contracts
        .event_emitter
        .emit_position_decrease(
            params.order_key,
            params.position_key,
            params.position,
            params.order.size_delta_usd,
            cache.initial_collateral_amount - params.position.collateral_amount,
            params.order.order_type,
            values,
            cache.prices.index_token_price,
            cache.collateral_token_price
        );

    values = decrease_position_swap_utils::swap_withdrawn_collateral_to_pnl_token(params, values);

    DecreasePositionResult {
        output_token: values.output.output_token,
        output_amount: values.output.output_amount,
        secondary_output_token: values.output.secondary_output_token,
        secondary_output_amount: values.output.secondary_output_amount,
    }
}
