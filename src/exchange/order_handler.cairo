//! Contract to handle creation, execution and cancellation of orders.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

// Local imports.
use satoru::oracle::oracle_utils::{SetPricesParams, SimulatePricesParams};
use satoru::order::{base_order_utils::CreateOrderParams, order::Order};

// *************************************************************************
//                  Interface of the `OrderHandler` contract.
// *************************************************************************
#[starknet::interface]
trait IOrderHandler<TContractState> {
    /// Creates an order in the order store.
    /// # Arguments
    /// * `account` - The order's account.
    /// * `params` - The parameters used to create the order.
    /// # Returns
    /// The key of where the order is stored.
    fn create_order(
        ref self: TContractState, account: ContractAddress, params: CreateOrderParams
    ) -> felt252;

    /// Updates the given order with the specified size delta, acceptable price, and trigger price.
    /// The `updateOrder()` feature must be enabled for the given order type. The caller must be the owner
    /// of the order, and the order must not be a market order. The size delta, trigger price, and
    /// acceptable price are updated on the order, and the order is unfrozen. Any additional WNT that is
    /// transferred to the contract is added to the order's execution fee. The updated order is then saved
    /// in the order store, and an `OrderUpdated` event is emitted.
    ///
    /// A user may be able to observe exchange prices and prevent order execution by updating the order's
    /// trigger price or acceptable price
    ///
    /// The main front-running concern is if a user knows whether the price is going to move up or down
    /// then positions accordingly, e.g. if price is going to move up then the user opens a long position
    ///
    /// With updating of orders, a user may know that price could be lower and delays the execution of an
    /// order by updating it, this should not be a significant front-running concern since it is similar
    /// to observing prices then creating a market order as price is decreasing
    /// # Arguments
    /// * `key` - The unique ID of the order to be updated.
    /// * `size_delta_usd` - The new size delta for the order.
    /// * `acceptable_price` - The new acceptable price for the order.
    /// * `trigger_price` - The new trigger price for the order.
    /// * `min_output_amount` - The minimum output amount for decrease orders and swaps.
    /// * `order` - The order to update that will be stored.
    fn update_order(
        ref self: TContractState,
        key: felt252,
        size_delta_usd: u128,
        acceptable_price: u128,
        trigger_price: u128,
        min_output_amount: u128,
        order: Order
    );

    /// Cancels the given order. The `cancelOrder()` feature must be enabled for the given order
    /// type. The caller must be the owner of the order. The order is cancelled by calling the `cancelOrder()`
    /// function in the `OrderUtils` contract. This function also records the starting gas amount and the
    /// reason for cancellation, which is passed to the `cancelOrder()` function.
    /// # Arguments
    /// * `key` - The unique ID of the order to cancel.
    fn cancel_order(ref self: TContractState, key: felt252);

    /// Executes an order.
    /// # Arguments
    /// * `key` - The key of the order to execute.
    /// * `oracle_params` - The oracle params to set prices before execution.
    fn execute_order(ref self: TContractState, key: felt252, oracle_params: SetPricesParams);

    /// Simulates execution of an order to check for any error.
    /// # Arguments
    /// * `key` - The key of the order to execute.
    /// * `oracle_params` - The oracle params to simulate prices.
    fn simulate_execute_order(ref self: TContractState, key: felt252, params: SimulatePricesParams);

    /// Executes an order with keeper.
    /// # Arguments
    /// * `key` - The key of the order to execute.
    /// * `oracle_params` - The oracle params to set prices before execution.
    /// * `keeper` - The keeper executing the order.
    fn execute_order_keeper(
        ref self: TContractState,
        key: felt252,
        oracle_params: SetPricesParams,
        keeper: ContractAddress
    );
}

#[starknet::contract]
mod OrderHandler {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::traits::Into;
    use clone::Clone;
    use starknet::ContractAddress;
    use starknet::get_contract_address;


    // Local imports.
    use super::IOrderHandler;
    use satoru::oracle::{
        oracle_modules::{with_oracle_prices_before, with_oracle_prices_after},
        oracle_utils::{SetPricesParams, SimulatePricesParams}
    };
    use satoru::order::{order::Order, base_order_utils::CreateOrderParams, order_utils};
    use satoru::market::market::Market;
    use satoru::exchange::base_order_handler::{IBaseOrderHandler, BaseOrderHandler};
    use satoru::exchange::base_order_handler::BaseOrderHandler::{
        data_store::InternalContractMemberStateTrait as DataStoreStateTrait,
        event_emitter::InternalContractMemberStateTrait as EventEmitterStateTrait,
        order_vault::InternalContractMemberStateTrait as OrderVaultStateTrait,
        referral_storage::InternalContractMemberStateTrait as ReferralStorageStateTrait,
    };
    use satoru::feature::feature_utils;
    use satoru::data::keys;
    use satoru::role::role_module::{RoleModule, IRoleModule};
    use satoru::utils::global_reentrancy_guard;

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
    impl OrderHandlerImpl of super::IOrderHandler<ContractState> {
        fn create_order(
            ref self: ContractState, account: ContractAddress, params: CreateOrderParams
        ) -> felt252 {
            // Check only controller.
            let role_module_state = RoleModule::unsafe_new_contract_state();
            role_module_state.only_controller();

            // Fetch data store.
            let base_order_handler_state = BaseOrderHandler::unsafe_new_contract_state();
            let data_store = base_order_handler_state.data_store.read();

            global_reentrancy_guard::non_reentrant_before(data_store);

            // Validate feature and create order.
            feature_utils::validate_feature(
                data_store, 
                keys::create_order_feature_disabled_key(
                    get_contract_address(),
                    params.order_type.clone()
                )
            );
            let key = order_utils::create_order(
                data_store,
                base_order_handler_state.event_emitter.read(),
                base_order_handler_state.order_vault.read(),
                base_order_handler_state.referral_storage.read(),
                account,
                params
            );

            global_reentrancy_guard::non_reentrant_after(data_store);

            key
        }

        fn update_order(
            ref self: ContractState,
            key: felt252,
            size_delta_usd: u128,
            acceptable_price: u128,
            trigger_price: u128,
            min_output_amount: u128,
            order: Order
        ) { // TODO
        }

        fn cancel_order(ref self: ContractState, key: felt252) { // TODO
        }

        fn execute_order(
            ref self: ContractState, key: felt252, oracle_params: SetPricesParams
        ) { // TODO
        }

        fn simulate_execute_order(
            ref self: ContractState, key: felt252, params: SimulatePricesParams
        ) { // TODO
        }

        fn execute_order_keeper(
            ref self: ContractState,
            key: felt252,
            oracle_params: SetPricesParams,
            keeper: ContractAddress
        ) { // TODO
        }
    }

    // *************************************************************************
    //                          INTERNAL FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Handles error from order.
        /// # Arguments
        /// * `key` - The key of the deposit to handle error for.
        /// * `starting_gas` - The starting gas of the transaction.
        /// * `reason_bytes` - The reason of the error.
        fn handle_order_error(
            key: felt252, starting_gas: u128, reason_bytes: Array<felt252>
        ) { // TODO
        }

        /// Validate that the keeper is a frozen order keeper.
        /// # Arguments
        /// * `keeper` - address of the keeper.
        fn validate_state_frozen_order_keeper(keeper: ContractAddress) { // TODO
        }
    }
}
