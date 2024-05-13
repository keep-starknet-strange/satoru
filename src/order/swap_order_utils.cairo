// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, contract_address_const};

// Local imports.
use satoru::order::base_order_utils::ExecuteOrderParams;
use satoru::order::order::OrderType;
use satoru::oracle::oracle_utils;
use satoru::utils::arrays::are_gte_u64;
use satoru::swap::swap_utils;
use satoru::event::event_utils::{
    Felt252IntoContractAddress, ContractAddressDictValue, I256252DictValue, U256252DictValue,
    U256IntoFelt252
};
use satoru::utils::serializable_dict::{SerializableFelt252Dict, SerializableFelt252DictTrait};
use satoru::order::error::OrderError;
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::utils::span32::{Span32, DefaultSpan32};
use satoru::oracle::error::OracleError;
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// *************************************************************************
//                  Interface of the `OrderUtils` contract.
// *************************************************************************
#[starknet::interface]
trait ISwapOrderUtils<TContractState> {
    fn process_order(ref self: TContractState, params: ExecuteOrderParams);

    /// Validate the oracle block numbers used for the prices in the oracle.
    /// # Arguments
    /// * `min_oracle_block_numbers` - The min oracle block numbers.
    /// * `max_oracle_block_numbers` - The max oracle block numbers.
    /// * `order_type` - The order type.
    /// * `order_updated_at_block` - the block at which the order was last updated.
    fn validate_oracle_block_numbers(
        ref self: TContractState,
        min_oracle_block_numbers: Span<u64>,
        max_oracle_block_numbers: Span<u64>,
        order_type: OrderType,
        order_updated_at_block: u64
    );
}
#[starknet::contract]
mod SwapOrderUtils {
    // Core lib imports.
    use starknet::{ContractAddress, contract_address_const};

    use debug::PrintTrait;

    // Local imports.
    use satoru::order::base_order_utils::ExecuteOrderParams;
    use satoru::order::order::OrderType;
    use satoru::oracle::oracle_utils;
    use satoru::utils::arrays::are_gte_u64;
    use satoru::swap::swap_utils;
    use satoru::event::event_utils::{
        Felt252IntoContractAddress, ContractAddressDictValue, I256252DictValue, U256252DictValue,
        U256IntoFelt252
    };
    use satoru::utils::serializable_dict::{SerializableFelt252Dict, SerializableFelt252DictTrait};
    use satoru::order::error::OrderError;
    use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
    use satoru::utils::span32::{Span32, DefaultSpan32};
    use satoru::oracle::error::OracleError;
    use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    #[storage]
    struct Storage {}

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl SwapOrderUtilsImpl of super::ISwapOrderUtils<ContractState> {
        fn process_order(ref self: ContractState, params: ExecuteOrderParams) {
            if (params.order.market.is_non_zero()) {
                panic(array![OrderError::UNEXPECTED_MARKET]);
            }
            // validate_oracle_block_numbers(
            //     params.min_oracle_block_numbers.span(),
            //     params.max_oracle_block_numbers.span(),
            //     params.order.order_type,
            //     params.order.updated_at_block
            // );
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
                    receiver: params.order.receiver,
                    ui_fee_receiver: params.order.ui_fee_receiver,
                }
            );
        // let mut log_data: LogData = Default::default();

        // log_data.address_dict.insert_single('output_token', output_token);
        // log_data.uint_dict.insert_single('output_amount', output_amount);

        // log_data
        }


        /// Validate the oracle block numbers used for the prices in the oracle.
        /// # Arguments
        /// * `min_oracle_block_numbers` - The min oracle block numbers.
        /// * `max_oracle_block_numbers` - The max oracle block numbers.
        /// * `order_type` - The order type.
        /// * `order_updated_at_block` - the block at which the order was last updated.
        fn validate_oracle_block_numbers(
            ref self: ContractState,
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
                if (!are_gte_u64(min_oracle_block_numbers, order_updated_at_block)) {
                    OracleError::ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED(
                        min_oracle_block_numbers, order_updated_at_block
                    );
                }
                return;
            }
            panic(array![OrderError::UNSUPPORTED_ORDER_TYPE]);
        }
    }
}
