// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::order::{
    base_order_utils::ExecuteOrderParams, order::{Order, OrderType}, error::OrderError
};
use satoru::data::{data_store::IDataStoreDispatcherTrait, error::DataError};
use satoru::oracle::{oracle_utils, error::OracleError};
use satoru::market::market_utils;
use satoru::swap::swap_utils;
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::position::{position_utils, error::PositionError, increase_position_utils};
use satoru::event::event_utils;

// External imports.
use alexandria_data_structures::array_ext::SpanTraitExt;

/// Process an increase order.
/// # Arguments
/// * `params` - The execute order params.
/// # Returns
/// * `EventLogData` - The event log data.
/// This function should return an EventLogData cause the callback_utils
/// needs it. We need to find a solution for that case.
#[inline(always)]
fn process_order(params: ExecuteOrderParams) -> event_utils::EventLogData {
    market_utils::validate_position_market(params.contracts.data_store, params.market);

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

    market_utils::validate_market_collateral_token(params.market, collateral_token);

    let position_key = position_utils::get_position_key(
        params.order.account, params.order.market, collateral_token, params.order.is_long,
    );
    let mut position = params
        .contracts
        .data_store
        .get_position(position_key)
        .expect(DataError::POSITION_NOT_FOUND);

    // Initialize position
    if position.account.is_zero() {
        position.account = params.order.account;
        if !position.market.is_zero() || !position.collateral_token.is_zero() {
            panic_with_felt252(PositionError::UNEXPECTED_POSITION_STATE);
        }

        position.market = params.order.market;
        position.collateral_token = collateral_token;
        position.is_long = params.order.is_long;
    };

    validate_oracle_block_numbers(
        params.min_oracle_block_numbers.span(),
        params.max_oracle_block_numbers.span(),
        params.order.order_type,
        params.order.updated_at_block
    );

    increase_position_utils::increase_position(
        position_utils::UpdatePositionParams {
            contracts: params.contracts,
            market: params.market,
            order: params.order,
            order_key: params.key,
            position: position,
            position_key: position_key,
            secondary_order_type: params.secondary_order_type,
        },
        collateral_increment_amount
    );

    event_utils::EventLogData { cant_be_empty: 'todo' } // TODO switch to LogData
}

/// Validate the oracle block numbers used for the prices in the oracle.
/// # Arguments
/// * `min_oracle_block_numbers` - The min oracle block numbers.
/// * `max_oracle_block_numbers` - The max oracle block numbers.
/// * `order_type` - The order type.
/// * `order_updated_at_block` - The block at which the order was last updated.
fn validate_oracle_block_numbers(
    min_oracle_block_numbers: Span<u64>,
    max_oracle_block_numbers: Span<u64>,
    order_type: OrderType,
    order_updated_at_block: u64
) {
    if order_type == OrderType::MarketIncrease {
        oracle_utils::validate_block_number_within_range(
            min_oracle_block_numbers, max_oracle_block_numbers, order_updated_at_block
        );
        return;
    };

    if order_type == OrderType::LimitIncrease {
        // since the oracle blocks are only validated against the orderUpdatedAtBlock
        // it is possible to cause a limit increase order to become executable by
        // having the order have an initial collateral amount of zero then opening
        // a position and depositing collateral if the limit order is desired to be executed
        // for this case, when the limit order price is reached, the order should be frozen
        // the frozen order keepers should only execute frozen orders if the latest prices
        // fulfill the limit price
        let min_oracle_block_number = min_oracle_block_numbers
            .min()
            .expect(OracleError::EMPTY_ORACLE_BLOCK_NUMBERS);
        if min_oracle_block_number < order_updated_at_block {
            OracleError::ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED(
                min_oracle_block_numbers, order_updated_at_block
            );
        }
        return;
    }

    panic(array![OrderError::UNSUPPORTED_ORDER_TYPE]);
}
