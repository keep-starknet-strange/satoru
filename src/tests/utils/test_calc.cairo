use integer::BoundedInt;

use satoru::role::role;
use satoru::utils::calc::{
    roundup_division, roundup_magnitude_division, sum_return_uint_128, sum_return_int_128, diff,
    bounded_add, bounded_sub, to_signed, max_i128, min_i128
};

fn max_i128_as_u128() -> u128 {
    170_141_183_460_469_231_731_687_303_715_884_105_727
}

#[test]
#[should_panic(expected: ('i128_add Overflow',))]
fn max_i128_test() {
    max_i128() + 1;
}

#[test]
#[should_panic(expected: ('i128_sub Underflow',))]
fn min_i128_test() {
    min_i128() - 1;
}

#[test]
fn roundup_division_test() {
    assert(roundup_division(12, 3) == 4, '12/3 should be 4');
    assert(roundup_division(13, 3) == 5, '13/3 should be 4');
    assert(roundup_division(13, 5) == 3, '13/5 should be 3');
    assert(roundup_division(9, 9) == 1, '9/9 should be 1');
    assert(roundup_division(9, 18) == 1, '9/18 should be 1');
    assert(roundup_division(9, 99) == 1, '9/99 should be 1');
    assert(roundup_division(max_i128_as_u128(), max_i128_as_u128()) == 1, 'max/max should be 1');
    assert(roundup_division(0, 99) == 0, '0/99 should be 0');
}

#[test]
#[should_panic(expected: ('u128 is 0',))]
fn roundup_division_zero_test() {
    roundup_division(4, 0);
}

#[test]
fn roundup_magnitude_division_test() {
    assert(roundup_magnitude_division(12, 3) == 4, '12/3 should be 4');
    assert(roundup_magnitude_division(-12, 3) == -4, '-12/3 should be -4');
    assert(roundup_magnitude_division(13, 3) == 5, '13/3 should be 4');
    assert(roundup_magnitude_division(-13, 3) == -4, '-13/3 should be -4');
    assert(roundup_magnitude_division(13, 5) == 3, '13/5 should be 3');
    assert(roundup_magnitude_division(-13, 5) == -2, '-13/5 should be -2');
    assert(roundup_magnitude_division(9, 9) == 1, '9/9 should be 1');
    assert(roundup_magnitude_division(-9, 9) == -1, '-9/9 should be -1');
    assert(roundup_magnitude_division(9, 18) == 1, '9/18 should be 1');
    assert(roundup_magnitude_division(-9, 18) == 0, '-9/18 should be 0');
    assert(roundup_magnitude_division(9, 99) == 1, '9/99 should be 1');
    assert(roundup_magnitude_division(-9, 99) == 0, '-9/99 should be 0');
    assert(roundup_magnitude_division(max_i128(), max_i128_as_u128()) == 1, 'max/max should be 1');
    assert(
        roundup_magnitude_division(min_i128() + 1, max_i128_as_u128()) == -1, 'min/max should be -1'
    );
    assert(roundup_magnitude_division(0, 12) == 0, '0/12 should be 0');
}

#[test]
#[should_panic(expected: ('i128_sub Overflow',))]
fn roundup_magnitude_min_test() {
    // Because here min is 1 bigger than max, there is an overflow
    roundup_magnitude_division(min_i128(), 1);
}

#[test]
#[should_panic(expected: ('u128 is 0',))]
fn roundup_magnitude_zero_test() {
    roundup_magnitude_division(4, 0);
}

#[test]
fn sum_return_uint_128_test() {
    assert(sum_return_uint_128(12, 3) == 15, 'Should be 15');
    assert(sum_return_uint_128(12, -3) == 9, 'Should be 9');
    assert(sum_return_uint_128(0, 3) == 3, 'Should be 3');
    assert(sum_return_uint_128(12, 0) == 12, 'Should be 12');
    assert(sum_return_uint_128(BoundedInt::max(), 0) == BoundedInt::max(), 'Should be max');

    assert(
        sum_return_uint_128(BoundedInt::max(), -1) == BoundedInt::max() - 1, 'Should be max - 1'
    );
    assert(
        sum_return_uint_128(BoundedInt::max(), min_i128() + 1) == max_i128_as_u128() + 1,
        'Should be max/2 +1 (1)'
    );

    assert(sum_return_uint_128(0, max_i128()) == max_i128_as_u128(), 'Should be max/2 (2)');
}

#[test]
#[should_panic(expected: ('i128_sub Overflow',))]
fn sum_return_uint_128_overflow_min_test() {
    // Because here min is 1 bigger than max, there is an overflow
    sum_return_uint_128(BoundedInt::max(), min_i128());
}

#[test]
#[should_panic(expected: ('u128_add Overflow',))]
fn sum_return_uint_128_overflow_add_test() {
    sum_return_uint_128(BoundedInt::max(), 1);
}

#[test]
#[should_panic(expected: ('u128_sub Overflow',))]
fn sum_return_uint_128_overflow_sub_test() {
    sum_return_uint_128(0, -1);
}

