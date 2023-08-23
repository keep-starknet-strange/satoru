//! Library to keep track of and increment nonce value.

#[starknet::contract]
mod NonceUtils {
    /// Storage is empty since the contract is designed to be stateless and called as a library only.
    #[storage]
    struct Storage {}

    // *************************************************************************
    //                          INTERNAL FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Get the current nonce value.
        fn get_current_nonce(self: @TContractState, data_store: DataStore) -> u128 {
            //TODO
            0
        }

        /// Increment the current nonce value.
        fn increment_nonce(self: @TContractState, data_store: DataStore) -> u128{
            //TODO
            0
        }
        
        /// Creates a bytes32 hash using the next nonce. The nonce can also be used directly as a key, but for positions, a bytes32 key derived from a hash of the position values is used instead.
        fn get_next_key(self: @TContractState, data_store: DataStore) -> felt252 {
            //TODO
            0
        }
    }
}