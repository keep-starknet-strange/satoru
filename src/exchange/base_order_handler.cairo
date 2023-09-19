//! Base contract for shared order handler functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

use satoru::oracle::oracle_utils::SetPricesParams;
use satoru::order::{order::SecondaryOrderType, base_order_utils::ExecuteOrderParams};

// *************************************************************************
//                  Interface of the `BaseOrderHandler` contract.
// *************************************************************************
#[starknet::interface]
trait IBaseOrderHandler<TContractState> {
    /// Initialize the contract.
    /// # Arguments
    /// * `data_store_address` - The address of the `DataStore` contract.
    /// * `role_store_address` - The address of the `RoleStore` contract.
    /// * `event_emitter_address` - The address of the `EventEmitter` contract.
    /// * `order_vault_address` - The address of the `OrderVault` contract.
    /// * `swap_handler_address` - The address of the `SwapHandler` contract.
    /// * `oracle_address` - The address of the `Oracle` contract.
    /// * `referral_storage_address` - The address of the `ReferralStorage` contract.
    fn initialize(
        ref self: TContractState,
        data_store_address: ContractAddress,
        role_store_address: ContractAddress,
        event_emitter_address: ContractAddress,
        order_vault_address: ContractAddress,
        oracle_address: ContractAddress,
        swap_handler_address: ContractAddress,
        referral_storage_address: ContractAddress
    );
}

#[starknet::contract]
mod BaseOrderHandler {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;
    use core::traits::Into;
    use starknet::{get_caller_address, ContractAddress, contract_address_const};

    use debug::PrintTrait;
    use result::ResultTrait;

    // Local imports.
    use super::IBaseOrderHandler;
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use satoru::oracle::{
        oracle::{IOracleDispatcher, IOracleDispatcherTrait},
        oracle_modules::{with_oracle_prices_before, with_oracle_prices_after},
        oracle_utils::{SetPricesParams, get_uncompacted_oracle_block_numbers},
    };
    use satoru::order::{
        order::{SecondaryOrderType, OrderType, Order, DecreasePositionSwapType},
        order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait},
        base_order_utils::{ExecuteOrderParams, ExecuteOrderParamsContracts}, order_store_utils,
    };
    use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
    use satoru::exchange::error::ExchangeError;
    use satoru::market::{market::Market, market_utils};
    use satoru::referral::referral_storage::interface::{
        IReferralStorageDispatcher, IReferralStorageDispatcherTrait
    };
    use satoru::utils::span32::Array32Trait;

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Interface to interact with the `DataStore` contract.
        data_store: IDataStoreDispatcher,
        /// Interface to interact with the `RoleStore` contract.
        role_store: IRoleStoreDispatcher,
        /// Interface to interact with the `EventEmitter` contract.
        event_emitter: IEventEmitterDispatcher,
        /// Interface to interact with the `OrderVault` contract.
        order_vault: IOrderVaultDispatcher,
        /// Interface to interact with the `SwapHandler` contract.
        swap_handler: ISwapHandlerDispatcher,
        /// Interface to interact with the `Oracle` contract.
        oracle: IOracleDispatcher,
        /// Interface to interact with the `ReferralStorage` contract.
        referral_storage: IReferralStorageDispatcher
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
    /// * `referral_storage_address` - The address of the `ReferralStorage` contract.
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
        self
            .initialize(
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
    impl BaseOrderHandlerImpl of super::IBaseOrderHandler<ContractState> {
        fn initialize(
            ref self: ContractState,
            data_store_address: ContractAddress,
            role_store_address: ContractAddress,
            event_emitter_address: ContractAddress,
            order_vault_address: ContractAddress,
            oracle_address: ContractAddress,
            swap_handler_address: ContractAddress,
            referral_storage_address: ContractAddress
        ) {
            // Make sure the contract is not already initialized.
            assert(
                self.data_store.read().contract_address.is_zero(),
                ExchangeError::ALREADY_INITIALIZED
            );
            self.data_store.write(IDataStoreDispatcher { contract_address: data_store_address });
            self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
            self
                .event_emitter
                .write(IEventEmitterDispatcher { contract_address: event_emitter_address });
            self.order_vault.write(IOrderVaultDispatcher { contract_address: order_vault_address });
            self.oracle.write(IOracleDispatcher { contract_address: oracle_address });
            self
                .swap_handler
                .write(ISwapHandlerDispatcher { contract_address: swap_handler_address });
            self
                .referral_storage
                .write(IReferralStorageDispatcher { contract_address: referral_storage_address });
        }
    }

    // *************************************************************************
    //                          INTERNAL FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Get the BaseOrderUtils.ExecuteOrderParams to execute an order.
        /// # Arguments
        /// * `key` - The the key of the order to execute.
        /// * `oracle_params` - The set price parameters for oracle.
        /// * `keeper` - The keeper executing the order.
        /// * `starting_gas` - The starting gas.
        fn get_execute_order_params(
            ref self: ContractState,
            key: felt252,
            oracle_params: SetPricesParams,
            keeper: ContractAddress,
            starting_gas: u128,
            secondary_order_type: SecondaryOrderType
        ) -> ExecuteOrderParams {
            let data_store = self.data_store.read();

            let order = order_store_utils::get(data_store, key);
            let swap_path_markets = market_utils::get_swap_path_markets(
                data_store, order.swap_path
            );

            let execute_order_params_contract = ExecuteOrderParamsContracts {
                data_store: data_store,
                event_emitter: self.event_emitter.read(),
                order_vault: self.order_vault.read(),
                oracle: self.oracle.read(),
                swap_handler: self.swap_handler.read(),
                referral_storage: self.referral_storage.read(),
            };

            let min_oracle_block_numbers = get_uncompacted_oracle_block_numbers(
                oracle_params.compacted_min_oracle_block_numbers.span(), oracle_params.tokens.len()
            );
            let max_oracle_block_numbers = get_uncompacted_oracle_block_numbers(
                oracle_params.compacted_max_oracle_block_numbers.span(), oracle_params.tokens.len()
            );

            let address_zero = 0.try_into().unwrap();

            let mut market = Default::default();

            if (order.market != address_zero) {
                market = market_utils::get_enabled_market(data_store, order.market);
            }

            ExecuteOrderParams {
                contracts: execute_order_params_contract,
                key: key,
                order: order,
                swap_path_markets: swap_path_markets,
                min_oracle_block_numbers: min_oracle_block_numbers,
                max_oracle_block_numbers: max_oracle_block_numbers,
                market: market,
                keeper: keeper,
                starting_gas: starting_gas,
                secondary_order_type: secondary_order_type
            }
        }
    }
}
