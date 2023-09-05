//! Library for functions to help with decreasing a position.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;

// Local imports
use satoru::position::position_utils::UpdatePositionParams;

/// Struct used as result for decrease_position_function output.
#[derive(Drop, starknet::Store, Serde)]
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
fn decrease_position(params: UpdatePositionParams) -> DecreasePositionResult {
    // TODO
    let address_zero: ContractAddress = 0.try_into().unwrap();
    DecreasePositionResult {
        output_token: address_zero,
        output_amount: 0,
        secondary_output_token: address_zero,
        secondary_output_amount: 0,
    }
}
