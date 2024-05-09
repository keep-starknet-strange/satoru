//! Library for functions to help with the calculations when decreasing a position.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use result::ResultTrait;
// Local imports.
use satoru::position::{position_utils, decrease_position_swap_utils, error};
use satoru::pricing::position_pricing_utils;
use satoru::market::market_utils;
use satoru::price::price::{Price, PriceTrait};
use satoru::order::{base_order_utils, order};
use satoru::utils::{i256::{i256, i256_neg, i256_new}, calc, precision};
use satoru::data::{keys, data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait}};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::fee::fee_utils;
use debug::PrintTrait;

/// Struct used in process_collateral function as cache.
#[derive(Drop, starknet::Store, Serde, Default, Copy)]
struct ProcessCollateralCache {
    /// Wether an insolvent close is allowed or not.
    is_insolvent_close_allowed: bool,
    /// Wether profit is swapped to collateral token.
    was_swapped: bool,
    /// The amount swapped to collateral token.
    swap_output_amount: u256,
    /// The output result after paying for costs.
    result: PayForCostResult,
}

/// Struct to store pay_for_cost function returned result.
#[derive(Drop, starknet::Store, Serde, Default, Copy)]
struct PayForCostResult {
    /// The amount of collateral token paid as cost.
    amount_paid_in_collateral_token: u256,
    /// The amount of secondary output token paid as cost.
    amount_paid_in_secondary_output_token: u256,
    /// The amount of remaining cost in USD
    remaining_cost_usd: u256,
}

/// Struct used in get_execution_price function as cache.
#[derive(Drop, starknet::Store, Serde, Default)]
struct GetExecutionPriceCache {
    /// The price impact induced by execution.
    price_impact_usd: i256,
    /// The difference between maximum price impact and originally calculated price impact.
    price_impact_diff_usd: u256,
    /// The execution price.
    execution_price: u256,
}

