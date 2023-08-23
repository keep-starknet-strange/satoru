//! Library to keep track of and increment nonce value.


#[starknet::contract]
mod NonceUtils {
    // Local imports.
    use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
    /// Storage is empty since the contract is designed to be stateless and called as a library only.
    #[storage]
    struct Storage {}

    // *************************************************************************
    //                          INTERNAL FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Get the current nonce value.
        /// # Arguments
        /// * `data_store` - The data store to use.
        /// # Returns
        /// Return the current nonce value.
        #[inline(always)]
        fn get_current_nonce(self: @ContractState, data_store: IDataStoreSafeDispatcher) -> u128 {
            //TODO
            0
        }

        /// Increment the current nonce value.
        /// # Arguments
        /// * `data_store` - The data store to use.
        /// # Returns
        /// Return the new nonce value.
        #[inline(always)]
        fn increment_nonce(ref self: ContractState, data_store: IDataStoreSafeDispatcher) -> u128 {
            //TODO
            0
        }

        /// Creates a felt252 hash using the next nonce. The nonce can also be used directly as a key, but for positions, a felt252 key derived from a hash of the position values is used instead.
        /// # Arguments
        /// * `data_store` - The data store to use.
        /// # Returns
        /// Return felt252 hash using the next nonce value
        #[inline(always)]
        fn get_next_key(ref self: ContractState, data_store: IDataStoreSafeDispatcher) -> felt252 {
            //TODO
            0
        }
    }
}
