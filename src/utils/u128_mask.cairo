// *************************************************************************
//                                  IMPORTS
// *************************************************************************
use satoru::utils::error::UtilsError;
use alexandria_math::BitShift;
use debug::PrintTrait;
// Core lib imports.

/// Validate that the index is unique.

#[derive(Drop)]
struct Mask {
    bits: u128,
}

#[generate_trait]
impl MaskImpl of MaskTrait {
    fn validate_unique_and_set_index(self: @Mask, index: u128) {
        let mut bits = *self.bits;
        validate_unique_and_set_index(ref bits, index);
    }
}

fn validate_unique_and_set_index(ref mask: u128, index: u128) {
    // if index >= 128 {
    //     panic_with_felt252(UtilsError::MASK_OUT_OF_BOUNDS);
    // }

    let bit: u128 = BitShift::shl(1, index);
    // if mask & bit != 0 {
    //     panic_with_felt252(UtilsError::MASK_INDEX_NOT_UNIQUE);
    // }

    mask = mask | bit;
}
