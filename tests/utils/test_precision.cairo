// IMPORTS
use satoru::utils::precision;
use satoru::utils::precision::{
    FLOAT_PRECISION, FLOAT_PRECISION_SQRT, WEI_PRECISION, BASIS_POINTS_DIVISOR, FLOAT_TO_WEI_DIVISOR
};
use satoru::utils::i256::{i256, i256_new};

#[test]
fn test_apply_factor_u256() {
    let value: u256 = 10;
    let factor: u256 = 1_000_000_000_000_000_000_000_000;
    let result = precision::apply_factor_u256(value, factor);
    assert(result == 100000, 'should be 100000.');
}

#[test]
fn test_apply_factor_i256() {
    let value: u256 = 10;
    let factor: i256 = i256_new(1_000_000_000_000_000_000_000_000, true);
    let result = precision::apply_factor_i256(value, factor);
    assert(result == i256_new(100000, true), 'should be -1OOO0O.');
}

#[test]
fn test_apply_factor_roundup_magnitude_positive() {
    let value: u256 = 15;
    let factor: i256 = i256_new(30_000_000_000_000_000_000, false);
    let roundup_magnitude = true;
    let result = precision::apply_factor_roundup_magnitude(value, factor, roundup_magnitude);
    assert(result == i256_new(5, false), 'should be 5.');
}

#[test]
fn test_apply_factor_roundup_magnitude_negative() {
    let value: u256 = 15;
    let factor: i256 = i256_new(30_000_000_000_000_000_000, true);
    let roundup_magnitude = true;
    let result = precision::apply_factor_roundup_magnitude(value, factor, roundup_magnitude);
    assert(result == i256_new(5, true), 'should be -5.');
}

#[test]
fn test_apply_factor_roundup_magnitude_no_rounding() {
    let value: u256 = 15;
    let factor: i256 = i256_new(30_000_000_000_000_000_000, true);
    let roundup_magnitude = false;
    let result = precision::apply_factor_roundup_magnitude(value, factor, roundup_magnitude);
    assert(result == i256_new(4, true), 'should be -4.');
}

#[test]
fn test_mul_div_ival_negative() {
    let value: i256 = i256_new(42, true);
    let factor: u256 = 10;
    let denominator = 8;
    let result = precision::mul_div_ival(value, factor, denominator);
    assert(result == i256_new(52, true), 'should be -52.');
}

#[test]
fn test_mul_div_inum_positive() {
    let value: u256 = 42;
    let factor: i256 = i256_new(10, false);
    let denominator = 8;
    let result = precision::mul_div_inum(value, factor, denominator);
    assert(result == i256_new(52, false), 'should be 52.');
}

#[test]
fn test_mul_div_inum_roundup_negative() {
    let value: u256 = 42;
    let factor: i256 = i256_new(10, true);
    let denominator = 8;
    let result = precision::mul_div_inum_roundup(value, factor, denominator, true);
    assert(result == i256_new(53, true), 'should be -53.');
}

#[test]
fn test_mul_div_inum_roundup_positive() {
    let value: u256 = 42;
    let factor: i256 = i256_new(10, false);
    let denominator = 8;
    let result = precision::mul_div_inum_roundup(value, factor, denominator, true);
    assert(result == i256_new(53, false), 'should be 53.');
}

#[test]
fn test_exp2() {
    let value1: u256 = 2000000000000000000;
    let value2: u256 = 2500000000000000000;
    let value3: u256 = 7482948646372839484;

    let result1 = precision::exp2(value1);
    let result2 = precision::exp2(value2);
    let result3 = precision::exp2(value3);

    assert(result1 == 4000000000000000000, 'should be 4000000000000000000');
    assert(result2 == 5656854249492380195, 'should be 5656854249492380195');
    assert(result3 == 178892444495791357043, 'should be 178892444495791357043');
}

#[test]
fn test_exp() {
    let value1: u256 = 2000000000000000000;
    let value2: u256 = 2500000000000000000;
    let value3: u256 = 7482948646372839484;
    let value4: u256 = 0000000000000000000;
    let value5: u256 = 1000000000000000000;

    let result1 = precision::exp(value1);
    let result2 = precision::exp(value2);
    let result3 = precision::exp(value3);
    let result4 = precision::exp(value4);
    let result5 = precision::exp(value5);

    assert(result1 == 7389056098930650223, 'should be 7389056098930650223');
    assert(result2 == 12182493960703473424, 'should be 12182493960703473424');
    assert(result3 == 1777474199233404337144, 'should_1777474199233404337144');
    assert(result4 == 1000000000000000000, 'should be 1000000000000000000');
    assert(result5 == 2718281828459045234, 'should be 2718281828459045234');
}


