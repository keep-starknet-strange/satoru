// *************************************************************************
//                                  IMPORTS
// *************************************************************************
use satoru::utils::error::UtilsError;
use alexandria_math::BitShift;
// Core lib imports.

/// Validate that the index is unique.

#[derive(Drop)]
struct Mask {
    bits: u256,
}

#[generate_trait]
impl MaskImpl of MaskTrait {
    fn validate_unique_and_set_index(self: @Mask, index: u256) {
        let mut bits = *self.bits;
        validate_unique_and_set_index(ref bits, index);
    }
}

fn validate_unique_and_set_index(ref mask: u256, index: u256) {
    if index >= 256 {
        panic_with_felt252(UtilsError::MASK_OUT_OF_BOUNDS);
    }

    let bit: u256 = BitShift::shl(1, index);

    if mask & bit != 0 {
        panic_with_felt252(UtilsError::MASK_INDEX_NOT_UNIQUE);
    }

    mask = mask | bit;
}
