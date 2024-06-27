// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, contract_address_const};

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
use satoru::event::event_utils::{
    Felt252IntoContractAddress, ContractAddressDictValue, I256252DictValue, U256252DictValue,
    U256IntoFelt252
};
use satoru::utils::serializable_dict::{SerializableFelt252Dict, SerializableFelt252DictTrait};
use satoru::market::market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait};
use satoru::utils::span32::{Span32, Array32Trait};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};

// *************************************************************************
//                  Interface of the `OrderUtils` contract.
// *************************************************************************
#[starknet::interface]
trait IDecreaseOrderUtils<TContractState> {
    // This function should return an EventLogData cause the callback_utils
    // needs it. We need to find a solution for that case.
    fn process_order(ref self: TContractState, params: ExecuteOrderParams);

    /// Validate the oracle block numbers used for the prices in the oracle.
    /// # Arguments
    /// * `min_oracle_block_numbers` - The min oracle block numbers.
    /// * `max_oracle_block_numbers` - The max oracle block numbers.
    /// * `order_type` - The order type.
    /// * `order_updated_at_block` - The block at which the order was last updated.
    /// * `position_increased_at_block` - The block at which the position was last increased.
    /// * `position_decrease_at_block` - The block at which the position was last decreased.
    fn validate_oracle_block_numbers(
        ref self: TContractState,
        min_oracle_block_numbers: Span<u64>,
        max_oracle_block_numbers: Span<u64>,
        order_type: OrderType,
        order_updated_at_block: u64,
        position_increased_at_block: u64,
        position_decreased_at_block: u64
    );

    fn validate_output_amount(
        ref self: TContractState,
        oracle: IOracleDispatcher,
        output_token: ContractAddress,
        output_amount: u256,
        min_output_amount: u256
    );

    // Note: that min_output_amount is treated as a USD value for this validation
    fn validate_output_amount_secondary(
        ref self: TContractState,
        oracle: IOracleDispatcher,
        output_token: ContractAddress,
        output_amount: u256,
        secondary_output_token: ContractAddress,
        secondary_output_amount: u256,
        min_output_amount: u256
    );

    fn handle_swap_error(
        ref self: TContractState,
        oracle: IOracleDispatcher,
        order: Order,
        result: DecreasePositionResult,
        reason: felt252,
        reason_bytes: Span<felt252>,
        event_emitter: IEventEmitterDispatcher
    );
}

#[starknet::contract]
mod DecreaseOrderUtils {
    // Core lib imports.
    use starknet::{ContractAddress, contract_address_const};

