//! Library for exchange helper functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
use starknet::info::get_block_number;
use satoru::exchange::error::ExchangeError;
use satoru::data::keys;
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};

/// Validates that request age is lower than request age expiration.
/// # Arguments
/// * `data_store` - The contract that provides access to data stored on-chain.
/// * `created_at_block` - The block the request was created at.
/// * `request_type` - The type of the created request.
fn validate_request_cancellation(
    data_store: IDataStoreSafeDispatcher, created_at_block: u64, request_type: felt252
) {
    let request_expiration_age = data_store.get_u128(keys::request_expiration_block_age()).unwrap();
    let request_age = get_block_number() - created_at_block;

    if request_age.into() < request_expiration_age {
        panic(array![ExchangeError::REQUEST_NOT_YET_CANCELLABLE, request_type]);
    };
}
