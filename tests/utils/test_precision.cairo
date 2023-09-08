// IMPORTS
use satoru::utils::precision;
use satoru::utils::precision::{ FLOAT_PRECISION, FLOAT_PRECISION_SQRT, WEI_PRECISION, BASIS_POINTS_DIVISOR, FLOAT_TO_WEI_DIVISOR };
use integer::BoundedInt;

#[test]
fn test_apply_factor_u128() {
    let value: u128 = 10;
    let factor: u128 = 2;
    let result = precision::apply_factor_u128(value, factor);
    assert(result == 20, '10 * 2 should be 20.');
}


// #[test]
// fn test_apply_factor_i128() {
//     assert( precision::apply_factor_i128(10, 2) == 20, '10 * 2 should be 20.' );
// }

// #[test]
// fn test_apply_factor_roundup_magnitude() {
//     let value: u128 = 10;
//     let factor: i128 = 2;
//     let roundup_magnitude = true; // Mettez la valeur appropriée
//     let result = precision::apply_factor_roundup_magnitude(value, factor, roundup_magnitude);
//     assert(result == 20, '10 * 2 should be 20.');
// }

// #[test]
// fn test_mul_div() {
//     let value: u128 = 10;
//     let numerator: u128 = 2;
//     let denominator: u128 = 3;
//     let result = precision::mul_div(value, numerator, denominator);
//     assert(result, 6);
// }

// #[test]
// fn test_mul_div_ival() {
//     let value: i128 = 10;
//     let numerator: u128 = 2;
//     let denominator: u128 = 3;
//     let result = precision::mul_div_ival(value, numerator, denominator);
//     assert(result, 6);
// }

// #[test]
// fn test_mul_div_inum() {
//     let value: u128 = 10;
//     let numerator: i128 = 2;
//     let denominator: u128 = 3;
//     let result = precision::mul_div_inum(value, numerator, denominator);
//     assert(result, 6);
// }

// #[test]
// fn test_mul_div_inum_roundup() {
//     let value: u128 = 10;
//     let numerator: i128 = 2;
//     let denominator: u128 = 3;
//     let roundup_magnitude = true; // Mettez la valeur appropriée
//     let result = precision::mul_div_inum_roundup(value, numerator, denominator, roundup_magnitude);
//     // Assurez-vous d'ajuster cette assertion en fonction de la valeur attendue.
//     // assert(result, ???);
// }

// #[test]
// fn test_mul_div_roundup() {
//     let value: u128 = 10;
//     let numerator: u128 = 2;
//     let denominator: u128 = 3;
//     let roundup_magnitude = true; // Mettez la valeur appropriée
//     let result = precision::mul_div_roundup(value, numerator, denominator, roundup_magnitude);
//     // Assurez-vous d'ajuster cette assertion en fonction de la valeur attendue.
//     // assert(result, ???);
// }

// #[test]
// fn test_apply_exponent_factor() {
//     let float_value: u128 = 1000;
//     let exponent_factor: u128 = 2;
//     let result = precision::apply_exponent_factor(float_value, exponent_factor);
//     assert(result, 1000000);
// }

// #[test]
// fn test_to_factor_roundup() {
//     let value: u128 = 10;
//     let divisor: u128 = 2;
//     let roundup_magnitude = true; // Mettez la valeur appropriée
//     let result = precision::to_factor_roundup(value, divisor, roundup_magnitude);
//     // Assurez-vous d'ajuster cette assertion en fonction de la valeur attendue.
//     // assert(result, ???);
// }

// #[test]
// fn test_to_factor() {
//     let value: u128 = 10;
//     let divisor: u128 = 2;
//     let result = precision::to_factor(value, divisor);
//     assert(result, 5);
// }

// #[test]
// fn test_to_factor_ival() {
//     let value: i128 = 10;
//     let divisor: u128 = 2;
//     let result = precision::to_factor_ival(value, divisor);
//     assert(result, 5);
// }

// #[test]
// fn test_float_to_wei() {
//     let value: u128 = 10000;
//     let result = precision::float_to_wei(value);
//     assert(result, 1000);
// }

// #[test]
// fn test_wei_to_float() {
//     let value: u128 = 1000;
//     let result = precision::wei_to_float(value);
//     assert(result, 10000);
// }

// #[test]
// fn test_basis_point_to_float() {
//     let basis_point: u128 = 10;
//     let result = precision::basis_point_to_float(basis_point);
//     assert(result, 100);
// }