/// Handle the collateral changes of the position.
/// # Returns
/// The values linked to the process of a decrease of collateral and position fees.
fn process_collateral(
    mut params: position_utils::UpdatePositionParams, cache: position_utils::DecreasePositionCache
) -> (position_utils::DecreasePositionCollateralValues, position_pricing_utils::PositionFees) {
    let mut collateral_cache: ProcessCollateralCache = Default::default();
    let mut values: position_utils::DecreasePositionCollateralValues = Default::default();
    values.output.output_token = params.position.collateral_token;
    values.output.secondary_output_token = cache.pnl_token;

    // only allow insolvent closing if it is a liquidation or ADL order
    // is_insolvent_close_allowed is used in handleEarlyReturn to determine
    // whether the txn should revert if the remainingCostUsd is below zero
    //
    // for is_insolvent_close_allowed to be true, the size_delta_usd must equal
    // the position size, otherwise there may be pending positive pnl that
    // could be used to pay for fees and the position would be undercharged
    // if the position is not fully closed
    //
    // for ADLs it may be possible that a position needs to be closed by a larger
    // size to fully pay for fees, but closing by that larger size could cause a PnlOvercorrected
    // error to be thrown in AdlHandler, this case should be rare
    collateral_cache
        .is_insolvent_close_allowed = params
        .order
        .size_delta_usd == params
        .position
        .size_in_usd
        && (base_order_utils::is_liquidation_order(params.order.order_type)
            || params.secondary_order_type == order::SecondaryOrderType::Adl(()));
    // in case price impact is too high it is capped and the difference is made to be claimable
    // the execution price is based on the capped price impact so it may be a better price than what it should be
    // price_impact_diff_usd is the difference between the maximum price impact and the originally calculated price impact
    // e.g. if the originally calculated price impact is -$100, but the capped price impact is -$80
    // then priceImpactDiffUsd would be $20

    //TODO uncomment this and should calculate price_impact_usd_ etc..
    // let (price_impact_usd_, price_impact_diff_usd_, execution_price_) = get_execution_price(
    //     params, cache.prices.index_token_price
    // );
    let (price_impact_usd_, price_impact_diff_usd_, execution_price_) = (i256_new(0, false), 0, 0);

    values.price_impact_usd = price_impact_usd_;
    values.price_impact_diff_usd = price_impact_diff_usd_;
    values.execution_price = execution_price_;
    // the total_position_pnl is calculated based on the current indexTokenPrice instead of the executionPrice
    // since the executionPrice factors in price impact which should be accounted for separately
    // the sizeDeltaInTokens is calculated as position.size_in_tokens() * size_delta_usd / position.size_in_usd()
    // the basePnlUsd is the pnl to be realized, and is calculated as:
    // total_position_pnl * size_delta_in_tokens / position.size_in_tokens()
    let (base_pnl_usd_, uncapped_base_pnl_usd_, size_delta_in_tokens_) =
        position_utils::get_position_pnl_usd(
        params.contracts.data_store,
        params.market,
        cache.prices,
        params.position,
        params.order.size_delta_usd
    );
    values.base_pnl_usd = base_pnl_usd_;
    values.uncapped_base_pnl_usd = uncapped_base_pnl_usd_;
    values.size_delta_in_tokens = size_delta_in_tokens_;

    let get_position_fees_params: position_pricing_utils::GetPositionFeesParams =
        position_pricing_utils::GetPositionFeesParams {
        data_store: params.contracts.data_store,
        referral_storage: params.contracts.referral_storage,
        position: params.position,
        collateral_token_price: cache.collateral_token_price,
        for_positive_impact: values.price_impact_usd > Zeroable::zero(),
        long_token: params.market.long_token,
        short_token: params.market.short_token,
        size_delta_usd: params.order.size_delta_usd,
        ui_fee_receiver: params.order.ui_fee_receiver,
    };
    let mut fees: position_pricing_utils::PositionFees = position_pricing_utils::get_position_fees(
        get_position_fees_params
    );

    // if the pnl is positive, deduct the pnl amount from the pool
    if values.base_pnl_usd > Zeroable::zero() {
        // use pnl_token_price.max to minimize the tokens paid out
        let deduction_amount_for_pool: u256 = calc::to_unsigned(values.base_pnl_usd)
            / cache.pnl_token_price.max;

        market_utils::apply_delta_to_pool_amount(
            params.contracts.data_store,
            params.contracts.event_emitter,
            params.market,
            cache.pnl_token,
            calc::to_signed(deduction_amount_for_pool, false)
        );

        if values.output.output_token == cache.pnl_token {
            values.output.output_amount += deduction_amount_for_pool;
        } else {
            values.output.secondary_output_amount += deduction_amount_for_pool;
        }
    }

    if values.price_impact_usd > Zeroable::zero() {
        // use indexTokenPrice.min to maximize the position impact pool reduction
        let deduction_amount_for_impact_pool = calc::roundup_division(
            calc::to_unsigned(values.price_impact_usd), cache.prices.index_token_price.min
        );

        market_utils::apply_delta_to_position_impact_pool(
            params.contracts.data_store,
            params.contracts.event_emitter,
            params.market.market_token,
            calc::to_signed(deduction_amount_for_impact_pool, false)
        );

        // use pnlTokenPrice.max to minimize the payout from the pool
        // some impact pool value may be transferred to the market token pool if there is a
        // large spread between min and max prices
        // since if there is a positive priceImpactUsd, the impact pool would be reduced using indexTokenPrice.min to
        // maximize the deduction value, while the market token pool is reduced using the pnlTokenPrice.max to minimize
        // the deduction value
        // the pool value is calculated by subtracting the worth of the tokens in the position impact pool
        // so this transfer of value would increase the price of the market token
        let deduction_amount_for_pool: u256 = calc::to_unsigned(values.price_impact_usd)
            / cache.pnl_token_price.max;

        market_utils::apply_delta_to_pool_amount(
            params.contracts.data_store,
            params.contracts.event_emitter,
            params.market,
            cache.pnl_token,
            calc::to_signed(deduction_amount_for_pool, false)
        );

        if values.output.output_token == cache.pnl_token {
            values.output.output_amount += deduction_amount_for_pool;
        } else {
            values.output.secondary_output_amount += deduction_amount_for_pool;
        }
    }

    // swap profit to the collateral token
    // if the decreasePositionSwapType was set to NoSwap or if the swap fails due
    // to insufficient liquidity or other reasons then it is possible that
    // the profit remains in a different token from the collateral token
    let (was_swapped_, swap_output_amount_) =
        decrease_position_swap_utils::swap_profit_to_collateral_token(
        params, cache.pnl_token, values.output.secondary_output_amount
    );
    collateral_cache.was_swapped = was_swapped_;
    collateral_cache.swap_output_amount = swap_output_amount_;

    // if the swap was successful the profit should have been swapped
    // to the collateral token
    if collateral_cache.was_swapped {
        values.output.output_amount += collateral_cache.swap_output_amount;
        values.output.secondary_output_amount = 0;
    }

    values.remaining_collateral_amount = params.position.collateral_amount;

    // pay for funding fees
    let (values_, result_) = pay_for_cost(
        params,
        values,
        cache.prices,
        cache.collateral_token_price,
        // use collateralTokenPrice.min because the payForCost
        // will divide the USD value by the price.min as well
        fees.funding.funding_fee_amount * cache.collateral_token_price.min
    );
    values = values_;
    collateral_cache.result = result_;
    if collateral_cache.result.amount_paid_in_secondary_output_token > 0 {
        let holding_address: ContractAddress = params
            .contracts
            .data_store
            .get_address(keys::holding_address());

        if holding_address.is_zero() {
            panic_with_felt252(error::PositionError::EMPTY_HOLDING_ADDRESS);
        }

        // send the funding fee amount to the holding address
        // this funding fee amount should be swapped to the required token
        // and the resulting tokens should be deposited back into the pool
        market_utils::increment_claimable_collateral_amount(
            params.contracts.data_store,
            params.contracts.event_emitter,
            params.market.market_token,
            values.output.secondary_output_token,
            holding_address,
            collateral_cache.result.amount_paid_in_secondary_output_token
        );
    }

    if collateral_cache.result.amount_paid_in_collateral_token < fees.funding.funding_fee_amount {
        // the case where this is insufficient collateral to pay funding fees
        // should be rare, and the difference should be small
        // in case it happens, the pool should be topped up with the required amount using
        // the claimable amount sent to the holding address, an insurance fund, or similar mechanism
        params
            .contracts
            .event_emitter
            .emit_insufficient_funding_fee_payment(
                params.market.market_token,
                params.position.collateral_token,
                fees.funding.funding_fee_amount,
                collateral_cache.result.amount_paid_in_collateral_token,
                collateral_cache.result.amount_paid_in_secondary_output_token
            );
    }

    if collateral_cache.result.remaining_cost_usd > 0 {
        return handle_early_return(params, @values, fees, collateral_cache, 'funding');
    };

    // pay for negative pnl
    if values.base_pnl_usd < Zeroable::zero() {
        let (values_, result_) = pay_for_cost(
            params,
            values,
            cache.prices,
            cache.collateral_token_price,
            calc::to_unsigned(i256_neg(values.base_pnl_usd))
        );
        values = values_;
        collateral_cache.result = result_;

        if collateral_cache.result.amount_paid_in_collateral_token > 0 {
            market_utils::apply_delta_to_pool_amount(
                params.contracts.data_store,
                params.contracts.event_emitter,
                params.market,
                params.position.collateral_token,
                calc::to_signed(collateral_cache.result.amount_paid_in_collateral_token, true)
            );
        }

        if collateral_cache.result.amount_paid_in_secondary_output_token > 0 {
            market_utils::apply_delta_to_pool_amount(
                params.contracts.data_store,
                params.contracts.event_emitter,
                params.market,
                values.output.secondary_output_token,
                calc::to_signed(collateral_cache.result.amount_paid_in_secondary_output_token, true)
            );
        }

        if collateral_cache.result.remaining_cost_usd > 0 {
            return handle_early_return(params, @values, fees, collateral_cache, 'pnl');
        }
    }

    // pay for fees
    let (values_, result_) = pay_for_cost(
        params,
        values,
        cache.prices,
        cache.collateral_token_price,
        // use collateral_token_price.min because the pay_for_cost
        // will divide the USD value by the price.min as well
        fees.total_cost_amount_excluding_funding * cache.collateral_token_price.min
    );
    values = values_;
    collateral_cache.result = result_;

    // if fees were fully paid in the collateral token, update the pool and claimable fee amounts
    if collateral_cache.result.remaining_cost_usd == 0
        && collateral_cache.result.amount_paid_in_secondary_output_token == 0 {
        // there may be a large amount of borrowing fees that could have been accumulated
        // these fees could cause the pool to become unbalanced, price impact is not paid for causing
        // this imbalance
        // the swap impact pool should be built up so that it can be used to pay for positive price impact
        // for re-balancing to help handle this case
        market_utils::apply_delta_to_pool_amount(
            params.contracts.data_store,
            params.contracts.event_emitter,
            params.market,
            params.position.collateral_token,
            calc::to_signed(fees.fee_amount_for_pool, true)
        );

        fee_utils::increment_claimable_fee_amount(
            params.contracts.data_store,
            params.contracts.event_emitter,
            params.market.market_token,
            params.position.collateral_token,
            fees.fee_receiver_amount,
            keys::position_fee_type()
        );

        fee_utils::increment_claimable_ui_fee_amount(
            params.contracts.data_store,
            params.contracts.event_emitter,
            params.order.ui_fee_receiver,
            params.market.market_token,
            params.position.collateral_token,
            fees.ui.ui_fee_amount,
            keys::ui_position_fee_type()
        );
    } else {
        // the fees are expected to be paid in the collateral token
        // if there are insufficient funds to pay for fees entirely in the collateral token
        // then credit the fee amount entirely to the pool
        if collateral_cache.result.amount_paid_in_collateral_token > 0 {
            market_utils::apply_delta_to_pool_amount(
                params.contracts.data_store,
                params.contracts.event_emitter,
                params.market,
                params.position.collateral_token,
                calc::to_signed(collateral_cache.result.amount_paid_in_collateral_token, true)
            );
        }

        if collateral_cache.result.amount_paid_in_secondary_output_token > 0 {
            market_utils::apply_delta_to_pool_amount(
                params.contracts.data_store,
                params.contracts.event_emitter,
                params.market,
                values.output.secondary_output_token,
                calc::to_signed(collateral_cache.result.amount_paid_in_secondary_output_token, true)
            );
        }

        // empty the fees since the amount was entirely paid to the pool instead of for fees
        // it is possible for the txn execution to still complete even in this case
        // as long as the remainingCostUsd is still zero
        fees = get_empty_fees(@fees);
    }

    if collateral_cache.result.remaining_cost_usd > 0 {
        return handle_early_return(params, @values, fees, collateral_cache, 'fees');
    }

    // pay for negative price impact
    if values.price_impact_usd < Zeroable::zero() {
        let (values_, result_) = pay_for_cost(
            params,
            values,
            cache.prices,
            cache.collateral_token_price,
            calc::to_unsigned(i256_neg(values.price_impact_usd))
        );
        values = values_;
        collateral_cache.result = result_;

        if collateral_cache.result.amount_paid_in_collateral_token > 0 {
            market_utils::apply_delta_to_pool_amount(
                params.contracts.data_store,
                params.contracts.event_emitter,
                params.market,
                params.position.collateral_token,
                calc::to_signed(collateral_cache.result.amount_paid_in_collateral_token, true)
            );

            market_utils::apply_delta_to_position_impact_pool(
                params.contracts.data_store,
                params.contracts.event_emitter,
                params.market.market_token,
                calc::to_signed(
                    collateral_cache.result.amount_paid_in_collateral_token
                        * cache.collateral_token_price.min
                        / cache.prices.index_token_price.max,
                    true
                )
            );
        }

        if collateral_cache.result.amount_paid_in_secondary_output_token > 0 {
            market_utils::apply_delta_to_pool_amount(
                params.contracts.data_store,
                params.contracts.event_emitter,
                params.market,
                values.output.secondary_output_token,
                calc::to_signed(collateral_cache.result.amount_paid_in_secondary_output_token, true)
            );

            market_utils::apply_delta_to_position_impact_pool(
                params.contracts.data_store,
                params.contracts.event_emitter,
                params.market.market_token,
                calc::to_signed(
                    collateral_cache.result.amount_paid_in_secondary_output_token
                        * cache.pnl_token_price.min
                        / cache.prices.index_token_price.max,
                    true
                )
            );
        }

        if collateral_cache.result.remaining_cost_usd > 0 {
            return handle_early_return(params, @values, fees, collateral_cache, 'impact');
        }
    }

    // pay for price impact diff
    if values.price_impact_diff_usd > 0 {
        let (values_, result_) = pay_for_cost(
            params, values, cache.prices, cache.collateral_token_price, values.price_impact_diff_usd
        );
        values = values_;
        collateral_cache.result = result_;

        if collateral_cache.result.amount_paid_in_collateral_token > 0 {
            market_utils::increment_claimable_collateral_amount(
                params.contracts.data_store,
                params.contracts.event_emitter,
                params.market.market_token,
                params.position.collateral_token,
                params.order.account,
                collateral_cache.result.amount_paid_in_collateral_token
            );
        }

        if collateral_cache.result.amount_paid_in_secondary_output_token > 0 {
            market_utils::increment_claimable_collateral_amount(
                params.contracts.data_store,
                params.contracts.event_emitter,
                params.market.market_token,
                values.output.secondary_output_token,
                params.order.account,
                collateral_cache.result.amount_paid_in_secondary_output_token
            );
        }

        if collateral_cache.result.remaining_cost_usd > 0 {
            return handle_early_return(params, @values, fees, collateral_cache, 'diff');
        }
    }

    // the priceImpactDiffUsd has been deducted from the output amount or the position's collateral
    // to reduce the chance that the position's collateral is reduced by an unexpected amount, adjust the
    // initialCollateralDeltaAmount by the priceImpactDiffAmount
    // this would also help to prevent the position's leverage from being unexpectedly increased
    //
    // note that this calculation may not be entirely accurate since it is possible that the priceImpactDiffUsd
    // could have been paid with one of or a combination of collateral / outputAmount / secondaryOutputAmount
    if params.order.initial_collateral_delta_amount > 0 && values.price_impact_diff_usd > 0 {
        let initial_collateral_delta_amount: u256 = params.order.initial_collateral_delta_amount;

        let price_impact_diff_amount: u256 = values.price_impact_diff_usd
            / cache.collateral_token_price.min;
        if initial_collateral_delta_amount > price_impact_diff_amount {
            params.order.initial_collateral_delta_amount = initial_collateral_delta_amount
                - price_impact_diff_amount;
        } else {
            params.order.initial_collateral_delta_amount = 0;
        }

        params
            .contracts
            .event_emitter
            .emit_order_collateral_delta_amount_auto_updated(
                params.order_key,
                initial_collateral_delta_amount, // collateral_delta_amount
                params.order.initial_collateral_delta_amount // next_collateral_delta_amount
            );
    }

    // cap the withdrawable amount to the remainingCollateralAmount
    if params.order.initial_collateral_delta_amount > values.remaining_collateral_amount {
        params
            .contracts
            .event_emitter
            .emit_order_collateral_delta_amount_auto_updated(
                params.order_key,
                params.order.initial_collateral_delta_amount, // collateral_delta_amount
                values.remaining_collateral_amount // next_collateral_delta_amount
            );

        params.order.initial_collateral_delta_amount = values.remaining_collateral_amount;
    }

    if params.order.initial_collateral_delta_amount > 0 {
        values.remaining_collateral_amount -= params.order.initial_collateral_delta_amount;
        values.output.output_amount += params.order.initial_collateral_delta_amount;
    }

    (values, fees)
}

