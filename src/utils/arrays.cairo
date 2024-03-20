// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use satoru::utils::{error_utils, calc};

/// Gets the value of the element at the specified index in the given array. If the index is out of bounds, returns 0.
/// # Arguments
/// * `arr` - the array to get the element of.
/// * `index` - The index to get the element at.
/// # Returns
/// Element at index if found, else 0.
fn get_felt252(arr: Span<felt252>, index: usize) -> felt252 {
    match arr.get(index) {
        Option::Some(value) => *value.unbox(),
        Option::None => 0,
    }
}

fn get_u256(arr: @Array<u256>, index: usize) -> u256 {
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
fn are_eq(mut arr: Span<u256>, value: u256) -> bool {
    loop {
        match arr.pop_front() {
            Option::Some(item) => { if *item != value {
                break false;
            } },
            Option::None => { break true; },
        };
    }
}

/// Determines whether all of the elements in the given array are greater than the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are greater than the specified value, false otherwise.
fn are_gt(mut arr: Span<u256>, value: u256) -> bool {
    loop {
        match arr.pop_front() {
            Option::Some(item) => { if *item <= value {
                break false;
            } },
            Option::None => { break true; },
        };
    }
}

/// For u64 typed array determines whether all of the elements in the given array are greater than or equal to the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are greater than or equal to the specified value, false otherwise.
fn are_gte_u64(mut arr: Span<u64>, value: u64) -> bool {
    loop {
        match arr.pop_front() {
            Option::Some(item) => { if *item < value {
                break false;
            } },
            Option::None => { break true; },
        };
    }
}

/// Determines whether all of the elements in the given array are greater than or equal to the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are greater than or equal to the specified value, false otherwise.
fn are_gte(mut arr: Span<u256>, value: u256) -> bool {
    loop {
        match arr.pop_front() {
            Option::Some(item) => { if *item < value {
                break false;
            } },
            Option::None => { break true; },
        };
    }
}

/// Determines whether all of the elements in the given array are less than the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are less than the specified value, false otherwise.
fn are_lt(mut arr: Span<u256>, value: u256) -> bool {
    loop {
        match arr.pop_front() {
            Option::Some(item) => { if *item >= value {
                break false;
            } },
            Option::None => { break true; },
        };
    }
}

/// Determines whether all of the elements in the given array are less than or equal to the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are less than or equal to the specified value, false otherwise.
fn are_lte(mut arr: Span<u256>, value: u256) -> bool {
    loop {
        match arr.pop_front() {
            Option::Some(item) => { if *item > value {
                break false;
            } },
            Option::None => { break true; },
        };
    }
}

/// Determines whether all of the elements in the given array are less than or equal to the specified value.
/// # Arguments
/// * `arr` - the array to check the elements of.
/// * `value` - The value to compare the elements to.
/// # Returns
/// true if all of the elements in the array are less than or equal to the specified value, false otherwise.
fn are_lte_u64(mut arr: Span<u64>, value: u64) -> bool {
    loop {
        match arr.pop_front() {
            Option::Some(item) => { if *item > value {
                break false;
            } },
            Option::None => { break true; },
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
fn get_median(arr: Span<u256>) -> u256 {
    if arr.len() % 2 == 1 {
        *arr.get(arr.len() / 2).expect('array.get failed').unbox()
    } else {
        let left = *arr.get(arr.len() / 2 - 1).expect('array.get failed').unbox();
        let right = *arr.get(arr.len() / 2).expect('array.get failed').unbox();
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
    compacted_values: Span<u256>,
    index: usize,
    compacted_value_bit_length: usize,
    bit_mask: u256,
    label: felt252
) -> u256 {
    error_utils::check_division_by_zero(
        compacted_value_bit_length.into(), 'compacted_value_bit_length'
    );
    let compacted_values_per_slot = 256 / compacted_value_bit_length; // 256 / 32 = 8

    error_utils::check_division_by_zero(
        compacted_values_per_slot.into(), 'compacted_values_per_slot'
    );
    let slot_index = index / compacted_values_per_slot; // 1 / 4 = 0
    if slot_index >= compacted_values.len() {
        panic(array!['CompactedArrayOutOfBounds', index.into(), slot_index.into(), label]);
    }

    let slot_bits = *compacted_values.at(slot_index); // 4294967346000000
    let offset = (index - slot_index * compacted_values_per_slot)
        * compacted_value_bit_length; // = 32

    let value = (slot_bits / pow(2, offset))
        & bit_mask; // 4294967346000000 / 2^32 = 1000000 & bit_mask

    value
}

/// Raise a number to a power, computes x^n.
/// * `x` - The number to raise.
/// * `n` - The exponent.
/// # Returns
/// * `u256` - The result of x raised to the power of n.
fn pow(x: u256, n: usize) -> u256 {
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

use starknet::{ContractAddress, StorageBaseAddress, SyscallResult, Store};

impl StoreContractAddressSpan of Store<Span<ContractAddress>> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<Span<ContractAddress>> {
        StoreContractAddressSpan::read_at_offset(address_domain, base, 0)
    }

    fn write(
        address_domain: u32, base: StorageBaseAddress, value: Span<ContractAddress>
    ) -> SyscallResult<()> {
        StoreContractAddressSpan::write_at_offset(address_domain, base, 0, value)
    }

    fn read_at_offset(
        address_domain: u32, base: StorageBaseAddress, mut offset: u8
    ) -> SyscallResult<Span<ContractAddress>> {
        let mut arr: Array<ContractAddress> = ArrayTrait::new();

        // Read the stored array's length. If the length is superior to 255, the read will fail.
        let len: u8 = Store::<u8>::read_at_offset(address_domain, base, offset)
            .expect('Storage Span too large');
        offset += 1;

        // Sequentially read all stored elements and append them to the array.
        let exit = len + offset;
        loop {
            if offset >= exit {
                break;
            }

            let value = Store::<ContractAddress>::read_at_offset(address_domain, base, offset)
                .expect('read_at_offset failed');
            arr.append(value);
            offset += Store::<ContractAddress>::size();
        };

        // Return the array.
        Result::Ok(arr.span())
    }

    fn write_at_offset(
        address_domain: u32,
        base: StorageBaseAddress,
        mut offset: u8,
        mut value: Span<ContractAddress>
    ) -> SyscallResult<()> {
        // Store the length of the array in the first storage slot.
        let len: u8 = value.len().try_into().expect('Storage - Span too large');
        Store::<u8>::write_at_offset(address_domain, base, offset, len);
        offset += 1;

        // Store the array elements sequentially
        loop {
            match value.pop_front() {
                Option::Some(element) => {
                    Store::<
                        ContractAddress
                    >::write_at_offset(address_domain, base, offset, *element);
                    offset += Store::<felt252>::size();
                },
                Option::None(_) => { break Result::Ok(()); }
            };
        }
    }

    fn size() -> u8 {
        255 * Store::<felt252>::size()
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
fn get_uncompacted_value_u64(
    compacted_values: Span<u64>,
    index: usize,
    compacted_value_bit_length: usize,
    bit_mask: u64,
    label: felt252
) -> u64 {
    let compacted_values_per_slot = 64 / compacted_value_bit_length;

    let slot_index = index / compacted_values_per_slot;
    if slot_index >= compacted_values.len() {
        panic(array!['CompactedArrayOutOfBounds', index.into(), slot_index.into(), label]);
    }

    let slot_bits = *compacted_values.at(slot_index);
    let offset = (index - slot_index * compacted_values_per_slot) * compacted_value_bit_length;

    let value = (slot_bits / calc::pow_u64(2, offset)) & bit_mask;

    value
}
