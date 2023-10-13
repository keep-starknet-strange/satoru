// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::order::base_order_utils::ExecuteOrderParams;
use satoru::order::order::OrderType;
use satoru::oracle::oracle_utils;
use satoru::utils::arrays::u64_are_gte;
use satoru::swap::swap_utils;
use satoru::event::event_utils;
use satoru::order::error::OrderError;
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::utils::span32::{Span32, DefaultSpan32};
use satoru::oracle::error::OracleError;

#[inline(always)]
fn process_order(params: ExecuteOrderParams) -> event_utils::LogData {
    if (params.order.market.is_non_zero()) {
        panic(array![OrderError::UNEXPECTED_MARKET]);
    }

    validate_oracle_block_numbers(
        params.min_oracle_block_numbers.span(),
        params.max_oracle_block_numbers.span(),
        params.order.order_type,
        params.order.updated_at_block
    );

    let (output_token, output_amount) = swap_utils::swap(
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

    let mut address_items: event_utils::AddressItems = Default::default();
    let mut uint_items: event_utils::UintItems = Default::default();

    address_items =
        event_utils::set_item_address_items(address_items, 0, "output_token", output_token);

    uint_items = event_utils::set_item_uint_items(uint_items, 0, "output_amount", output_amount);

    event_utils::LogData {
        address_items,
        uint_items,
        int_items: Default::default(),
        bool_items: Default::default(),
        felt252_items: Default::default(),
        array_of_felt_items: Default::default(),
        string_items: Default::default(),
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
    min_oracle_block_numbers: Span<u64>,
    max_oracle_block_numbers: Span<u64>,
    order_type: OrderType,
    order_updated_at_block: u64
) {
    if (order_type == OrderType::MarketSwap) {
        oracle_utils::validate_block_number_within_range(
            min_oracle_block_numbers, max_oracle_block_numbers, order_updated_at_block
        );
        return;
    }
    if (order_type == OrderType::LimitSwap) {
        if (!u64_are_gte(min_oracle_block_numbers, order_updated_at_block)) {
            OracleError::ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED(
                min_oracle_block_numbers, order_updated_at_block
            );
        }
        return;
    }
    panic(array![OrderError::UNSUPPORTED_ORDER_TYPE]);
}