/// Compute execution price of the position update.
/// # Arguments
/// * `params` - The parameters of the position update.
/// * `index_token_price` - The price of the index token.
/// (price_impact_usd, price_impact_diff_usd, execution_price)
fn get_execution_price(
    params: position_utils::UpdatePositionParams, index_token_price: Price
) -> (i256, u256, u256) {
    let size_delta_usd: u256 = params.order.size_delta_usd;

    // note that the executionPrice is not validated against the order.acceptable_price value
    // if the size_delta_usd is zero
    // for limit orders the order.triggerPrice should still have been validated
    if size_delta_usd == 0 {
        // decrease order:
        //     - long: use the smaller price
        //     - short: use the larger price
        return (Zeroable::zero(), 0, index_token_price.pick_price(!params.position.is_long));
    }

    let mut cache: GetExecutionPriceCache = Default::default();

    cache
        .price_impact_usd =
            position_pricing_utils::get_price_impact_usd(
                position_pricing_utils::GetPriceImpactUsdParams {
                    data_store: params.contracts.data_store,
                    market: params.market,
                    usd_delta: calc::to_signed(size_delta_usd, false),
                    is_long: params.order.is_long,
                }
            );

    // cap priceImpactUsd based on the amount available in the position impact pool
    cache
        .price_impact_usd =
            market_utils::get_capped_position_impact_usd(
                params.contracts.data_store,
                params.market.market_token,
                index_token_price,
                cache.price_impact_usd,
                size_delta_usd
            );

    if cache.price_impact_usd < Zeroable::zero() {
        let max_price_impact_factor: u256 = market_utils::get_max_position_impact_factor(
            params.contracts.data_store, params.market.market_token, false
        );

        // convert the max price impact to the min negative value
        // e.g. if size_delta_usd is 10,000 and max_price_impact_factor is 2%
        // then minPriceImpactUsd = -200
        let min_price_impact_usd: i256 = calc::to_signed(
            precision::apply_factor_u256(size_delta_usd, max_price_impact_factor), false
        );

        // cap priceImpactUsd to the min negative value and store the difference in price_impact_diff_usd
        // e.g. if price_impact_usd is -500 and min_price_impact_usd is -200
        // then set price_impact_diff_usd to -200 - -500 = 300
        // set priceImpactUsd to -200
        if cache.price_impact_usd < min_price_impact_usd {
            cache
                .price_impact_diff_usd =
                    calc::to_unsigned(min_price_impact_usd - cache.price_impact_usd);
            cache.price_impact_usd = min_price_impact_usd;
        }
    }

    // the execution_price is calculated after the price impact is capped
    // so the output amount directly received by the user may not match
    // the execution_price, the difference would be in the stored as a
    // claimable amount
    cache
        .execution_price =
            base_order_utils::get_execution_price_for_decrease(
                index_token_price,
                params.position.size_in_usd,
                params.position.size_in_tokens,
                size_delta_usd,
                cache.price_impact_usd,
                params.order.acceptable_price,
                params.position.is_long
            );

    (cache.price_impact_usd, cache.price_impact_diff_usd, cache.execution_price)
}

