//! Contract to handle creation, execution and cancellation of withdrawals.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

// Local imports.
use satoru::oracle::oracle_utils::{SetPricesParams, SimulatePricesParams};
use satoru::withdrawal::withdrawal_utils::CreateWithdrawalParams;

// *************************************************************************
//                  Interface of the `WithdrawalHandler` contract.
// *************************************************************************
#[starknet::interface]
trait IWithdrawalHandler<TContractState> {
    /// Creates a withdrawal in the withdrawal store.
    /// # Arguments
    /// * `account` - The withdrawaling account.
    /// * `params` - The parameters used to create the withdrawal.
    /// # Returns
    /// The key of where the withdrawal is stored.
    fn create_withdrawal(
        ref self: TContractState, account: ContractAddress, params: CreateWithdrawalParams
    ) -> felt252;

    /// Cancels a withdrawal.
    /// # Arguments
    /// * `key` - The key of the withdrawal to cancel.
    fn cancel_withdrawal(ref self: TContractState, key: felt252);

    /// Executes a withdrawal.
    /// # Arguments
    /// * `key` - The key of the withdrawal to execute.
    /// * `oracle_params` - The oracle params to set prices before execution.
    fn execute_withdrawal(ref self: TContractState, key: felt252, oracle_params: SetPricesParams);

    /// Simulates execution of a withdrawal to check for any error.
    /// # Arguments
    /// * `key` - The key of the withdrawal to execute.
    /// * `oracle_params` - The oracle params to set prices before simulation.
    fn simulate_execute_withdrawal(
        ref self: TContractState, key: felt252, params: SimulatePricesParams
    );

    /// Executes a withdrawal with keeper.
    /// # Arguments
    /// * `key` - The key of the withdrawal to execute.
    /// * `oracle_params` - The oracle params to set prices before execution.
    /// * `keeper` - The keeper executing the withdrawal.
    fn execute_withdrawal_keeper(
        ref self: TContractState,
        key: felt252,
        oracle_params: SetPricesParams,
        keeper: ContractAddress
    );
}

#[starknet::contract]
mod WithdrawalHandler {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::ContractAddress;


    // Local imports.
    use super::IWithdrawalHandler;
    use satoru::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
    use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
    use satoru::event::event_emitter::{
        IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait
    };
    use satoru::oracle::{
        oracle::{IOracleSafeDispatcher, IOracleSafeDispatcherTrait},
        oracle_modules::{with_oracle_prices_before, with_oracle_prices_after},
        oracle_utils::{SetPricesParams, SimulatePricesParams}
    };
    use satoru::order::base_order_utils::{ExecuteOrderParams, ExecuteOrderParamsContracts};
    use satoru::swap::swap_handler::{ISwapHandlerSafeDispatcher, ISwapHandlerSafeDispatcherTrait};
    use satoru::market::market::Market;
    use satoru::withdrawal::{
        withdrawal_utils::CreateWithdrawalParams,
        withdrawal_vault::{IWithdrawalVaultSafeDispatcher, IWithdrawalVaultSafeDispatcherTrait}
    };

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Interface to interact with the `DataStore` contract.
        data_store: IDataStoreSafeDispatcher,
        /// Interface to interact with the `RoleStore` contract.
        role_store: IRoleStoreSafeDispatcher,
        /// Interface to interact with the `EventEmitter` contract.
        event_emitter: IEventEmitterSafeDispatcher,
        /// Interface to interact with the `WithdrawalVault` contract.
        withdrawal_vault: IWithdrawalVaultSafeDispatcher,
        /// Interface to interact with the `Oracle` contract.
        oracle: IOracleSafeDispatcher
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************

    /// Constructor of the contract.
    /// # Arguments
    /// * `data_store_address` - The address of the `DataStore` contract.
    /// * `role_store_address` - The address of the `RoleStore` contract.
    /// * `event_emitter_address` - The address of the `EventEmitter` contract.
    /// * `withdrawal_vault_address` - The address of the `WithdrawalVault` contract.
    /// * `oracle_address` - The address of the `Oracle` contract.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        data_store_address: ContractAddress,
        role_store_address: ContractAddress,
        event_emitter_address: ContractAddress,
        withdrawal_vault_address: ContractAddress,
        oracle_address: ContractAddress,
    ) {
        self.data_store.write(IDataStoreSafeDispatcher { contract_address: data_store_address });
        self.role_store.write(IRoleStoreSafeDispatcher { contract_address: role_store_address });
        self
            .event_emitter
            .write(IEventEmitterSafeDispatcher { contract_address: event_emitter_address });
        self
            .withdrawal_vault
            .write(IWithdrawalVaultSafeDispatcher { contract_address: withdrawal_vault_address });
        self.oracle.write(IOracleSafeDispatcher { contract_address: oracle_address });
    }


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl WithdrawalHandlerImpl of super::IWithdrawalHandler<ContractState> {
        fn create_withdrawal(
            ref self: ContractState, account: ContractAddress, params: CreateWithdrawalParams
        ) -> felt252 {
            // TODO
            0
        }

        fn cancel_withdrawal(ref self: ContractState, key: felt252) { // TODO
        }

        fn execute_withdrawal(
            ref self: ContractState, key: felt252, oracle_params: SetPricesParams
        ) { // TODO
        }

        fn simulate_execute_withdrawal(
            ref self: ContractState, key: felt252, params: SimulatePricesParams
        ) { // TODO
        }

        fn execute_withdrawal_keeper(
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
        /// Handles error from withdrawal.
        /// # Arguments
        /// * `key` - The key of the withdrawal to handle error for.
        /// * `starting_gas` - The starting gas of the transaction.
        /// * `reason_bytes` - The reason of the error.
        fn handle_withdrawal_error(
            ref self: ContractState, key: felt252, starting_gas: u128, reason_bytes: Array<felt252>
        ) { // TODO
        }
    }
}