    // Local imports.
    use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
    use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use satoru::oracle::oracle_utils;
    use satoru::position::decrease_position_utils::DecreasePositionResult;
    use satoru::position::decrease_position_utils;
    use satoru::order::{
        base_order_utils::ExecuteOrderParams, order::Order, order::OrderType, error::OrderError,
        order
    };
    use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};

    use satoru::utils::arrays;
    use satoru::market::market_utils;
    use satoru::position::position_utils;
    use satoru::position::position::Position;
    use satoru::swap::swap_utils::{SwapParams};
    use satoru::position::position_utils::UpdatePositionParams;
    use satoru::event::event_utils::{
        Felt252IntoContractAddress, ContractAddressDictValue, I256252DictValue, U256252DictValue,
        U256IntoFelt252
    };
    use satoru::utils::serializable_dict::{SerializableFelt252Dict, SerializableFelt252DictTrait};
    use satoru::market::market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait};
    use satoru::utils::span32::{Span32, Array32Trait};
    use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};

    #[storage]
    struct Storage {}

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl DecreaseOrderUtilsImpl of super::IDecreaseOrderUtils<ContractState> {
        // This function should return an EventLogData cause the callback_utils
        // needs it. We need to find a solution for that case.
        fn process_order(
            ref self: ContractState, params: ExecuteOrderParams
        ) { //TODO check with refactor with callback_utils
            let order: Order = params.order;

            market_utils::validate_position_market_check(
                params.contracts.data_store, params.market
            );

            let position_key: felt252 = position_utils::get_position_key(
                order.account, order.market, order.initial_collateral_token, order.is_long
            );

            let data_store: IDataStoreDispatcher = params.contracts.data_store;
            let position = data_store.get_position(position_key);
            position_utils::validate_non_empty_position(position);

            // validate_oracle_block_numbers(
            //     params.min_oracle_block_numbers.span(),
            //     params.max_oracle_block_numbers.span(),
            //     order.order_type,
            //     order.updated_at_block,
            //     position.increased_at_block,
            //     position.decreased_at_block
            // );
            let mut update_position_params: UpdatePositionParams = UpdatePositionParams {
                contracts: params.contracts,
                market: params.market,
                order: order,
                order_key: params.key,
                position: position,
                position_key,
                secondary_order_type: params.secondary_order_type
            };
            let mut result: DecreasePositionResult = decrease_position_utils::decrease_position(
                update_position_params
            );
            // if the pnl_token and the collateral_token are different
            // and if a swap fails or no swap was requested
            // then it is possible to receive two separate tokens from decreasing
            // the position
            // transfer the two tokens to the user in this case and skip processing
            // the swap_path
            if (result.secondary_output_amount > 0) {
                self
                    .validate_output_amount_secondary(
                        params.contracts.oracle,
                        result.output_token,
                        result.output_amount,
                        result.secondary_output_token,
                        result.secondary_output_amount,
                        order.min_output_amount
                    );
                IMarketTokenDispatcher { contract_address: order.market }
                    .transfer_out(
                        order.market, result.output_token, order.receiver, result.output_amount
                    );

                IMarketTokenDispatcher { contract_address: order.market }
                    .transfer_out(
                        order.market,
                        result.secondary_output_token,
                        order.receiver,
                        result.secondary_output_amount
                    );
            // return get_output_event_data(
            //     result.output_token,
            //     result.output_amount,
            //     result.secondary_output_token,
            //     result.secondary_output_amount
            // );
            }

            let swap_param: SwapParams = SwapParams {
                data_store: params.contracts.data_store,
                event_emitter: params.contracts.event_emitter,
                oracle: params.contracts.oracle,
                bank: IBankDispatcher { contract_address: order.market },
                key: params.key,
                token_in: result.output_token,
                amount_in: result.output_amount,
                swap_path_markets: params.swap_path_markets.span(),
                min_output_amount: 0,
                receiver: order.receiver,
                ui_fee_receiver: order.ui_fee_receiver,
            };

            //TODO handle the swap_error when its possible
            let (token_out, swap_output_amount) = params.contracts.swap_handler.swap(swap_param);

            self
                .validate_output_amount(
                    params.contracts.oracle, token_out, swap_output_amount, order.min_output_amount
                );
        // return get_output_event_data(token_out, swap_output_amount, contract_address_const::<0>(), 0);
        }


        /// Validate the oracle block numbers used for the prices in the oracle.
        /// # Arguments
        /// * `min_oracle_block_numbers` - The min oracle block numbers.
        /// * `max_oracle_block_numbers` - The max oracle block numbers.
        /// * `order_type` - The order type.
        /// * `order_updated_at_block` - The block at which the order was last updated.
        /// * `position_increased_at_block` - The block at which the position was last increased.
        /// * `position_decrease_at_block` - The block at which the position was last decreased.
        fn validate_oracle_block_numbers(
            ref self: ContractState,
            min_oracle_block_numbers: Span<u64>,
            max_oracle_block_numbers: Span<u64>,
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

            if (order_type == OrderType::LimitDecrease
                || order_type == OrderType::StopLossDecrease) {
                let mut latest_updated_at_block: u64 = position_increased_at_block;
                if (order_updated_at_block > position_increased_at_block) {
                    latest_updated_at_block = order_updated_at_block
                }
                if (!arrays::are_gte_u64(min_oracle_block_numbers, latest_updated_at_block)) {
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
                if (!arrays::are_gte_u64(min_oracle_block_numbers, latest_updated_at_block)) {
                    OrderError::ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED(
                        min_oracle_block_numbers, latest_updated_at_block
                    );
                }
                return;
            }
            panic_with_felt252(OrderError::UNSUPPORTED_ORDER_TYPE);
        }

        // Note: that min_output_amount is treated as a USD value for this validation
        fn validate_output_amount(
            ref self: ContractState,
            oracle: IOracleDispatcher,
            output_token: ContractAddress,
            output_amount: u256,
            min_output_amount: u256
        ) {
            let output_token_price: u256 = oracle.get_primary_price(output_token).min;
            let output_usd: u256 = output_amount * output_token_price;

            if (output_usd < min_output_amount) {
                OrderError::INSUFFICIENT_OUTPUT_AMOUNT(output_usd, output_token_price);
            }
        }

        // Note: that min_output_amount is treated as a USD value for this validation
        fn validate_output_amount_secondary(
            ref self: ContractState,
            oracle: IOracleDispatcher,
            output_token: ContractAddress,
            output_amount: u256,
            secondary_output_token: ContractAddress,
            secondary_output_amount: u256,
            min_output_amount: u256
        ) {
            let output_token_price: u256 = oracle.get_primary_price(output_token).min;
            let output_usd: u256 = output_amount * output_token_price;

            let secondary_output_token_price: u256 = oracle
                .get_primary_price(secondary_output_token)
                .min;
            let seconday_output_usd: u256 = secondary_output_amount * secondary_output_token_price;

            let total_output_usd: u256 = output_usd + seconday_output_usd;

            if (total_output_usd < min_output_amount) {
                OrderError::INSUFFICIENT_OUTPUT_AMOUNT(output_usd, output_token_price);
            }
        }

        fn handle_swap_error(
            ref self: ContractState,
            oracle: IOracleDispatcher,
            order: Order,
            result: DecreasePositionResult,
            reason: felt252,
            reason_bytes: Span<felt252>,
            event_emitter: IEventEmitterDispatcher
        ) {
            event_emitter.emit_swap_reverted(reason, reason_bytes);

            self
                .validate_output_amount(
                    oracle, result.output_token, result.output_amount, order.min_output_amount
                );

            IMarketTokenDispatcher { contract_address: order.market }
                .transfer_out(
                    order.market, result.output_token, order.receiver, result.output_amount
                );
        }
    // This function should return an EventLogData cause the callback_utils
    // needs it. We need to find a solution for that case.
    // fn get_output_event_data(
    //     output_token: ContractAddress,
    //     output_amount: u256,
    //     secondary_output_token: ContractAddress,
    //     secondary_output_amount: u256
    // ) { //-> LogData {
    //     let mut log_data: LogData = Default::default();

    //     log_data.address_dict.insert_single('output_token', output_token);
    //     log_data.address_dict.insert_single('secondary_output_token', secondary_output_token);

    //     log_data.uint_dict.insert_single('output_amount', output_amount);
    //     log_data.uint_dict.insert_single('secondary_output_amount', secondary_output_amount);

    //     //log_data
    // }
    }
}
