// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// TODO EnumerableSet needs to be implemented before this.

/// Returns an array of felt252 values from the given set, starting at the given
/// start index and ending before the given end index..
/// # Arguments
/// * `set` - The set to get the values from.
/// * `start` - The starting index.
/// * `end` - The ending index.
/// # Returns
/// An array of felt252 values.
fn values_at_felt252() -> Array<felt252> { // TODO
    ArrayTrait::new()
}

/// Returns an array of ContractAddress values from the given set, starting at the given
/// start index and ending before the given end index..
/// # Arguments
/// * `set` - The set to get the values from.
/// * `start` - The starting index.
/// * `end` - The ending index.
/// # Returns
/// An array of ContractAddress values.
fn values_at_address() -> Array<ContractAddress> { // TODO
    ArrayTrait::new()
}

/// Returns an array of u256 values from the given set, starting at the given
/// start index and ending before the given end index..
/// # Arguments
/// * `set` - The set to get the values from.
/// * `start` - The starting index.
/// * `end` - The ending index.
/// # Returns
/// An array of u256 values.
fn values_at_u256() -> Array<u256> { // TODO
    ArrayTrait::new()
}
