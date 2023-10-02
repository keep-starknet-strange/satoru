//! Data store for all general state values.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
use core::traits::Into;
use starknet::ContractAddress;
use satoru::market::market::Market;
use satoru::order::order::Order;
use satoru::position::position::Position;
use satoru::withdrawal::withdrawal::Withdrawal;
use satoru::deposit::deposit::Deposit;
use satoru::utils::i128::{I128Div, I128Mul, I128Store, I128Serde, I128Default};

// *************************************************************************
//                  Interface of the `DataStore` contract.
// *************************************************************************
#[starknet::interface]
trait IDataStore<TContractState> {
    // *************************************************************************
    //                      Felt252 related functions.
    // *************************************************************************
    /// Get a felt252 value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_felt252(self: @TContractState, key: felt252) -> felt252;

    /// Set a felt252 value for the given key.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `value` - The value to set.
    fn set_felt252(ref self: TContractState, key: felt252, value: felt252);

    /// Delete a felt252 value for the given key.
    /// # Arguments
    /// * `key` - The key to delete the value for.
    fn remove_felt252(ref self: TContractState, key: felt252);

    /// Add input to existing value.
    /// # Arguments
    /// * `key` - The key to add the value to.
    /// * `value` - The value to add.
    fn increment_felt252(ref self: TContractState, key: felt252, value: felt252) -> felt252;

    /// Subtract input from existing value.
    /// # Arguments
    /// * `key` - The key to subtract the value from.
    /// * `value` - The value to subtract.
    fn decrement_felt252(ref self: TContractState, key: felt252, value: felt252) -> felt252;

    // *************************************************************************
    //                          u256 related functions.
    // *************************************************************************
    /// Get a u256 value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_u256(self: @TContractState, key: felt252) -> u256;

    /// Set a u256 value for the given key.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `value` - The value to set.
    fn set_u256(ref self: TContractState, key: felt252, value: u256);

    /// Delete a u256 value for the given key.
    /// # Arguments
    /// * `key` - The key to delete the value for.
    fn remove_u256(ref self: TContractState, key: felt252);

    /// Add input to existing value.
    /// # Arguments
    /// * `key` - The key to add the value to.
    /// * `value` - The value to add.
    fn increment_u256(ref self: TContractState, key: felt252, value: u256) -> u256;

    /// Subtract input from existing value.
    /// # Arguments
    /// * `key` - The key to subtract the value from.
    /// * `value` - The value to subtract.
    fn decrement_u256(ref self: TContractState, key: felt252, value: u256) -> u256;


    // *************************************************************************
    //                          u128 related functions.
    // *************************************************************************
    /// Get a u128 value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_u128(self: @TContractState, key: felt252) -> u128;

    /// Set a u128 value for the given key.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `value` - The value to set.
    fn set_u128(ref self: TContractState, key: felt252, value: u128);

    /// Delete a u128 value for the given key.
    /// # Arguments
    /// * `key` - The key to delete the value for.
    fn remove_u128(ref self: TContractState, key: felt252);

    /// Add signed value to existing value if result positive.
    /// # Arguments
    /// * `key` - The key to add the value to.
    /// * `value` - The value to add.
    /// * `error` - The error to throw if result is negative.
    fn apply_delta_to_u128(
        ref self: TContractState, key: felt252, value: i128, error: felt252
    ) -> u128;

    /// Add input to existing value.
    /// # Arguments
    /// * `key` - The key to add the value to.
    /// * `value` - The value to add.
    fn increment_u128(ref self: TContractState, key: felt252, value: u128) -> u128;

    /// Subtract input from existing value.
    /// # Arguments
    /// * `key` - The key to subtract the value from.
    /// * `value` - The value to subtract.
    fn decrement_u128(ref self: TContractState, key: felt252, value: u128) -> u128;

    // *************************************************************************
    //                      Address related functions.
    // *************************************************************************
    /// Get an address value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_address(self: @TContractState, key: felt252) -> ContractAddress;

    /// Set an address value for the given key.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `value` - The value to set.
    fn set_address(ref self: TContractState, key: felt252, value: ContractAddress);

    /// Remove an address value for the given key.
    /// # Arguments
    /// * `key` - The key to remove the value for.
    fn remove_address(ref self: TContractState, key: felt252);
    // *************************************************************************
    //                      Bool related functions.
    // *************************************************************************
    /// Get a bool value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_bool(self: @TContractState, key: felt252) -> Option<bool>;

    /// Set a bool value for the given key.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `value` - The value to set.
    fn set_bool(ref self: TContractState, key: felt252, value: bool);

    /// Remove a bool value for the given key.
    /// # Arguments
    /// * - The key to remove the value for.
    fn remove_bool(ref self: TContractState, key: felt252);

    // *************************************************************************
    //                      Market related functions.
    // *************************************************************************
    /// Get a market value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_market(self: @TContractState, key: ContractAddress) -> Option<Market>;

    /// Set a market value for the given key.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `value` - The value to set.
    fn set_market(ref self: TContractState, key: ContractAddress, salt: felt252, market: Market);
    /// Get a market value for the given salt.
    /// # Arguments
    /// * `salt` - The salt to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_by_salt_market(self: @TContractState, salt: felt252) -> Option<Market>;
    fn remove_market(ref self: TContractState, key: ContractAddress);
    /// Get a hash given salt.
    /// # Arguments
    /// * `salt` - The salt to hash.
    /// # Returns
    /// The hash of the salt.
    fn get_market_salt_hash(self: @TContractState, salt: felt252) -> felt252;
    fn get_market_count(self: @TContractState) -> u32;
    /// Get market between start and end.
    /// # Arguments
    /// * `start` - The start index, included.
    /// * `end` - The end index, not included.
    /// # Returns
    /// Array of markets contract addresses.
    fn get_market_keys(self: @TContractState, start: usize, end: usize) -> Array<ContractAddress>;

