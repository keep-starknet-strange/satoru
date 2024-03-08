// This code uses a portion of the code from the YAS project under the Apache 2.0 license.
// Here is the link to the original project:
// https://github.com/lambdaclass/yet-another-swap

// The original source code is subject to the Apache 2.0 license, the terms of which can be found here:
// http://www.apache.org/licenses/LICENSE-2.0

/// Trait
///
/// new - Constructs a new `signed_integer
/// div_rem - Computes `signed_integer` division and modulus simultaneously
/// abs - Computes the absolute value of the given `signed_integer`
/// max - Returns the maximum between two `signed_integer`
/// min - Returns the minimum between two `signed_integer`
trait IntegerTrait<T, U> {
    /// # IntegerTrait::new
    /// 
    /// ```rust
    /// fn new(mag: U, sign: bool) -> T;
    /// ```
    /// 
    /// Returns a new signed integer.
    ///
    /// ## Args
    ///
    /// * `mag`(`U`) - The magnitude of the integer.
    /// * `sign`(`bool`) - The sign of the integer, where `true` represents a negative number.
    ///
    /// > _`<U>` generic type depends on the uint type (u8, u16, u32, u64, u256)._
    ///
    /// ## Panics
    ///
    /// Panics if `mag` is out of range.
    ///
    /// ## Returns
    /// 
    /// A new signed integer.
    /// 
    /// ## Examples
    /// 
    /// ```rust
    /// fn new_i8_example() -> i8 {
    ///     IntegerTrait::<i8>::new(42_u8, true)
    /// }
    /// >>> {mag: 42, sign: true} // = -42
    /// ```
    /// 
    /// ```rust
    /// fn panic_i8_example() -> i8 {
    ///     IntegerTrait::<i8>::new(129_u8, true)
    /// }
    /// >>> panics with "int: out of range"
    /// ```
    /// 
    fn new(mag: U, sign: bool) -> T;
    /// # int.div_rem
    /// 
    /// ```rust
    /// fn div_rem(self: T, other: T) -> (T, T);
    /// ```
    /// 
    /// Computes signed\_integer division and modulus simultaneously
    ///
    /// ## Args
    /// 
    /// * `self`(`T`) - The dividend
    /// * `other`(`T`) - The divisor
    ///
    /// ## Panics
    ///
    /// Panics if the divisor is zero.
    ///
    /// ## Returns
    ///
    /// A tuple of signed integer `<T>`, containing the quotient and the remainder of the division.
    ///
    /// ## Examples
    /// 
    /// ```rust
    /// fn div_rem_example() -> (i32, i32) {
    ///     // We instantiate signed integers here.
    ///     let a = IntegerTrait::<i32>::new(13, false);
    ///     let b = IntegerTrait::<i32>::new(5, false);
    ///     
    ///     // We can call `div_rem` function as follows.
    ///     a.div_rem(b)
    /// }
    /// >>> ({mag: 2, sign: false}, {mag: 3, sign: false}) // = (2, 3)
    /// ```
    ///
    fn div_rem(self: T, other: T) -> (T, T);
    /// # int.abs 
    /// 
    /// ```rust
    /// fn abs(self: T) -> T;
    /// ```
    /// 
    /// Computes the absolute value of a signed\_integer.
    ///
    /// ## Args
    ///
    /// `self`(`T`) - The signed integer to which the absolute value is applied
    ///
    /// ## Returns
    ///
    /// A signed integer `<T>`, representing the absolute value of `self` .
    ///
    /// ## Examples
    ///
    /// ```rust
    /// fn abs_example() -> i32 {
    ///     // We instantiate signed integers here.
    ///     let int = IntegerTrait::<i32>::new(42, true);
    ///     
    ///     // We can call `abs` function as follows.
    ///     a.abs()
    /// }
    /// >>> {mag: 42, sign: false} // = 42
    /// ```
    ///
    fn abs(self: T) -> T;
    /// # int.max
    /// 
    /// ```rust
    /// fn max(self: T, other: T) -> T;
    /// ```
    /// 
    /// Returns the maximum between two signed\_integer.
    ///
    /// ## Args
    ///
    /// *`self`(`T`) - The first signed integer to compare.
    /// * `other`(`T`) - The second signed integer to compare.
    ///
    /// ## Returns
    ///
    /// A signed integer `<T>`, The maximum between `self` and `other`.
    ///
    /// ## Examples
    /// 
    /// ```rust
    /// fn max_example() -> i32 {
    ///     // We instantiate signed integer here.
    ///     let a = IntegerTrait::<i32>::new(42, true);
    ///     let b = IntegerTrait::<i32>::new(13, false);
    ///     
    ///     // We can call `max` function as follows.
    ///     a.max(b)
    /// }
    /// >>> {mag: 13, sign: false} // as 13 > -42
    /// ```
    ///
    fn max(self: T, other: T) -> T;
    /// # int.min
    /// 
    /// ```rust
    /// fn min(self: T, other: T) -> T;
    /// ```
    /// 
    /// Returns the minimum between two signed\_integer.
    ///
    /// ## Args
    ///
    /// `self`(`T`) - The first signed integer to compare.
    /// `other`(`T`) - The second signed integer to compare.
    ///
    /// ## Returns
    ///
    /// A signed integer `<T>`, The minimum between `self` and `other`.
    ///
    /// ## Examples
    /// 
    /// 
    /// ```rust
    /// fn min_example() -> i32 {
    ///     // We instantiate signed integer here.
    ///     let a = IntegerTrait::<i32>::new(42, true);
    ///     let b = IntegerTrait::<i32>::new(13, false);
    ///     
    ///     // We can call `max` function as follows.
    ///     a.min(b)
    /// }
    /// >>> {mag: 42, sign: true} // as -42 < 13
    /// ```
    /// 
    fn min(self: T, other: T) -> T;
}

