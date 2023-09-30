// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::oracle::oracle_utils;
use satoru::position::decrease_position_utils::DecreasePositionResult;
use satoru::position::decrease_position_utils;
use satoru::order::{
    base_order_utils::ExecuteOrderParams, order::Order, order::OrderType, error::OrderError, order
};
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};

use satoru::utils::arrays;
use satoru::market::market_utils;
use satoru::position::position_utils;
use satoru::position::position::Position;
use satoru::swap::swap_utils::{SwapParams};
use satoru::position::position_utils::UpdatePositionParams;


// This function should return an EventLogData cause the callback_utils
// needs it. We need to find a solution for that case.
#[inline(always)]
fn process_order(params: ExecuteOrderParams) { //TODO check with refactor with callback_utils
    let order: Order = params.order;

    // market_utils::validate_position_market(params.contracts.data_store, params.market);

    let position_key: felt252 = position_utils::get_position_key(order.account, order.market, order.initial_collateral_token, order.is_long);

    let data_store: IDataStoreDispatcher = params.contracts.data_store;
    let position: Option<Position> = data_store.get_position(position_key);

    match position {
        Option::Some(data) => {
            ();
        },
        Option::None => {
            //panic;
        }
    }

    let positions: Position = position.unwrap(); //CHANGE UNWRAP TO EXPECT

    position_utils::validate_non_empty_position(positions);

    validate_oracle_block_numbers(params.min_oracle_block_numbers, params.max_oracle_block_numbers, order.order_type, order.updated_at_block, positions.increased_at_block, positions.decreased_at_block);

    let update_position_params: UpdatePositionParams = UpdatePositionParams {
        contracts: params.contracts,
        market: params.market,
        order: order,
        order_key: params.key,
        position: positions,
        position_key,
        secondary_order_type: params.secondary_order_type
    };

    let result: DecreasePositionResult = decrease_position_utils::decrease_position(update_position_params);

    if (result.secondary_output_amount > 0) {
        validate_output_amount_secondary(params.contracts.oracle,
        result.output_token, result.output_amount, result.secondary_output_token, result.secondary_output_amount, order.min_output_amount);

            // MarketToken(payable(order.market())).transferOut(
            //     result.outputToken,
            //     order.receiver(),
            //     result.outputAmount,
            //     order.shouldUnwrapNativeToken()
            // );

            // MarketToken(payable(order.market())).transferOut(
            //     result.secondaryOutputToken,
            //     order.receiver(),
            //     result.secondaryOutputAmount,
            //     order.shouldUnwrapNativeToken()
            // );    }

        return get_output_event_data(result.output_token, result.output_amount, result.secondary_output_token, result.secondary_output_amount);
    }

    let swap_param: SwapParams = SwapParams {
        data_store: params.contracts.data_store,
        event_emitter: params.contracts.event_emitter,
        oracle: params.contracts.oracle,
        bank: IBankDispatcher { contract_address: order.market },
                        // Bank(payable(order.market())),
        key: params.key,
        token_in: result.output_token,
        amount_in: result.output_amount,
        swap_path_markets: params.swap_path_markets,
        receiver: order.receiver,
        ui_fee_receiver: order.ui_fee_receiver,
    };

    params.contracts.swap_handler.swap(swap_param);

    let (token_out, swap_output_amount) = validate_output_amount(params.contracts.oracle, token_out);

    validate_output_amount(params.contracts.oracle, token_out, swap_out_amount, order.min_output_amount);

    return get_output_event_data(token_out, swap_out_amount, try_into().unwrap(), 0);
    
    //NEED TO ADD THE CATCH!

}


