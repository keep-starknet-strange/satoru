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
    use starknet::{get_caller_address, get_contract_address, ContractAddress};

    // Local imports.
    use super::IDepositHandler;
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::role::role_module::{RoleModule, IRoleModule};
    use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use satoru::oracle::{
        oracle::{IOracleDispatcher, IOracleDispatcherTrait}, oracle_modules,
        oracle_modules::{with_oracle_prices_before, with_oracle_prices_after},
        oracle_utils::{SetPricesParams, SimulatePricesParams}
    };
    use satoru::order::base_order_utils::{ExecuteOrderParams, ExecuteOrderParamsContracts};
    use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
    use satoru::market::market::Market;
    use satoru::deposit::{
        deposit_utils::CreateDepositParams,
        deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait}
    };
    use satoru::deposit::deposit_utils;
    use satoru::feature::feature_utils;
    use satoru::gas::gas_utils;
    use satoru::data::keys;
    use satoru::exchange::exchange_utils;
    use satoru::deposit::execute_deposit_utils;
    use satoru::oracle::oracle_utils;
    use satoru::utils::global_reentrancy_guard;

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
        /// Interface to interact with the `DepositVault` contract.
        deposit_vault: IDepositVaultDispatcher,
        /// Interface to interact with the `Oracle` contract.
        oracle: IOracleDispatcher
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
        self.data_store.write(IDataStoreDispatcher { contract_address: data_store_address });
        self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
        self
            .event_emitter
            .write(IEventEmitterDispatcher { contract_address: event_emitter_address });
        self
            .deposit_vault
            .write(IDepositVaultDispatcher { contract_address: deposit_vault_address });
        self.oracle.write(IOracleDispatcher { contract_address: oracle_address });
    }


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl DepositHandlerImpl of super::IDepositHandler<ContractState> {
        fn create_deposit(
            ref self: ContractState, account: ContractAddress, params: CreateDepositParams
        ) -> felt252 {
            let state: RoleModule::ContractState = RoleModule::unsafe_new_contract_state();
            IRoleModule::only_controller(@state);

            let data_store = self.data_store.read();

            feature_utils::validate_feature(
                self.data_store.read(),
                keys::create_deposit_feature_disabled_key(get_contract_address())
            );

            let key = deposit_utils::create_deposit(
                self.data_store.read(),
                self.event_emitter.read(),
                self.deposit_vault.read(),
                account,
                params
            );

            key
        }

        fn cancel_deposit(ref self: ContractState, key: felt252) {
            let state: RoleModule::ContractState = RoleModule::unsafe_new_contract_state();
            IRoleModule::only_controller(@state);

            let data_store = self.data_store.read();

            // let starting_gas = gas_left();

            let deposit = data_store.get_deposit(key);

            feature_utils::validate_feature(
                data_store, keys::cancel_deposit_feature_disabled_key(get_contract_address())
            );
            exchange_utils::validate_request_cancellation(
                data_store, deposit.updated_at_block, 'Deposit'
            );

            deposit_utils::cancel_deposit(
                data_store,
                self.event_emitter.read(),
                self.deposit_vault.read(),
                key,
                deposit.account,
                0, //starting_gas
                keys::user_initiated_cancel(),
                array!['Cancel Deposit'] //TODO should be empty string
            );
        }

        fn execute_deposit(ref self: ContractState, key: felt252, oracle_params: SetPricesParams) {
            let state: RoleModule::ContractState = RoleModule::unsafe_new_contract_state();
            IRoleModule::only_order_keeper(@state);

            let data_store = self.data_store.read();
            let oracle = self.oracle.read();
            let event_emitter = self.event_emitter.read();
            // global_reentrancy_guard::non_reentrant_before(data_store);
            oracle_modules::with_oracle_prices_before(
                oracle, data_store, event_emitter, @oracle_params
            );

            // let starting_gas = gas_left();
            let execution_gas = gas_utils::get_execution_gas(data_store, 0);

            self.execute_deposit_keeper(key, oracle_params, get_caller_address());

            oracle_modules::with_oracle_prices_after(oracle);
        // global_reentrancy_guard::non_reentrant_after(data_store);
        }

        fn simulate_execute_deposit(
            ref self: ContractState, key: felt252, params: SimulatePricesParams
        ) {
            let state: RoleModule::ContractState = RoleModule::unsafe_new_contract_state();
            IRoleModule::only_controller(@state);

            let data_store = self.data_store.read();
            let oracle = self.oracle.read();

            oracle_modules::with_simulated_oracle_prices_before(oracle, params);

            let oracleParams = Default::default();

            self.execute_deposit_keeper(key, oracleParams, get_caller_address());

            oracle_modules::with_simulated_oracle_prices_after();
        }

        fn execute_deposit_keeper(
            ref self: ContractState,
            key: felt252,
            oracle_params: SetPricesParams,
            keeper: ContractAddress
        ) {
            // let starting_gas = gas_left();
            let data_store = self.data_store.read();
            feature_utils::validate_feature(
                data_store, keys::execute_deposit_feature_disabled_key(get_contract_address())
            );
            let min_oracle_block_numbers = oracle_utils::get_uncompacted_oracle_block_numbers(
                oracle_params.compacted_min_oracle_block_numbers.span(), oracle_params.tokens.len()
            );

            let max_oracle_block_numbers = oracle_utils::get_uncompacted_oracle_block_numbers(
                oracle_params.compacted_max_oracle_block_numbers.span(), oracle_params.tokens.len()
            );

            let params = execute_deposit_utils::ExecuteDepositParams {
                data_store,
                event_emitter: self.event_emitter.read(),
                deposit_vault: self.deposit_vault.read(),
                oracle: self.oracle.read(),
                key,
                min_oracle_block_numbers,
                max_oracle_block_numbers,
                keeper,
                starting_gas: 0 // TODO starting_gas
            };

            execute_deposit_utils::execute_deposit(params);
        }
    }
/// TODO no try catch, we need to find alternative
// // *************************************************************************
// //                          INTERNAL FUNCTIONS
// // *************************************************************************
// #[generate_trait]
// impl InternalImpl of InternalTrait {
//     /// Handles error from deposit.
//     /// # Arguments
//     /// * `key` - The key of the deposit to handle error for.
//     /// * `starting_gas` - The starting gas of the transaction.
//     /// * `reason_bytes` - The reason of the error.
//     fn handle_deposit_error(
//         ref self: ContractState, key: felt252, starting_gas: u256, reason_bytes: Array<felt252>
//     ) { // TODO
//     }
// }
}
