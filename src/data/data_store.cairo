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
    // STORAGE
    #[storage]
    struct Storage {
        felt252_values: LegacyMap::<felt252, felt252>, 
    }

    // CONSTRUCTOR
    #[constructor]
    fn constructor(ref self: ContractState) { // TODO: Add constructor logic here.
    // * Add role management to ensure proper access of some functions.
    }

    // EXTERNAL FUNCTIONS
    #[external(v0)]
    impl DataStore of super::IDataStore<ContractState> {
        fn get_felt252(ref self: ContractState, key: felt252) -> felt252 {
            return self.felt252_values.read(key);
        }

        fn set_felt252(ref self: ContractState, key: felt252, value: felt252) {
            self.felt252_values.write(key, value);
        }
    }
}
