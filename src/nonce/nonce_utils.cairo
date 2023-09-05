use poseidon::poseidon_hash_span;

// Local imports.
use satoru::data::keys;
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};

/// Get the current nonce value.
/// # Arguments
/// * `data_store` - The data store to use.
/// # Returns
/// Return the current nonce value.
fn get_current_nonce(data_store: IDataStoreSafeDispatcher) -> u128 {
    data_store.get_u128(keys::nonce()).expect('satoru/datastore-failure')
}

/// Increment the current nonce value.
/// # Arguments
/// * `data_store` - The data store to use.
/// # Returns
/// Return the new nonce value.
fn increment_nonce(data_store: IDataStoreSafeDispatcher) -> u128 {
    data_store.increment_u128(keys::nonce(), 1).expect('satoru/datastore-failure')
}

/// Creates a felt252 hash using the next nonce. The nonce can also be used directly as a key,
/// but for positions,a felt252 key derived from a hash of the position values is used instead.
/// # Arguments
/// * `data_store` - The data store to use.
/// # Returns
/// Return felt252 hash using the next nonce value
fn get_next_key(data_store: IDataStoreSafeDispatcher) -> felt252 {
    let nonce = increment_nonce(data_store);
    let data = array![data_store.contract_address.into(), nonce.into()];
    poseidon_hash_span(data.span())
}
