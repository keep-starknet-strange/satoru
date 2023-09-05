//! Library for functions to help with increasing a position.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;

// Local imports
use satoru::position::position_utils::UpdatePositionParams;
use satoru::pricing::position_pricing_utils::{
    PositionFees, PositionBorrowingFees, PositionFundingFees, PositionReferralFees, PositionUiFees,
};
use satoru::price::price::Price;

#[derive(Drop, starknet::Store, Serde)]
struct IncreasePositionCache {
    /// The change in collateral amount.
    collateral_delta_amount: u128, // TODO replace with i128 when storeable
    execution_price: u128,
    collateral_token_price: Price,
    /// The price impact of the position increase in USD.
    price_impact_usd: u128, // TODO replace with i128 when storeable
    /// The price impact of the position increase in tokens.
    price_impact_amount: u128, // TODO replace with i128 when storeable
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
fn increase_position(params: UpdatePositionParams, collateral_increment_amount: u128) { // TODO
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
