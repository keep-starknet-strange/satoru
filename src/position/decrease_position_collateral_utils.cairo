//! Library for functions to help with the calculations when decreasing a position.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;
use traits::{Into, TryInto};
use option::OptionTrait;

// Local imports.
use gojo::position::position_utils::{
    DecreasePositionCollateralValues, UpdatePositionParams, DecreasePositionCache,
    DecreasePositionCollateralValuesOutput
};
use gojo::pricing::position_pricing_utils::{
    PositionFees, PositionBorrowingFees, PositionFundingFees, PositionReferralFees, PositionUiFees,
};
use gojo::market::market_utils::MarketPrices;
use gojo::price::price::Price;

/// Struct used in process_collateral function as cache.
#[derive(Drop, starknet::Store, Serde)]
struct ProcessCollateralCache {
    /// Wether an insolvent close is allowed or not.
    is_insolvent_close_allowed: bool,
    /// Wether profit is swapped to collateral token.
    was_swapped: bool,
    /// The amount swapped to collateral token.
    swap_output_amount: u128,
    /// The output result after paying for costs.
    result: PayForCostResult,
}

/// Struct to store pay_for_cost function returned result.
#[derive(Drop, starknet::Store, Serde)]
struct PayForCostResult {
    /// The amount of collateral token paid as cost.
    amount_paid_in_collateral_token: u128,
    /// The amount of secondary output token paid as cost.
    amount_paid_in_secondary_output_token: u128,
    /// The amount of remaining cost in USD
    remaining_cost_usd: u128,
}

/// Struct used in get_execution_price function as cache.
#[derive(Drop, starknet::Store, Serde)]
struct GetExecutionPriceCache {
    /// The price impact induced by execution.
    price_impact_usd: u128, // TODO replace with i128 when it derives Store
    /// The difference between maximum price impact and originally calculated price impact.
    priceImpactDiffUsd: u128,
    /// The execution price.
    execution_price: u128,
}

/// Handle the collateral changes of the position.
/// # Returns
/// (DecreasePositionCollateralValues, PositionFees)
#[inline(always)]
fn process_collateral(
    params: UpdatePositionParams, cache: DecreasePositionCache
) -> (DecreasePositionCollateralValues, PositionFees) {
    // TODO
    let address_zero: ContractAddress = 0.try_into().unwrap();
    let decrease_position_collateral_values_output = DecreasePositionCollateralValuesOutput {
        output_token: address_zero,
        output_amount: 0,
        secondary_output_token: address_zero,
        secondary_output_amount: 0,
    };
    let decrease_position_collateral_values = DecreasePositionCollateralValues {
        execution_price: 0,
        remaining_collateral_amount: 0,
        base_pnl_usd: 0,
        uncapped_base_pnl_usd: 0,
        size_delta_in_tokens: 0,
        price_impact_usd: 0,
        price_imact_diff_usd: 0,
        output: decrease_position_collateral_values_output
    };
    let position_referral_fees = PositionReferralFees {
        referral_code: 0,
        affiliate: address_zero,
        trader: address_zero,
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
        ui_fee_receiver: address_zero, ui_fee_receiver_factor: 0, ui_fee_amount: 0,
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
    (decrease_position_collateral_values, position_fees)
}

/// Compute execution price of the position update.
/// # Arguments
/// * `params` - The parameters of the position update.
/// * `index_token_price` - The price of the index token.
/// (price_impact_usd, price_impact_diff_usd, execution_price)
fn get_execution_price(
    params: UpdatePositionParams, index_token_price: Price
) -> (i128, u128, u128) {
    // TODO
    (0, 0, 0)
}

/// Pay costs of the position update.
/// # Arguments
/// * `params` - The parameters of the position update.
/// * `values` - The struct filled with values computed in process_collateral.
/// * `prices` - The prices of tokens in the market.
/// * `collateral_token_price` - The prices of the collateral token.
/// * `cost_usd` - The total cost in usd.
/// # Returns
/// Updated DecreasePositionCollateralValues and output of pay for cost.
fn pay_for_cost(
    params: UpdatePositionParams,
    values: DecreasePositionCollateralValues,
    prices: MarketPrices,
    collateral_token_price: Price,
    cost_usd: u128,
) -> (DecreasePositionCollateralValues, PayForCostResult) {
    // TODO
    let address_zero: ContractAddress = 0.try_into().unwrap();
    let decrease_position_collateral_values_output = DecreasePositionCollateralValuesOutput {
        output_token: address_zero,
        output_amount: 0,
        secondary_output_token: address_zero,
        secondary_output_amount: 0,
    };
    let decrease_position_collateral_values = DecreasePositionCollateralValues {
        execution_price: 0,
        remaining_collateral_amount: 0,
        base_pnl_usd: 0,
        uncapped_base_pnl_usd: 0,
        size_delta_in_tokens: 0,
        price_impact_usd: 0,
        price_imact_diff_usd: 0,
        output: decrease_position_collateral_values_output
    };
    let pay_for_cost_result = PayForCostResult {
        amount_paid_in_collateral_token: 0,
        amount_paid_in_secondary_output_token: 0,
        remaining_cost_usd: 0,
    };
    (decrease_position_collateral_values, pay_for_cost_result)
}

/// Handle early return case where there is still remaining costs.
/// # Arguments
/// * `params` - The parameters of the position update.
/// * `values` - The struct filled with values computed in process_collateral.
/// * `fees` - The position fees.
/// * `collateral_cache` - The struct used as cache in process_collateral.
/// # Returns
/// Updated DecreasePositionCollateralValues and position fees.
fn handle_early_return(
    params: UpdatePositionParams,
    values: DecreasePositionCollateralValues,
    fees: PositionFees,
    collateral_cache: ProcessCollateralCache,
) -> (DecreasePositionCollateralValues, PositionFees) {
    // TODO
    let address_zero: ContractAddress = 0.try_into().unwrap();
    let decrease_position_collateral_values_output = DecreasePositionCollateralValuesOutput {
        output_token: address_zero,
        output_amount: 0,
        secondary_output_token: address_zero,
        secondary_output_amount: 0,
    };
    let decrease_position_collateral_values = DecreasePositionCollateralValues {
        execution_price: 0,
        remaining_collateral_amount: 0,
        base_pnl_usd: 0,
        uncapped_base_pnl_usd: 0,
        size_delta_in_tokens: 0,
        price_impact_usd: 0,
        price_imact_diff_usd: 0,
        output: decrease_position_collateral_values_output
    };
    let position_referral_fees = PositionReferralFees {
        referral_code: 0,
        affiliate: address_zero,
        trader: address_zero,
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
        ui_fee_receiver: address_zero, ui_fee_receiver_factor: 0, ui_fee_amount: 0,
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
    (decrease_position_collateral_values, position_fees)
}

/// Return empty fees struct using fees struct given in parameter.
/// Keep useful values such as accumulated funding fees.
/// # Arguments
/// * `fees` - The PositionFees struct used to get the new empty struct.
/// # Returns
/// An empty PositionFees struct.
fn get_empty_fees(fees: PositionFees) -> PositionFees {
    // TODO
    let address_zero: ContractAddress = 0.try_into().unwrap();
    let position_referral_fees = PositionReferralFees {
        referral_code: 0,
        affiliate: address_zero,
        trader: address_zero,
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
        ui_fee_receiver: address_zero, ui_fee_receiver_factor: 0, ui_fee_amount: 0,
    };
    let price = Price { min: 0, max: 0, };
    PositionFees {
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
    }
}
