//! Contract to handle adl.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

// Local imports.
use satoru::oracle::oracle_utils::SetPricesParams;

// *************************************************************************
//                  Interface of the `AdlHandler` contract.
// *************************************************************************
#[starknet::interface]
trait IAdlHandler<TContractState> {
    /// Checks the ADL state to update the isAdlEnabled flag.
    /// # Arguments
    /// * `market` - The market to check.
    /// * `is_long` - Wether to check long or short side.
    /// * `oracle_params` - The oracle set price parameters used to set price
    /// before performing checks
    fn update_adl_state(
        ref self: TContractState,
        market: ContractAddress,
        is_long: bool,
        oracle_params: SetPricesParams
    );

    /// Auto-deleverages a position.
    /// There is no validation that ADL is executed in order of position profit
    /// or position size, this is due to the limitation of the gas overhead
    /// required to check this ordering.
    ///
    /// ADL keepers could be separately incentivised using a rebate based on
    /// position profit, this is not implemented within the contracts at the moment.
    /// # Arguments
    /// * `market` - The market to check.
    /// * `is_long` - Wether to check long or short side.
    /// * `oracle_params` - The oracle set price parameters used to set price
    /// before performing adl.
    fn execute_adl(
        ref self: TContractState,
        account: ContractAddress,
        market_address: ContractAddress,
        collateral_token: ContractAddress,
        is_long: bool,
        size_delta_usd: u128,
        oracle_params: SetPricesParams
    );
}

#[starknet::contract]
mod AdlHandler {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::{ContractAddress, get_caller_address, get_contract_address};


