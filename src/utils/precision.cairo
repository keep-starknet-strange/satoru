// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use alexandria_math::pow;
use integer::{
    u256_wide_mul, u512_safe_div_rem_by_u256, BoundedU256, u256_try_as_non_zero, U256TryIntoFelt252
};
use satoru::utils::i256::{i256, i256_neg};
use core::traits::TryInto;
use core::option::Option;
use satoru::utils::calc::{roundup_division, roundup_magnitude_division};

const FLOAT_PRECISION: u256 = 100_000_000_000_000_000_000; // 10^20
const FLOAT_PRECISION_SQRT: u256 = 10_000_000_000; // 10^10

const WEI_PRECISION: u256 = 1_000_000_000_000_000_000; // 10^18
const BASIS_POINTS_DIVISOR: u256 = 10000;

const FLOAT_TO_WEI_DIVISOR: u256 = 1_000_000_000_000; // 10^12

/// Applies the given factor to the given value and returns the result.
/// # Arguments
/// * `value` - The value to apply the factor to.
/// * `factor` - The factor to apply.
/// # Returns
/// The result of applying the factor to the value.
fn apply_factor_u256(value: u256, factor: u256) -> u256 {
    return mul_div(value, factor, FLOAT_PRECISION);
}

/// Applies the given factor to the given value and returns the result.
/// # Arguments
/// * `value` - The value to apply the factor to.
/// * `factor` - The factor to apply.
/// # Returns
/// The result of applying the factor to the value.
fn apply_factor_i256(value: u256, factor: i256) -> i256 {
    return mul_div_inum(value, factor, FLOAT_PRECISION);
}

