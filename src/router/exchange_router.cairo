//! Router for exchange functions, supports functions which require.
//! token transfers from the user

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;
use core::zeroable::Zeroable;


use debug::PrintTrait;

// Local imports.
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::router::router::{IRouterDispatcher, IRouterDispatcherTrait};
use satoru::deposit::deposit_utils::CreateDepositParams;
use satoru::withdrawal::withdrawal_utils::CreateWithdrawalParams;
use satoru::order::base_order_utils::CreateOrderParams;
use satoru::oracle::oracle_utils::SimulatePricesParams;
use satoru::exchange::{
    deposit_handler::{IDepositHandlerDispatcher, IDepositHandlerDispatcherTrait},
    withdrawal_handler::{IWithdrawalHandlerDispatcher, IWithdrawalHandlerDispatcherTrait},
    order_handler::{IOrderHandlerDispatcher, IOrderHandlerDispatcherTrait},
};

// *************************************************************************
//                  Interface of the `ExchangeRouter` contract.
// *************************************************************************
#[starknet::interface]
trait IExchangeRouter<TContractState> {
    /// Sends the given amount of tokens to the given address.
    /// # Arguments
    /// * `token` - The token address to transfer.
    /// * `receiver` - The address of the receiver.
    /// * `amount` - The amount of tokens to transfer.
    fn send_tokens(
        ref self: TContractState, token: ContractAddress, receiver: ContractAddress, amount: u128
    );

    /// Creates a new deposit with the given params. The deposit is created by transferring the specified amounts of
    /// * long and short tokens from the caller's account to the deposit store.
    /// # Arguments
    /// * `params` - The parameters used to create the deposit.
    /// # Returns
    /// Return the unique ID of the newly created deposit.
    fn create_deposit(ref self: TContractState, params: CreateDepositParams) -> felt252;

    /// Cancels the given deposit.
    /// # Arguments
    /// * `key` - The unique ID of the order to be cancelled.
    fn cancel_deposit(ref self: TContractState, key: felt252);

    /// Creates a new withdrawal with the given withdrawal parameters.
    /// # Arguments
    /// * `params` - The parameters used to create the withdrawal.
    /// # Returns
    /// Return the unique ID of the newly created withdrawal.
    fn create_withdrawal(ref self: TContractState, params: CreateWithdrawalParams) -> felt252;

    /// Cancels the given withdrawal.
    /// # Arguments
    /// * `key` - The unique ID of the order to be cancelled.
    fn cancel_withdrawal(ref self: TContractState, key: felt252);

    /// Creates a new order with the given amount, order parameters.
    /// # Arguments
    /// * `params` - The parameters used to create the order.
    fn create_order(ref self: TContractState, params: CreateOrderParams) -> felt252;

    /// Set a callback contract address for a specific market and user account.
    /// # Arguments
    /// * `market` - Address of the market to check.
    /// * `callback_contract` - The address of the callback contract to be associated with the specified market and user account.
    fn set_saved_callback_contract(
        ref self: TContractState, market: ContractAddress, callback_contract: ContractAddress
    );

    /// Simulate the execution of a deposit operation.
    /// # Arguments
    /// * `key` - Unique identifier for the deposit operation.
    /// * `simulated_oracle_params` - A struct containing parameters needed for simulating the deposit.
    fn simulate_execute_deposit(
        ref self: TContractState, key: felt252, simulated_oracle_params: SimulatePricesParams
    );

    /// Simulate the execution of a withdrawal operation.
    /// # Arguments
    /// * `key` - Unique identifier for the deposit operation.
    /// * `simulated_oracle_params` - A struct containing parameters needed for simulating the withdrawal.
    fn simulate_execute_withdrawal(
        ref self: TContractState, key: felt252, simulated_oracle_params: SimulatePricesParams
    );

    /// Simulate the execution of an order.
    /// # Arguments
    /// * `key` - Unique identifier for the deposit operation.
    /// * `simulated_oracle_params` - A struct containing parameters needed for simulating the order.
    fn simulate_execute_order(
        ref self: TContractState, key: felt252, simulated_oracle_params: SimulatePricesParams
    );

