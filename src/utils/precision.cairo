// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use alexandria_math::karatsuba::multiply;
use alexandria_math::{ pow, BitShift };
use integer::{ u128_wide_mul, u256_safe_div_rem, u128_try_as_non_zero };
use integer::BoundedU128;

const FLOAT_PRECISION: u128 = 1_000_000_000_000_000_000_000_000_000_000_000; // 10^30
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
fn apply_factor_u128(value: u128, factor: u128) -> u128 { // TODO
    return mul_div(value, factor, FLOAT_PRECISION);
}

/// Applies the given factor to the given value and returns the result.
/// # Arguments
/// * `value` - The value to apply the factor to.
/// * `factor` - The factor to apply.
/// # Returns
/// The result of applying the factor to the value.
fn apply_factor_i128(value: u128, factor: i128) -> i128 { // TODO
    return mul_div_inum(value, factor, FLOAT_PRECISION);
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
    return mul_div_inum_roundup(value, factor, FLOAT_PRECISION, roundup_magnitude);
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div(value: u128, numerator: u128, denominator: u128) -> u128 {
    let (high, low) = u128_wide_mul(value, numerator);

    // Convertir high en u256
    let u256_high: u256 = high.into();
    let u256_low: u256 = low.into();

    // Utiliser BitShift::shl pour effectuer le décalage de bits
    let u256_product = BitShift::shl(u256_high, 128) + u256_low;

    // Convertir denominator en u256
    let u256_denominator: u256 = denominator.into();

    // Utiliser u256_safe_div_rem avec u256_product et u256_denominator
    let (q, r) = u256_safe_div_rem(u256_product, u256_denominator.try_into().expect("Division by 0"));

    // Convertir q en u128
    let q_u128: u128 = q.try_into().unwrap();

    q_u128
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The integer value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_ival(value: i128, numerator: u128, denominator: u128) -> i128 { // TODO
    return mul_div_inum(numerator, value, denominator);
}

/// Apply multiplication then division to value.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The integer numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_inum(value: u128, numerator: i128, denominator: u128) -> i128 { // TODO
    let numerator_abs = if numerator < 0 {
            -numerator
        } else {
            numerator
        };
    let u128_numerator: u128 = numerator_abs.into();
    let result: u128 = mul_div(value, u128_numerator, denominator);
    let result: i128 = result.try_into().unwrap();
    if numerator > 0 {
        return result;
    } else {
        return -result;
    }
}

/// Apply multiplication then division to value with a roundup.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The integer numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_inum_roundup(
    value: u128, numerator: i128, denominator: u128, roundup_magnitude: bool
) -> i128 { // TODO
    let numerator_abs = if numerator < 0 {
            -numerator
        } else {
            numerator
        };
    let u128_numerator: u128 = numerator_abs.into();
    let result: u128 = mul_div_roundup(value, u128_numerator, denominator, roundup_magnitude);
    let result: i128 = result.into();
    if numerator > 0 {
        return result;
    } else {
        return -result;
    }
}

/// Apply multiplication then division to value with a roundup.
/// # Arguments
/// * `value` - The value muldiv is applied to.
/// * `numerator` - The numerator that multiplies value.
/// * `divisor` - The denominator that divides value.
fn mul_div_roundup(
    value: u128, numerator: u128, denominator: u128, roundup_magnitude: bool
) -> u128 { // TODO
    let product = u128_wide_mul(value, numerator);
    let (q, r) = u256_safe_div_rem(
        product, 
        denominator.try_into().expect('Division by 0')
    );
    if roundup_magnitude && r > 0 {
        let result = u128 { low: q.limb0, high: q.limb1 };
        assert(result != BoundedU128::max() && q.limb2 == 0 && q.limb3 == 0, 'MulDivOverflow');
        u128 { low: q.limb0, high: q.limb1 } + 1
    } else {
        assert(q.limb2 == 0 && q.limb3 == 0, 'MulDivOverflow');
        u128 { low: q.limb0, high: q.limb1 }
    }
}

/// Apply exponent factor to float value.
/// # Arguments
/// * `value` - The value to the exponent is applied to.
/// * `divisor` - The exponent applied.
fn apply_exponent_factor(float_value: u128, exponent_factor: u128) -> u128 { // TODO
    if float_value < FLOAT_PRECISION {
        return 0;
    }

    if exponent_factor == FLOAT_PRECISION {
        return float_value;
    }

    let wei_value = float_to_wei(float_value);
    let exponent_wei = float_to_wei(exponent_factor);

    // Effectuer une puissance sur les valeurs converties en wei
    let wei_result = pow(wei_value, exponent_wei);

    // Convertir le résultat en valeur flottante
    let float_result = wei_to_float(wei_result);

    float_result
}

/// Compute factor from value and divisor with a roundup.
/// # Arguments
/// * `value` - The value to compute the factor.
/// * `divisor` - The divisor to compute the factor.
/// # Returns
/// The factor between value and divisor.
fn to_factor_roundup(value: u128, divisor: u128, roundup_magnitude: bool) -> u128 { // TODO
    if (value == 0) { return 0; }

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
fn to_factor(value: u128, divisor: u128) -> u128 { // TODO
    return to_factor_roundup(value, divisor, false);
}

/// Compute factor from integer value and divisor.
/// # Arguments
/// * `value` - The value to compute the factor.
/// * `divisor` - The divisor to compute the factor.
/// # Returns
/// The factor between value and divisor.
fn to_factor_ival(value: i128, divisor: u128) -> i128 { // TODO
    let value_abs = if value < 0 {
            -value
        } else {
            value
        };
    let u128_value: u128 = value_abs.into();
    let result: u128 = to_factor(u128_value, divisor);
    let result: i128 = result.into();
    if value > 0 {
        return result;
    } else {
        return -result;
    }
}

/// Converts the given value from float to wei.
/// # Arguments
/// * `value` - The value to convert.
/// # Returns
/// The wei value.
fn float_to_wei(value: u128) -> u128 { // TODO
    return value / FLOAT_TO_WEI_DIVISOR;
}

/// Converts the given value from wei to float.
/// # Arguments
/// * `value` - The value to convert
/// # Returns
/// The float value.
fn wei_to_float(value: u128) -> u128 { // TODO
    return value * FLOAT_TO_WEI_DIVISOR;
}

/// Converts the given value basis point to float.
/// # Arguments
/// * `value` - The value to convert
/// # Returns
/// The float value.
fn basis_point_to_float(basis_point: u128) -> u128 { // TODO
    return basis_point * FLOAT_PRECISION / BASIS_POINTS_DIVISOR;
}