/// Applies the given factor to the given value and returns the result.
/// # Arguments
/// * `value` - The value to apply the factor to.
/// * `factor` - The factor to apply.
/// # Returns
/// The result of applying the factor to the value.
fn apply_factor_roundup_magnitude(value: u256, factor: i256, roundup_magnitude: bool) -> i256 {
    return mul_div_inum_roundup(value, factor, FLOAT_PRECISION, roundup_magnitude);
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div(value: u256, numerator: u256, denominator: u256) -> u256 {
    let product = u256_wide_mul(value, numerator);
    let (q, _) = u512_safe_div_rem_by_u256(
        product, u256_try_as_non_zero(denominator).expect('MulDivByZero')
    );
    assert(q.limb2 == 0 && q.limb3 == 0, 'mul_div u256 overflow');
    u256 { low: q.limb0, high: q.limb1 }
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The integer value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_ival(value: i256, numerator: u256, denominator: u256) -> i256 {
    return mul_div_inum(numerator, value, denominator);
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The integer numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_inum(value: u256, numerator: i256, denominator: u256) -> i256 {
    let numerator_abs = if numerator < Zeroable::zero() {
        i256_neg(numerator)
    } else {
        numerator
    };
    let felt252_numerator: felt252 = numerator_abs.try_into().expect('i256 into felt failed');
    let u256_numerator = felt252_numerator.into();
    let result: u256 = mul_div(value, u256_numerator, denominator);
    let felt252_result: felt252 = result.try_into().expect('u256 into felt failed');
    let i256_result: i256 = felt252_result.into();
    if numerator > Zeroable::zero() {
        return i256_result;
    } else {
        return i256_neg(i256_result);
    }
}

/// Apply multiplication then division to value with a roundup.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The integer numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_inum_roundup(
    value: u256, numerator: i256, denominator: u256, roundup_magnitude: bool
) -> i256 {
    let numerator_abs = if numerator < Zeroable::zero() {
        i256_neg(numerator)
    } else {
        numerator
    };
    let felt252_numerator: felt252 = numerator_abs.try_into().expect('i256 into felt failed');
    let u256_numerator = felt252_numerator.into();
    let result: u256 = mul_div_roundup(value, u256_numerator, denominator, roundup_magnitude);
    let felt252_result: felt252 = result.try_into().expect('u256 into felt failed');
    let i256_result: i256 = felt252_result.into();
    if numerator > Zeroable::zero() {
        return i256_result;
    } else {
        return i256_neg(i256_result);
    }
}

/// Apply multiplication then division to value with a roundup.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_roundup(
    value: u256, numerator: u256, denominator: u256, roundup_magnitude: bool
) -> u256 {
    let product = u256_wide_mul(value, numerator);
    let (q, r) = u512_safe_div_rem_by_u256(
        product, u256_try_as_non_zero(denominator).expect('MulDivByZero')
    );
    if roundup_magnitude && r > 0 {
        let result = u256 { low: q.limb0, high: q.limb1 };
        assert(
            result != BoundedU256::max() && q.limb2 == 0 && q.limb3 == 0,
            'MulDivOverflow'
        );
        u256 { low: q.limb0, high: q.limb1 } + 1
    } else {
        assert(q.limb2 == 0 && q.limb3 == 0, 'MulDivOverflow');
        u256 { low: q.limb0, high: q.limb1 }
    }
}

/// Apply exponent factor to float value.
/// # Arguments
/// * `value` - The value to the exponent is applied to.
/// * `divisor` - The exponent applied.
fn apply_exponent_factor(float_value: u256, exponent_factor: u256) -> u256 {
    if float_value < FLOAT_PRECISION {
        return 0;
    }
    if exponent_factor == FLOAT_PRECISION {
        return float_value;
    }
    let wei_value = float_to_wei(float_value);
    let exponent_wei = float_to_wei(exponent_factor);
    let wei_result = pow_decimal(wei_value.into(), exponent_wei.into());

    let wei_u256: u256 = wei_result.try_into().unwrap();
    let float_result = wei_to_float(wei_u256);
    float_result
//0
}

//use starknet::cairo::common::cairo_builtins::bitwise_and;
//use starknet::{*};
use alexandria_math::BitShift;

fn exp2(mut x: u256) -> u256 {
    let EXP2_MAX_INPUT = 192 * 1000000000000000000 - 1;
    if x > EXP2_MAX_INPUT {
        panic_with_felt252('error');
    }
    x = BitShift::shl(x, 64);
    x = x / 1000000000000000000;
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
        if (x & 0x8000000000000000 > 0) {
            result = BitShift::shr(result * 0x16A09E667F3BCC909, 64);
        }
        if (x & 0x4000000000000000 > 0) {
            result = BitShift::shr(result * 0x1306FE0A31B7152DF, 64);
        }
        if (x & 0x2000000000000000 > 0) {
            result = BitShift::shr(result * 0x1172B83C7D517ADCE, 64);
        }
        if (x & 0x1000000000000000 > 0) {
            result = BitShift::shr(result * 0x10B5586CF9890F62A, 64);
        }
        if (x & 0x800000000000000 > 0) {
            result = BitShift::shr(result * 0x1059B0D31585743AE, 64);
        }
        if (x & 0x400000000000000 > 0) {
            result = BitShift::shr(result * 0x102C9A3E778060EE7, 64);
        }
        if (x & 0x200000000000000 > 0) {
            result = BitShift::shr(result * 0x10163DA9FB33356D8, 64);
        }
        if (x & 0x100000000000000 > 0) {
            result = BitShift::shr(result * 0x100B1AFA5ABCBED61, 64);
        }
    }

    if (x & 0xFF000000000000 > 0) {
        if (x & 0x80000000000000 > 0) {
            result = BitShift::shr(result * 0x10058C86DA1C09EA2, 64);
        }
        if (x & 0x40000000000000 > 0) {
            result = BitShift::shr(result * 0x1002C605E2E8CEC50, 64);
        }
        if (x & 0x20000000000000 > 0) {
            result = BitShift::shr(result * 0x100162F3904051FA1, 64);
        }
        if (x & 0x10000000000000 > 0) {
            result = BitShift::shr(result * 0x1000B175EFFDC76BA, 64);
        }
        if (x & 0x8000000000000 > 0) {
            result = BitShift::shr(result * 0x100058BA01FB9F96D, 64);
        }
        if (x & 0x4000000000000 > 0) {
            result = BitShift::shr(result * 0x10002C5CC37DA9492, 64);
        }
        if (x & 0x2000000000000 > 0) {
            result = BitShift::shr(result * 0x1000162E525EE0547, 64);
        }
        if (x & 0x1000000000000 > 0) {
            result = BitShift::shr(result * 0x10000B17255775C04, 64);
        }
    }

    if (x & 0xFF0000000000 > 0) {
        if (x & 0x800000000000 > 0) {
            result = BitShift::shr(result * 0x1000058B91B5BC9AE, 64);
        }
        if (x & 0x400000000000 > 0) {
            result = BitShift::shr(result * 0x100002C5C89D5EC6D, 64);
        }
        if (x & 0x200000000000 > 0) {
            result = BitShift::shr(result * 0x10000162E43F4F831, 64);
        }
        if (x & 0x100000000000 > 0) {
            result = BitShift::shr(result * 0x100000B1721BCFC9A, 64);
        }
        if (x & 0x80000000000 > 0) {
            result = BitShift::shr(result * 0x10000058B90CF1E6E, 64);
        }
        if (x & 0x40000000000 > 0) {
            result = BitShift::shr(result * 0x1000002C5C863B73F, 64);
        }
        if (x & 0x20000000000 > 0) {
            result = BitShift::shr(result * 0x100000162E430E5A2, 64);
        }
        if (x & 0x10000000000 > 0) {
            result = BitShift::shr(result * 0x1000000B172183551, 64);
        }
    }

    if (x & 0xFF00000000 > 0) {
        if (x & 0x8000000000 > 0) {
            result = BitShift::shr(result * 0x100000058B90C0B49, 64);
        }
        if (x & 0x4000000000 > 0) {
            result = BitShift::shr(result * 0x10000002C5C8601CC, 64);
        }
        if (x & 0x2000000000 > 0) {
            result = BitShift::shr(result * 0x1000000162E42FFF0, 64);
        }
        if (x & 0x1000000000 > 0) {
            result = BitShift::shr(result * 0x10000000B17217FBB, 64);
        }
        if (x & 0x800000000 > 0) {
            result = BitShift::shr(result * 0x1000000058B90BFCE, 64);
        }
        if (x & 0x400000000 > 0) {
            result = BitShift::shr(result * 0x100000002C5C85FE3, 64);
        }
        if (x & 0x200000000 > 0) {
            result = BitShift::shr(result * 0x10000000162E42FF1, 64);
        }
        if (x & 0x100000000 > 0) {
            result = BitShift::shr(result * 0x100000000B17217F8, 64);
        }
    }

    if (x & 0xFF000000 > 0) {
        if (x & 0x80000000 > 0) {
            result = BitShift::shr(result * 0x10000000058B90BFC, 64);
        }
        if (x & 0x40000000 > 0) {
            result = BitShift::shr(result * 0x1000000002C5C85FE, 64);
        }
        if (x & 0x20000000 > 0) {
            result = BitShift::shr(result * 0x100000000162E42FF, 64);
        }
        if (x & 0x10000000 > 0) {
            result = BitShift::shr(result * 0x1000000000B17217F, 64);
        }
        if (x & 0x8000000 > 0) {
            result = BitShift::shr(result * 0x100000000058B90C0, 64);
        }
        if (x & 0x4000000 > 0) {
            result = BitShift::shr(result * 0x10000000002C5C860, 64);
        }
        if (x & 0x2000000 > 0) {
            result = BitShift::shr(result * 0x1000000000162E430, 64);
        }
        if (x & 0x1000000 > 0) {
            result = BitShift::shr(result * 0x10000000000B17218, 64);
        }
    }

    if (x & 0xFF0000 > 0) {
        if (x & 0x800000 > 0) {
            result = BitShift::shr(result * 0x1000000000058B90C, 64);
        }
        if (x & 0x400000 > 0) {
            result = BitShift::shr(result * 0x100000000002C5C86, 64);
        }
        if (x & 0x200000 > 0) {
            result = BitShift::shr(result * 0x10000000000162E43, 64);
        }
        if (x & 0x100000 > 0) {
            result = BitShift::shr(result * 0x100000000000B1721, 64);
        }
        if (x & 0x80000 > 0) {
            result = BitShift::shr(result * 0x10000000000058B91, 64);
        }
        if (x & 0x40000 > 0) {
            result = BitShift::shr(result * 0x1000000000002C5C8, 64);
        }
        if (x & 0x20000 > 0) {
            result = BitShift::shr(result * 0x100000000000162E4, 64);
        }
        if (x & 0x10000 > 0) {
            result = BitShift::shr(result * 0x1000000000000B172, 64);
        }
    }

    if (x & 0xFF00 > 0) {
        if (x & 0x8000 > 0) {
            result = BitShift::shr(result * 0x100000000000058B9, 64);
        }
        if (x & 0x4000 > 0) {
            result = BitShift::shr(result * 0x10000000000002C5D, 64);
        }
        if (x & 0x2000 > 0) {
            result = BitShift::shr(result * 0x1000000000000162E, 64);
        }
        if (x & 0x1000 > 0) {
            result = BitShift::shr(result * 0x10000000000000B17, 64);
        }
        if (x & 0x800 > 0) {
            result = BitShift::shr(result * 0x1000000000000058C, 64);
        }
        if (x & 0x400 > 0) {
            result = BitShift::shr(result * 0x100000000000002C6, 64);
        }
        if (x & 0x200 > 0) {
            result = BitShift::shr(result * 0x10000000000000163, 64);
        }
        if (x & 0x100 > 0) {
            result = BitShift::shr(result * 0x100000000000000B1, 64);
        }
    }

    if (x & 0xFF > 0) {
        if (x & 0x80 > 0) {
            result = BitShift::shr(result * 0x10000000000000059, 64);
        }
        if (x & 0x40 > 0) {
            result = BitShift::shr(result * 0x1000000000000002C, 64);
        }
        if (x & 0x20 > 0) {
            result = BitShift::shr(result * 0x10000000000000016, 64);
        }
        if (x & 0x10 > 0) {
            result = BitShift::shr(result * 0x1000000000000000B, 64);
        }
        if (x & 0x8 > 0) {
            result = BitShift::shr(result * 0x10000000000000006, 64);
        }
        if (x & 0x4 > 0) {
            result = BitShift::shr(result * 0x10000000000000003, 64);
        }
        if (x & 0x2 > 0) {
            result = BitShift::shr(result * 0x10000000000000001, 64);
        }
        if (x & 0x1 > 0) {
            result = BitShift::shr(result * 0x10000000000000001, 64);
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
    result = BitShift::shr(result, 191 - BitShift::shr(x, 64));
    result
}

fn exp(x: u256) -> u256 {
    //check if x is not too big, but it's already checked in exp 2?
    let uLOG2_E = 1_442695040888963407;
    let double_unit_product = x * uLOG2_E;
    exp2(double_unit_product / 1000000000000000000)
}

/// Raise a number to a power, computes x^n.
/// * `x` - The number to raise.
/// * `n` - The exponent.
/// # Returns
/// * `u256` - The result of x raised to the power of n.
fn pow256(x: u256, n: usize) -> u256 {
    if n == 0 {
        1
    } else if n == 1 {
        x
    } else if (n & 1) == 1 {
        x * pow256(x * x, n / 2)
    } else {
        pow256(x * x, n / 2)
    }
}

fn msb(mut x: u256) -> u256 {
    let mut result = 0;
    if (x >= pow256(2, 256)) {
        x = BitShift::shr(x, 256);
        result += 256;
    }
    if x >= pow256(2, 64) {
        x = BitShift::shr(x, 64);
        result += 64;
    }
    if x >= pow256(2, 32) {
        x = BitShift::shr(x, 32);
        result += 32;
    }
    if x >= pow256(2, 16) {
        x = BitShift::shr(x, 16);
        result += 16;
    }
    if x >= pow256(2, 8) {
        x = BitShift::shr(x, 8);
        result += 8;
    }
    if x >= pow256(2, 4) {
        x = BitShift::shr(x, 4);
        result += 4;
    }
    if x >= pow256(2, 2) {
        x = BitShift::shr(x, 2);
        result += 2;
    }
    if x >= pow256(2, 1) {
        result += 1;
    }
    result
}

fn log2(x: u256) -> u256 {
    let xUint: u256 = x;

    // If the input value is smaller than the base unit, error out.
    if xUint < 1000000000000000000 {
        panic_with_felt252('error');
    }

    // Calculate the integer part of the logarithm.
    let n: u256 = msb(xUint / 1000000000000000000);

    // Calculate the integer part of the logarithm as a fixed-point number.
    let mut resultUint: u256 = n * 1000000000000000000;

    // Calculate y = x * 2^{-n}
    let mut y: u256 = BitShift::shr(xUint, n);

    // If y equals the base unit, the fractional part is zero.
    if y == 1000000000000000000 {
        return resultUint;
    }

    // Calculate the fractional part through iterative approximation.
    let mut delta: u256 = 500000000000000000;
    loop {
        if delta == 0 {
            break;
        }
        y = (y * y) / 1000000000000000000;

        if y >= 2000000000000000000 {
            resultUint += delta;
            y = BitShift::shr(y, 1);
        }
        delta = BitShift::shr(delta, 1); // Decrement the delta by halving it.
    };

    return resultUint;
}

fn pow_decimal(x: u256, y: u256) -> u256 {
    let xUint: u256 = x;
    let yUint: u256 = y;

    // If both x and y are zero, the result is `UNIT`. If just x is zero, the result is always zero.
    if (xUint == 0) {
        if yUint == 0 {
            return 1000000000000000000;
        } else {
            return 0;
        }
    } // If x is `UNIT`, the result is always `UNIT`.
    else if (xUint == 1000000000000000000) {
        return 1000000000000000000;
    }

    // If y is zero, the result is always `UNIT`.
    if (yUint == 0) {
        return 1000000000000000000;
    } // If y is `UNIT`, the result is always x.
    else if (yUint == 1000000000000000000) {
        return x;
    }

    // If x is greater than `UNIT`, use the standard formula.
    if (xUint > 1000000000000000000) {
        return exp2(log2(x) * y / 1000000000000000000);
    } // Conversely, if x is less than `UNIT`, use the equivalent formula.
    else {
        let i = 1000000000000000000000000000000000000 / xUint;
        let w = exp2(log2(i) * y);
        return 1000000000000000000000000000000000000 / w;
    }
}


/// Compute factor from value and divisor with a roundup.
/// # Arguments
/// * `value` - The value to compute the factor.
/// * `divisor` - The divisor to compute the factor.
/// # Returns
/// The factor between value and divisor.
fn to_factor_roundup(value: u256, divisor: u256, roundup_magnitude: bool) -> u256 {
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
fn to_factor(value: u256, divisor: u256) -> u256 {
    return to_factor_roundup(value, divisor, false);
}

/// Compute factor from integer value and divisor.
/// # Arguments
/// * `value` - The value to compute the factor.
/// * `divisor` - The divisor to compute the factor.
/// # Returns
/// The factor between value and divisor.
fn to_factor_ival(value: i256, divisor: u256) -> i256 {
    let value_abs = if value < Zeroable::zero() {
        i256_neg(value)
    } else {
        value
    };
    let felt252_value: felt252 = value_abs.try_into().expect('i256 into felt failed');
    let u256_value = felt252_value.into();
    let result: u256 = to_factor(u256_value, divisor);
    let felt252_result: felt252 = result.try_into().expect('u256 into felt252 failed');
    let i256_result: i256 = felt252_result.into();
    if value > Zeroable::zero() {
        i256_result
    } else {
        i256_neg(i256_result)
    }
}

/// Converts the given value from float to wei.
/// # Arguments
/// * `value` - The value to convert.
/// # Returns
/// The wei value.
fn float_to_wei(value: u256) -> u256 {
    return value / FLOAT_TO_WEI_DIVISOR;
}

/// Converts the given value from wei to float.
/// # Arguments
/// * `value` - The value to convert
/// # Returns
/// The float value.
fn wei_to_float(value: u256) -> u256 {
    return value * FLOAT_TO_WEI_DIVISOR;
}

/// Converts the given value basis point to float.
/// # Arguments
/// * `value` - The value to convert
/// # Returns
/// The float value.
fn basis_points_to_float(basis_point: u256) -> u256 {
    return basis_point * FLOAT_PRECISION / BASIS_POINTS_DIVISOR;
}