    // *************************************************************************
    //                      Oracle related functions.
    // *************************************************************************
    /// Sets the token ID for a given contract address.
    /// This function checks if the caller has the `CONTROLLER` role
    /// before updating the `tokens_ids` mapping.
    /// # Arguments
    /// * `self` - Mutable reference to the contract state.
    /// * `token` - Contract address for which to set the ID.
    /// * `id` - The ID to set.
    fn set_token_id(ref self: TContractState, token: ContractAddress, id: felt252);

    /// Retrieves the token ID associated with a given contract address.
    /// # Arguments
    /// * `self` - Reference to the contract state.
    /// * `token` - Contract address for which to retrieve the ID.
    /// # Returns
    /// Returns the ID associated with the given token address.
    fn get_token_id(self: @TContractState, token: ContractAddress) -> felt252;

    // *************************************************************************
    //                      Order related functions.
    // *************************************************************************
    /// Get a order value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_order(self: @TContractState, key: felt252) -> Option<Order>;

    /// Set a order value for the given key.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `value` - The value to set.
    fn set_order(ref self: TContractState, key: felt252, order: Order);

    /// Remove a order value for the given key.
    /// # Arguments
    /// * `key` - The key to remove the value for.
    /// * `account` - The account to remove key for.
    fn remove_order(ref self: TContractState, key: felt252, account: ContractAddress);


    /// Return order keys between start - end  indexes
    /// # Arguments
    /// * `start` - Start index
    /// * `end` - Start index
    fn get_order_keys(self: @TContractState, start: usize, end: usize) -> Array<felt252>;

    // TODO checkk
    /// Return total order count
    fn get_order_count(self: @TContractState) -> u32;

    /// Returns the number of withdrawals made by a specific account.
    ///
    /// # Arguments
    ///
    /// * `account` - The account address to retrieve the order count for.
    fn get_account_order_count(self: @TContractState, account: ContractAddress) -> u32;


    /// Return order keys between start - end  indexes for given account
    /// # Arguments
    /// * `account` - The order account 
    /// * `start` - Start index
    /// * `end` - Start index
    fn get_account_order_keys(
        self: @TContractState, account: ContractAddress, start: usize, end: usize
    ) -> Array<felt252>;


    // *************************************************************************
    //                      Postion related functions.
    // *************************************************************************
    /// Get a position value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_position(self: @TContractState, key: felt252) -> Option<Position>;

    /// Set a position value for the given key.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `value` - The value to set.
    fn set_position(ref self: TContractState, key: felt252, position: Position);

    /// Remove a position value for the given key.
    /// # Arguments
    /// * `key` - The key to remove the value for.
    /// * `account` - The account to remove key for.
    fn remove_position(ref self: TContractState, key: felt252, account: ContractAddress);


    /// Return position keys between start - end  indexes
    /// # Arguments
    /// * `start` - Start index
    /// * `end` - Start index
    fn get_position_keys(self: @TContractState, start: usize, end: usize) -> Array<felt252>;

    // TODO checkk
    /// Return total position count
    fn get_position_count(self: @TContractState) -> u32;

    /// Returns the number of position made by a specific account.
    ///
    /// # Arguments
    ///
    /// * `account` - The account address to retrieve the position count for.
    fn get_account_position_count(self: @TContractState, account: ContractAddress) -> u32;


    /// Return position keys between start - end  indexes for given account
    /// # Arguments
    /// * `account` - The position account 
    /// * `start` - Start index
    /// * `end` - Start index
    fn get_account_position_keys(
        self: @TContractState, account: ContractAddress, start: usize, end: usize
    ) -> Array<felt252>;

    // *************************************************************************
    //                      Withdrawal related functions.
    // *************************************************************************
    /// Get a withdrawal value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_withdrawal(self: @TContractState, key: felt252) -> Option<Withdrawal>;

    /// Set a withdrawal value for the given key.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `value` - The value to set.
    fn set_withdrawal(ref self: TContractState, key: felt252, withdrawal: Withdrawal);

    /// Removes a withdrawal value for the given key.
    /// Sets the withdrawal account address to zero.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `account` - The value to set.
    fn remove_withdrawal(ref self: TContractState, key: felt252, account: ContractAddress);

    /// Returns an array of withdrawal keys from the stored List of Withdrawals.
    ///
    /// # Arguments
    ///
    /// * `start` - The starting index of the withdrawal keys to retrieve.
    /// * `end` - The ending index of the withdrawal keys to retrieve.
    fn get_withdrawal_keys(self: @TContractState, start: usize, end: usize) -> Array<felt252>;

    /// Returns the number of withdrawals made by a specific account.
    ///
    /// # Arguments
    ///
    /// * `account` - The account address to retrieve the withdrawal count for.
    fn get_account_withdrawal_count(self: @TContractState, account: ContractAddress) -> u32;


    /// Returns an array of withdrawal keys for a specific account, starting from `start` and ending at `end`.
    ///
    /// # Arguments
    ///
    /// * `account` - The account address to retrieve the withdrawal keys for.
    /// * `start` - The starting index of the withdrawal keys to retrieve.
    /// * `end` - The ending index of the withdrawal keys to retrieve.
    fn get_account_withdrawal_keys(
        self: @TContractState, account: ContractAddress, start: u32, end: u32
    ) -> Array<felt252>;

