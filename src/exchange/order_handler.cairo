//! Contract to handle creation, execution and cancellation of orders.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
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
    /// acceptable price are updated on the order, and the order is unfrozen. Any additional FEE_TOKEN that is
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
    /// # Returns
    /// The updated order.
    // fn update_order(
    //     ref self: TContractState,
    //     key: felt252,
    //     size_delta_usd: u256,
    //     acceptable_price: u256,
    //     trigger_price: u256,
    //     min_output_amount: u256,
    //     order: Order
    // ) -> Order;

    /// Cancels the given order. The `cancelOrder()` feature must be enabled for the given order
    /// type. The caller must be the owner of the order. The order is cancelled by calling the `cancelOrder()`
    /// function in the `OrderUtils` contract. This function also records the starting gas amount and the
    /// reason for cancellation, which is passed to the `cancelOrder()` function.
    /// # Arguments
    /// * `key` - The unique ID of the order to cancel.
    // fn cancel_order(ref self: TContractState, key: felt252);

    /// Executes an order.
    /// # Arguments
    /// * `key` - The key of the order to execute.
    /// * `oracle_params` - The oracle params to set prices before execution.
    fn execute_order(ref self: TContractState, key: felt252, oracle_params: SetPricesParams);

    /// Executes an order.
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

    /// Simulates execution of an order to check for any error.
    /// # Arguments
    /// * `key` - The key of the order to execute.
    /// * `oracle_params` - The oracle params to simulate prices.
    fn simulate_execute_order(ref self: TContractState, key: felt252, params: SimulatePricesParams);
}