/// Validate the oracle block numbers used for the prices in the oracle.
/// # Arguments
/// * `min_oracle_block_numbers` - The min oracle block numbers.
/// * `max_oracle_block_numbers` - The max oracle block numbers.
/// * `order_type` - The order type.
/// * `order_updated_at_block` - The block at which the order was last updated.
/// * `position_increased_at_block` - The block at which the position was last increased.
/// * `position_decrease_at_block` - The block at which the position was last decreased.
#[inline(always)]
fn validate_oracle_block_numbers(
    min_oracle_block_numbers: Array<u64>,
    max_oracle_block_numbers: Array<u64>,
    order_type: OrderType,
    order_updated_at_block: u64,
    position_increased_at_block: u64,
    position_decreased_at_block: u64
) {
    if order_type == OrderType::MarketDecrease {
        oracle_utils::validate_block_number_within_range(
            min_oracle_block_numbers, max_oracle_block_numbers, order_updated_at_block
        );
        return;
    }

    if (order_type == OrderType::LimitDecrease || order_type == OrderType::StopLossDecrease) {
        let mut latest_updated_at_block: u64 = position_increased_at_block;
        if (order_updated_at_block > position_increased_at_block) {
            latest_updated_at_block = order_updated_at_block
        }
        if (!arrays::u64_are_gte(min_oracle_block_numbers, latest_updated_at_block)) {
            OrderError::ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED(
                min_oracle_block_numbers, latest_updated_at_block
            );
        }
        return;
    }
    if (order_type == OrderType::Liquidation) {
        let mut latest_updated_at_block: u64 = position_decreased_at_block;
        if (position_increased_at_block > position_decreased_at_block) {
            latest_updated_at_block = position_increased_at_block
        }
        if (!arrays::u64_are_gte(min_oracle_block_numbers, latest_updated_at_block)) {
            OrderError::ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED(
                min_oracle_block_numbers, latest_updated_at_block
            );
        }
        return;
    }
    OrderError::UNSUPPORTED_ORDER_TYPE;
    return;
}

// Note: that min_output_amount is treated as a USD value for this validation
fn validate_output_amount(
    oracle: IOracleDispatcher,
    output_token: ContractAddress,
    output_amount: u128,
    min_output_amount: u128
) {
    let output_token_price: u128 = oracle.get_primary_price(output_token).min;
    let output_usd: u128 = output_amount * output_token_price;

    if (output_usd < min_output_amount) {
        OrderError::INSUFFICIENT_OUTPUT_AMOUNT(output_usd, output_token_price);
    }
}

// Note: that min_output_amount is treated as a USD value for this validation
fn validate_output_amount_secondary(
    oracle: IOracleDispatcher,
    output_token: ContractAddress,
    output_amount: u128,
    secondary_output_token: ContractAddress,
    secondary_output_amount: u128,
    min_output_amount: u128
) {
    let output_token_price: u128 = oracle.get_primary_price(output_token).min;
    let output_usd: u128 = output_amount * output_token_price;

    let secondary_output_token_price: u128 = oracle.get_primary_price(secondary_output_token).min;
    let seconday_output_usd: u128 = secondary_output_amount * secondary_output_token_price;

    let total_output_usd: u128 = output_usd + seconday_output_usd;

    if (total_output_usd < min_output_amount) {
        OrderError::INSUFFICIENT_OUTPUT_AMOUNT(output_usd, output_token_price);
    }
}

#[inline(always)]
fn handle_swap_error(
    oracle: IOracleDispatcher,
    order: Order,
    result: DecreasePositionResult,
    reason: felt252,
    reason_bytes: Span<felt252>,
    event_emitter: IEventEmitterDispatcher
) {
    event_emitter.emit_swap_reverted(reason, reason_bytes);

    validate_output_amount(
        oracle, result.output_token, result.output_amount, order.min_output_amount
    );
//TODO Call this when its implemented
//Need to call transfer_out function when its implemented
}

// This function should return an EventLogData cause the callback_utils
// needs it. We need to find a solution for that case.
fn get_output_event_data(
    output_token: ContractAddress,
    output_amount: u128,
    secondary_output_token: ContractAddress,
    secondary_output_amount: u128
) { //TODO check with refactor with callback_utils
    //ASK BORA
}
