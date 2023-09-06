// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// Satoru imports
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::utils::error::ReentrancyGuardError;

const REENTRANCY_GUARD_STATUS: felt252 = 'REENTRANCY_GUARD_STATUS';

/// Modifier to avoid reentrancy.
fn non_reentrant_before(data_store: IDataStoreDispatcher) {
    let status = match data_store.get_bool(REENTRANCY_GUARD_STATUS) {
        Option::Some(v) => v,
        Option::None => false,
    }; // Read key from Data Store

    assert(!status, ReentrancyGuardError::REENTRANT_CALL);

    data_store.set_bool(REENTRANCY_GUARD_STATUS, true);
}

/// Modifier to avoid reentrancy.
fn non_reentrant_after(data_store: IDataStoreDispatcher) { // Return key to default value
    data_store.set_bool(REENTRANCY_GUARD_STATUS, false);
}
