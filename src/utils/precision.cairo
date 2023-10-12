// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use alexandria_math::pow;
use integer::{
    i128_to_felt252, u128_to_felt252, u256_wide_mul, u512_safe_div_rem_by_u256, BoundedU256,
    U256TryIntoNonZero
};
use satoru::utils::calc::{roundup_division, roundup_magnitude_division};

const FLOAT_PRECISION: u128 = 100_000_000_000_000_000_000; // 10^20
const FLOAT_PRECISION_SQRT: u128 = 10_000_000_000; // 10^10

const WEI_PRECISION: u128 = 1_000_000_000_000_000_000; // 10^18
const BASIS_POINTS_DIVISOR: u128 = 10_000;

const FLOAT_TO_WEI_DIVISOR: u128 = 1_000_000_000_000; // 10^12

/// Applies the given factor to the given value and returns the result.
/// # Arguments
/// * `value` - The value to apply the factor to.
/// * `factor` - The factor to apply.
/// # Returns
/// The result of applying the factor to the value.
fn apply_factor_u128(value: u128, factor: u128) -> u128 {
    mul_div(value, factor, FLOAT_PRECISION)
}

/// Applies the given factor to the given value and returns the result.
/// # Arguments
/// * `value` - The value to apply the factor to.
/// * `factor` - The factor to apply.
/// # Returns
/// The result of applying the factor to the value.
fn apply_factor_i128(value: u128, factor: i128) -> i128 {
    mul_div_inum(value, factor, FLOAT_PRECISION)
}

