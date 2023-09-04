//! Contract to handle creation, execution and cancellation of deposits.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

// Local imports.
use satoru::oracle::oracle_utils::{SetPricesParams, SimulatePricesParams};
use satoru::deposit::deposit_utils::CreateDepositParams;

// *************************************************************************
//                  Interface of the `DepositHandler` contract.
// *************************************************************************
#[starknet::interface]
trait IDepositHandler<TContractState> {
    /// Creates a deposit in the deposit store.
    /// # Arguments
    /// * `account` - The depositing account.
    /// * `params` - The parameters used to create the deposit.
    /// # Returns
    /// The key of where the deposit is stored.
    fn create_deposit(
        ref self: TContractState, account: ContractAddress, params: CreateDepositParams
    ) -> felt252;

    /// Cancels a deposit.
    /// # Arguments
    /// * `key` - The key of the deposit to cancel.
    fn cancel_deposit(ref self: TContractState, key: felt252);

    /// Executes a deposit.
    /// # Arguments
    /// * `key` - The key of the deposit to execute.
    /// * `oracle_params` - The oracle params to set prices before execution.
    fn execute_deposit(ref self: TContractState, key: felt252, oracle_params: SetPricesParams);

    /// Simulates execution of a deposit to check for any error.
    /// # Arguments
    /// * `key` - The key of the deposit to execute.
    /// * `oracle_params` - The oracle params to set prices before simulation.
    fn simulate_execute_deposit(
        ref self: TContractState, key: felt252, params: SimulatePricesParams
    );

    /// Executes a deposit with keeper.
    /// # Arguments
    /// * `key` - The key of the deposit to execute.
    /// * `oracle_params` - The oracle params to set prices before execution.
    /// * `keeper` - The keeper executing the deposit.
    fn execute_deposit_keeper(
        ref self: TContractState,
        key: felt252,
        oracle_params: SetPricesParams,
        keeper: ContractAddress
    );
}

#[starknet::contract]
mod DepositHandler {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::ContractAddress;
    use array::ArrayTrait;

    // Local imports.
    use super::IDepositHandler;
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
    use satoru::deposit::{
        deposit_utils::CreateDepositParams,
        deposit_vault::{IDepositVaultSafeDispatcher, IDepositVaultSafeDispatcherTrait}
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
        /// Interface to interact with the `DepositVault` contract.
        deposit_vault: IDepositVaultSafeDispatcher,
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
    /// * `event_emitter_address` - The address of the EventEmitter contract.
    /// * `deposit_vault_address` - The address of the DepositVault contract.
    /// * `oracle_address` - The address of the `Oracle` contract.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        data_store_address: ContractAddress,
        role_store_address: ContractAddress,
        event_emitter_address: ContractAddress,
        deposit_vault_address: ContractAddress,
        oracle_address: ContractAddress,
    ) {
        self.data_store.write(IDataStoreSafeDispatcher { contract_address: data_store_address });
        self.role_store.write(IRoleStoreSafeDispatcher { contract_address: role_store_address });
        self
            .event_emitter
            .write(IEventEmitterSafeDispatcher { contract_address: event_emitter_address });
        self
            .deposit_vault
            .write(IDepositVaultSafeDispatcher { contract_address: deposit_vault_address });
        self.oracle.write(IOracleSafeDispatcher { contract_address: oracle_address });
    }


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl DepositHandlerImpl of super::IDepositHandler<ContractState> {
        fn create_deposit(
            ref self: ContractState, account: ContractAddress, params: CreateDepositParams
        ) -> felt252 {
            // TODO
            0
        }

        fn cancel_deposit(ref self: ContractState, key: felt252) { // TODO
        }

        fn execute_deposit(
            ref self: ContractState, key: felt252, oracle_params: SetPricesParams
        ) { // TODO
        }

        fn simulate_execute_deposit(
            ref self: ContractState, key: felt252, params: SimulatePricesParams
        ) { // TODO
        }

        fn execute_deposit_keeper(
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
        /// Handles error from deposit.
        /// # Arguments
        /// * `key` - The key of the deposit to handle error for.
        /// * `starting_gas` - The starting gas of the transaction.
        /// * `reason_bytes` - The reason of the error.
        fn handle_deposit_error(
            ref self: ContractState, key: felt252, starting_gas: u128, reason_bytes: Array<felt252>
        ) { // TODO
        }
    }
}