    // *************************************************************************
    //                      Deposit related functions.
    // *************************************************************************

    /// Get a deposit value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_deposit(self: @TContractState, key: felt252) -> Option<Deposit>;

    /// Set a deposit value for the given key.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `value` - The value to set.
    fn set_deposit(ref self: TContractState, key: felt252, deposit: Deposit);

    /// Remove a deposit value for the given key.
    /// # Arguments
    /// * `key` - The key to remove the value for.
    /// * `account` - The account to remove key for.
    fn remove_deposit(ref self: TContractState, key: felt252, account: ContractAddress);

    /// Return deposit keys between start - end  indexes
    /// # Arguments
    /// * `start` - Start index
    /// * `end` - Start index
    fn get_deposit_keys(self: @TContractState, start: usize, end: usize) -> Array<felt252>;

    fn get_deposit_count(self: @TContractState) -> u32;

    /// Returns the number of deposit made by a specific account.
    /// # Arguments
    /// * `account` - The account address to retrieve the position count for.
    fn get_account_deposit_count(self: @TContractState, account: ContractAddress) -> u32;

    /// Return deposit keys between start - end  indexes for given account
    /// # Arguments
    /// * `account` - The deposit account 
    /// * `start` - Start index
    /// * `end` - Start index
    fn get_account_deposit_keys(
        self: @TContractState, account: ContractAddress, start: u32, end: u32
    ) -> Array<felt252>;


    //TODO: Update u128 to i128 when Serde and Store for i128 implementations are released.
    // *************************************************************************
    //                          int128 related functions.
    // *************************************************************************
    /// Get a int value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_i128(self: @TContractState, key: felt252) -> i128;

    /// Set the int value for the given key.
    /// # Arguments
    /// `key` - The key of the value
    /// `value` - The value to set
    /// # Return
    /// The int value for the key.
    fn set_i128(ref self: TContractState, key: felt252, value: i128);


    /// Delete a i128 value for the given key.
    /// # Arguments
    /// * `key` - The key to delete the value for.
    fn remove_i128(ref self: TContractState, key: felt252);

    /// Add input to existing value.
    /// # Arguments
    /// * `key` - The key to add the value to.
    /// * `value` - The value to add.
    fn increment_i128(ref self: TContractState, key: felt252, value: i128) -> i128;

    /// Subtract input from existing value.
    /// # Arguments
    /// * `key` - The key to subtract the value from.
    /// * `value` - The value to subtract.
    fn decrement_i128(ref self: TContractState, key: felt252, value: i128) -> i128;
}

#[starknet::contract]
mod DataStore {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use starknet::{get_caller_address, ContractAddress, contract_address_const,};
    use nullable::NullableTrait;
    use zeroable::Zeroable;
    use alexandria_storage::list::{ListTrait, List};
    use debug::PrintTrait;
    use poseidon::poseidon_hash_span;

