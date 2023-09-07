//! Data store for all general state values.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
use core::traits::Into;
use starknet::ContractAddress;
use satoru::market::market::Market;
use satoru::order::order::Order;
use satoru::withdrawal::withdrawal::Withdrawal;

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
    fn get_market(self: @TContractState, key: felt252) -> Option<Market>;

    /// Set a market value for the given key.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `value` - The value to set.
    fn set_market(ref self: TContractState, key: felt252, market: Market);


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

    //TODO: Update u128 to i128 when Serde and Store for i128 implementations are released.
    // *************************************************************************
    //                          int128 related functions.
    // *************************************************************************
    /// Get a int value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_i128(self: @TContractState, key: felt252) -> u128;

    /// Set the int value for the given key.
    /// # Arguments
    /// `key` - The key of the value
    /// `value` - The value to set
    /// # Return
    /// The int value for the key.
    fn set_i128(ref self: TContractState, key: felt252, value: u128);


    /// Delete a i128 value for the given key.
    /// # Arguments
    /// * `key` - The key to delete the value for.
    fn remove_i128(ref self: TContractState, key: felt252);

    /// Add input to existing value.
    /// # Arguments
    /// * `key` - The key to add the value to.
    /// * `value` - The value to add.
    fn increment_i128(ref self: TContractState, key: felt252, value: u128) -> u128;

    /// Subtract input from existing value.
    /// # Arguments
    /// * `key` - The key to subtract the value from.
    /// * `value` - The value to subtract.
    fn decrement_i128(ref self: TContractState, key: felt252, value: u128) -> u128;
}

#[starknet::contract]
mod DataStore {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::traits::TryInto;
    use starknet::{get_caller_address, ContractAddress, contract_address_const,};
    use nullable::NullableTrait;
    use zeroable::Zeroable;
    use alexandria_storage::list::{ListTrait, List};
    use debug::PrintTrait;

    // Local imports.
    use satoru::role::role;
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::market::market::{Market, ValidateMarket};
    use satoru::order::order::Order;
    use satoru::withdrawal::{withdrawal::Withdrawal, error::WithdrawalError};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        role_store: IRoleStoreDispatcher,
        felt252_values: LegacyMap::<felt252, felt252>,
        u256_values: LegacyMap::<felt252, u256>,
        u128_values: LegacyMap::<felt252, u128>,
        i128_values: LegacyMap::<felt252, u128>,
        address_values: LegacyMap::<felt252, ContractAddress>,
        bool_values: LegacyMap::<felt252, Option<bool>>,
        market_values: LegacyMap::<felt252, Market>,
        order_values: LegacyMap::<felt252, Order>,
        withdrawals: List<Withdrawal>,
        account_withdrawals: LegacyMap<ContractAddress, List<felt252>>,
        withdrawal_indexes: LegacyMap::<felt252, usize>,
    }

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
        fn get_i128(self: @ContractState, key: felt252) -> u128 {
            self.i128_values.read(key)
        }

        fn set_i128(ref self: ContractState, key: felt252, value: u128) {
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

        fn increment_i128(ref self: ContractState, key: felt252, value: u128) -> u128 {
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

        fn decrement_i128(ref self: ContractState, key: felt252, value: u128) -> u128 {
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

        fn get_market(self: @ContractState, key: felt252) -> Option<Market> {
            let market = self.market_values.read(key);

            // We use the zero address to indicate that the market does not exist.
            if market.index_token.is_zero() {
                Option::None
            } else {
                Option::Some(market)
            }
        }

        fn set_market(ref self: ContractState, key: felt252, market: Market) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);

            // Assert that the market is valid.
            market.assert_valid();

            // Set the value.
            self.market_values.write(key, market);
        }

        // *************************************************************************
        //                      Order related functions.
        // *************************************************************************

        fn get_order(self: @ContractState, key: felt252) -> Option<Order> {
            let order = self.order_values.read(key);

            // We use the zero address to indicate that the order does not exist.
            if order.account.is_zero() {
                Option::None
            } else {
                Option::Some(order)
            }
        }

        fn set_order(ref self: ContractState, key: felt252, order: Order) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);

            // Set the value.
            self.order_values.write(key, order);
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
            assert(withdrawal.account != 0.try_into().unwrap(), WithdrawalError::CANT_BE_ZERO);

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
                let withdrawal = withdrawals[i];
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
                let key = account_withdrawals[i];
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
                let withdrawal_key = account_withdrawals[i];
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
    }
}