/// Pay costs of the position update.
/// # Arguments
/// * `params` - The parameters of the position update.
/// * `values` - The struct filled with values computed in process_collateral.
/// * `prices` - The prices of tokens in the market.
/// * `collateral_token_price` - The prices of the collateral token.
/// * `cost_usd` - The total cost in usd.
/// # Returns
/// Updated position_utils::DecreasePositionCollateralValues and output of pay for cost.
fn pay_for_cost(
    params: position_utils::UpdatePositionParams,
    mut values: position_utils::DecreasePositionCollateralValues,
    prices: market_utils::MarketPrices,
    collateral_token_price: Price,
    cost_usd: u256,
) -> (position_utils::DecreasePositionCollateralValues, PayForCostResult) {
    let mut result: PayForCostResult = Default::default();

    if cost_usd == 0 {
        return (values, result);
    }

    let mut remaining_cost_in_output_token: u256 = calc::roundup_division(
        cost_usd, collateral_token_price.min
    );

    if values.output.output_amount > 0 {
        if values.output.output_amount > remaining_cost_in_output_token {
            result.amount_paid_in_collateral_token += remaining_cost_in_output_token;
            values.output.output_amount -= remaining_cost_in_output_token;
            remaining_cost_in_output_token = 0;
        } else {
            result.amount_paid_in_collateral_token += values.output.output_amount;
            remaining_cost_in_output_token -= values.output.output_amount;
            values.output.output_amount = 0;
        }
    }

    if remaining_cost_in_output_token == 0 {
        return (values, result);
    }

    if (values.remaining_collateral_amount > 0) {
        if (values.remaining_collateral_amount > remaining_cost_in_output_token) {
            result.amount_paid_in_collateral_token += remaining_cost_in_output_token;
            values.remaining_collateral_amount -= remaining_cost_in_output_token;
            remaining_cost_in_output_token = 0;
        } else {
            result.amount_paid_in_collateral_token += values.remaining_collateral_amount;
            remaining_cost_in_output_token -= values.remaining_collateral_amount;
            values.remaining_collateral_amount = 0;
        }
    }

    if remaining_cost_in_output_token == 0 {
        return (values, result);
    }

    let secondary_output_token_price: Price = market_utils::get_cached_token_price(
        values.output.secondary_output_token, params.market, prices
    );

    let mut remaining_cost_in_secondary_output_token: u256 = remaining_cost_in_output_token
        * collateral_token_price.min
        / secondary_output_token_price.min;

    if (values.output.secondary_output_amount > 0) {
        if (values.output.secondary_output_amount > remaining_cost_in_secondary_output_token) {
            result
                .amount_paid_in_secondary_output_token += remaining_cost_in_secondary_output_token;
            values.output.secondary_output_amount -= remaining_cost_in_secondary_output_token;
            remaining_cost_in_secondary_output_token = 0;
        } else {
            result.amount_paid_in_secondary_output_token += values.output.secondary_output_amount;
            remaining_cost_in_secondary_output_token -= values.output.secondary_output_amount;
            values.output.secondary_output_amount = 0;
        }
    }

    result.remaining_cost_usd = remaining_cost_in_secondary_output_token
        * secondary_output_token_price.min;

    (values, result)
}

