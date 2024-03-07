use starknet::ContractAddress;
use poseidon::poseidon_hash_span;

// Local imports.
use satoru::data::keys;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};

/// Get the current nonce value.
/// # Arguments
/// * `data_store` - The data store to use.
/// # Returns
/// Return the current nonce value.
fn get_current_nonce(data_store: IDataStoreDispatcher) -> u256 {
    data_store.get_u256(keys::nonce())
}

/// Increment the current nonce value.
/// # Arguments
/// * `data_store` - The data store to use.
/// # Returns
/// Return the new nonce value.
fn increment_nonce(data_store: IDataStoreDispatcher) -> u256 {
    data_store.increment_u256(keys::nonce(), 1)
}

/// Creates a felt252 hash using the next nonce. The nonce can also be used directly as a key,
/// but for positions,a felt252 key derived from a hash of the position values is used instead.
/// # Arguments
/// * `data_store` - The data store to use.
/// # Returns
/// Return felt252 hash using the next nonce value
fn get_next_key(data_store: IDataStoreDispatcher) -> felt252 {
    let nonce = increment_nonce(data_store);
    compute_key(data_store.contract_address, nonce)
}

fn compute_key(data_store_address: ContractAddress, nonce: u256) -> felt252 {
    let data = array![data_store_address.into(), nonce.try_into().expect('u256 into felt failed')];
    poseidon_hash_span(data.span())
}