    // Local imports.
    use super::IAdlHandler;
    use satoru::adl::adl_utils;
    use satoru::exchange::base_order_handler::{
        IBaseOrderHandlerSafeDispatcher, IBaseOrderHandlerSafeDispatcherTrait
    };
    use satoru::oracle::oracle_utils;
    use satoru::chain::chain::{IChainSafeDispatcher, IChainSafeDispatcherTrait};
    use satoru::data::{keys, data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait}};
    use satoru::event::event_emitter::{
        IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait
    };
    use satoru::exchange::base_order_handler::{IBaseOrderHandler, BaseOrderHandler};
    use satoru::feature::feature_utils;
    use satoru::market::{market::Market, market_utils};

    use satoru::oracle::{
        oracle::{IOracleSafeDispatcher, IOracleSafeDispatcherTrait},
        oracle_modules::{with_oracle_prices_before, with_oracle_prices_after},
        oracle_utils::{SetPricesParams, get_uncompacted_oracle_block_numbers}
    };
    use satoru::order::{
        order::{SecondaryOrderType, OrderType, Order},
        order_vault::{IOrderVaultSafeDispatcher, IOrderVaultSafeDispatcherTrait},
        base_order_utils::{ExecuteOrderParams, ExecuteOrderParamsContracts}, order_utils
    };
    use satoru::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
    use satoru::swap::swap_handler::{ISwapHandlerSafeDispatcher, ISwapHandlerSafeDispatcherTrait};
    use satoru::utils::store_arrays::StoreU64Array;

    /// ExecuteAdlCache struct used in execute_adl.
    #[derive(Drop, Serde)]
    struct ExecuteAdlCache {
        /// The starting gas to execute adl.
        starting_gas: u128,
        /// The min oracles block numbers.
        min_oracle_block_numbers: Array<u128>,
        /// The max oracles block numbers.
        max_oracle_block_numbers: Array<u128>,
        /// The key of the adl to execute.
        key: felt252,
        /// Wether adl should be allowed, depending on pnl state.
        should_allow_adl: bool,
        /// The maximum pnl factor to allow adl.
        max_pnl_factor_for_adl: u128,
        /// The factor between pnl and pool.
        pnl_to_pool_factor: u128, // TODO i128 when it derive Store
        /// The new factor between pnl and pool.
        next_pnl_to_pool_factor: u128, // TODO i128 when it derive Store
        /// The minimal pnl factor for adl.
        min_pnl_factor_for_adl: u128
    }

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        data_store: IDataStoreSafeDispatcher,
        event_emitter: IEventEmitterSafeDispatcher,
        oracle: IOracleSafeDispatcher,
        chain: IChainSafeDispatcher,
        base_order_handler: IBaseOrderHandlerSafeDispatcher
    }


    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************

    /// Constructor of the contract.
    /// # Arguments
    /// * `data_store_address` - The address of the `DataStore` contract.
    /// * `role_store_address` - The address of the `RoleStore` contract.
    /// * `event_emitter_address` - The address of the EventEmitter contract.
    /// * `order_vault_address` - The address of the `OrderVault` contract.
    /// * `oracle_address` - The address of the `Oracle` contract.
    /// * `swap_handler_address` - The address of the `SwapHandler` contract.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        data_store_address: ContractAddress,
        role_store_address: ContractAddress,
        event_emitter_address: ContractAddress,
        order_vault_address: ContractAddress,
        oracle_address: ContractAddress,
        swap_handler_address: ContractAddress,
        referral_storage_address: ContractAddress,
        chain_address: ContractAddress,
        order_handler_address: ContractAddress
    ) {
        let mut state: BaseOrderHandler::ContractState =
            BaseOrderHandler::unsafe_new_contract_state();
        IBaseOrderHandler::initialize(
            ref state,
            data_store_address,
            role_store_address,
            event_emitter_address,
            order_vault_address,
            oracle_address,
            swap_handler_address,
            referral_storage_address
        );
        self.data_store.write(IDataStoreSafeDispatcher { contract_address: data_store_address });
        self
            .event_emitter
            .write(IEventEmitterSafeDispatcher { contract_address: event_emitter_address });
        self.oracle.write(IOracleSafeDispatcher { contract_address: oracle_address });
        self.chain.write(IChainSafeDispatcher { contract_address: chain_address });
        self
            .base_order_handler
            .write(IBaseOrderHandlerSafeDispatcher { contract_address: order_handler_address });
    }

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl AdlHandlerImpl of super::IAdlHandler<ContractState> {
        fn update_adl_state(
            ref self: ContractState,
            market: ContractAddress,
            is_long: bool,
            oracle_params: SetPricesParams
        ) {
            let max_oracle_block_numbers = get_uncompacted_oracle_block_numbers(
                @oracle_params.compacted_max_oracle_block_numbers, oracle_params.tokens.len()
            );
            adl_utils::update_adl_state(
                self.data_store.read(),
                self.event_emitter.read(),
                self.oracle.read(),
                market,
                is_long,
                max_oracle_block_numbers.span(),
                self.chain.read()
            );
        }

        fn execute_adl(
            ref self: ContractState,
            account: ContractAddress,
            market_address: ContractAddress,
            collateral_token: ContractAddress,
            is_long: bool,
            size_delta_usd: u128,
            oracle_params: SetPricesParams
        ) {
            let mut cache = ExecuteAdlCache {
                starting_gas: 0,
                min_oracle_block_numbers: array![],
                max_oracle_block_numbers: array![],
                key: 0,
                should_allow_adl: false,
                max_pnl_factor_for_adl: 0,
                pnl_to_pool_factor: 0,
                next_pnl_to_pool_factor: 0,
                min_pnl_factor_for_adl: 0
            };

            cache
                .min_oracle_block_numbers =
                    oracle_utils::get_uncompacted_oracle_block_numbers(
                        @oracle_params.compacted_min_oracle_block_numbers,
                        oracle_params.tokens.len()
                    );

            cache
                .max_oracle_block_numbers =
                    oracle_utils::get_uncompacted_oracle_block_numbers(
                        @oracle_params.compacted_min_oracle_block_numbers,
                        oracle_params.tokens.len()
                    );

            adl_utils::validate_adl(
                self.data_store.read(),
                market_address,
                is_long,
                cache.max_oracle_block_numbers.span()
            );

            let (should_allow_adl, pnl_to_pool_factor, max_pnl_factor_for_adl) =
                market_utils::is_pnl_factor_exceeded(
                self.data_store.read(),
                self.oracle.read(),
                market_address,
                is_long,
                keys::max_pnl_factor_for_adl()
            );
            cache.should_allow_adl = should_allow_adl;
            cache.pnl_to_pool_factor = pnl_to_pool_factor;
            cache.max_pnl_factor_for_adl = max_pnl_factor_for_adl;

            assert(cache.should_allow_adl, 'adl not required');

            cache
                .key =
                    adl_utils::create_adl_order(
                        adl_utils::CreateAdlOrderParams {
                            data_store: self.data_store.read(),
                            event_emitter: self.event_emitter.read(),
                            account,
                            market: market_address,
                            collateral_token,
                            is_long,
                            size_delta_usd,
                            updated_at_block: (*cache.min_oracle_block_numbers.at(0))
                                .try_into()
                                .unwrap()
                        }
                    );

            let params: ExecuteOrderParams = self
                .base_order_handler
                .read()
                .get_execute_order_params(
                    cache.key,
                    oracle_params,
                    get_caller_address(),
                    cache.starting_gas,
                    SecondaryOrderType::Adl(())
                )
                .unwrap();

            // let order_type: felt252 = params.order.order_type.into();
            feature_utils::validate_feature(
                params.contracts.data_store,
                keys::execute_adl_feature_disabled_key(
                    get_contract_address(), params.order.order_type.into()
                )
            );

            order_utils::execute_order(params);

            // validate that the ratio of pending pnl to pool value was decreased
            cache
                .next_pnl_to_pool_factor =
                    market_utils::get_pnl_to_pool_factor(
                        self.data_store.read(), self.oracle.read(), market_address, is_long, true
                    );
            assert(cache.next_pnl_to_pool_factor >= cache.pnl_to_pool_factor, 'invalid adl');

            cache
                .min_pnl_factor_for_adl =
                    market_utils::get_min_pnl_factor_after_adl(
                        self.data_store.read(), market_address, is_long
                    );
            assert(
                cache.next_pnl_to_pool_factor > cache.min_pnl_factor_for_adl, 'pnl overcorrected'
            );
        }
    }
}
