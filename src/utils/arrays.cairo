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
fn get(arr: Span<felt252>, index: usize) -> felt252 {
    match arr.get(index) {
        Option::Some(value) => *value.unbox(),
        Option::None => 0,
    }
}

/// Determines whether all of the elements in the given array are equal to the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// Wether all of the elements in the array are equal to the given value.
fn are_eq(mut arr: Span<u128>, value: u128) -> bool {
    loop {
        match arr.pop_front() {
            Option::Some(item) => {
                if *item != value {
                    break false;
                }
            },
            Option::None => {
                break true;
            },
        };
    }
}

/// Determines whether all of the elements in the given array are greater than the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are greater than the specified value, false otherwise.
fn are_gt(mut arr: Span<u128>, value: u128) -> bool {
    loop {
        match arr.pop_front() {
            Option::Some(item) => {
                if *item <= value {
                    break false;
                }
            },
            Option::None => {
                break true;
            },
        };
    }
}

/// Determines whether all of the elements in the given array are greater than or equal to the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are greater than or equal to the specified value, false otherwise.
fn are_gte(mut arr: Span<u128>, value: u128) -> bool {
    loop {
        match arr.pop_front() {
            Option::Some(item) => {
                if *item < value {
                    break false;
                }
            },
            Option::None => {
                break true;
            },
        };
    }
}

/// Determines whether all of the elements in the given array are less than the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are less than the specified value, false otherwise.
fn are_lt(mut arr: Span<u128>, value: u128) -> bool {
    loop {
        match arr.pop_front() {
            Option::Some(item) => {
                if *item >= value {
                    break false;
                }
            },
            Option::None => {
                break true;
            },
        };
    }
}

/// Determines whether all of the elements in the given array are less than or equal to the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are less than or equal to the specified value, false otherwise.
fn are_lte(mut arr: Span<u128>, value: u128) -> bool {
    loop {
        match arr.pop_front() {
            Option::Some(item) => {
                if *item > value {
                    break false;
                }
            },
            Option::None => {
                break true;
            },
        };
    }
}

/// Gets the median value of the elements in the given array. For arrays with an odd number of elements,
/// returns the element at the middle index. For arrays with an even number of elements, returns the average
/// of the two middle elements.
/// # Arguments
/// * `arr` - the array to get the median of.
/// # Returns
/// the median value of the elements in the given array.
fn get_median(arr: Span<u128>) -> u128 {
    if arr.len() % 2 == 1 {
        *arr.get(arr.len() / 2).unwrap().unbox()
    } else {
        let left = *arr.get(arr.len() / 2 - 1).unwrap().unbox();
        let right = *arr.get(arr.len() / 2).unwrap().unbox();
        (left + right) / 2
    }
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
    index: usize,
    compacted_value_bit_length: usize,
    bit_mask: u128,
    label: felt252
) -> u128 {
    let compacted_values_per_slot = 128 / compacted_value_bit_length;

    let slot_index = index / compacted_values_per_slot;
    if slot_index >= compacted_values.len() {
        panic(array!['CompactedArrayOutOfBounds', index.into(), slot_index.into(), label]);
    }

    let slot_bits = *compacted_values.at(slot_index);
    let offset = (index - slot_index * compacted_values_per_slot) * compacted_value_bit_length;

    let value = (slot_bits / pow(2, offset)) & bit_mask;

    value
}

/// Raise a number to a power, computes x^n.
/// * `x` - The number to raise.
/// * `n` - The exponent.
/// # Returns
/// * `u128` - The result of x raised to the power of n.
fn pow(x: u128, n: usize) -> u128 {
    if n == 0 {
        1
    } else if n == 1 {
        x
    } else if (n & 1) == 1 {
        x * pow(x * x, n / 2)
    } else {
        pow(x * x, n / 2)
    }
}
