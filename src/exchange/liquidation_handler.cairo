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
    use satoru::exchange::base_order_handler::BaseOrderHandler::{
        event_emitter::InternalContractMemberStateTrait, data_store::InternalContractMemberStateImpl
    };
    use starknet::{ContractAddress, get_caller_address, get_contract_address};


    // Local imports.
    use super::ILiquidationHandler;
    use satoru::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
    use satoru::data::{
        data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait, DataStore},
        keys::execute_order_feature_disabled_key
    };
    use satoru::oracle::{
        oracle::{IOracleDispatcher, IOracleDispatcherTrait},
        oracle_modules::{with_oracle_prices_before, with_oracle_prices_after},
        oracle_utils::SetPricesParams
    };
    use satoru::order::{
        order_utils, order::{SecondaryOrderType, OrderType, Order},
        order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait},
        base_order_utils::{ExecuteOrderParams, ExecuteOrderParamsContracts}
    };
    use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
    use satoru::market::market::Market;
    use satoru::exchange::base_order_handler::{IBaseOrderHandler, BaseOrderHandler};
    use satoru::liquidation::liquidation_utils::create_liquidation_order;
    use satoru::exchange::order_handler;
    use debug::PrintTrait;
    use satoru::feature::feature_utils::validate_feature;
    use satoru::exchange::order_handler::{IOrderHandler, OrderHandler};
    use satoru::utils::starknet_utils;

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
    impl LiquidationHandlerImpl of super::ILiquidationHandler<
        ContractState
    > { // executes a position liquidation
        fn execute_liquidation(
            ref self: ContractState,
            account: ContractAddress,
            market: ContractAddress,
            collateral_token: ContractAddress,
            is_long: bool,
            oracle_params: SetPricesParams
        ) {
            let starting_gas: u128 = starknet_utils::sn_gasleft(array![100]);
            let mut state_base: BaseOrderHandler::ContractState =
                BaseOrderHandler::unsafe_new_contract_state(); //retrieve BaseOrderHandler state
            let key: felt252 = create_liquidation_order(
                state_base.data_store.read(),
                state_base.event_emitter.read(),
                account,
                market,
                collateral_token,
                is_long
            );
            let tmp_oracle_params: SetPricesParams = oracle_params.clone();
            let params: ExecuteOrderParams =
                BaseOrderHandler::InternalImpl::get_execute_order_params(
                ref state_base,
                key,
                tmp_oracle_params,
                get_caller_address(),
                starting_gas,
                SecondaryOrderType::None
            );
            validate_feature(
                params.contracts.data_store,
                execute_order_feature_disabled_key(get_contract_address(), params.order.order_type)
            );
            order_utils::execute_order(params);
        }
    }
}
