// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use integer::BoundedInt;
use traits::{Into, TryInto};

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
fn roundup_magnitude_division(a: i128, b: u128) -> i128 {
    let a_abs = if a < 0 {
        -a
    } else {
        a
    };
    let a_felt: felt252 = a_abs.into();
    let a_u128: u128 = a_felt.try_into().unwrap();
    if a < 0 {
        if a_u128 < b {
            return 0;
        }
        let response_u128 = (a_u128 - b + 1) / b;
        let response_felt: felt252 = response_u128.into();
        -response_felt.try_into().unwrap() - 1
    } else {
        let response_u128 = (a_u128 + b - 1) / b;
        let response_felt: felt252 = response_u128.into();
        response_felt.try_into().unwrap()
    }
}

/// Adds two numbers together and return an u256 value, treating the second number as a signed integer,
/// # Arguments
/// * `a` - first number.
/// * `b` - second number.
/// # Return
/// the result of adding the two numbers together.
fn sum_return_uint_128(a: u128, b: i128) -> u128 {
    let b_abs = if b < 0 {
        -b
    } else {
        b
    };
    let b_abs: felt252 = b_abs.into();
    let b_abs: u128 = b_abs.try_into().unwrap();
    if (b > 0) {
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
    let a: felt252 = a.into();
    let a: i128 = a.try_into().expect('i128 Overflow');
    a + b
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
    if (a == 0 || b == 0 || (a < 0 && b > 0) || (a > 0 && b < 0)) {
        return a + b;
    }

    let max = max_i128();
    // if adding `b` to `a` would result in a value less than the min int256 value
    // then return the min int256 value
    if (a < 0 && b <= -max - a) {
        return -max;
    }

    // if adding `b` to `a` would result in a value more than the max int256 value
    // then return the max int256 value
    if (a > 0 && b >= max - a) {
        return max;
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
    if (a == 0 || b == 0 || (a > 0 && b > 0) || (a < 0 && b < 0)) {
        return a - b;
    }
    let max = max_i128();
    // if adding `-b` to `a` would result in a value greater than the max int256 value
    // then return the max int256 value
    if (a > 0 && -b >= max - a) {
        return max;
    }

    // if subtracting `b` from `a` would result in a value less than the min int256 value
    // then return the min int256 value
    if (a < 0 && -b <= -max - a) {
        return -max;
    }

    return a - b;
}

/// Converts the given unsigned integer to a signed integer.
/// # Arguments
/// * `a` - first number.
/// * `b` - second number.
/// # Return
/// The signed integer.
fn to_signed(a: u128, is_positive: bool) -> i128 {
    if is_positive {
        let a_felt: felt252 = a.into();
        a_felt.try_into().expect('i128 Overflow')
    } else {
        let a_felt: felt252 = a.into();
        0 - a_felt.try_into().expect('i128 Overflow')
    }
}

fn max_i128() -> i128 {
    // Comes from https://doc.rust-lang.org/std/i128/constant.MAX.html
    170_141_183_460_469_231_731_687_303_715_884_105_727
}

fn max_i128_as_u128() -> u128 {
    170_141_183_460_469_231_731_687_303_715_884_105_727
}
