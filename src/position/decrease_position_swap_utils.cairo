// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;

// Local imports.
use satoru::position::position_utils::{
    DecreasePositionCollateralValues, UpdatePositionParams, DecreasePositionCollateralValuesOutput
};

/// Swap the withdrawn collateral from collateral_token to pnl_token if needed.
#[inline(always)]
fn swap_withdrawn_collateral_to_pnl_token(
    params: UpdatePositionParams, values: DecreasePositionCollateralValues
) -> DecreasePositionCollateralValues {
    // TODO
    let address_zero: ContractAddress = 0.try_into().unwrap();
    let decrease_position_collateral_values_output = DecreasePositionCollateralValuesOutput {
        output_token: address_zero,
        output_amount: 0,
        secondary_output_token: address_zero,
        secondary_output_amount: 0,
    };
    DecreasePositionCollateralValues {
        execution_price: 0,
        remaining_collateral_amount: 0,
        base_pnl_usd: 0,
        uncapped_base_pnl_usd: 0,
        size_delta_in_tokens: 0,
        price_impact_usd: 0,
        price_impact_diff_usd: 0,
        output: decrease_position_collateral_values_output
    }
}

/// Swap the realized profit from the pnlToken to the collateralToken if needed.
/// # Arguments
/// * `pnl_token` - The profit token.
/// * `pnl_amount` - The amount of profit in usd.
/// # Returns
/// DecreasePositionCollateralValues
#[inline(always)]
fn swap_profit_to_collateral_token(
    params: UpdatePositionParams, pnl_token: ContractAddress, profit_amount: u128
) -> (bool, u128) {
    // TODO
    (false, 0)
}
