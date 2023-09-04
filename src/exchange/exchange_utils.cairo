//! Library for exchange helper functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Local imports.
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};


/// Validates that request age is lower than request age expiration.
/// # Arguments
/// * `data_store` - The contract that provides access to data stored on-chain.
/// * `created_at_block` - The block the request was created at.
/// * `request_type` - The type of the created request.
fn validate_request_cancellation(
    data_store: IDataStoreSafeDispatcher, created_at_block: u64, request_type: felt252
) { // TODO
}
