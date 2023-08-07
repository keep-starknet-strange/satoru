//! Data store for all general state values

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
use core::traits::Into;
use starknet::ContractAddress;
use gojo::market::market::Market;

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
    //                          U256 related functions.
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
}

#[starknet::contract]
mod DataStore {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::{get_caller_address, ContractAddress, contract_address_const};
    use nullable::NullableTrait;
    use option::OptionTrait;
    use zeroable::Zeroable;

    // Local imports.
    use gojo::role::role;
    use gojo::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use gojo::market::market::{Market, ValidateMarket};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        role_store: IRoleStoreDispatcher,
        felt252_values: LegacyMap::<felt252, felt252>,
        u256_values: LegacyMap::<felt252, u256>,
        address_values: LegacyMap::<felt252, ContractAddress>,
        // FIXME: #9
        // For some reason it's not possible to store `Option<bool>` in the storage.
        // Error: Trait has no implementation in context: core::starknet::storage_access::Store::<core::option::Option::<core::bool>>
        //bool_values: LegacyMap::<felt252, Option<bool>>,
        market_values: LegacyMap::<felt252, Market>,
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
            //self.bool_values.read(key)
            Option::None(())
        }

        fn set_bool(
            ref self: ContractState, key: felt252, value: bool
        ) { // Check that the caller has permission to set the value.
        //self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
        // Set the value.
        //self.bool_values.write(key, Option::Some(value));
        }

        fn remove_bool(
            ref self: ContractState, key: felt252
        ) { // Check that the caller has permission to delete the value.
        //self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
        // Delete the value.
        //self.bool_values.write(key, Option::None(()));
        }

        // *************************************************************************
        //                      Market related functions.
        // *************************************************************************

        fn get_market(self: @ContractState, key: felt252) -> Option<Market> {
            let market = self.market_values.read(key);

            // We use the zero address to indicate that the market does not exist.
            if market.index_token.is_zero() {
                Option::None(())
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
    }
}
