use core::traits::Into;
//! Data store for all general state values

#[starknet::interface]
trait IDataStore<TContractState> {
    /// Get a felt252 value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_felt252(ref self: TContractState, key: felt252) -> felt252;
    /// Set a felt252 value for the given key.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `value` - The value to set.
    fn set_felt252(ref self: TContractState, key: felt252, value: felt252);

    /// Get a u256 value for the given key.
    /// # Arguments
    /// * `key` - The key to get the value for.
    /// # Returns
    /// The value for the given key.
    fn get_u256(ref self: TContractState, key: felt252) -> u256;
    /// Set a u256 value for the given key.
    /// # Arguments
    /// * `key` - The key to set the value for.
    /// * `value` - The value to set.
    fn set_u256(ref self: TContractState, key: felt252, value: u256);
}

#[starknet::contract]
mod DataStore {
    // IMPORTS
    use gojo::role::role;
    use gojo::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use starknet::{get_caller_address, ContractAddress};
    use debug::PrintTrait;
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
        fn get_felt252(ref self: ContractState, key: felt252) -> felt252 {
            return self.felt252_values.read(key);
        }

        fn set_felt252(ref self: ContractState, key: felt252, value: felt252) {
            let caller = get_caller_address();

            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(caller, role::CONTROLLER);

            self.felt252_values.write(key, value);
        }

        fn get_u256(ref self: ContractState, key: felt252) -> u256 {
            return self.u256_values.read(key);
        }

        fn set_u256(ref self: ContractState, key: felt252, value: u256) {
            let caller = get_caller_address();

            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(caller, role::ROLE_ADMIN);

            self.u256_values.write(key, value);
        }
    }
}
