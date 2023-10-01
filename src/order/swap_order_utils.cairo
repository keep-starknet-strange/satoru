// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::order::base_order_utils::ExecuteOrderParams;
use satoru::order::order::OrderType;
use satoru::oracle::oracle_utils;
use satoru::utils::arrays::are_gte;
use satoru::swap::swap_utils;
use satoru::event::event_utils;
use satoru::order::error::OrderError;

// This function should return an EventLogData cause the callback_utils
// needs it. We need to find a solution for that case.
#[inline(always)]
fn process_order(params: ExecuteOrderParams) -> event_utils::LogData {
    if (params.order.market.is_non_zero()) {
        panic(array![OrderError::UNEXPECTED_MARKET]);
    }

    validate_oracle_block_numbers(params.min_oracle_block_numbers, params.max_oracle_block_numbers, params.order.order_type, params.order.updated_at_block);

    let (collateral_token, collateral_increment_amount) = swap_utils::swap(
        @swap_utils::SwapParams {
            data_store: params.contracts.data_store,
            event_emitter: params.contracts.event_emitter,
            oracle: params.contracts.oracle,
            bank: IBankDispatcher {
                contract_address: params.contracts.order_vault.contract_address
            },
            key: params.key,
            token_in: params.order.initial_collateral_token,
            amount_in: params.order.initial_collateral_delta_amount,
            swap_path_markets: params.swap_path_markets.span(),
            min_output_amount: params.order.min_output_amount,
            receiver: params.order.market,
            ui_fee_receiver: params.order.ui_fee_receiver,
        }
    );

    let address_items: AddressItems = AddressItems {
        //
    }

    let uint_items: UintItems = UintItems {
        //
    }
    
    //add LogData
    event_utils::LogData{
        address_items,
        uint_items
    }

}


/// Validate the oracle block numbers used for the prices in the oracle.
/// # Arguments
/// * `min_oracle_block_numbers` - The min oracle block numbers.
/// * `max_oracle_block_numbers` - The max oracle block numbers.
/// * `order_type` - The order type.
/// * `order_updated_at_block` - the block at which the order was last updated.
#[inline(always)]
fn validate_oracle_block_numbers(
    min_oracle_block_numbers: Array<u64>,
    max_oracle_block_numbers: Array<u64>,
    order_type: OrderType,
    order_updated_at_block: u128
) {
    if (order_type == OrderType.MarketSwap) {
        oracle_utils::validate_block_number_within_range(min_oracle_block_numbers, max_oracle_block_numbers, order_updated_at_block);
        return
    }
    if (order_type == OrderType.LimitSwap) {
        if (!min_oracle_block_numbers.are_gte(order_updated_at_block)) {
            panic(array![OrderError::ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED]);
        }
        return
    }
    panic(array![OrderError::UNSUPPORTED_ORDER_TYPE]);
}