use integer::{BoundedInt, u256_wide_mul};
use satoru::utils::felt_math::{felt_abs, felt_sign};
// ====================== INT 256 ======================

// i256 represents a 256-bit integer.
// The mag field holds the absolute value of the integer.
// The sign field is true for negative integers, and false for non-negative integers.
#[derive(Serde, Copy, Drop, Hash, starknet::Store)]
struct i256 {
    mag: u256,
    sign: bool,
}

impl i256Impl of IntegerTrait<i256, u256> {
    fn new(mag: u256, sign: bool) -> i256 {
        i256_new(mag, sign)
    }

    fn div_rem(self: i256, other: i256) -> (i256, i256) {
        i256_div_rem(self, other)
    }

    fn abs(self: i256) -> i256 {
        i256_abs(self)
    }

    fn max(self: i256, other: i256) -> i256 {
        i256_max(self, other)
    }

    fn min(self: i256, other: i256) -> i256 {
        i256_min(self, other)
    }
}

impl I256Default of Default<i256> {
    fn default() -> i256 {
        Zeroable::zero()
    }
}

// Implements the Add trait for i256.
impl i256Add of Add<i256> {
    fn add(lhs: i256, rhs: i256) -> i256 {
        i256_add(lhs, rhs)
    }
}

// Implements the AddEq trait for i256.
impl i256AddEq of AddEq<i256> {
    #[inline(always)]
    fn add_eq(ref self: i256, other: i256) {
        self = Add::add(self, other);
    }
}

// Implements the Sub trait for i256.
impl i256Sub of Sub<i256> {
    fn sub(lhs: i256, rhs: i256) -> i256 {
        i256_sub(lhs, rhs)
    }
}

// Implements the SubEq trait for i256.
impl i256SubEq of SubEq<i256> {
    #[inline(always)]
    fn sub_eq(ref self: i256, other: i256) {
        self = Sub::sub(self, other);
    }
}

// Implements the Mul trait for i256.
impl i256Mul of Mul<i256> {
    fn mul(lhs: i256, rhs: i256) -> i256 {
        i256_mul(lhs, rhs)
    }
}

// Implements the MulEq trait for i256.
impl i256MulEq of MulEq<i256> {
    #[inline(always)]
    fn mul_eq(ref self: i256, other: i256) {
        self = Mul::mul(self, other);
    }
}

// Implements the Div trait for i256.
impl i256Div of Div<i256> {
    fn div(lhs: i256, rhs: i256) -> i256 {
        i256_div(lhs, rhs)
    }
}

// Implements the DivEq trait for i256.
impl i256DivEq of DivEq<i256> {
    #[inline(always)]
    fn div_eq(ref self: i256, other: i256) {
        self = Div::div(self, other);
    }
}

// Implements the Rem trait for i256.
impl i256Rem of Rem<i256> {
    fn rem(lhs: i256, rhs: i256) -> i256 {
        i256_rem(lhs, rhs)
    }
}

