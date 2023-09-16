// IMPORTS
use satoru::utils::precision;
use satoru::utils::precision::{
    FLOAT_PRECISION, FLOAT_PRECISION_SQRT, WEI_PRECISION, BASIS_POINTS_DIVISOR, FLOAT_TO_WEI_DIVISOR
};

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

#[test]
fn test_apply_factor_roundup_magnitude_negative() {
    let value: u128 = 15;
    let factor: i128 = -300_000_000_000_000_000_000_000_000_000;
    let roundup_magnitude = true;
    let result = precision::apply_factor_roundup_magnitude(value, factor, roundup_magnitude);
    assert(result == -5, 'should be -5.');
}

#[test]
fn test_apply_factor_roundup_magnitude_no_rounding() {
    let value: u128 = 15;
    let factor: i128 = -300_000_000_000_000_000_000_000_000_000;
    let roundup_magnitude = false;
    let result = precision::apply_factor_roundup_magnitude(value, factor, roundup_magnitude);
    assert(result == -4, 'should be -4.');
}

#[test]
fn test_mul_div_ival_negative() {
    let value: i128 = -42;
    let factor: u128 = 10;
    let denominator = 8;
    let result = precision::mul_div_ival(value, factor, denominator);
    assert(result == -52, 'should be -52.');
}

#[test]
fn test_mul_div_inum_positive() {
    let value: u128 = 42;
    let factor: i128 = 10;
    let denominator = 8;
    let result = precision::mul_div_inum(value, factor, denominator);
    assert(result == 52, 'should be 52.');
}

#[test]
fn test_mul_div_inum_roundup_negative() {
    let value: u128 = 42;
    let factor: i128 = -10;
    let denominator = 8;
    let result = precision::mul_div_inum_roundup(value, factor, denominator, true);
    assert(result == -53, 'should be -53.');
}

#[test]
fn test_mul_div_inum_roundup_positive() {
    let value: u128 = 42;
    let factor: i128 = 10;
    let denominator = 8;
    let result = precision::mul_div_inum_roundup(value, factor, denominator, true);
    assert(result == 53, 'should be 53.');
}

#[test]
fn test_apply_exponent_factor() {
    let float_value: u128 = 1_000_000_000_000_000_000_000_000_000_000_000; //10^33
    let exponent_factor: u128 = 1_000_000_000_000; //10^12
    let result = precision::apply_exponent_factor(float_value, exponent_factor);
    assert(result == 1_000_000_000_000_000_000_000_000_000_000_000, 'should be 10^33');
}

#[test]
fn test_to_factor_roundup() {
    let value: u128 = 450000;
    let divisor: u128 = 200_000_000_000_000_000_000_000_000_000_000_000; //2*10^35
    let roundup_magnitude = true;
    let result = precision::to_factor_roundup(value, divisor, roundup_magnitude);
    assert(result == 3, 'should be 3.');
}

#[test]
fn test_to_factor() {
    let value: u128 = 450000;
    let divisor: u128 = 200_000_000_000_000_000_000_000_000_000_000_000; // 2*10^35
    let result = precision::to_factor(value, divisor);
    assert(result == 2, 'should be 2.');
}

#[test]
fn test_to_factor_ival_positive() {
    let value: i128 = 450000;
    let divisor: u128 = 200_000_000_000_000_000_000_000_000_000_000_000; // 2*10^35
    let result = precision::to_factor_ival(value, divisor);
    assert(result == 2, 'from positive integer value.');
}

#[test]
fn test_to_factor_ival_negative() {
    let value: i128 = -450000;
    let divisor: u128 = 200_000_000_000_000_000_000_000_000_000_000_000; // 2*10^35
    let result = precision::to_factor_ival(value, divisor);
    assert(result == -2, 'should be -2.');
}

#[test]
fn test_float_to_wei() {
    let float_value: u128 = 1_000_000_000_000_000;
    let result = precision::float_to_wei(float_value);
    assert(result == 1000, 'should be 10^3');
}

#[test]
fn test_wei_to_float() {
    let wei_value: u128 = 10_000_000_000_000_000_000_000_000; //10^25
    let result = precision::wei_to_float(wei_value);
    assert(result == 10_000_000_000_000_000_000_000_000_000_000_000_000, 'should be 10^37');
}

#[test]
fn test_basis_points_to_float() {
    let basis_point: u128 = 1000;
    let result = precision::basis_points_to_float(basis_point);
    assert(result == 100_000_000_000_000_000_000_000_000_000, 'should be 10^29');
}