    // Local imports.
    use satoru::role::role;
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::market::{market::{Market, ValidateMarket}, error::MarketError};
    use satoru::data::error::DataError;
    use satoru::order::{order::Order, error::OrderError};
    use satoru::position::{position::Position, error::PositionError};
    use satoru::withdrawal::{withdrawal::Withdrawal, error::WithdrawalError};
    use satoru::deposit::{deposit::Deposit, error::DepositError};
    use satoru::utils::calc;
    use satoru::utils::i128::{I128Div, I128Mul, I128Store, I128Serde, I128Default};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        role_store: IRoleStoreDispatcher,
        felt252_values: LegacyMap::<felt252, felt252>,
        u256_values: LegacyMap::<felt252, u256>,
        u128_values: LegacyMap::<felt252, u128>,
        i128_values: LegacyMap::<felt252, i128>,
        address_values: LegacyMap::<felt252, ContractAddress>,
        bool_values: LegacyMap::<felt252, Option<bool>>,
        /// Market storage
        market_values: LegacyMap::<ContractAddress, Market>,
        markets: List<Market>,
        market_indexes: LegacyMap::<ContractAddress, usize>,
        /// Oracle storage
        tokens_ids: LegacyMap::<ContractAddress, felt252>,
        /// Order storage
        order_values: LegacyMap::<felt252, Order>,
        orders: List<Order>,
        account_orders: LegacyMap<ContractAddress, List<felt252>>,
        order_indexes: LegacyMap::<felt252, usize>,
        /// Position storage
        positions: List<Position>,
        account_positions: LegacyMap<ContractAddress, List<felt252>>,
        position_indexes: LegacyMap::<felt252, usize>,
        /// Withdrawal storage
        withdrawals: List<Withdrawal>,
        account_withdrawals: LegacyMap<ContractAddress, List<felt252>>,
        withdrawal_indexes: LegacyMap::<felt252, usize>,
        /// Deposit storage
        deposits: List<Deposit>,
        account_deposits: LegacyMap<ContractAddress, List<felt252>>,
        deposit_indexes: LegacyMap::<felt252, usize>,
    }

    const MARKET: felt252 = 'MARKET_SALT';

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, role_store_address: ContractAddress) {
        self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
    }

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl DataStore of super::IDataStore<ContractState> {
        // *************************************************************************
        //                      Felt252 related functions.
        // *************************************************************************
        fn get_felt252(self: @ContractState, key: felt252) -> felt252 {
            self.felt252_values.read(key)
        }

        fn set_felt252(ref self: ContractState, key: felt252, value: felt252) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Set the value.
            self.felt252_values.write(key, value);
        }

        fn remove_felt252(ref self: ContractState, key: felt252) {
            // Check that the caller has permission to delete the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Delete the value.
            self.felt252_values.write(key, Default::default());
        }

        fn increment_felt252(ref self: ContractState, key: felt252, value: felt252) -> felt252 {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Get the current value.
            let current_value = self.felt252_values.read(key);
            // Add the delta to the current value.
            // TODO: Check for overflow.
            let new_value = current_value + value;
            // Set the new value.
            self.felt252_values.write(key, new_value);
            // Return the new value.
            new_value
        }

        fn decrement_felt252(ref self: ContractState, key: felt252, value: felt252) -> felt252 {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Get the current value.
            let current_value = self.felt252_values.read(key);
            // Subtract the delta from the current value.
            let new_value = current_value - value;
            // Set the new value.
            self.felt252_values.write(key, new_value);
            // Return the new value.
            new_value
        }

        // *************************************************************************
        //                          U256 related functions.
        // *************************************************************************
        fn get_u256(self: @ContractState, key: felt252) -> u256 {
            self.u256_values.read(key)
        }

        fn set_u256(ref self: ContractState, key: felt252, value: u256) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Set the value.
            self.u256_values.write(key, value);
        }

        fn remove_u256(ref self: ContractState, key: felt252) {
            // Check that the caller has permission to delete the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Delete the value.
            self.u256_values.write(key, Default::default());
        }

        fn increment_u256(ref self: ContractState, key: felt252, value: u256) -> u256 {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Get the current value.
            let current_value = self.u256_values.read(key);
            // Add the delta to the current value.
            let new_value = current_value + value;
            // Set the new value.
            self.u256_values.write(key, new_value);
            // Return the new value.
            new_value
        }

        fn decrement_u256(ref self: ContractState, key: felt252, value: u256) -> u256 {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Get the current value.
            let current_value = self.u256_values.read(key);
            // Subtract the delta from the current value.
            let new_value = current_value - value;
            // Set the new value.
            self.u256_values.write(key, new_value);
            // Return the new value.
            new_value
        }

        // *************************************************************************
        //                          u128 related functions.
        // *************************************************************************
        fn get_u128(self: @ContractState, key: felt252) -> u128 {
            self.u128_values.read(key)
        }

        fn set_u128(ref self: ContractState, key: felt252, value: u128) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Set the value.
            self.u128_values.write(key, value);
        }

        fn remove_u128(ref self: ContractState, key: felt252) {
            // Check that the caller has permission to delete the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Delete the value.
            self.u128_values.write(key, Default::default());
        }

        fn apply_delta_to_u128(
            ref self: ContractState, key: felt252, value: i128, error: felt252
        ) -> u128 {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);

            let current_value = self.u128_values.read(key);
            if value < 0 && calc::to_unsigned(-value) > current_value {
                panic(array![error]);
            }

            let next_value = calc::sum_return_uint_128(current_value, value);
            self.u128_values.write(key, next_value);
            next_value
        }

        fn increment_u128(ref self: ContractState, key: felt252, value: u128) -> u128 {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Get the current value.
            let current_value = self.u128_values.read(key);
            // Add the delta to the current value.
            let new_value = current_value + value;
            // Set the new value.
            self.u128_values.write(key, new_value);
            // Return the new value.
            new_value
        }

        fn decrement_u128(ref self: ContractState, key: felt252, value: u128) -> u128 {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Get the current value.
            let current_value = self.u128_values.read(key);
            // Subtract the delta from the current value.
            let new_value = current_value - value;
            // Set the new value.
            self.u128_values.write(key, new_value);
            // Return the new value.
            new_value
        }

        //TODO: Update u128 to i128 when Serde and Store for i128 implementations are released.
        // *************************************************************************
        //                      i128 related functions.
        // *************************************************************************
        fn get_i128(self: @ContractState, key: felt252) -> i128 {
            self.i128_values.read(key)
        }

        fn set_i128(ref self: ContractState, key: felt252, value: i128) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Set the value.
            self.i128_values.write(key, value);
        }

        fn remove_i128(ref self: ContractState, key: felt252) {
            // Check that the caller has permission to delete the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Delete the value.
            self.i128_values.write(key, Default::default());
        }

        fn increment_i128(ref self: ContractState, key: felt252, value: i128) -> i128 {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Get the current value.
            let current_value = self.i128_values.read(key);
            // Add the delta to the current value.
            // TODO: Check for overflow.
            let new_value = current_value + value;
            // Set the new value.
            self.i128_values.write(key, new_value);
            // Return the new value.
            new_value
        }

        fn decrement_i128(ref self: ContractState, key: felt252, value: i128) -> i128 {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Get the current value.
            let current_value = self.i128_values.read(key);
            // Subtract the delta from the current value.
            let new_value = current_value - value;
            // Set the new value.
            self.i128_values.write(key, new_value);
            // Return the new value.
            new_value
        }

        // *************************************************************************
        //                      Address related functions.
        // *************************************************************************
        fn get_address(self: @ContractState, key: felt252) -> ContractAddress {
            self.address_values.read(key)
        }

        fn set_address(ref self: ContractState, key: felt252, value: ContractAddress) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Set the value.
            self.address_values.write(key, value);
        }

        fn remove_address(ref self: ContractState, key: felt252) {
            // Check that the caller has permission to delete the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Delete the value.
            self.address_values.write(key, contract_address_const::<0>());
        }

        // *************************************************************************
        //                      Bool related functions.
        // *************************************************************************
        fn get_bool(self: @ContractState, key: felt252) -> Option<bool> {
            self.bool_values.read(key)
        }

        fn set_bool(ref self: ContractState, key: felt252, value: bool) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Set the value.
            self.bool_values.write(key, Option::Some(value));
        }

        fn remove_bool(ref self: ContractState, key: felt252) {
            // Check that the caller has permission to delete the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Delete the value.
            self.bool_values.write(key, Option::None);
        }

        // *************************************************************************
        //                      Market related functions.
        // *************************************************************************

        fn get_market(self: @ContractState, key: ContractAddress) -> Option<Market> {
            let offsetted_index: usize = self.market_indexes.read(key);
            if offsetted_index == 0 {
                return Option::None;
            }
            let orders: List<Market> = self.markets.read();
            orders.get(offsetted_index - 1)
        }

        fn set_market(
            ref self: ContractState, key: ContractAddress, salt: felt252, market: Market
        ) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::MARKET_KEEPER);

            let mut markets = self.markets.read();

            // Because default values in storage are 0, indexes are offseted by 1.
            let offsetted_index: usize = self.market_indexes.read(key);
            assert(offsetted_index <= markets.len(), MarketError::MARKET_NOT_FOUND);

            // If the index is 0, it means the key has not been registered yet and
            // we need to append the order to the list.
            if offsetted_index == 0 {
                // Valid indexes start from 1.
                self.market_indexes.write(key, markets.len() + 1);
                markets.append(market);
                self.set_address(self.get_market_salt_hash(salt), key);
                return;
            }
            let index = offsetted_index - 1;
            self.set_address(self.get_market_salt_hash(salt), key);
            markets.set(index, market);
        }

        fn remove_market(ref self: ContractState, key: ContractAddress) {
            // Check that the caller has permission to remove the market.
            self.role_store.read().assert_only_role(get_caller_address(), role::MARKET_KEEPER);
            let offsetted_index: usize = self.market_indexes.read(key);
            let mut markets = self.markets.read();
            assert(offsetted_index <= markets.len(), MarketError::MARKET_NOT_FOUND);

            let index = offsetted_index - 1;
            // Replace the value at `index` by the last market in the list.

            // Specifically handle case where there is only one market
            let last_market_index = markets.len() - 1;
            if index == last_market_index {
                markets.pop_front();
                self.market_indexes.write(key, 0);
                return;
            }

            let mut last_market_maybe = markets.pop_front();
            match last_market_maybe {
                Option::Some(last_market) => {
                    markets.set(index, last_market);
                    self.market_indexes.write(last_market.market_token.into(), offsetted_index);
                    self.market_indexes.write(key, 0);
                },
                Option::None => {
                    // This case should never happen, because index is always <= length
                    return;
                }
            }
        }

        fn get_market_keys(
            self: @ContractState, start: usize, mut end: usize
        ) -> Array<ContractAddress> {
            let markets = self.markets.read();
            let mut keys: Array<ContractAddress> = Default::default();
            assert(start <= end, 'start must be <= end');
            if start >= markets.len() {
                return keys;
            }

            if end > markets.len() {
                end = markets.len()
            }
            let mut i = start;
            loop {
                if i == end {
                    break;
                }
                let market: Market = markets[i];
                keys.append(market.market_token);
                i = i + 1;
            };
            keys
        }

        fn get_market_count(self: @ContractState,) -> u32 {
            self.markets.read().len()
        }

        fn get_by_salt_market(self: @ContractState, salt: felt252) -> Option<Market> {
            let key = self.get_address(self.get_market_salt_hash(salt));
            self.get_market(key)
        }

        fn get_market_salt_hash(self: @ContractState, salt: felt252) -> felt252 {
            poseidon_hash_span(array![MARKET, salt].span())
        }

        // *************************************************************************
        //                      Oracle related functions.
        // *************************************************************************
        fn set_token_id(ref self: ContractState, token: ContractAddress, id: felt252) {
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            self.tokens_ids.write(token, id);
        }

        fn get_token_id(self: @ContractState, token: ContractAddress) -> felt252 {
            self.tokens_ids.read(token)
        }

        // *************************************************************************
        //                      Order related functions.
        // *************************************************************************

        fn get_order(self: @ContractState, key: felt252) -> Option<Order> {
            let offsetted_index: usize = self.order_indexes.read(key);
            if offsetted_index == 0 {
                return Option::None;
            }
            let orders: List<Order> = self.orders.read();
            orders.get(offsetted_index - 1)
        }

        fn set_order(ref self: ContractState, key: felt252, order: Order) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            assert(order.account != contract_address_const::<0>(), OrderError::CANT_BE_ZERO);

            let mut orders = self.orders.read();
            let mut account_orders = self.account_orders.read(order.account);

            // Because default values in storage are 0, indexes are offseted by 1.
            let offsetted_index: usize = self.order_indexes.read(key);
            assert(offsetted_index <= orders.len(), OrderError::ORDER_NOT_FOUND);

            // If the index is 0, it means the key has not been registered yet and
            // we need to append the order to the list.
            if offsetted_index == 0 {
                // Valid indexes start from 1.
                self.order_indexes.write(key, orders.len() + 1);
                account_orders.append(key);
                orders.append(order);
                return;
            }
            let index = offsetted_index - 1;

            orders.set(index, order);
        }

        fn remove_order(ref self: ContractState, key: felt252, account: ContractAddress) {
            // Check that the caller has permission to remove the order.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            let offsetted_index: usize = self.order_indexes.read(key);
            let mut orders = self.orders.read();
            assert(offsetted_index <= orders.len(), OrderError::ORDER_NOT_FOUND);

            let index = offsetted_index - 1;
            // Replace the value at `index` by the last order in the list.

            // Specifically handle case where there is only one order
            let last_order_index = orders.len() - 1;
            if index == last_order_index {
                orders.pop_front();
                self.order_indexes.write(key, 0);
                self._remove_account_order(key, account);
                return;
            }

            let mut last_order_maybe = orders.pop_front();
            match last_order_maybe {
                Option::Some(last_order) => {
                    orders.set(index, last_order);
                    self.order_indexes.write(last_order.key, offsetted_index);
                    self.order_indexes.write(key, 0);
                    self._remove_account_order(key, account)
                },
                Option::None => {
                    // This case should never happen, because index is always <= length
                    return;
                }
            }
        }

        fn get_order_keys(self: @ContractState, start: usize, mut end: usize) -> Array<felt252> {
            let orders = self.orders.read();
            let mut keys: Array<felt252> = Default::default();
            assert(start <= end, 'start must be <= end');
            if start >= orders.len() {
                return keys;
            }

            if end > orders.len() {
                end = orders.len()
            }
            let mut i = start;
            loop {
                if i == end {
                    break;
                }
                let order: Order = orders[i];
                keys.append(order.key);
                i = i + 1;
            };
            keys
        }

        fn get_order_count(self: @ContractState,) -> u32 {
            self.orders.read().len()
        }

        fn get_account_order_count(self: @ContractState, account: ContractAddress) -> u32 {
            self.account_orders.read(account).len()
        }

        fn get_account_order_keys(
            self: @ContractState, account: ContractAddress, start: u32, mut end: u32
        ) -> Array<felt252> {
            let mut keys: Array<felt252> = Default::default();
            let mut account_orders = self.account_orders.read(account);

            assert(start <= end, 'start must be <= end');
            if start >= account_orders.len() {
                return keys;
            }

            if end > account_orders.len() {
                end = account_orders.len()
            }

            let mut i = start;
            loop {
                if i == end {
                    break;
                }
                let key: felt252 = account_orders[i];
                keys.append(key);
                i += 1;
            };
            keys
        }

        // *************************************************************************
        //                      Position related functions.
        // *************************************************************************

        fn get_position(self: @ContractState, key: felt252) -> Option<Position> {
            let offsetted_index: usize = self.position_indexes.read(key);
            if offsetted_index == 0 {
                return Option::None;
            }
            let positions: List<Position> = self.positions.read();
            positions.get(offsetted_index - 1)
        }

        fn set_position(ref self: ContractState, key: felt252, position: Position) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            assert(position.account != contract_address_const::<0>(), PositionError::CANT_BE_ZERO);

            let mut positions = self.positions.read();
            let mut account_positions = self.account_positions.read(position.account);

            // Because default values in storage are 0, indexes are offseted by 1.
            let offsetted_index: usize = self.position_indexes.read(key);
            assert(offsetted_index <= positions.len(), PositionError::POSITION_NOT_FOUND);

            // If the index is 0, it means the key has not been registered yet and
            // we need to append the position to the list.
            if offsetted_index == 0 {
                // Valid indexes start from 1.
                self.position_indexes.write(key, positions.len() + 1);
                account_positions.append(key);
                positions.append(position);
                return;
            }
            let index = offsetted_index - 1;

            positions.set(index, position);
        }

        fn remove_position(ref self: ContractState, key: felt252, account: ContractAddress) {
            // Check that the caller has permission to remove the position.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            let offsetted_index: usize = self.position_indexes.read(key);
            let mut positions = self.positions.read();
            assert(offsetted_index <= positions.len(), PositionError::POSITION_NOT_FOUND);

            let index = offsetted_index - 1;
            // Replace the value at `index` by the last position in the list.

            // Specifically handle case where there is only one position
            let last_position_index = positions.len() - 1;
            if index == last_position_index {
                positions.pop_front();
                self.position_indexes.write(key, 0);
                self._remove_account_position(key, account);
                return;
            }

            let mut last_position_maybe = positions.pop_front();
            match last_position_maybe {
                Option::Some(last_position) => {
                    positions.set(index, last_position);
                    self.position_indexes.write(last_position.key, offsetted_index);
                    self.position_indexes.write(key, 0);
                    self._remove_account_position(key, account)
                },
                Option::None => {
                    // This case should never happen, because index is always <= length
                    return;
                }
            }
        }

        fn get_position_keys(self: @ContractState, start: usize, mut end: usize) -> Array<felt252> {
            let positions = self.positions.read();
            let mut keys: Array<felt252> = Default::default();
            assert(start <= end, 'start must be <= end');
            if start >= positions.len() {
                return keys;
            }

            if end > positions.len() {
                end = positions.len()
            }
            let mut i = start;
            loop {
                if i == end {
                    break;
                }
                let position: Position = positions[i];
                keys.append(position.key);
                i = i + 1;
            };
            keys
        }

        fn get_position_count(self: @ContractState) -> u32 {
            self.positions.read().len()
        }

        fn get_account_position_count(self: @ContractState, account: ContractAddress) -> u32 {
            self.account_positions.read(account).len()
        }

        fn get_account_position_keys(
            self: @ContractState, account: ContractAddress, start: u32, mut end: u32
        ) -> Array<felt252> {
            let mut keys: Array<felt252> = Default::default();
            let mut account_positions = self.account_positions.read(account);

            assert(start <= end, 'start must be <= end');
            if start >= account_positions.len() {
                return keys;
            }

            if end > account_positions.len() {
                end = account_positions.len()
            }

            let mut i = start;
            loop {
                if i == end {
                    break;
                }
                let key: felt252 = account_positions[i];
                keys.append(key);
                i += 1;
            };
            keys
        }

        // *************************************************************************
        //                      Withdrawal related functions.
        // *************************************************************************

        fn get_withdrawal(self: @ContractState, key: felt252) -> Option<Withdrawal> {
            let offsetted_index: usize = self.withdrawal_indexes.read(key);
            if offsetted_index == 0 {
                return Option::None;
            }
            let withdrawals: List<Withdrawal> = self.withdrawals.read();
            withdrawals.get(offsetted_index - 1)
        }

        fn set_withdrawal(ref self: ContractState, key: felt252, withdrawal: Withdrawal) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            assert(
                withdrawal.account != contract_address_const::<0>(), WithdrawalError::CANT_BE_ZERO
            );

            let mut withdrawals = self.withdrawals.read();
            let mut account_withdrawals = self.account_withdrawals.read(withdrawal.account);

            // Because default values in storage are 0, indexes are offseted by 1.
            let offsetted_index: usize = self.withdrawal_indexes.read(key);
            assert(offsetted_index <= withdrawals.len(), WithdrawalError::NOT_FOUND);

            // If the index is 0, it means the key has not been registered yet and
            // we need to append the withdrawal to the list.
            if offsetted_index == 0 {
                // Valid indexes start from 1.
                self.withdrawal_indexes.write(key, withdrawals.len() + 1);
                account_withdrawals.append(key);
                withdrawals.append(withdrawal);
                return;
            }
            let index = offsetted_index - 1;

            withdrawals.set(index, withdrawal);
        }

        fn remove_withdrawal(ref self: ContractState, key: felt252, account: ContractAddress) {
            // Check that the caller has permission to remove the withdrawal.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            let offsetted_index: usize = self.withdrawal_indexes.read(key);
            let mut withdrawals = self.withdrawals.read();
            assert(offsetted_index <= withdrawals.len(), WithdrawalError::NOT_FOUND);

            let index = offsetted_index - 1;
            // Replace the value at `index` by the last withdrawal in the list.

            // Specifically handle case where there is only one withdrawal
            let last_withdrawal_index = withdrawals.len() - 1;
            if index == last_withdrawal_index {
                withdrawals.pop_front();
                self.withdrawal_indexes.write(key, 0);
                self._remove_account_withdrawal(key, account);
                return;
            }

            let mut last_withdrawal_maybe = withdrawals.pop_front();
            match last_withdrawal_maybe {
                Option::Some(last_withdrawal) => {
                    withdrawals.set(index, last_withdrawal);
                    self.withdrawal_indexes.write(last_withdrawal.key, offsetted_index);
                    self.withdrawal_indexes.write(key, 0);
                    self._remove_account_withdrawal(key, account)
                },
                Option::None => {
                    // This case should never happen, because index is always <= length
                    return;
                }
            }
        }
        fn get_withdrawal_keys(
            self: @ContractState, start: usize, mut end: usize
        ) -> Array<felt252> {
            let withdrawals = self.withdrawals.read();
            let mut keys: Array<felt252> = Default::default();
            assert(start <= end, 'start must be <= end');
            if start >= withdrawals.len() {
                return keys;
            }

            if end > withdrawals.len() {
                end = withdrawals.len()
            }
            let mut i = start;
            loop {
                if i == end {
                    break;
                }
                let withdrawal: Withdrawal = withdrawals[i];
                keys.append(withdrawal.key);
            };
            keys
        }

        fn get_account_withdrawal_count(self: @ContractState, account: ContractAddress) -> u32 {
            self.account_withdrawals.read(account).len()
        }

        fn get_account_withdrawal_keys(
            self: @ContractState, account: ContractAddress, start: u32, mut end: u32
        ) -> Array<felt252> {
            let mut keys: Array<felt252> = Default::default();
            let mut account_withdrawals = self.account_withdrawals.read(account);

            assert(start <= end, 'start must be <= end');
            if start >= account_withdrawals.len() {
                return keys;
            }

            if end > account_withdrawals.len() {
                end = account_withdrawals.len()
            }

            let mut i = start;
            loop {
                if i == end {
                    break;
                }
                let key: felt252 = account_withdrawals[i];
                keys.append(key);
                i += 1;
            };
            keys
        }

        // *************************************************************************
        //                      Deposit related functions.
        // *************************************************************************

        fn get_deposit(self: @ContractState, key: felt252) -> Option<Deposit> {
            let offsetted_index: usize = self.deposit_indexes.read(key);
            if offsetted_index == 0 {
                return Option::None;
            }
            let deposits: List<Deposit> = self.deposits.read();
            deposits.get(offsetted_index - 1)
        }

        fn set_deposit(ref self: ContractState, key: felt252, deposit: Deposit) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            assert(deposit.account != contract_address_const::<0>(), DepositError::CANT_BE_ZERO);

            let mut deposits = self.deposits.read();
            let mut account_deposits = self.account_deposits.read(deposit.account);

            // Because default values in storage are 0, indexes are offseted by 1.
            let offsetted_index: usize = self.deposit_indexes.read(key);
            assert(offsetted_index <= deposits.len(), DepositError::DEPOSIT_NOT_FOUND);

            // If the index is 0, it means the key has not been registered yet and
            // we need to append the deposit to the list.
            if offsetted_index == 0 {
                // Valid indexes start from 1.
                self.deposit_indexes.write(key, deposits.len() + 1);
                account_deposits.append(key);
                deposits.append(deposit);
                return;
            }
            let index = offsetted_index - 1;
            deposits.set(index, deposit);
        }

        fn remove_deposit(ref self: ContractState, key: felt252, account: ContractAddress) {
            // Check that the caller has permission to remove the deposit.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            let offsetted_index: usize = self.deposit_indexes.read(key);
            let mut deposits = self.deposits.read();
            assert(offsetted_index <= deposits.len(), DepositError::DEPOSIT_NOT_FOUND);

            let index = offsetted_index - 1;
            // Replace the value at `index` by the last deposit in the list.

            // Specifically handle case where there is only one deposit
            let last_deposit_index = deposits.len() - 1;
            if index == last_deposit_index {
                deposits.pop_front();
                self.deposit_indexes.write(key, 0);
                self._remove_account_deposit(key, account);
                return;
            }

            let mut last_deposit_maybe = deposits.pop_front();
            match last_deposit_maybe {
                Option::Some(last_deposit) => {
                    deposits.set(index, last_deposit);
                    self.deposit_indexes.write(last_deposit.key, offsetted_index);
                    self.deposit_indexes.write(key, 0);
                    self._remove_account_deposit(key, account)
                },
                Option::None => {
                    // This case should never happen, because index is always <= length
                    return;
                }
            }
        }

        fn get_deposit_keys(self: @ContractState, start: usize, mut end: usize) -> Array<felt252> {
            let deposits = self.deposits.read();
            let mut keys: Array<felt252> = Default::default();
            assert(start <= end, 'start must be <= end');
            if start >= deposits.len() {
                return keys;
            }

            if end > deposits.len() {
                end = deposits.len()
            }
            let mut i = start;
            loop {
                if i == end {
                    break;
                }
                let deposit = deposits[i];
                keys.append(deposit.key);
                i = i + 1;
            };
            keys
        }

        fn get_deposit_count(self: @ContractState) -> u32 {
            self.deposits.read().len
        }

        fn get_account_deposit_count(self: @ContractState, account: ContractAddress) -> u32 {
            self.account_deposits.read(account).len()
        }

        fn get_account_deposit_keys(
            self: @ContractState, account: ContractAddress, start: u32, mut end: u32
        ) -> Array<felt252> {
            let mut keys: Array<felt252> = Default::default();
            let mut account_deposits = self.account_deposits.read(account);

            assert(start <= end, 'start must be <= end');
            if start >= account_deposits.len() {
                return keys;
            }

            if end > account_deposits.len() {
                end = account_deposits.len()
            }

            let mut i = start;
            loop {
                if i == end {
                    break;
                }
                let key = account_deposits[i];
                keys.append(key);
                i += 1;
            };
            keys
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _remove_account_withdrawal(
            ref self: ContractState, key: felt252, account: ContractAddress
        ) {
            let mut account_withdrawals = self.account_withdrawals.read(account);
            let mut i = 0;
            loop {
                if i == account_withdrawals.len() {
                    break;
                }
                let withdrawal_key: felt252 = account_withdrawals[i];
                if withdrawal_key == key {
                    let mut last_key_maybe = account_withdrawals.pop_front();
                    match last_key_maybe {
                        Option::Some(last_key) => {
                            // If the list is empty, then there's no need to replace an existing key
                            if account_withdrawals.len() == 0 {
                                break;
                            }
                            account_withdrawals.set(i, last_key);
                        },
                        Option::None => {
                            // This case should never happen, because index is always < length
                            break;
                        }
                    }
                    break;
                }
                i += 1;
            }
        }

        fn _remove_account_order(ref self: ContractState, key: felt252, account: ContractAddress) {
            let mut account_orders = self.account_orders.read(account);
            let mut i = 0;
            loop {
                if i == account_orders.len() {
                    break;
                }
                let order_key: felt252 = account_orders[i];
                if order_key == key {
                    let mut last_key_maybe = account_orders.pop_front();
                    match last_key_maybe {
                        Option::Some(last_key) => {
                            // If the list is empty, then there's no need to replace an existing key
                            if account_orders.len() == 0 {
                                break;
                            }
                            account_orders.set(i, last_key);
                        },
                        Option::None => {
                            // This case should never happen, because index is always < length
                            break;
                        }
                    }
                    break;
                }
                i += 1;
            }
        }

        fn _remove_account_deposit(
            ref self: ContractState, key: felt252, account: ContractAddress
        ) {
            let mut account_deposits = self.account_deposits.read(account);
            let mut i = 0;
            loop {
                if i == account_deposits.len() {
                    break;
                }
                let deposit_key = account_deposits[i];
                if deposit_key == key {
                    let mut last_key_maybe = account_deposits.pop_front();
                    match last_key_maybe {
                        Option::Some(last_key) => {
                            // If the list is empty, then there's no need to replace an existing key
                            if account_deposits.len() == 0 {
                                break;
                            }
                            account_deposits.set(i, last_key);
                        },
                        Option::None => {
                            // This case should never happen, because index is always < length
                            break;
                        }
                    }
                    break;
                }
                i += 1;
            }
        }

        fn _remove_account_position(
            ref self: ContractState, key: felt252, account: ContractAddress
        ) {
            let mut account_positions = self.account_positions.read(account);
            let mut i = 0;
            loop {
                if i == account_positions.len() {
                    break;
                }
                let position_key: felt252 = account_positions[i];
                if position_key == key {
                    let mut last_key_maybe = account_positions.pop_front();
                    match last_key_maybe {
                        Option::Some(last_key) => {
                            // If the list is empty, then there's no need to replace an existing key
                            if account_positions.len() == 0 {
                                break;
                            }
                            account_positions.set(i, last_key);
                        },
                        Option::None => {
                            // This case should never happen, because index is always < length
                            break;
                        }
                    }
                    break;
                }
                i += 1;
            }
        }
    }
}
