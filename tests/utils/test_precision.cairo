// IMPORTS
use satoru::utils::precision;
use satoru::utils::precision::{ FLOAT_PRECISION, FLOAT_PRECISION_SQRT, WEI_PRECISION, BASIS_POINTS_DIVISOR, FLOAT_TO_WEI_DIVISOR };
use integer::BoundedInt;
use debug::PrintTrait;
#[test]
fn test_apply_factor_u128() {
    let value: u128 = 10;
    let factor: u128 = 1_000_000_000_000_000_000_000_000_000_000_000;
    let result = precision::apply_factor_u128(value, factor);
    assert(result == 10000, 'should be 10000.');
}

#[test]
fn test_apply_factor_i128() {
    let value: u128 = 10;
    let factor: i128 = -1_000_000_000_000_000_000_000_000_000_000_000;
    let result = precision::apply_factor_i128(value, factor);
    assert(result == -10000, 'should be -1OOOO.');
}

#[test]
fn test_apply_factor_roundup_magnitude_positive() {
    let value: u128 = 15;
    let factor: i128 = 300_000_000_000_000_000_000_000_000_000;
    let roundup_magnitude = true;
    let result = precision::apply_factor_roundup_magnitude(value, factor, roundup_magnitude);
    assert(result == 5, 'should be 5.');
}

// #[test]
// fn test_apply_factor_roundup_magnitude_negative() {
//     let value: u128 = 10;
//     let factor: i128 = -3;
//     let roundup_magnitude = true;
//     let result = apply_factor_roundup_magnitude(value, factor, roundup_magnitude);
//     assert_eq!(result, -4, "should be -4 when rounding up.");
// }

// #[test]
// fn test_apply_factor_roundup_magnitude_no_rounding() {
//     let value: u128 = 10;
//     let factor: i128 = 3;
//     let roundup_magnitude = false;
//     let result = apply_factor_roundup_magnitude(value, factor, roundup_magnitude);
//     assert_eq!(result, 3, "should be 3 without rounding.");
// }


// #[test]
// fn test_mul_div_ival() {
//     let value: i128 = 10;
//     let numerator: u128 = 2;
//     let denominator: u128 = 4;
//     let result = precision::mul_div_ival(value, numerator, denominator);
//     assert(result == 5, "10 * 2 / 4 should be 5.");
// }

// #[test]
// fn test_mul_div_inum() {
//     let value: u128 = 10;
//     let numerator: i128 = -2;
//     let denominator: u128 = 4;
//     let result = precision::mul_div_inum(value, numerator, denominator);
//     assert(result == -5, "10 * -2 / 4 should be -5.");
// }

// #[test]
// fn test_mul_div_inum_roundup() {
//     let value: u128 = 10;
//     let numerator: i128 = 3;
//     let denominator: u128 = 4;
//     let roundup_magnitude: bool = true;
//     let result = precision::mul_div_inum_roundup(value, numerator, denominator, roundup_magnitude);
//     assert(result == 4, "10 * 3 / 4 (rounded up) should be 4.");
// }

// #[test]
// fn test_mul_div_roundup() {
//     let value: u128 = 10;
//     let numerator: u128 = 3;
//     let denominator: u128 = 4;
//     let roundup_magnitude: bool = true;
//     let result = precision::mul_div_roundup(value, numerator, denominator, roundup_magnitude);
//     assert(result == 8, "10 * 3 / 4 (rounded up) should be 8.");
// }
