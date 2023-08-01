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
}

#[starknet::contract]
mod DataStore {
    // IMPORTS
    use gojo::role::role;
    use gojo::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use starknet::{get_caller_address, ContractAddress};

    // STORAGE
    #[storage]
    struct Storage {
        role_store_address: ContractAddress,
        felt252_values: LegacyMap::<felt252, felt252>,
    }

    // CONSTRUCTOR
    #[constructor]
    fn constructor(ref self: ContractState, role_store_address: ContractAddress) {
        self.role_store_address.write(role_store_address);
    }

    // EXTERNAL FUNCTIONS
    #[external(v0)]
    impl DataStore of super::IDataStore<ContractState> {
        fn get_felt252(ref self: ContractState, key: felt252) -> felt252 {
            return self.felt252_values.read(key);
        }

        fn set_felt252(ref self: ContractState, key: felt252, value: felt252) {
            let caller = get_caller_address();

            // Check that the caler has permission to set the value.
            IRoleStoreDispatcher {
                contract_address: self.role_store_address.read()
            }.assert_only_role(caller, role::ROLE_ADMIN);

            self.felt252_values.write(key, value);
        }
    }
}
