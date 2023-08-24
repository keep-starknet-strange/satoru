//! Library to keep track of and increment nonce value.

// Local imports.

use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};

// *************************************************************************
//                          INTERNAL FUNCTIONS
// *************************************************************************

    /// Get the current nonce value.
    /// # Arguments
    /// * `data_store` - The data store to use.
    /// # Returns
    /// Return the current nonce value.
    fn get_current_nonce(self: @ContractState, data_store: IDataStoreSafeDispatcher) -> u128 {
        //TODO
        0
    }
    
    /// Increment the current nonce value.
    /// # Arguments
    /// * `data_store` - The data store to use.
    /// # Returns
    /// Return the new nonce value.
    fn increment_nonce(ref self: ContractState, data_store: IDataStoreSafeDispatcher) -> u128 {
        //TODO
        0
    }    
    
    /// Creates a felt252 hash using the next nonce. The nonce can also be used directly as a key, but for positions, a felt252 key derived from a hash of the position values is used instead.
    /// # Arguments
    /// * `data_store` - The data store to use.
    /// # Returns
    /// Return felt252 hash using the next nonce value
    fn get_next_key(ref self: ContractState, data_store: IDataStoreSafeDispatcher) -> felt252 {
        //TODO
        0
    }