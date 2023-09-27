// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use alexandria_math::pow;
use integer::{
    i128_to_felt252, u128_to_felt252, u256_wide_mul, u512_safe_div_rem_by_u256, BoundedU256,
    u256_try_as_non_zero
};
use core::traits::TryInto;
use core::option::Option;
use satoru::utils::calc::{roundup_division, roundup_magnitude_division};

const FLOAT_PRECISION: u128 = 1_000_000_000_000_000_000_000_000_000_000; // 10^30
const FLOAT_PRECISION_SQRT: u128 = 1_000_000_000_000_000; // 10^15

const WEI_PRECISION: u128 = 1_000_000_000_000_000_000; // 10^18
const BASIS_POINTS_DIVISOR: u128 = 10000;

const FLOAT_TO_WEI_DIVISOR: u128 = 1_000_000_000_000; // 10^12

/// Applies the given factor to the given value and returns the result.
/// # Arguments
/// * `value` - The value to apply the factor to.
/// * `factor` - The factor to apply.
/// # Returns
/// The result of applying the factor to the value.
fn apply_factor_u128(value: u128, factor: u128) -> u128 {
    return mul_div(value, factor, FLOAT_PRECISION);
}

/// Applies the given factor to the given value and returns the result.
/// # Arguments
/// * `value` - The value to apply the factor to.
/// * `factor` - The factor to apply.
/// # Returns
/// The result of applying the factor to the value.
fn apply_factor_i128(value: u128, factor: i128) -> i128 {
    return mul_div_inum(value, factor, FLOAT_PRECISION);
}