// Implements the RemEq trait for i256.
impl i256RemEq of RemEq<i256> {
    #[inline(always)]
    fn rem_eq(ref self: i256, other: i256) {
        self = Rem::rem(self, other);
    }
}

// Implements the PartialEq trait for i256.
impl i256PartialEq of PartialEq<i256> {
    fn eq(lhs: @i256, rhs: @i256) -> bool {
        i256_eq(*lhs, *rhs)
    }

    fn ne(lhs: @i256, rhs: @i256) -> bool {
        i256_ne(*lhs, *rhs)
    }
}

// Implements the PartialOrd trait for i256.
impl i256PartialOrd of PartialOrd<i256> {
    fn le(lhs: i256, rhs: i256) -> bool {
        i256_le(lhs, rhs)
    }
    fn ge(lhs: i256, rhs: i256) -> bool {
        i256_ge(lhs, rhs)
    }

    fn lt(lhs: i256, rhs: i256) -> bool {
        i256_lt(lhs, rhs)
    }
    fn gt(lhs: i256, rhs: i256) -> bool {
        i256_gt(lhs, rhs)
    }
}

// Implements the Neg trait for i256.
impl i256Neg of Neg<i256> {
    fn neg(a: i256) -> i256 {
        i256_neg(a)
    }
}

impl i256TryIntou256 of TryInto<i256, u256> {
    fn try_into(self: i256) -> Option<u256> {
        assert(self.sign == false, 'The sign must be positive');
        Option::Some(self.mag)
    }
}

impl u256Intoi256 of Into<u256, i256> {
    fn into(self: u256) -> i256 {
        IntegerTrait::<i256>::new(self, false)
    }
}

impl I256TryIntoFelt252 of TryInto<i256, felt252> {
    fn try_into(self: i256) -> Option<felt252> {
        let val: Option<felt252> = self.mag.try_into();
        match val {
            Option::Some(val) => Option::Some(val * if self.sign {
                -1
            } else {
                1
            }),
            Option::None(()) => Option::None(())
        }
    }
}

impl I256IntoFelt252 of Into<i256, felt252> {
    fn into(self: i256) -> felt252 {
        let mag_felt: felt252 = self.mag.try_into().unwrap();
        if self.sign {
            mag_felt * -1
        } else {
            mag_felt
        }
    }
}

impl Felt252IntoI256 of Into<felt252, i256> {
    fn into(self: felt252) -> i256 {
        let mag = felt_abs(self).into();
        IntegerTrait::<i256>::new(mag, felt_sign(self))
    }
}

impl i256Zeroable of Zeroable<i256> {
    fn zero() -> i256 {
        IntegerTrait::<i256>::new(0, false)
    }
    #[inline(always)]
    fn is_zero(self: i256) -> bool {
        self == i256Zeroable::zero()
    }
    #[inline(always)]
    fn is_non_zero(self: i256) -> bool {
        self != i256Zeroable::zero()
    }
}

// Checks if the given i256 integer is zero and has the correct sign.
// # Arguments
// * `x` - The i256 integer to check.
// # Panics
// Panics if `x` is zero and has a sign that is not false.
fn i256_check_sign_zero(x: i256) {
    if x.mag == 0_u256 {
        assert(x.sign == false, 'sign of 0 must be false');
    }
}

/// Cf: IntegerTrait::new docstring
fn i256_new(mag: u256, sign: bool) -> i256 {
    if sign == true {
        assert(mag <= BoundedInt::<u256>::max(), 'i256 Overflow');
    } else {
        assert(mag <= (BoundedInt::<u256>::max() - 1), 'i256 Overflow');
    }
    i256 { mag, sign }
}

// Adds two i256 integers.
// # Arguments
// * `a` - The first i256 to add.
// * `b` - The second i256 to add.
// # Returns
// * `i256` - The sum of `a` and `b`.
fn i256_add(a: i256, b: i256) -> i256 {
    i256_check_sign_zero(a);
    i256_check_sign_zero(b);

    // If both integers have the same sign, 
    // the sum of their absolute values can be returned.
    if a.sign == b.sign {
        let sum = a.mag + b.mag;
        if (sum == 0_u256) {
            return IntegerTrait::new(sum, false);
        }
        return ensure_non_negative_zero(sum, a.sign);
    } else {
        // If the integers have different signs, 
        // the larger absolute value is subtracted from the smaller one.
        let (larger, smaller) = if a.mag >= b.mag {
            (a, b)
        } else {
            (b, a)
        };
        let difference = larger.mag - smaller.mag;

        if (difference == 0_u256) {
            return IntegerTrait::new(difference, false);
        }
        return ensure_non_negative_zero(difference, larger.sign);
    }
}