/// Handle early return case where there is still remaining costs.
/// # Arguments
/// * `params` - The parameters of the position update.
/// * `values` - The struct filled with values computed in process_collateral.
/// * `fees` - The position fees.
/// * `collateral_cache` - The struct used as cache in process_collateral.
/// # Returns
/// Updated position_utils::DecreasePositionCollateralValues and position fees.
fn handle_early_return(
    params: position_utils::UpdatePositionParams,
    values: @position_utils::DecreasePositionCollateralValues,
    fees: position_pricing_utils::PositionFees,
    collateral_cache: ProcessCollateralCache,
    step: felt252
) -> (position_utils::DecreasePositionCollateralValues, position_pricing_utils::PositionFees) {
    if (!collateral_cache.is_insolvent_close_allowed) {
        error::PositionError::INSUFFICIENT_FUNDS_TO_PAY_FOR_COSTS(
            collateral_cache.result.remaining_cost_usd, step
        );
    }

    params
        .contracts
        .event_emitter
        .emit_position_fees_info(
            params.order_key,
            params.position_key,
            params.market.market_token,
            params.position.collateral_token,
            params.order.size_delta_usd,
            false, // isIncrease
            fees
        );

    params
        .contracts
        .event_emitter
        .emit_insolvent_close_info(
            params.order_key,
            params.position.collateral_amount,
            *values.base_pnl_usd,
            collateral_cache.result.remaining_cost_usd
        );

    (*values, get_empty_fees(@fees))
}

