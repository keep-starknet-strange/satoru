// IMPORTS
use array::ArrayTrait;
use poseidon::poseidon_hash_span;

/// Hash a single felt value using Poseidon hash function.
/// # Arguments
/// * `value` - The value to hash.
/// # Returns
/// * The hash of the value.
fn hash_poseidon_single(value: felt252) -> felt252 {
    let mut data = array![];
    data.append(value);
    poseidon_hash_span(data.span())
}
