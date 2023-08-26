// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.

/// Gets the value of the element at the specified index in the given array. If the index is out of bounds, returns 0.
/// # Arguments
/// * `arr` - the array to get the element of.
/// * `index` - The index to get the element at.
/// # Returns
/// Element at index if found, else 0.
fn get(arr: Span<felt252>, index: u128) -> felt252 {
    // TODO
    0
}

/// Determines whether all of the elements in the given array are equal to the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// Wether all of the elements in the array are equal to the given value.
fn are_equal_to(arr: Span<u128>, value: u128) -> bool {
    // TODO
    true
}

/// Determines whether all of the elements in the given array are greater than the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are greater than the specified value, false otherwise.
fn are_greater_than(arr: Span<u128>, value: u128) -> bool {
    // TODO
    true
}

/// Determines whether all of the elements in the given array are greater than or equal to the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are greater than or equal to the specified value, false otherwise.
fn are_greater_than_or_equal_to(arr: Span<u128>, value: u128) -> bool {
    // TODO
    true
}

/// Determines whether all of the elements in the given array are less than the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are less than the specified value, false otherwise.
fn are_less_than(arr: Span<u128>, value: u128) -> bool {
    // TODO
    true
}

/// Determines whether all of the elements in the given array are less than or equal to the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are less than or equal to the specified value, false otherwise.
fn are_less_than_or_equal_to(arr: Span<u128>, value: u128) -> bool {
    // TODO
    true
}

/// Gets the median value of the elements in the given array. For arrays with an odd number of elements,
/// returns the element at the middle index. For arrays with an even number of elements, returns the average
/// of the two middle elements.
/// # Arguments
/// * `arr` - the array to get the median of.
/// # Returns
/// the median value of the elements in the given array.
fn get_median(arr: Span<u128>) -> u128 {
    // TODO
    0
}

/// Gets the uncompacted value at the specified index in the given array of compacted values.
/// # Arguments
/// * `compacted_values` - the array of compacted values to get the uncompacted value from.
/// * `index` - the index of the uncompacted value in the array.
/// * `compacted_value_bit_length` - the length of each compacted value, in bits.
/// * `bit_mask` - the bitmask to use to extract the uncompacted value from the compacted value.
/// * `label` - the array of compacted values to get the uncompacted value from.
/// # Returns
/// The uncompacted value at the specified index in the array of compacted values.
fn get_uncompacted_value(
    compacted_values: Span<u128>,
    index: u128,
    compacted_value_bit_length: u128,
    bit_mask: u128,
    label: felt252
) -> u128 {
    // TODO
    0
}