/// Applies the given factor to the given value and returns the result.
/// # Arguments
/// * `value` - The value to apply the factor to.
/// * `factor` - The factor to apply.
/// # Returns
/// The result of applying the factor to the value.
fn apply_factor_roundup_magnitude(value: u128, factor: i128, roundup_magnitude: bool) -> i128 {
    mul_div_inum_roundup(value, factor, FLOAT_PRECISION, roundup_magnitude)
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div(value: u128, numerator: u128, denominator: u128) -> u128 {
    let product = u256_wide_mul(value.into(), numerator.into());
    let denominator: u256 = denominator.into();
    let non_zero_denominator = denominator.try_into().expect('MulDivByZero');
    let (q, _) = u512_safe_div_rem_by_u256(product, non_zero_denominator);
    assert(q.limb1 == 0 && q.limb2 == 0 && q.limb3 == 0, 'MulDivOverflow');
    q.limb0
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The integer value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_ival(value: i128, numerator: u128, denominator: u128) -> i128 {
    mul_div_inum(numerator, value, denominator)
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The integer numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_inum(value: u128, numerator: i128, denominator: u128) -> i128 {
    let numerator_abs = if numerator < 0 {
        -numerator
    } else {
        numerator
    };
    let felt252_numerator: felt252 = numerator_abs.into();
    let u128_numerator = felt252_numerator.try_into().expect('felt252 into u128 failed');
    let result: u128 = mul_div(value, u128_numerator, denominator);
    let felt252_result: felt252 = result.into();
    let i128_result: i128 = felt252_result.try_into().expect('felt252 into i128 failed');
    if numerator > 0 {
        i128_result
    } else {
        -i128_result
    }
}

/// Apply multiplication then division to value with a roundup.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The integer numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_inum_roundup(
    value: u128, numerator: i128, denominator: u128, roundup_magnitude: bool
) -> i128 {
    let numerator_abs = if numerator < 0 {
        -numerator
    } else {
        numerator
    };
    let felt252_numerator: felt252 = numerator_abs.into();
    let u128_numerator = felt252_numerator.try_into().expect('felt252 into u128 failed');
    let result: u128 = mul_div_roundup(value, u128_numerator, denominator, roundup_magnitude);
    let felt252_result: felt252 = result.into();
    let i128_result: i128 = felt252_result.try_into().expect('felt252 into i128 failed');
    if numerator > 0 {
        i128_result
    } else {
        -i128_result
    }
}

/// Apply multiplication then division to value with a roundup.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_roundup(
    value: u128, numerator: u128, denominator: u128, roundup_magnitude: bool
) -> u128 {
    let product = u256_wide_mul(value.into(), numerator.into());
    let denominator: u256 = denominator.into();
    let non_zero_denominator = denominator.try_into().expect('MulDivByZero');
    let (q, r) = u512_safe_div_rem_by_u256(product, non_zero_denominator);
    if roundup_magnitude && r > 0 {
        let result = u256 { low: q.limb0, high: q.limb1 };
        assert(
            result != BoundedU256::max() && q.limb1 == 0 && q.limb2 == 0 && q.limb3 == 0,
            'MulDivOverflow'
        );
        q.limb0 + 1
    } else {
        assert(q.limb1 == 0 && q.limb2 == 0 && q.limb3 == 0, 'MulDivOverflow');
        q.limb0
    }
}

/// Apply exponent factor to float value.
/// # Arguments
/// * `value` - The value to the exponent is applied to.
/// * `divisor` - The exponent applied.
fn apply_exponent_factor(float_value: u128, exponent_factor: u128) -> u128 { // TODO
    // if float_value < FLOAT_PRECISION {
    //     return 0;
    // }
    // if exponent_factor == FLOAT_PRECISION {
    //     return float_value;
    // }
    // let wei_value = float_to_wei(float_value);
    // let exponent_wei = float_to_wei(exponent_factor);
    // let wei_result = pow(wei_value, exponent_wei);
    // let float_result = wei_to_float(wei_result);
    // float_result
    0
}

/// Compute factor from value and divisor with a roundup.
/// # Arguments
/// * `value` - The value to compute the factor.
/// * `divisor` - The divisor to compute the factor.
/// # Returns
/// The factor between value and divisor.
fn to_factor_roundup(value: u128, divisor: u128, roundup_magnitude: bool) -> u128 {
    if (value == 0) {
        return 0;
    }

    if (roundup_magnitude) {
        mul_div_roundup(value, FLOAT_PRECISION, divisor, roundup_magnitude)
    } else {
        mul_div(value, FLOAT_PRECISION, divisor)
    }
}

/// Compute factor from value and divisor.
/// # Arguments
/// * `value` - The value to compute the factor.
/// * `divisor` - The divisor to compute the factor.
/// # Returns
/// The factor between value and divisor.
fn to_factor(value: u128, divisor: u128) -> u128 {
    to_factor_roundup(value, divisor, false)
}

/// Compute factor from integer value and divisor.
/// # Arguments
/// * `value` - The value to compute the factor.
/// * `divisor` - The divisor to compute the factor.
/// # Returns
/// The factor between value and divisor.
fn to_factor_ival(value: i128, divisor: u128) -> i128 {
    let value_abs = if value < 0 {
        -value
    } else {
        value
    };
    let felt252_value: felt252 = i128_to_felt252(value_abs);
    let u128_value = felt252_value.try_into().expect('felt252 into u128 failed');
    let result: u128 = to_factor(u128_value, divisor);
    let felt252_result: felt252 = u128_to_felt252(result);
    let i128_result: i128 = felt252_result.try_into().expect('felt252 into i128 failed');
    if value > 0 {
        i128_result
    } else {
        -i128_result
    }
}

/// Converts the given value from float to wei.
/// # Arguments
/// * `value` - The value to convert.
/// # Returns
/// The wei value.
fn float_to_wei(value: u128) -> u128 {
    value / FLOAT_TO_WEI_DIVISOR
}

/// Converts the given value from wei to float.
/// # Arguments
/// * `value` - The value to convert
/// # Returns
/// The float value.
fn wei_to_float(value: u128) -> u128 {
    value * FLOAT_TO_WEI_DIVISOR
}

/// Converts the given value basis point to float.
/// # Arguments
/// * `value` - The value to convert
/// # Returns
/// The float value.
fn basis_points_to_float(basis_point: u128) -> u128 {
    basis_point * FLOAT_PRECISION / BASIS_POINTS_DIVISOR
}