    /// Updates the given order with the specified size delta, acceptable price, and trigger price.
    /// # Arguments
    /// * `key` - The unique ID of the order to be updated.
    /// * `size_delta_usd` - The new size delta for the order.
    /// * `acceptable_price` - The new acceptable price for the order.
    /// * `trigger_price` - The new trigger price for the order.
    /// * `min_output_amout` - The minimum required output amount in the transaction.
    fn update_order(
        ref self: TContractState,
        key: felt252,
        size_delta_usd: u128,
        acceptable_price: u128,
        trigger_price: u128,
        min_output_amout: u128
    );

    /// Cancels the given order.
    /// # Arguments
    /// * `key` - The unique ID of the order to be cancelled.
    fn cancel_order(ref self: TContractState, key: felt252);

    /// Claims funding fees for the given markets and tokens on behalf of the caller, and sends the
    /// fees to the specified receiver. The length of the `markets` and `tokens` arrays must be the same.
    /// For each market-token pair, the `claim_funding_fees()` function in the `MarketUtils` contract is
    /// called to claim the fees for the caller.
    /// # Arguments
    /// * `market` - An array of market addresses.
    /// * `tokens` - An array of token addresses, corresponding to the given markets.
    /// * `receiver` - The address to which the claimed fees should be sent.
    fn claim_funding_fees(
        ref self: TContractState,
        markets: Array<ContractAddress>,
        tokens: Array<ContractAddress>,
        receiver: ContractAddress
    ) -> Array<u128>;

    fn claim_collateral(
        ref self: TContractState,
        markets: Array<ContractAddress>,
        tokens: Array<ContractAddress>,
        time_keys: Array<u128>,
        receiver: ContractAddress
    ) -> Array<u128>;

    /// Claims affiliate rewards for the given markets and tokens on behalf of the caller, and sends the rewards to the specified receiver.
    /// # Arguments
    /// * `market` - An array of market addresses.
    /// * `tokens` - An array of token addresses, corresponding to the given markets.
    /// * `receiver` - The address to which the claimed rewards should be sent.
    fn claim_affiliate_rewards(
        ref self: TContractState,
        markets: Array<ContractAddress>,
        tokens: Array<ContractAddress>,
        receiver: ContractAddress
    ) -> Array<u128>;

    fn set_ui_fee_factor(ref self: TContractState, ui_fee_factor: u128);

    fn claim_ui_fees(
        ref self: TContractState,
        markets: Array<ContractAddress>,
        tokens: Array<ContractAddress>,
        receiver: ContractAddress
    ) -> Array<u128>;
}

#[starknet::contract]
mod ExchangeRouter {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::ContractAddress;
    use core::zeroable::Zeroable;

    use debug::PrintTrait;

    // Local imports.
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
    use satoru::router::router::{IRouterDispatcher, IRouterDispatcherTrait};
    use satoru::exchange::{
        deposit_handler::{IDepositHandlerDispatcher, IDepositHandlerDispatcherTrait},
        withdrawal_handler::{IWithdrawalHandlerDispatcher, IWithdrawalHandlerDispatcherTrait},
        order_handler::{IOrderHandlerDispatcher, IOrderHandlerDispatcherTrait},
    };

    use super::IExchangeRouter;
    use satoru::deposit::deposit_utils::CreateDepositParams;
    use satoru::withdrawal::withdrawal_utils::CreateWithdrawalParams;
    use satoru::order::base_order_utils::CreateOrderParams;
    use satoru::oracle::oracle_utils::SimulatePricesParams;

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Interface to interact with the `Router` contract.
        router: IRouterDispatcher,
        /// Interface to interact with the `DataStore` contract.
        data_store: IDataStoreDispatcher,
        /// Interface to interact with the `RoleStore` contract.
        role_store: IRoleStoreDispatcher,
        /// Interface to interact with the `EventEmitter` contract.
        event_emitter: IEventEmitterDispatcher,
        /// Interface to interact with the `DepositHandler` contract.
        deposit_handler: IDepositHandlerDispatcher,
        /// Interface to interact with the `WithdrawalHandler` contract.
        withdrawal_handler: IWithdrawalHandlerDispatcher,
        /// Interface to interact with the `OrderHandler` contract.
        order_handler: IOrderHandlerDispatcher
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************