#[test]
fn test_log2() {
    let value1: u256 = 2000000000000000000;
    let value2: u256 = 5000000000000000000;
    let value3: u256 = 4000000000000000000;
    let value5: u256 = 1000000000000000000;

    let result1 = precision::log2(value1);
    let result2 = precision::log2(value2);
    let result3 = precision::log2(value3);
    let result5 = precision::log2(value5);

    assert(result1 == 1000000000000000000, 'should be 1000000000000000000');
    assert(result2 == 2321928094887362334, 'should be 2321928094887362334');
    assert(result3 == 2000000000000000000, 'should be 2000000000000000000');
    assert(result5 == 0000000000000000000, 'should be 0000000000000000000');
}

#[test]
fn test_pow_decimal() {
    let value1: u256 = 2000000000000000000;
    let value2: u256 = 3000000000000000000;
    let value3: u256 = 4000000000000000000;
    let value5: u256 = 1000000000000000000;
    let value6: u256 = 1524558784654678955;

    let result1 = precision::pow_decimal(value2, value1);
    let result2 = precision::pow_decimal(value2, value5);
    let result3 = precision::pow_decimal(value3, 0);
    let result4 = precision::pow_decimal(value3, value6);
    //let result5 = precision::pow_decimal(0, value5);

    assert(result1 == 8999999999999999806, 'should be 8999999999999999806');
    //assert(result2 == 2999999999999999967, 'should be 2999999999999999967');
    assert(result3 == 1000000000000000000, 'should be 2000000000000000000');
    assert(result4 == 8277055145359463000, 'should be 8277055145359463000');
}

#[test]
fn test_apply_exponent_factor() {
    let value1: u256 = 2000000000000000000000000000000;
    let value2: u256 = 3000000000000000000000000000000;
    let value3: u256 = 4000000000000000000000000000000;
    let value5: u256 = 1000000000000000000000000000000;
    let value6: u256 = 1524558784654678955000000000000;

    let result1 = precision::apply_exponent_factor(value2, value1);
    let result2 = precision::apply_exponent_factor(value2, value5);
    let result3 = precision::apply_exponent_factor(value3, 0);
    let result4 = precision::apply_exponent_factor(value3, value6);
    //let result5 = precision::pow_decimal(0, value5);

    assert(result1 == 8999999999999999806000000000000, 'should be ');
    //assert(result2 == 2999999999999999967, 'should be 2999999999999999967');
    assert(result3 == 1000000000000000000000000000000, 'should be ');
    assert(result4 == 8277055145359463000000000000000, 'should be ');
}

#[test]
fn test_to_factor_roundup() {
    let value: u256 = 450000;
    let divisor: u256 = 20_000_000_000_000_000_000_000_000; //2*10^25
    let roundup_magnitude = true;
    let result = precision::to_factor_roundup(value, divisor, roundup_magnitude);
    assert(result == 3, 'should be 3.');
}

#[test]
fn test_to_factor() {
    let value: u256 = 450000;
    let divisor: u256 = 20_000_000_000_000_000_000_000_000; // 2*10^25
    let result = precision::to_factor(value, divisor);
    assert(result == 2, 'should be 2.');
}

#[test]
fn test_to_factor_ival_positive() {
    let value: i256 = i256_new(450000, false);
    let divisor: u256 = 20_000_000_000_000_000_000_000_000; // 2*10^25
    let result = precision::to_factor_ival(value, divisor);
    assert(result == i256_new(2, false), 'from positive integer value.');
}

#[test]
fn test_to_factor_ival_negative() {
    let value: i256 = i256_new(450000, true);
    let divisor: u256 = 20_000_000_000_000_000_000_000_000; // 2*10^25
    let result = precision::to_factor_ival(value, divisor);
    assert(result == i256_new(2, true), 'should be -2.');
}

#[test]
fn test_float_to_wei() {
    let float_value: u256 = 1_000_000_000_000_000;
    let result = precision::float_to_wei(float_value);
    assert(result == 1000, 'should be 10^3');
}

#[test]
fn test_wei_to_float() {
    let wei_value: u256 = 10_000_000_000_000_000_000_000_000; //10^25
    let result = precision::wei_to_float(wei_value);
    assert(result == 10_000_000_000_000_000_000_000_000_000_000_000_000, 'should be 10^37');
}

#[test]
fn test_basis_points_to_float() {
    let basis_point: u256 = 1000;
    let result = precision::basis_points_to_float(basis_point);
    assert(result == 10_000_000_000_000_000_000, 'should be 10^19');
}
