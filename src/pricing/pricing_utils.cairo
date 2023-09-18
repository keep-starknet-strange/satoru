//! Library for pricing functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

/// Get the price impact USD if there is no crossover in balance
/// a crossover in balance is for example if the long open interest is larger
/// than the short open interest, and a short position is opened such that the
/// short open interest becomes larger than the long open interest.
fn get_price_impact_usd_for_same_side_rebalance(
    initial_diff_usd: u128, next_diff_usd: u128, impact_factor: u128, impact_exponent_factor: u128,
) -> i128 {
    // TODO
    0
}

/// Get the price impact USD if there is a crossover in balance
/// a crossover in balance is for example if the long open interest is larger
/// than the short open interest, and a short position is opened such that the
/// short open interest becomes larger than the long open interest.
fn get_price_impact_usd_for_crossover_rebalance(
    initial_diff_usd: u128,
    next_diff_usd: u128,
    positive_impact_factor: u128,
    negative_impact_factor: u128,
    impact_exponent_factor: u128,
) -> i128 {
    // TODO
    0
}

/// Apply the impact factor calculation to a USD diff value.
fn apply_impact_factor(diff_usd: u128, impact_factor: u128, impact_exponent_factor: u128,) -> u128 {
    // TODO
    0
}