/// Return empty fees struct using fees struct given in parameter.
/// Keep useful values such as accumulated funding fees.
/// # Arguments
/// * `fees` - The position_pricing_utils::PositionFees struct used to get the new empty struct.
/// # Returns
/// An empty position_pricing_utils::PositionFees struct.
fn get_empty_fees(
    fees: @position_pricing_utils::PositionFees
) -> position_pricing_utils::PositionFees {
    let referral: position_pricing_utils::PositionReferralFees = Default::default();

    // allow the accumulated funding fees to still be claimable
    // return the latestFundingFeeAmountPerSize, latest_long_token_claimable_funding_amount_per_size,
    // latest_short_token_claimable_funding_amount_per_size values as these may be used to update the
    // position's values if the position will be partially closed
    let funding = position_pricing_utils::PositionFundingFees {
        funding_fee_amount: 0,
        claimable_long_token_amount: *fees.funding.claimable_long_token_amount,
        claimable_short_token_amount: *fees.funding.claimable_short_token_amount,
        latest_funding_fee_amount_per_size: *fees.funding.latest_funding_fee_amount_per_size,
        latest_long_token_claimable_funding_amount_per_size: *fees
            .funding
            .latest_long_token_claimable_funding_amount_per_size,
        latest_short_token_claimable_funding_amount_per_size: *fees
            .funding
            .latest_short_token_claimable_funding_amount_per_size,
    };
    let borrowing: position_pricing_utils::PositionBorrowingFees = Default::default();
    let ui: position_pricing_utils::PositionUiFees = Default::default();
    // all fees are zeroed even though funding may have been paid
    // the funding fee amount value may not be accurate in the events due to this
    position_pricing_utils::PositionFees {
        referral,
        funding,
        borrowing,
        ui,
        collateral_token_price: *fees.collateral_token_price,
        position_fee_factor: 0,
        protocol_fee_amount: 0,
        position_fee_receiver_factor: 0,
        fee_receiver_amount: 0,
        fee_amount_for_pool: 0,
        position_fee_amount_for_pool: 0,
        position_fee_amount: 0,
        total_cost_amount_excluding_funding: 0,
        total_cost_amount: 0,
    }
}