// Subtracts two i256 integers.
// # Arguments
// * `a` - The first i256 to subtract.
// * `b` - The second i256 to subtract.
// # Returns
// * `i256` - The difference of `a` and `b`.
fn i256_sub(a: i256, b: i256) -> i256 {
    i256_check_sign_zero(a);
    i256_check_sign_zero(b);

    if a.sign == b.sign {
        if a.mag > b.mag {
            return ensure_non_negative_zero(a.mag - b.mag, a.sign);
        } else if a.mag < b.mag {
            return ensure_non_negative_zero(b.mag - a.mag, !a.sign);
        } else {
            return ensure_non_negative_zero(0, false);
        }
    } else if a.sign {
        return ensure_non_negative_zero(a.mag + b.mag, true);
    } else {
        return ensure_non_negative_zero(a.mag + b.mag, false);
    }
}

// Multiplies two i256 integers.
// 
// # Arguments
//
// * `a` - The first i256 to multiply.
// * `b` - The second i256 to multiply.
//
// # Returns
//
// * `i256` - The product of `a` and `b`.
fn i256_mul(a: i256, b: i256) -> i256 {
    i256_check_sign_zero(a);
    i256_check_sign_zero(b);

    // The sign of the product is the XOR of the signs of the operands.
    let sign = a.sign ^ b.sign;
    // The product is the product of the absolute values of the operands.
    let mag_512 = u256_wide_mul(a.mag, b.mag);
    assert(mag_512.limb2 == 0 && mag_512.limb3 == 0, 'mul i256 overflow');

    let result = u256 { low: mag_512.limb0, high: mag_512.limb1 };

    if (result == 0) {
        return IntegerTrait::new(result, false);
    }

    return ensure_non_negative_zero(result, sign);
}

// Divides the first i256 by the second i256.
// # Arguments
// * `a` - The i256 dividend.
// * `b` - The i256 divisor.
// # Returns
// * `i256` - The quotient of `a` and `b`.
fn i256_div(a: i256, b: i256) -> i256 {
    i256_check_sign_zero(a);
    // Check that the divisor is not zero.
    assert(b.mag != 0_u256, 'b can not be 0');

    // The sign of the quotient is the XOR of the signs of the operands.
    let sign = a.sign ^ b.sign;

    if (sign == false) {
        // If the operands are positive, the quotient is simply their absolute value quotient.
        return ensure_non_negative_zero(a.mag / b.mag, sign);
    }

    // If the operands have different signs, rounding is necessary.
    // First, check if the quotient is an integer.
    if (a.mag % b.mag == 0) {
        let quotient = a.mag / b.mag;
        if (quotient == 0) {
            return IntegerTrait::new(quotient, false);
        }
        return ensure_non_negative_zero(quotient, sign);
    }

    // If the quotient is not an integer, multiply the dividend by 10 to move the decimal point over.
    let quotient = (a.mag * 10) / b.mag;
    let last_digit = quotient % 10;

    if (quotient == 0) {
        return IntegerTrait::new(quotient, false);
    }

    return ensure_non_negative_zero(quotient / 10_u256, sign);
}

// Calculates the remainder of the division of a first i256 by a second i256.
// # Arguments
// * `a` - The i256 dividend.
// * `b` - The i256 divisor.
// # Returns
// * `i256` - The remainder of dividing `a` by `b`.
fn i256_rem(a: i256, b: i256) -> i256 {
    i256_check_sign_zero(a);
    // Check that the divisor is not zero.
    assert(b.mag != 0_u256, 'b can not be 0');

    return IntegerTrait::new((a - (b * (a / b))).mag, a.sign);
}

/// Cf: IntegerTrait::div_rem docstring
fn i256_div_rem(a: i256, b: i256) -> (i256, i256) {
    let quotient = i256_div(a, b);
    let remainder = i256_rem(a, b);

    return (quotient, remainder);
}

