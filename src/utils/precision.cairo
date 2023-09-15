// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.

/// Applies the given factor to the given value and returns the result.
/// # Arguments
/// * `value` - The value to apply the factor to.
/// * `factor` - The factor to apply.
/// # Returns
/// The result of applying the factor to the value.
fn apply_factor_u128(value: u128, factor: u128) -> u128 { // TODO
    0
}

/// Applies the given factor to the given value and returns the result.
/// # Arguments
/// * `value` - The value to apply the factor to.
/// * `factor` - The factor to apply.
/// # Returns
/// The result of applying the factor to the value.
fn apply_factor_i128(value: u128, factor: i128) -> i128 { // TODO
    0
}

/// Applies the given factor to the given value and returns the result.
/// # Arguments
/// * `value` - The value to apply the factor to.
/// * `factor` - The factor to apply.
/// # Returns
/// The result of applying the factor to the value.
fn apply_factor_roundup_magnitude(
    value: u128, factor: i128, roundup_magnitude: bool
) -> i128 { // TODO
    0
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div(value: u128, numerator: u128, denominator: u128) -> u128 { // TODO
    (value * numerator) / denominator
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The integer value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_ival(value: i128, numerator: u128, denominator: u128) -> i128 { // TODO
    0
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The integer numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_inum(value: u128, numerator: i128, denominator: u128) -> i128 { // TODO
    0
}

/// Apply multiplication then division to value with a roundup.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The integer numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_inum_roundup(
    value: u128, numerator: i128, denominator: u128, roundup_magnitude: bool
) -> i128 { // TODO
    0
}

/// Apply multiplication then division to value with a roundup.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_roundup(
    value: u128, numerator: u128, denominator: u128, roundup_magnitude: bool
) -> u128 { // TODO
    0
}

/// Apply exponent factor to float value.
/// # Arguments
/// * `value` - The value to the exponent is applied to.
/// * `divisor` - The exponent applied.
fn apply_exponent_factor(float_value: u128, exponent_factor: u128) -> u128 { // TODO
    0
}

/// Compute factor from value and divisor with a roundup.
/// # Arguments
/// * `value` - The value to compute the factor.
/// * `divisor` - The divisor to compute the factor.
/// # Returns
/// The factor between value and divisor.
fn to_factor_roundup(value: u128, divisor: u128, roundup_magnitude: bool) -> u128 { // TODO
    0
}

/// Compute factor from value and divisor.
/// # Arguments
/// * `value` - The value to compute the factor.
/// * `divisor` - The divisor to compute the factor.
/// # Returns
/// The factor between value and divisor.
fn to_factor(value: u128, divisor: u128) -> u128 { // TODO
    0
}

/// Compute factor from integer value and divisor.
/// # Arguments
/// * `value` - The value to compute the factor.
/// * `divisor` - The divisor to compute the factor.
/// # Returns
/// The factor between value and divisor.
fn to_factor_ival(value: i128, divisor: u128) -> i128 { // TODO
    0
}

/// Converts the given value from float to wei.
/// # Arguments
/// * `value` - The value to convert.
/// # Returns
/// The wei value.
fn float_to_wei(value: u128) -> u128 { // TODO
    0
}

/// Converts the given value from wei to float.
/// # Arguments
/// * `value` - The value to convert
/// # Returns
/// The float value.
fn wei_to_float(value: u128) -> u128 { // TODO
    0
}

/// Converts the given value basis point to float.
/// # Arguments
/// * `value` - The value to convert
/// # Returns
/// The float value.
fn basis_point_to_float(basis_point: u128) -> u128 { // TODO
    0
}
