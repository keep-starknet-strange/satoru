// *************************************************************************
//                                  IMPORTS
// *************************************************************************
use satoru::utils::error::UtilsError;
use alexandria_math::BitShift;
// Core lib imports.

/// Validate that the index is unique.
fn validate_unique_and_set_index(ref mask: u128, index: u128) {
    if index >= 128 {
        panic_with_felt252(UtilsError::MASK_OUT_OF_BOUNDS);
    }

    let bit: u128 = BitShift::shl(1, index);

    if mask & bit != 0 {
        panic_with_felt252(UtilsError::MASK_INDEX_NOT_UNIQUE);
    }

    mask = mask | bit;
}
