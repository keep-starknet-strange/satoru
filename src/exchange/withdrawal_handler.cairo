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
}

#[starknet::contract]
mod WithdrawalHandler {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::{ContractAddress, get_contract_address, get_caller_address};
    use traits::Default;
    use clone::Clone;

    // Local imports.
    use super::{
        IWithdrawalHandler, IWithdrawalHandlerDispatcher, IWithdrawalHandlerDispatcherTrait
    };
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::role::role;
    use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
    use satoru::data::keys;
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use satoru::oracle::{
        oracle::{IOracleDispatcher, IOracleDispatcherTrait},
        oracle_modules::{with_oracle_prices_before, with_oracle_prices_after},
        oracle_utils::{SetPricesParams, SimulatePricesParams}
    };
    use satoru::order::base_order_utils::{ExecuteOrderParams, ExecuteOrderParamsContracts};
    use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
    use satoru::market::market::Market;
    use satoru::withdrawal::{
        withdrawal_utils,
        withdrawal_utils::{CreateWithdrawalParams, create_withdrawal, cancel_withdrawal},
        withdrawal_vault::{IWithdrawalVaultDispatcher, IWithdrawalVaultDispatcherTrait}
    };
    use satoru::feature::feature_utils;
    use satoru::utils::starknet_utils;
    use satoru::utils::global_reentrancy_guard;
    use satoru::exchange::exchange_utils;
    use satoru::gas::gas_utils;
    use satoru::oracle::{oracle_modules, oracle_utils};

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
        /// Interface to interact with the `WithdrawalVault` contract.
        withdrawal_vault: IWithdrawalVaultDispatcher,
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
        self.data_store.write(IDataStoreDispatcher { contract_address: data_store_address });
        self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
        self
            .event_emitter
            .write(IEventEmitterDispatcher { contract_address: event_emitter_address });
        self
            .withdrawal_vault
            .write(IWithdrawalVaultDispatcher { contract_address: withdrawal_vault_address });
        self.oracle.write(IOracleDispatcher { contract_address: oracle_address });
    }


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl WithdrawalHandlerImpl of super::IWithdrawalHandler<ContractState> {
        fn create_withdrawal(
            ref self: ContractState, account: ContractAddress, params: CreateWithdrawalParams
        ) -> felt252 {
            let role_store = self.role_store.read();
            role_store
                .assert_only_role(
                    get_caller_address(), role::CONTROLLER
                ); // Only controller can call this method.

            let data_store = self.data_store.read();

            global_reentrancy_guard::non_reentrant_before(data_store); // Initiates re-entrancy

            feature_utils::validate_feature(
                data_store, keys::create_withdrawal_feature_disabled_key(get_contract_address())
            );

            let result = withdrawal_utils::create_withdrawal(
                data_store, self.event_emitter.read(), self.withdrawal_vault.read(), account, params
            );

            global_reentrancy_guard::non_reentrant_after(data_store); // Finalizes re-entrancy

            result
        }

        fn cancel_withdrawal(ref self: ContractState, key: felt252) {
            let role_store = self.role_store.read();
            role_store
                .assert_only_role(
                    get_caller_address(), role::CONTROLLER
                ); // Only controller can call this method.

            let data_store = self.data_store.read();

            global_reentrancy_guard::non_reentrant_before(data_store); // Initiates re-entrancy

            let starting_gas = starknet_utils::sn_gasleft(array![100]); // Returns 100 for now,
            let withdrawal = data_store.get_withdrawal(key).unwrap(); // Panics if Option::None

            feature_utils::validate_feature(
                data_store, keys::cancel_withdrawal_feature_disabled_key(get_contract_address())
            );

            exchange_utils::validate_request_cancellation(
                data_store, withdrawal.updated_at_block.try_into().unwrap(), 'Withdrawal'
            );

            withdrawal_utils::cancel_withdrawal(
                data_store,
                self.event_emitter.read(),
                self.withdrawal_vault.read(),
                key,
                withdrawal.account,
                starting_gas,
                keys::user_initiated_cancel(),
                array![]
            );

            global_reentrancy_guard::non_reentrant_after(data_store); // Finalizes re-entrancy
        }

        fn execute_withdrawal(
            ref self: ContractState, key: felt252, oracle_params: SetPricesParams
        ) {
            let role_store = self.role_store.read();
            role_store
                .assert_only_role(
                    get_caller_address(), role::ORDER_KEEPER
                ); // Only order keeper can call.

            let data_store = self.data_store.read();

            global_reentrancy_guard::non_reentrant_before(data_store); // Initiates re-entrancy
            let oracle_params_copy = SetPricesParams {
                signer_info: oracle_params.signer_info,
                tokens: oracle_params.tokens.clone(),
                compacted_min_oracle_block_numbers: oracle_params
                    .compacted_min_oracle_block_numbers
                    .clone(),
                compacted_max_oracle_block_numbers: oracle_params
                    .compacted_max_oracle_block_numbers
                    .clone(),
                compacted_oracle_timestamps: oracle_params.compacted_oracle_timestamps.clone(),
                compacted_decimals: oracle_params.compacted_decimals.clone(),
                compacted_min_prices: oracle_params.compacted_min_prices.clone(),
                compacted_min_prices_indexes: oracle_params.compacted_min_prices_indexes.clone(),
                compacted_max_prices: oracle_params.compacted_max_prices.clone(),
                compacted_max_prices_indexes: oracle_params.compacted_max_prices_indexes.clone(),
                signatures: oracle_params.signatures.clone(),
                price_feed_tokens: oracle_params.price_feed_tokens.clone(),
            };
            // withOraclePrices
            oracle_modules::with_oracle_prices_before(
                self.oracle.read(), self.data_store.read(), self.event_emitter.read(), oracle_params
            );

            let starting_gas = starknet_utils::sn_gasleft(array![100]);
            let execution_gas = gas_utils::get_execution_gas(data_store, starting_gas);

            // TODO self dispatcher ile çağır
            self
                .execute_withdrawal_keeper(
                    key, oracle_params_copy, get_caller_address()
                ); // TODO handle revert, call _handleRevert if reverts

            oracle_modules::with_oracle_prices_after();

            global_reentrancy_guard::non_reentrant_after(data_store); // Finalizes re-entrancy
        }

        fn simulate_execute_withdrawal(
            ref self: ContractState, key: felt252, params: SimulatePricesParams
        ) {
            let role_store = self.role_store.read();
            role_store
                .assert_only_role(
                    get_caller_address(), role::CONTROLLER
                ); // Only controller can call this method.

            oracle_modules::with_simulated_oracle_prices_before(self.oracle.read(), params);

            let data_store = self.data_store.read();

            global_reentrancy_guard::non_reentrant_before(data_store); // Initiates re-entrancy

            let oracle_params: SetPricesParams = SetPricesParams {
                signer_info: 0,
                tokens: Default::default(),
                compacted_min_oracle_block_numbers: Default::default(),
                compacted_max_oracle_block_numbers: Default::default(),
                compacted_oracle_timestamps: Default::default(),
                compacted_decimals: Default::default(),
                compacted_min_prices: Default::default(),
                compacted_min_prices_indexes: Default::default(),
                compacted_max_prices: Default::default(),
                compacted_max_prices_indexes: Default::default(),
                signatures: Default::default(),
                price_feed_tokens: Default::default(),
            }; // Initiates default values for this struct. Derive Default is not enough for that.

            self
                .execute_withdrawal_keeper(
                    key, oracle_params, get_caller_address()
                ); // TODO Should call with dispatcher as like external call

            global_reentrancy_guard::non_reentrant_after(data_store); // Finalizes re-entrancy

            oracle_modules::with_simulated_oracle_prices_after();
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
        ) {
            // Just cancels withdrawal. There is no way to handle revert and revert reason right now.

            withdrawal_utils::cancel_withdrawal(
                self.data_store.read(),
                self.event_emitter.read(),
                self.withdrawal_vault.read(),
                key,
                get_caller_address(),
                starting_gas,
                '', // TODO: There is no way to get revert message currently.
                reason_bytes
            );
        }

        /// Executes a withdrawal with keeper.
        /// # Arguments
        /// * `key` - The key of the withdrawal to execute.
        /// * `oracle_params` - The oracle params to set prices before execution.
        /// * `keeper` - The keeper executing the withdrawal.
        fn execute_withdrawal_keeper(
            ref self: ContractState,
            key: felt252,
            oracle_params: SetPricesParams,
            keeper: ContractAddress
        ) {
            let starting_gas = starknet_utils::sn_gasleft(array![100]);
            let data_store = self.data_store.read();

            feature_utils::validate_feature(
                data_store, keys::execute_withdrawal_feature_disabled_key(get_contract_address())
            );

            let min_oracle_block_numbers = oracle_utils::get_uncompacted_oracle_block_numbers(
                @oracle_params.compacted_min_oracle_block_numbers, @oracle_params.tokens.len()
            );
            let max_oracle_block_numbers = oracle_utils::get_uncompacted_oracle_block_numbers(
                @oracle_params.compacted_max_oracle_block_numbers, @oracle_params.tokens.len()
            );

            let params: withdrawal_utils::ExecuteWithdrawalParams =
                withdrawal_utils::ExecuteWithdrawalParams {
                data_store,
                event_emitter: self.event_emitter.read(),
                withdrawal_vault: self.withdrawal_vault.read(),
                oracle: self.oracle.read(),
                key,
                min_oracle_block_numbers,
                max_oracle_block_numbers,
                keeper,
                starting_gas
            };

            withdrawal_utils::execute_withdrawal(params);
        }
    }
}