#[starknet::contract]
mod OrderHandler {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use satoru::exchange::base_order_handler::BaseOrderHandler::order_utils_lib::InternalContractMemberStateTrait;
    use satoru::order::order_utils::IOrderUtilsDispatcherTrait;
    use core::starknet::SyscallResultTrait;
    use core::traits::Into;
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_contract_address, ClassHash};
    use array::ArrayTrait;
    use debug::PrintTrait;

    // Local imports.
    use super::IOrderHandler;
    use satoru::oracle::oracle_modules;

    use satoru::oracle::oracle_utils::{SetPricesParams, SimulatePricesParams};
    use satoru::order::{
        base_order_utils::CreateOrderParams, order_utils::{IOrderUtilsDispatcher},
        order::{Order, OrderTrait, OrderType, SecondaryOrderType},
        order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait}
    };
    // use satoru::market::error::MarketError;
    // use satoru::position::error::PositionError;
    // use satoru::feature::error::FeatureError;
    use satoru::order::error::OrderError;
    // use satoru::exchange::exchange_utils;
    use satoru::exchange::base_order_handler::{IBaseOrderHandler, BaseOrderHandler};
    use satoru::exchange::base_order_handler::BaseOrderHandler::{
        role_store::InternalContractMemberStateTrait as RoleStoreStateTrait,
        data_store::InternalContractMemberStateTrait as DataStoreStateTrait,
        event_emitter::InternalContractMemberStateTrait as EventEmitterStateTrait,
        order_vault::InternalContractMemberStateTrait as OrderVaultStateTrait,
        referral_storage::InternalContractMemberStateTrait as ReferralStorageStateTrait,
        oracle::InternalContractMemberStateTrait as OracleStateTrait,
        InternalTrait as BaseOrderHandleInternalTrait,
    };
    use satoru::feature::feature_utils::{validate_feature};
    use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use satoru::data::keys::{create_order_feature_disabled_key, execute_order_feature_disabled_key};
    use satoru::role::role::FROZEN_ORDER_KEEPER;
    use satoru::role::role_module::{RoleModule, IRoleModule};
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    // use satoru::token::token_utils;
    // use satoru::gas::gas_utils;
    use satoru::utils::global_reentrancy_guard::{non_reentrant_before, non_reentrant_after};
    // use satoru::utils::error_utils;
    use satoru::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::contract_address_const;

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
        referral_storage_address: ContractAddress,
        order_utils_class_hash: ClassHash,
        increase_order_utils_class_hash: ClassHash,
        decrease_order_utils_class_hash: ClassHash,
        swap_order_utils_class_hash: ClassHash,
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
            referral_storage_address,
            order_utils_class_hash,
            increase_order_utils_class_hash,
            decrease_order_utils_class_hash,
            swap_order_utils_class_hash
        );
    }


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl OrderHandlerImpl of super::IOrderHandler<ContractState> {
        fn create_order(
            ref self: ContractState, account: ContractAddress, params: CreateOrderParams
        ) -> felt252 {
            // Check only controller.
            // let role_module_state = RoleModule::unsafe_new_contract_state(); // TODO uncomment role
            // role_module_state.only_controller();
            // Fetch data store.
            let base_order_handler_state = BaseOrderHandler::unsafe_new_contract_state();
            let data_store = base_order_handler_state.data_store.read();

            non_reentrant_before(data_store);

            // Validate feature and create order.
            validate_feature(
                data_store,
                create_order_feature_disabled_key(get_contract_address(), params.order_type)
            );
            let key = base_order_handler_state
                .order_utils_lib
                .read()
                .create_order_utils(
                    data_store,
                    base_order_handler_state.event_emitter.read(),
                    base_order_handler_state.order_vault.read(),
                    base_order_handler_state.referral_storage.read(),
                    account,
                    params
                );

            non_reentrant_after(data_store);

            key
        }


        fn execute_order(ref self: ContractState, key: felt252, oracle_params: SetPricesParams) {
            // Check only order keeper.
            let role_module_state = RoleModule::unsafe_new_contract_state();
            role_module_state.only_order_keeper();
            // Fetch data store.
            let base_order_handler_state = BaseOrderHandler::unsafe_new_contract_state();
            let data_store = base_order_handler_state.data_store.read();
            // non_reentrant_before(data_store);
            oracle_modules::with_oracle_prices_before(
                base_order_handler_state.oracle.read(),
                data_store,
                base_order_handler_state.event_emitter.read(),
                @oracle_params
            );
            // TODO: Did not implement starting gas and try / catch logic as not available in Cairo
            self._execute_order(key, oracle_params, get_contract_address());
            oracle_modules::with_oracle_prices_after(base_order_handler_state.oracle.read());
        // non_reentrant_after(data_store);
        }

        fn execute_order_keeper(
            ref self: ContractState,
            key: felt252,
            oracle_params: SetPricesParams,
            keeper: ContractAddress
        ) {
            self._execute_order(key, oracle_params, keeper);
        }

        fn simulate_execute_order(
            ref self: ContractState, key: felt252, params: SimulatePricesParams
        ) {
            // Check only order keeper.
            let role_module_state = RoleModule::unsafe_new_contract_state();
            role_module_state.only_order_keeper();

            // Fetch data store.
            let base_order_handler_state = BaseOrderHandler::unsafe_new_contract_state();
            let data_store = base_order_handler_state.data_store.read();

            non_reentrant_before(data_store);
            // oracle_modules::with_simulated_oracle_prices_before(
            //     base_order_handler_state.oracle.read(), params
            // );

            let oracle_params: SetPricesParams = Default::default();
            self._execute_order(key, oracle_params, get_contract_address());

            // oracle_modules::with_simulated_oracle_prices_after();
            non_reentrant_after(data_store);
        }
    }

    // ***********************************************a**************************
    //                          INTERNAL FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Executes an order.
        /// # Arguments
        /// * `key` - The key of the order to execute.
        /// * `oracle_params` - The oracle params to set prices before execution.
        /// * `keeper` - The keeper executing the order.
        fn _execute_order(
            self: @ContractState,
            key: felt252,
            oracle_params: SetPricesParams,
            keeper: ContractAddress
        ) {
            let starting_gas: u256 = 100000; // TODO: Get starting gas from Cairo.

            // Check only self.
            let role_module_state = RoleModule::unsafe_new_contract_state();
            //role_module_state.only_self();

            let mut base_order_handler_state = BaseOrderHandler::unsafe_new_contract_state();
            let params = base_order_handler_state
                .get_execute_order_params(
                    key, oracle_params, keeper, starting_gas, SecondaryOrderType::None(()),
                );

            if params.order.is_frozen || params.order.order_type == OrderType::LimitSwap(()) {
                self._validate_state_frozen_order_keeper(keeper);
            }

            // Validate feature.
            validate_feature(
                params.contracts.data_store,
                execute_order_feature_disabled_key(get_contract_address(), params.order.order_type)
            );

            base_order_handler_state.order_utils_lib.read().execute_order_utils(params);
        }


        /// Validate that the keeper is a frozen order keeper.
        /// # Arguments
        /// * `keeper` - address of the keeper.
        fn _validate_state_frozen_order_keeper(self: @ContractState, keeper: ContractAddress) {
            let mut base_order_handler_state = BaseOrderHandler::unsafe_new_contract_state();
            let role_store = base_order_handler_state.role_store.read();

            assert(
                role_store.has_role(keeper, FROZEN_ORDER_KEEPER),
                OrderError::INVALID_FROZEN_ORDER_KEEPER
            );
        }
    }
}