/// Applies the given factor to the given value and returns the result.
/// # Arguments
/// * `value` - The value to apply the factor to.
/// * `factor` - The factor to apply.
/// # Returns
/// The result of applying the factor to the value.
fn apply_factor_roundup_magnitude(value: u128, factor: i128, roundup_magnitude: bool) -> i128 {
    return mul_div_inum_roundup(value, factor, FLOAT_PRECISION, roundup_magnitude);
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div(value: u128, numerator: u128, denominator: u128) -> u128 {
    let value = u256 { low: value, high: 0 };
    let numerator = u256 { low: numerator, high: 0 };
    let denominator = u256 { low: denominator, high: 0 };
    let product = u256_wide_mul(value, numerator);
    let (q, _) = u512_safe_div_rem_by_u256(
        product, u256_try_as_non_zero(denominator).expect('MulDivByZero')
    );
    assert(q.limb1 == 0 && q.limb2 == 0 && q.limb3 == 0, 'MulDivOverflow');
    q.limb0
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The integer value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_ival(value: i128, numerator: u128, denominator: u128) -> i128 {
    return mul_div_inum(numerator, value, denominator);
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
    let felt252_numerator: felt252 = i128_to_felt252(numerator_abs);
    let u128_numerator = felt252_numerator.try_into().expect('felt252 into u128 failed');
    let result: u128 = mul_div(value, u128_numerator, denominator);
    let felt252_result: felt252 = u128_to_felt252(result);
    let i128_result: i128 = felt252_result.try_into().expect('felt252 into i128 failed');
    if numerator > 0 {
        return i128_result;
    } else {
        return -i128_result;
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
    let felt252_numerator: felt252 = i128_to_felt252(numerator_abs);
    let u128_numerator = felt252_numerator.try_into().expect('felt252 into u128 failed');
    let result: u128 = mul_div_roundup(value, u128_numerator, denominator, roundup_magnitude);
    let felt252_result: felt252 = u128_to_felt252(result);
    let i128_result: i128 = felt252_result.try_into().expect('felt252 into i128 failed');
    if numerator > 0 {
        return i128_result;
    } else {
        return -i128_result;
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
    let value = u256 { low: value, high: 0 };
    let numerator = u256 { low: numerator, high: 0 };
    let denominator = u256 { low: denominator, high: 0 };
    let product = u256_wide_mul(value, numerator);
    let (q, r) = u512_safe_div_rem_by_u256(
        product, u256_try_as_non_zero(denominator).expect('MulDivByZero')
    );
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

//use starknet::cairo::common::cairo_builtins::bitwise_and;
//use starknet::{*};
use alexandria_math::BitShift;
fn exp2(x: u256) -> u256 {
    //what is the cairo equivalent of `unchecked` in solidity?

    // Start from 0.5 in the 192.64-bit fixed-point format.
    let mut result = 0x800000000000000000000000000000000000000000000000;

    // The following logic multiplies the result by $\sqrt{2^{-i}}$ when the bit at position i is 1. Key points:
    //
    // 1. Intermediate results will not overflow, as the starting point is 2^191 and all magic factors are under 2^65.
    // 2. The rationale for organizing the if statements into groups of 8 is gas savings. If the result of performing
    // a bitwise AND operation between x and any value in the array [0x80; 0x40; 0x20; 0x10; 0x08; 0x04; 0x02; 0x01] is 1,
    // we know that `x & 0xFF` is also 1.

    if (x & 0xFF00000000000000 > 0) {
        result = BitShift::shl(result * 0x16A09E667F3BCC909, 64); //shl or shr?
    }

    if (x & 0xFF00000000000000 > 0) {
        if (x & 0x8000000000000000 > 0) {
            result = BitShift::shl(result * 0x16A09E667F3BCC909, 64);
        }
        if (x & 0x4000000000000000 > 0) {
            result = BitShift::shl(result * 0x1306FE0A31B7152DF, 64);
        }
        if (x & 0x2000000000000000 > 0) {
            result = BitShift::shl(result * 0x1172B83C7D517ADCE, 64);
        }
        if (x & 0x1000000000000000 > 0) {
            result = BitShift::shl(result * 0x10B5586CF9890F62A, 64);
        }
        if (x & 0x800000000000000 > 0) {
            result = BitShift::shl(result * 0x1059B0D31585743AE, 64);
        }
        if (x & 0x400000000000000 > 0) {
            result = BitShift::shl(result * 0x102C9A3E778060EE7, 64);
        }
        if (x & 0x200000000000000 > 0) {
            result = BitShift::shl(result * 0x10163DA9FB33356D8, 64);
        }
        if (x & 0x100000000000000 > 0) {
            result = BitShift::shl(result * 0x100B1AFA5ABCBED61, 64);
        }
    }

    if (x & 0xFF000000000000 > 0) {
        if (x & 0x80000000000000 > 0) {
            result = BitShift::shl(result * 0x10058C86DA1C09EA2, 64);
        }
        if (x & 0x40000000000000 > 0) {
            result = BitShift::shl(result * 0x1002C605E2E8CEC50, 64);
        }
        if (x & 0x20000000000000 > 0) {
            result = BitShift::shl(result * 0x100162F3904051FA1, 64);
        }
        if (x & 0x10000000000000 > 0) {
            result = BitShift::shl(result * 0x1000B175EFFDC76BA, 64);
        }
        if (x & 0x8000000000000 > 0) {
            result = BitShift::shl(result * 0x100058BA01FB9F96D, 64);
        }
        if (x & 0x4000000000000 > 0) {
            result = BitShift::shl(result * 0x10002C5CC37DA9492, 64);
        }
        if (x & 0x2000000000000 > 0) {
            result = BitShift::shl(result * 0x1000162E525EE0547, 64);
        }
        if (x & 0x1000000000000 > 0) {
            result = BitShift::shl(result * 0x10000B17255775C04, 64);
        }
    }

    if (x & 0xFF0000000000 > 0) {
        if (x & 0x800000000000 > 0) {
            result = BitShift::shl(result * 0x1000058B91B5BC9AE, 64);
        }
        if (x & 0x400000000000 > 0) {
            result = BitShift::shl(result * 0x100002C5C89D5EC6D, 64);
        }
        if (x & 0x200000000000 > 0) {
            result = BitShift::shl(result * 0x10000162E43F4F831, 64);
        }
        if (x & 0x100000000000 > 0) {
            result = BitShift::shl(result * 0x100000B1721BCFC9A, 64);
        }
        if (x & 0x80000000000 > 0) {
            result = BitShift::shl(result * 0x10000058B90CF1E6E, 64);
        }
        if (x & 0x40000000000 > 0) {
            result = BitShift::shl(result * 0x1000002C5C863B73F, 64);
        }
        if (x & 0x20000000000 > 0) {
            result = BitShift::shl(result * 0x100000162E430E5A2, 64);
        }
        if (x & 0x10000000000 > 0) {
            result = BitShift::shl(result * 0x1000000B172183551, 64);
        }
    }

    if (x & 0xFF00000000 > 0) {
        if (x & 0x8000000000 > 0) {
            result = BitShift::shl(result * 0x100000058B90C0B49, 64);
        }
        if (x & 0x4000000000 > 0) {
            result = BitShift::shl(result * 0x10000002C5C8601CC, 64);
        }
        if (x & 0x2000000000 > 0) {
            result = BitShift::shl(result * 0x1000000162E42FFF0, 64);
        }
        if (x & 0x1000000000 > 0) {
            result = BitShift::shl(result * 0x10000000B17217FBB, 64);
        }
        if (x & 0x800000000 > 0) {
            result = BitShift::shl(result * 0x1000000058B90BFCE, 64);
        }
        if (x & 0x400000000 > 0) {
            result = BitShift::shl(result * 0x100000002C5C85FE3, 64);
        }
        if (x & 0x200000000 > 0) {
            result = BitShift::shl(result * 0x10000000162E42FF1, 64);
        }
        if (x & 0x100000000 > 0) {
            result = BitShift::shl(result * 0x100000000B17217F8, 64);
        }
    }

    if (x & 0xFF000000 > 0) {
        if (x & 0x80000000 > 0) {
            result = BitShift::shl(result * 0x10000000058B90BFC, 64);
        }
        if (x & 0x40000000 > 0) {
            result = BitShift::shl(result * 0x1000000002C5C85FE, 64);
        }
        if (x & 0x20000000 > 0) {
            result = BitShift::shl(result * 0x100000000162E42FF, 64);
        }
        if (x & 0x10000000 > 0) {
            result = BitShift::shl(result * 0x1000000000B17217F, 64);
        }
        if (x & 0x8000000 > 0) {
            result = BitShift::shl(result * 0x100000000058B90C0, 64);
        }
        if (x & 0x4000000 > 0) {
            result = BitShift::shl(result * 0x10000000002C5C860, 64);
        }
        if (x & 0x2000000 > 0) {
            result = BitShift::shl(result * 0x1000000000162E430, 64);
        }
        if (x & 0x1000000 > 0) {
            result = BitShift::shl(result * 0x10000000000B17218, 64);
        }
    }

    if (x & 0xFF0000 > 0) {
        if (x & 0x800000 > 0) {
            result = BitShift::shl(result * 0x1000000000058B90C, 64);
        }
        if (x & 0x400000 > 0) {
            result = BitShift::shl(result * 0x100000000002C5C86, 64);
        }
        if (x & 0x200000 > 0) {
            result = BitShift::shl(result * 0x10000000000162E43, 64);
        }
        if (x & 0x100000 > 0) {
            result = BitShift::shl(result * 0x100000000000B1721, 64);
        }
        if (x & 0x80000 > 0) {
            result = BitShift::shl(result * 0x10000000000058B91, 64);
        }
        if (x & 0x40000 > 0) {
            result = BitShift::shl(result * 0x1000000000002C5C8, 64);
        }
        if (x & 0x20000 > 0) {
            result = BitShift::shl(result * 0x100000000000162E4, 64);
        }
        if (x & 0x10000 > 0) {
            result = BitShift::shl(result * 0x1000000000000B172, 64);
        }
    }

    if (x & 0xFF00 > 0) {
        if (x & 0x8000 > 0) {
            result = BitShift::shl(result * 0x100000000000058B9, 64);
        }
        if (x & 0x4000 > 0) {
            result = BitShift::shl(result * 0x10000000000002C5D, 64);
        }
        if (x & 0x2000 > 0) {
            result = BitShift::shl(result * 0x1000000000000162E, 64);
        }
        if (x & 0x1000 > 0) {
            result = BitShift::shl(result * 0x10000000000000B17, 64);
        }
        if (x & 0x800 > 0) {
            result = BitShift::shl(result * 0x1000000000000058C, 64);
        }
        if (x & 0x400 > 0) {
            result = BitShift::shl(result * 0x100000000000002C6, 64);
        }
        if (x & 0x200 > 0) {
            result = BitShift::shl(result * 0x10000000000000163, 64);
        }
        if (x & 0x100 > 0) {
            result = BitShift::shl(result * 0x100000000000000B1, 64);
        }
    }

    if (x & 0xFF > 0) {
        if (x & 0x80 > 0) {
            result = BitShift::shl(result * 0x10000000000000059, 64);
        }
        if (x & 0x40 > 0) {
            result = BitShift::shl(result * 0x1000000000000002C, 64);
        }
        if (x & 0x20 > 0) {
            result = BitShift::shl(result * 0x10000000000000016, 64);
        }
        if (x & 0x10 > 0) {
            result = BitShift::shl(result * 0x1000000000000000B, 64);
        }
        if (x & 0x8 > 0) {
            result = BitShift::shl(result * 0x10000000000000006, 64);
        }
        if (x & 0x4 > 0) {
            result = BitShift::shl(result * 0x10000000000000003, 64);
        }
        if (x & 0x2 > 0) {
            result = BitShift::shl(result * 0x10000000000000001, 64);
        }
        if (x & 0x1 > 0) {
            result = BitShift::shl(result * 0x10000000000000001, 64);
        }
    }

    // In the code snippet below, two operations are executed simultaneously:
    //
    // 1. The result is multiplied by $(2^n + 1)$, where $2^n$ represents the integer part, and the additional 1
    // accounts for the initial guess of 0.5. This is achieved by subtracting from 191 instead of 192.
    // 2. The result is then converted to an unsigned 60.18-decimal fixed-point format.
    //
    // The underlying logic is based on the relationship $2^{191-ip} = 2^{ip} / 2^{191}$, where $ip$ denotes the,
    // integer part, $2^n$.

    result *= 1000000000000000000;
    result = BitShift::shl(191, BitShift::shl(x, 64));
    result
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
        return mul_div_roundup(value, FLOAT_PRECISION, divisor, roundup_magnitude);
    }
    return mul_div(value, FLOAT_PRECISION, divisor);
}

/// Compute factor from value and divisor.
/// # Arguments
/// * `value` - The value to compute the factor.
/// * `divisor` - The divisor to compute the factor.
/// # Returns
/// The factor between value and divisor.
fn to_factor(value: u128, divisor: u128) -> u128 {
    return to_factor_roundup(value, divisor, false);
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
    return value / FLOAT_TO_WEI_DIVISOR;
}

/// Converts the given value from wei to float.
/// # Arguments
/// * `value` - The value to convert
/// # Returns
/// The float value.
fn wei_to_float(value: u128) -> u128 {
    return value * FLOAT_TO_WEI_DIVISOR;
}

/// Converts the given value basis point to float.
/// # Arguments
/// * `value` - The value to convert
/// # Returns
/// The float value.
fn basis_points_to_float(basis_point: u128) -> u128 {
    return basis_point * FLOAT_PRECISION / BASIS_POINTS_DIVISOR;
}
