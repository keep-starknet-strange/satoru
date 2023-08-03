use core::traits::Into;
//! Data store for all general state values

// *************************************************************************
// Interface of the `DataStore` contract.
// *************************************************************************
#[starknet::interface]
trait IDataStore<TContractState> {
    // *************************************************************************
    // Felt252 related functions.
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
    fn delete_felt252(ref self: TContractState, key: felt252);
    /// Add input to existing value.
    /// # Arguments
    /// * `key` - The key to add the value to.
    /// * `value` - The value to add.
    fn apply_delta_to_felt252(ref self: TContractState, key: felt252, value: felt252) -> felt252;

    // *************************************************************************
    // U256 related functions.
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
    fn delete_u256(ref self: TContractState, key: felt252);
}

#[starknet::contract]
mod DataStore {
    // IMPORTS
    use gojo::role::role;
    use gojo::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use starknet::{get_caller_address, ContractAddress};
    use nullable::NullableTrait;

    // STORAGE
    #[storage]
    struct Storage {
        role_store: IRoleStoreDispatcher,
        felt252_values: LegacyMap::<felt252, felt252>,
        u256_values: LegacyMap::<felt252, u256>,
    }

    // CONSTRUCTOR
    #[constructor]
    fn constructor(ref self: ContractState, role_store_address: ContractAddress) {
        self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
    }

    // EXTERNAL FUNCTIONS
    #[external(v0)]
    impl DataStore of super::IDataStore<ContractState> {
        fn get_felt252(self: @ContractState, key: felt252) -> felt252 {
            return self.felt252_values.read(key);
        }

        fn set_felt252(ref self: ContractState, key: felt252, value: felt252) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Set the value.
            self.felt252_values.write(key, value);
        }

        fn delete_felt252(ref self: ContractState, key: felt252) {
            // Check that the caller has permission to delete the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Delete the value.
            self.felt252_values.write(key, Default::default());
        }

        fn apply_delta_to_felt252(
            ref self: ContractState, key: felt252, value: felt252
        ) -> felt252 {
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
            return new_value;
        }

        fn get_u256(self: @ContractState, key: felt252) -> u256 {
            return self.u256_values.read(key);
        }

        fn set_u256(ref self: ContractState, key: felt252, value: u256) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Set the value.
            self.u256_values.write(key, value);
        }

        fn delete_u256(ref self: ContractState, key: felt252) {
            // Check that the caller has permission to delete the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            // Delete the value.
            self.u256_values.write(key, Default::default());
        }
    }
}