#[test]
fn sum_return_int_128_test() {
    assert(sum_return_int_128(12, 3) == 15, 'Should be 15');
    assert(sum_return_int_128(12, -3) == 9, 'Should be 9');
    assert(sum_return_int_128(0, 3) == 3, 'Should be 3');
    assert(sum_return_int_128(0, -3) == -3, 'Should be -3');

    assert(
        sum_return_int_128(max_i128_as_u128() - 3, 2) == max_i128() - 1, 'Should be max_i128 -1 (1)'
    );

    assert(sum_return_int_128(max_i128_as_u128() - 1, 1) == max_i128(), 'Should be max_i128');
    assert(
        sum_return_int_128(max_i128_as_u128(), -1) == max_i128() - 1, 'Should be max_i128 - 1 (2)'
    );
}

#[test]
#[should_panic(expected: ('i128 Overflow',))]
fn sum_return_int_128_overflow_i128_test() {
    sum_return_int_128(max_i128_as_u128() + 1, 3);
}

#[test]
#[should_panic(expected: ('i128_add Overflow',))]
fn sum_return_int_128_overflow_when_adding_test() {
    sum_return_int_128(max_i128_as_u128() - 1, 2);
}

#[test]
fn diff_test() {
    assert(diff(12, 3) == 9, 'Should be 9');
    assert(diff(3, 11) == 8, 'Should be 8');
    assert(diff(0, 5) == 5, 'Should be 5');
    assert(diff(6, 0) == 6, 'Should be 6');
    assert(diff(3, 3) == 0, 'Should be 0 (1)');

    let max = BoundedInt::max();
    assert(diff(max, max) == 0, 'Should be 0 (2)');
    assert(diff(max - 1, max) == 1, 'Should be 1 (1))');
    assert(diff(max, max - 1) == 1, 'Should be 1 (2)');
}

#[test]
fn bounded_add_test() {
    // This tests the first if 
    assert(bounded_add(0, 3) == 3, 'Should be 3');
    assert(bounded_add(4, 0) == 4, 'Should be 4');
    assert(bounded_add(42, 41) == 83, 'Shoud be 83');
    assert(bounded_add(42, 42) == 84, 'Should be 84');
    assert(bounded_add(-10, -12) == -22, 'Should be -22');
    assert(bounded_add(-10, -10) == -20, 'Should be -20');

    let max = max_i128();
    let min = min_i128();
    // This tests the second if 
    assert(bounded_add(min, -1) == min, 'Should be min (1)');
    assert(bounded_add(min + 1, -1) == min, 'Should be min (2)');
    // This tests the third if 
    assert(bounded_add(max, 1) == max, 'Should be max (1)');
    assert(bounded_add(max - 1, 1) == max, 'Should be max (2)');

    // Mixing signing
    assert(bounded_add(-10, 10) == 0, 'Should be 0 (1)');
    assert(bounded_add(10, -10) == 0, 'Should be 0 (2)');
    assert(bounded_add(-10, -10) == -20, 'Shoud be -20');
}

#[test]
fn bounded_sub_test() {
    // This tests the first if 
    assert(bounded_sub(0, 3) == -3, 'Should be -3');
    assert(bounded_sub(3, 0) == 3, 'Should be 3');
    assert(bounded_sub(42, 41) == 1, 'Shoud be 1');
    assert(bounded_sub(41, 42) == -1, 'Should be -1');
    assert(bounded_sub(-10, -12) == 2, 'Should be 2');
    assert(bounded_sub(-12, -10) == -2, 'Should be -2');

    let max = max_i128();
    let min = min_i128();
    // This tests the second if 
    assert(bounded_sub(max, -1) == max, 'Should be max (1)');
    assert(bounded_sub(max - 1, -1) == max, 'Should be max (2)');
    // This tests the third if 
    assert(bounded_sub(min, 1) == min, 'Should be min (1)');
    assert(bounded_sub(min + 1, 1) == min, 'Should be min (2)');

    // Zero test case
    assert(bounded_sub(10, 10) == 0, 'Shoud be 0');
    // Mixing signing
    assert(bounded_sub(-10, 10) == -20, 'Should be -20');
    assert(bounded_sub(10, -10) == 20, 'Should be 20');
}

#[test]
fn to_signed_test() {
    assert(to_signed(12, true) == 12, 'Should be 12');
    assert(to_signed(12, false) == -12, 'Should be -12');

    let max = max_i128();
    let min = min_i128();
    assert(to_signed(max_i128_as_u128(), true) == max, 'Should be max');
    assert(to_signed(max_i128_as_u128(), false) == min + 1, 'Should be min)');
}

#[test]
#[should_panic(expected: ('i128 Overflow',))]
fn to_signed_overflow_pos_test() {
    to_signed(BoundedInt::max(), true);
}


#[test]
#[should_panic(expected: ('i128 Overflow',))]
fn to_signed_overflow_neg_test() {
    to_signed(BoundedInt::max(), false);
}