// Compares two i256 integers for equality.
// # Arguments
// * `a` - The first i256 integer to compare.
// * `b` - The second i256 integer to compare.
// # Returns
// * `bool` - `true` if the two integers are equal, `false` otherwise.
fn i256_eq(a: i256, b: i256) -> bool {
    // Check if the two integers have the same sign and the same absolute value.
    if a.sign == b.sign && a.mag == b.mag {
        return true;
    }

    return false;
}

// Compares two i256 integers for inequality.
// # Arguments
// * `a` - The first i256 integer to compare.
// * `b` - The second i256 integer to compare.
// # Returns
// * `bool` - `true` if the two integers are not equal, `false` otherwise.
fn i256_ne(a: i256, b: i256) -> bool {
    // The result is the inverse of the equal function.
    return !i256_eq(a, b);
}

// Compares two i256 integers for greater than.
// # Arguments
// * `a` - The first i256 integer to compare.
// * `b` - The second i256 integer to compare.
// # Returns
// * `bool` - `true` if `a` is greater than `b`, `false` otherwise.
fn i256_gt(a: i256, b: i256) -> bool {
    // Check if `a` is negative and `b` is positive.
    if (a.sign & !b.sign) {
        return false;
    }
    // Check if `a` is positive and `b` is negative.
    if (!a.sign & b.sign) {
        return true;
    }
    // If `a` and `b` have the same sign, compare their absolute values.
    if (a.sign & b.sign) {
        return a.mag < b.mag;
    } else {
        return a.mag > b.mag;
    }
}

// Determines whether the first i256 is less than the second i256.
// # Arguments
// * `a` - The i256 to compare against the second i256.
// * `b` - The i256 to compare against the first i256.
// # Returns
// * `bool` - `true` if `a` is less than `b`, `false` otherwise.
fn i256_lt(a: i256, b: i256) -> bool {
    if (a.sign != b.sign) {
        return a.sign;
    } else {
        return a.mag != b.mag && (a.mag < b.mag) ^ a.sign;
    }
}

// Checks if the first i256 integer is less than or equal to the second.
// # Arguments
// * `a` - The first i256 integer to compare.
// * `b` - The second i256 integer to compare.
// # Returns
// * `bool` - `true` if `a` is less than or equal to `b`, `false` otherwise.
fn i256_le(a: i256, b: i256) -> bool {
    if (a == b || i256_lt(a, b) == true) {
        return true;
    } else {
        return false;
    }
}

// Checks if the first i256 integer is greater than or equal to the second.
// # Arguments
// * `a` - The first i256 integer to compare.
// * `b` - The second i256 integer to compare.
// # Returns
// * `bool` - `true` if `a` is greater than or equal to `b`, `false` otherwise.
fn i256_ge(a: i256, b: i256) -> bool {
    if (a == b || i256_gt(a, b) == true) {
        return true;
    } else {
        return false;
    }
}

// Negates the given i256 integer.
// # Arguments
// * `x` - The i256 integer to negate.
// # Returns
// * `i256` - The negation of `x`.
fn i256_neg(x: i256) -> i256 {
    // The negation of an integer is obtained by flipping its sign.
    return ensure_non_negative_zero(x.mag, !x.sign);
}

/// Cf: IntegerTrait::abs docstring
fn i256_abs(x: i256) -> i256 {
    return IntegerTrait::new(x.mag, false);
}

/// Cf: IntegerTrait::max docstring
fn i256_max(a: i256, b: i256) -> i256 {
    if (a > b) {
        return a;
    } else {
        return b;
    }
}

/// Cf: IntegerTrait::new docstring
fn i256_min(a: i256, b: i256) -> i256 {
    if (a < b) {
        return a;
    } else {
        return b;
    }
}

fn ensure_non_negative_zero(mag: u256, sign: bool) -> i256 {
    if mag == 0 {
        IntegerTrait::<i256>::new(mag, false)
    } else {
        IntegerTrait::<i256>::new(mag, sign)
    }
}

fn two_complement_if_nec(x: i256) -> i256 {
    let mag = if x.sign {
        ~(x.mag) + 1
    } else {
        x.mag
    };

    i256 { mag: mag, sign: x.sign }
}

fn bitwise_or(x: i256, y: i256) -> i256 {
    let x = two_complement_if_nec(x);
    let y = two_complement_if_nec(y);
    let sign = x.sign || y.sign;
    let mag = if sign {
        ~(x.mag | y.mag) + 1
    } else {
        x.mag | y.mag
    };

    IntegerTrait::<i256>::new(mag, sign)
}
