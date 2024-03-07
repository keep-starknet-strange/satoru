//! Library for pricing functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
use satoru::utils::{precision, calc};
use satoru::utils::i256::i256;

/// Get the price impact USD if there is no crossover in balance
/// a crossover in balance is for example if the long open interest is larger
/// than the short open interest, and a short position is opened such that the
/// short open interest becomes larger than the long open interest.
fn get_price_impact_usd_for_same_side_rebalance(
    initial_diff_usd: u256, next_diff_usd: u256, impact_factor: u256, impact_exponent_factor: u256,
) -> i256 {
    let has_positive_impact: bool = next_diff_usd < initial_diff_usd;

    let delta_diff_usd = calc::diff(
        apply_impact_factor(initial_diff_usd, impact_factor, impact_exponent_factor),
        apply_impact_factor(next_diff_usd, impact_factor, impact_exponent_factor),
    );

    calc::to_signed(delta_diff_usd, has_positive_impact)
}

/// Get the price impact USD if there is a crossover in balance
/// a crossover in balance is for example if the long open interest is larger
/// than the short open interest, and a short position is opened such that the
/// short open interest becomes larger than the long open interest.
fn get_price_impact_usd_for_crossover_rebalance(
    initial_diff_usd: u256,
    next_diff_usd: u256,
    positive_impact_factor: u256,
    negative_impact_factor: u256,
    impact_exponent_factor: u256,
) -> i256 {
    let positive_impact_usd = apply_impact_factor(
        initial_diff_usd, positive_impact_factor, impact_exponent_factor
    );
    let negative_impact_usd = apply_impact_factor(
        next_diff_usd, negative_impact_factor, impact_exponent_factor
    );
    let delta_diff_usd = calc::diff(positive_impact_usd, negative_impact_usd);

    calc::to_signed(delta_diff_usd, positive_impact_usd > negative_impact_usd)
}

/// Apply the impact factor calculation to a USD diff value.
fn apply_impact_factor(diff_usd: u256, impact_factor: u256, impact_exponent_factor: u256,) -> u256 {
    let exponent_value = precision::apply_exponent_factor(diff_usd, impact_exponent_factor);
    precision::apply_factor_u256(exponent_value, impact_factor)
}
