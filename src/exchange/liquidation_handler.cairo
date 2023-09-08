//! Contract to handle liquidation.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

// Local imports.
use satoru::oracle::oracle_utils::SetPricesParams;

// *************************************************************************
//                  Interface of the `LiquidationHandler` contract.
// *************************************************************************
#[starknet::interface]
trait ILiquidationHandler<TContractState> {
    /// Executes a position liquidation.
    /// # Arguments
    /// * `account` - The account of the position to liquidate.
    /// * `market` - The position's market.
    /// * `collateral_token` - The position's collateralToken.
    /// * `is_long` - Whether the position is long or short.
    /// * `oracle_params` - The oracle params to set prices before execution.
    fn execute_liquidation(
        ref self: TContractState,
        account: ContractAddress,
        market: ContractAddress,
        collateral_token: ContractAddress,
        is_long: bool,
        oracle_params: SetPricesParams
    );
}

#[starknet::contract]
mod LiquidationHandler {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::ContractAddress;


    // Local imports.
    use super::ILiquidationHandler;
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use satoru::oracle::{
        oracle::{IOracleDispatcher, IOracleDispatcherTrait},
        oracle_modules::{with_oracle_prices_before, with_oracle_prices_after},
        oracle_utils::SetPricesParams
    };
    use satoru::order::{
        order::{SecondaryOrderType, OrderType, Order},
        order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait},
        base_order_utils::{ExecuteOrderParams, ExecuteOrderParamsContracts}
    };
    use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
    use satoru::market::market::Market;
    use satoru::exchange::base_order_handler::{IBaseOrderHandler, BaseOrderHandler};

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
        swap_handler_address: ContractAddress,
        referral_storage_address: ContractAddress
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
    }


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl LiquidationHandlerImpl of super::ILiquidationHandler<ContractState> {
        fn execute_liquidation(
            ref self: ContractState,
            account: ContractAddress,
            market: ContractAddress,
            collateral_token: ContractAddress,
            is_long: bool,
            oracle_params: SetPricesParams
        ) { // TODO
        }
    }
}