    /// Constructor of the contract.
    /// # Arguments
    /// * `router_address` - The address of the router contract.
    /// * `data_store_address` - The address of the data store contract.
    /// * `role_store_address` - The address of the role store contract.
    /// * `event_emitter_address` - The address of the event emitter contract.
    /// * `deposit_handler_address` - The address of the deposit handler contract.
    /// * `withdrawal_handler_address` - The address of the withdrawal handler contract.
    /// * `order_handler_address` - The address of the order handler contract.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        router_address: ContractAddress,
        data_store_address: ContractAddress,
        role_store_address: ContractAddress,
        event_emitter_address: ContractAddress,
        deposit_handler_address: ContractAddress,
        withdrawal_handler_address: ContractAddress,
        order_handler_address: ContractAddress
    ) {
        self.router.write(IRouterDispatcher { contract_address: router_address });
        self.data_store.write(IDataStoreDispatcher { contract_address: data_store_address });
        self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
        self
            .event_emitter
            .write(IEventEmitterDispatcher { contract_address: event_emitter_address });
        self
            .deposit_handler
            .write(IDepositHandlerDispatcher { contract_address: deposit_handler_address });
        self
            .withdrawal_handler
            .write(IWithdrawalHandlerDispatcher { contract_address: withdrawal_handler_address });
        self
            .order_handler
            .write(IOrderHandlerDispatcher { contract_address: order_handler_address });
    }

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl ExchangeRouterImpl of super::IExchangeRouter<ContractState> {
        fn send_tokens(
            ref self: ContractState, token: ContractAddress, receiver: ContractAddress, amount: u128
        ) { //TODO
        }

        fn create_deposit(ref self: ContractState, params: CreateDepositParams) -> felt252 {
            //TODO
            0
        }

        fn cancel_deposit(ref self: ContractState, key: felt252) { //TODO
        }

        fn create_withdrawal(ref self: ContractState, params: CreateWithdrawalParams) -> felt252 {
            //TODO
            0
        }

        fn cancel_withdrawal(ref self: ContractState, key: felt252) { //TODO
        }

        fn create_order(ref self: ContractState, params: CreateOrderParams) -> felt252 {
            //TODO
            0
        }

        fn set_saved_callback_contract(
            ref self: ContractState, market: ContractAddress, callback_contract: ContractAddress
        ) { //TODO
        }

        fn simulate_execute_deposit(
            ref self: ContractState, key: felt252, simulated_oracle_params: SimulatePricesParams
        ) { //TODO
        }

        fn simulate_execute_withdrawal(
            ref self: ContractState, key: felt252, simulated_oracle_params: SimulatePricesParams
        ) { //TODO
        }

        fn simulate_execute_order(
            ref self: ContractState, key: felt252, simulated_oracle_params: SimulatePricesParams
        ) { //TODO
        }

        fn update_order(
            ref self: ContractState,
            key: felt252,
            size_delta_usd: u128,
            acceptable_price: u128,
            trigger_price: u128,
            min_output_amout: u128
        ) { //TODO
        }

        fn cancel_order(ref self: ContractState, key: felt252) { //TODO
        }

        fn claim_funding_fees(
            ref self: ContractState,
            markets: Array<ContractAddress>,
            tokens: Array<ContractAddress>,
            receiver: ContractAddress
        ) -> Array<u128> {
            //TODO
            ArrayTrait::new()
        }

        fn claim_collateral(
            ref self: ContractState,
            markets: Array<ContractAddress>,
            tokens: Array<ContractAddress>,
            time_keys: Array<u128>,
            receiver: ContractAddress
        ) -> Array<u128> {
            //TODO
            ArrayTrait::new()
        }

        fn claim_affiliate_rewards(
            ref self: ContractState,
            markets: Array<ContractAddress>,
            tokens: Array<ContractAddress>,
            receiver: ContractAddress
        ) -> Array<u128> {
            //TODO
            ArrayTrait::new()
        }

        fn set_ui_fee_factor(ref self: ContractState, ui_fee_factor: u128) { //TODO
        }

        fn claim_ui_fees(
            ref self: ContractState,
            markets: Array<ContractAddress>,
            tokens: Array<ContractAddress>,
            receiver: ContractAddress
        ) -> Array<u128> {
            //TODO
            ArrayTrait::new()
        }
    }
}
