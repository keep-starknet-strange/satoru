//! Contract to handle adl.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

// Local imports.
use gojo::oracle::oracle_utils::SetPricesParams;

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
        market: ContractAddress,
        is_long: bool,
        oracle_params: SetPricesParams
    );
}

#[starknet::contract]
mod AdlHandler {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::ContractAddress;
    use array::ArrayTrait;

    // Local imports.
    use super::IAdlHandler;
    use gojo::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
    use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
    use gojo::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
    use gojo::oracle::{
        oracle::{IOracleSafeDispatcher, IOracleSafeDispatcherTrait},
        oracle_modules::{with_oracle_prices_before, with_oracle_prices_after},
        oracle_utils::SetPricesParams
    };
    use gojo::order::{
        order::{SecondaryOrderType, OrderType, Order},
        order_vault::{IOrderVaultSafeDispatcher, IOrderVaultSafeDispatcherTrait},
        base_order_utils::{ExecuteOrderParams, ExecuteOrderParamsContracts}
    };
    use gojo::swap::swap_handler::{ISwapHandlerSafeDispatcher, ISwapHandlerSafeDispatcherTrait};
    use gojo::market::market::Market;
    use gojo::exchange::base_order_handler::{IBaseOrderHandler, BaseOrderHandler};
    use gojo::utils::store_arrays::StoreU64Array;

    /// ExecuteAdlCache struct used in execute_adl.
    #[derive(Drop, starknet::Store, Serde)]
    struct ExecuteAdlCache {
        /// The starting gas to execute adl.
        starting_gas: u128,
        /// The min oracles block numbers.
        min_oracle_block_numbers: Array<u64>,
        /// The max oracles block numbers.
        max_oracle_block_numbers: Array<u64>,
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
    struct Storage {}

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
        swap_handler_address: ContractAddress
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
            swap_handler_address
        );
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
        ) { // TODO
        }

        fn execute_adl(
            ref self: ContractState,
            market: ContractAddress,
            is_long: bool,
            oracle_params: SetPricesParams
        ) { // TODO
        }
    }
}
