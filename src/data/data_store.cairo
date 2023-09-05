//! Data store for all general state values.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
use core::traits::Into;
use starknet::ContractAddress;
use satoru::market::market::Market;
use satoru::order::order::Order;

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
    use starknet::{get_caller_address, ContractAddress, contract_address_const,};
    use nullable::NullableTrait;
    use zeroable::Zeroable;

    // Local imports.
    use satoru::role::role;
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::market::market::{Market, ValidateMarket};
    use satoru::order::order::Order;

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
    }
}
