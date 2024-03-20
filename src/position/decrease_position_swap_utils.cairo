// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;
use array::ArrayTrait;

// Local imports.
use satoru::position::{
    error::PositionError,
    position_utils::{
        DecreasePositionCollateralValues, UpdatePositionParams,
        DecreasePositionCollateralValuesOutput
    }
};
use satoru::order::order::DecreasePositionSwapType;
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::swap::swap_utils::{SwapParams};
use satoru::market::market::Market;

/// Swap the withdrawn collateral from collateral_token to pnl_token if needed.
fn swap_withdrawn_collateral_to_pnl_token(
    params: UpdatePositionParams, mut values: DecreasePositionCollateralValues
) -> DecreasePositionCollateralValues {
    let mut swap_path_markets = ArrayTrait::<Market>::new();
    if (values.output.output_amount > 0
        && params
            .order
            .decrease_position_swap_type == DecreasePositionSwapType::SwapCollateralTokenToPnlToken) {
        swap_path_markets.append(params.market);
        let (token_out, swap_output_amount) = params
            .contracts
            .swap_handler
            .swap(
                SwapParams {
                    data_store: params.contracts.data_store,
                    event_emitter: params.contracts.event_emitter,
                    oracle: params.contracts.oracle,
                    bank: IBankDispatcher { contract_address: params.market.market_token },
                    key: params.order_key,
                    token_in: params.position.collateral_token,
                    amount_in: values.output.output_amount,
                    swap_path_markets: swap_path_markets.span(),
                    min_output_amount: 0,
                    receiver: params.market.market_token,
                    ui_fee_receiver: params.order.ui_fee_receiver,
                }
            );

        if (token_out != values.output.secondary_output_token) {
            panic(array![PositionError::INVALID_OUTPUT_TOKEN]);
        }
        values.output.output_token = token_out;
        values.output.output_amount = values.output.secondary_output_amount + swap_output_amount;
        values.output.secondary_output_amount = 0;
    }
    values
}

/// Swap the realized profit from the pnlToken to the collateralToken if needed.
/// # Arguments
/// * `pnl_token` - The profit token.
/// * `pnl_amount` - The amount of profit in usd.
/// # Returns
/// DecreasePositionCollateralValues
fn swap_profit_to_collateral_token(
    params: UpdatePositionParams, pnl_token: ContractAddress, profit_amount: u256
) -> (bool, u256) {
    let mut swap_path_markets = ArrayTrait::<Market>::new();
    if (profit_amount > 0
        && params
            .order
            .decrease_position_swap_type == DecreasePositionSwapType::SwapPnlTokenToCollateralToken) {
        swap_path_markets.append(params.market);
        let (token_out, swap_output_amount) = params
            .contracts
            .swap_handler
            .swap(
                SwapParams {
                    data_store: params.contracts.data_store,
                    event_emitter: params.contracts.event_emitter,
                    oracle: params.contracts.oracle,
                    bank: IBankDispatcher { contract_address: params.market.market_token },
                    key: params.order_key,
                    token_in: pnl_token,
                    amount_in: profit_amount,
                    swap_path_markets: swap_path_markets.span(),
                    min_output_amount: 0,
                    receiver: params.market.market_token,
                    ui_fee_receiver: params.order.ui_fee_receiver,
                }
            );
        return (true, swap_output_amount);
    }
    (false, 0)
}
