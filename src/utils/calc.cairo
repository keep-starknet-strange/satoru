// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use satoru::utils::error_utils;
use satoru::utils::i128::{i128, i128_new, i128_neg};

/// Calculates the result of dividing the first number by the second number 
/// rounded up to the nearest integer.
/// # Arguments
/// * `a` - the dividend.
/// * `b` - the divisor.
/// # Return
/// The result of dividing the first number by the second number, rounded up to the nearest integer.
fn roundup_division(a: u128, b: u128) -> u128 {
    (a + b - 1) / b
}

/// Calculates the result of dividing the first number by the second number,
/// rounded up to the nearest integer.
/// The rounding is purely on the magnitude of a, if a is negative the result
/// is a larger magnitude negative
/// # Arguments
/// * `a` - the dividend.
/// * `b` - the divisor.
/// # Return
/// The result of dividing the first number by the second number, rounded up to the nearest integer.
// TODO Update to use i128 division when available
// TODO function doesn't really do what the comments tell
fn roundup_magnitude_division(a: i128, b: u128) -> i128 {
    error_utils::check_division_by_zero(b, 'roundup_magnitude_division');
    if (a < Zeroable::zero()) {
        return ((a - i128_new(b, false) + i128_new(1, false)) / i128_new(b, false));
    }
    return ((a + i128_new(b, false) - i128_new(1, false)) / i128_new(b, false));
}

/// Adds two numbers together and return an u128 value, treating the second number as a signed integer,
/// # Arguments
/// * `a` - first number.
/// * `b` - second number.
/// # Return
/// the result of adding the two numbers together.
fn sum_return_uint_128(a: u128, b: i128) -> u128 {
    let b_abs = b.mag;
    if (b > Zeroable::zero()) {
        a + b_abs
    } else {
        a - b_abs
    }
}

/// Adds two numbers together and return an i256 value, treating the second number as a signed integer,
/// # Arguments
/// * `a` - first number.
/// * `b` - second number.
/// # Return
/// the result of adding the two numbers together.
fn sum_return_int_128(a: u128, b: i128) -> i128 {
    let a_i128 = i128_new(a, false);
    a_i128 + b
}

/// Calculates the absolute difference between two numbers,
/// # Arguments
/// * `a` - first number.
/// * `b` - second number.
/// # Return
/// the absolute difference between the two numbers.
fn diff(a: u128, b: u128) -> u128 {
    if a > b {
        a - b
    } else {
        b - a
    }
}

/// Adds two numbers together, the result is bounded to prevent overflows,
/// # Arguments
/// * `a` - first number.
/// * `b` - second number.
/// # Return
/// the result of adding the two numbers together.
fn bounded_add(a: i128, b: i128) -> i128 {
    if (a == Zeroable::zero()
        || b == Zeroable::zero()
        || (a < Zeroable::zero() && b > Zeroable::zero())
        || (a > Zeroable::zero() && b < Zeroable::zero())) {
        return a + b;
    }

    // if adding `b` to `a` would result in a value less than the min int256 value
    // then return the min int256 value
    if (a < Zeroable::zero() && b <= min_i128() - a) {
        return min_i128();
    }

    // if adding `b` to `a` would result in a value more than the max int256 value
    // then return the max int256 value
    if (a > Zeroable::zero() && b >= max_i128() - a) {
        return max_i128();
    }

    return a + b;
}

/// Returns a - b, the result is bounded to prevent overflows,
/// # Arguments
/// * `a` - first number.
/// * `b` - second number.
/// # Return
/// the bounded result of a - b.
fn bounded_sub(a: i128, b: i128) -> i128 {
    if (a == Zeroable::zero()
        || b == Zeroable::zero()
        || (a > Zeroable::zero() && b > Zeroable::zero())
        || (a < Zeroable::zero() && b < Zeroable::zero())) {
        return a - b;
    }

    // if adding `-b` to `a` would result in a value greater than the max int256 value
    // then return the max int256 value
    if (a > Zeroable::zero() && i128_neg(b) >= max_i128() - a) {
        return max_i128();
    }

    // if subtracting `b` from `a` would result in a value less than the min int256 value
    // then return the min int256 value
    if (a < Zeroable::zero() && i128_neg(b) <= min_i128() - a) {
        return min_i128();
    }

    return a - b;
}

/// Converts the given unsigned integer to a signed integer.
/// # Arguments
/// * `a` - first number.
/// * `b` - second number.
/// # Return
/// The signed integer.
fn to_signed(a: u128, mut is_positive: bool) -> i128 {
    // let a_felt: felt252 = a.into();
    // let a_signed = a_felt.try_into().expect('i128 Overflow');
    if (a == 0) {
        is_positive = true;
    }
    i128_new(a, !is_positive)
}

/// Converts the given signed integer to an unsigned integer, panics otherwise
/// # Return
/// The unsigned integer.
fn to_unsigned(value: i128) -> u128 {
    assert(value >= Zeroable::zero(), 'to_unsigned: value is negative');
    return value.mag;
}

// TODO use BoundedInt::max() && BoundedInt::mint() when possible
// Can't impl trait BoundedInt because of "-" that can panic (unless I can do it without using the minus operator)
fn max_i128() -> i128 {
    // Comes from https://doc.rust-lang.org/std/i128/constant.MAX.html
    i128 { mag: 170_141_183_460_469_231_731_687_303_715_884_105_727, sign: false }
}

fn min_i128() -> i128 {
    // Comes from https://doc.rust-lang.org/std/i128/constant.MIN.html
    i128 { mag: 170_141_183_460_469_231_731_687_303_715_884_105_728, sign: true }
}

/// Raise a number to a power, computes x^n.
/// * `x` - The number to raise.
/// * `n` - The exponent.
/// # Returns
/// * `u64` - The result of x raised to the power of n.
fn pow_u64(x: u64, n: usize) -> u64 {
    if n == 0 {
        1
    } else if n == 1 {
        x
    } else if (n & 1) == 1 {
        x * pow_u64(x * x, n / 2)
    } else {
        pow_u64(x * x, n / 2)
    }
}