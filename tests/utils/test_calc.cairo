use integer::BoundedInt;

use satoru::role::role;
use satoru::utils::calc::{
    roundup_division, roundup_magnitude_division, sum_return_uint_128, sum_return_int_128, diff,
    bounded_add, bounded_sub, to_signed, max_i128, min_i128
};

fn max_i128_as_u128() -> u128 {
    170_141_183_460_469_231_731_687_303_715_884_105_727
}
use satoru::utils::i128::{i128, i128_new};

#[test]
#[should_panic(expected: ('i128_add Overflow',))]
fn given_overflow_when_max_i128_then_fails() {
    max_i128() + i128_new(1, false);
}

#[test]
#[should_panic(expected: ('i128_sub Underflow',))]
fn given_underflow_when_max_i128_then_fails() {
    min_i128() - i128_new(1, false);
}

#[test]
fn given_normal_conditions_when_roundup_division_then_works() {
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
fn given_division_by_0_when_roundup_division_then_fails() {
    roundup_division(4, 0);
}

#[test]
fn given_normal_conditions_when_roundup_magnitude_division_then_works() {
    let 12_pos_signed = i128_new(12, false);
    let 12_neg_signed = i128_new(12, true);

    let 3_pos_signed = i128_new(3, false);
    let 3_neg_signed = i128_new(3, true);

    let 13_pos_signed = i128_new(13, false);
    let 13_neg_signed = i128_new(13, true);

    let 9_pos_signed = i128_new(9, false);
    let 9_neg_signed = i128_new(9, true);

    let 18_pos_signed = i128_new(18, false);
    let 18_neg_signed = i128_new(18, true);

    let 99_pos_signed = i128_new(99, false);
    let 99_neg_signed = i128_new(99, true);

    let 5_pos_signed = i128_new(5, false);
    let 5_neg_signed = i128_new(5, true);

    let 1_pos_signed = i128_new(1, false);
    let 1_neg_signed = i128_new(1, true);

    let 4_pos_signed = i128_new(4, false);
    let 4_neg_signed = i128_new(4, true);

    assert(roundup_magnitude_division(12_pos_signed, 3_pos_signed) == 4_pos_signed, '12/3 should be 4');
    assert(roundup_magnitude_division(12_neg_signed, 3_pos_signed) == 4_neg_signed, '-12/3 should be -4');
    assert(roundup_magnitude_division(13_pos_signed, 3_pos_signed) == 5_pos_signed, '13/3 should be 4');
    assert(roundup_magnitude_division(13_neg_signed, 3_pos_signed) == 4_neg_signed, '-13/3 should be -4');
    assert(roundup_magnitude_division(13_pos_signed, 5_pos_signed) == 3_pos_signed, '13/5 should be 3');
    assert(roundup_magnitude_division(13_neg_signed, 5_pos_signed) == 2_neg_signed, '-13/5 should be -2');
    assert(roundup_magnitude_division(9_pos_signed, 9_pos_signed) == 1_pos_signed, '9/9 should be 1');
    assert(roundup_magnitude_division(9_neg_signed, 9_pos_signed) == 1_neg_signed, '-9/9 should be -1');
    assert(roundup_magnitude_division(9_pos_signed, 18_pos_signed) == 1_pos_signed, '9/18 should be 1');
    assert(roundup_magnitude_division(9_neg_signed, 18_pos_signed) == i128_new(0, false), '-9/18 should be 0');
    assert(roundup_magnitude_division(9_pos_signed, 99_pos_signed) == 1_pos_signed, '9/99 should be 1');
    assert(roundup_magnitude_division(9_neg_signed, 99_pos_signed) == i128_new(0, false), '-9/99 should be 0');
    assert(roundup_magnitude_division(max_i128(), max_i128_as_u128()) == 1_pos_signed, 'max/max should be 1');
    assert(
        roundup_magnitude_division(min_i128() + 1_pos_signed, max_i128_as_u128()) == 1_neg_signed, 'min/max should be -1'
    );
    assert(roundup_magnitude_division(i128_new(0, false), 12_pos_signed) == i128_new(0, false), '0/12 should be 0');
}

#[test]
#[should_panic(expected: ('i128_sub Overflow',))]
fn given_overflow_when_roundup_magnitude_division_then_works() {
    // Because here min is 1 bigger than max, there is an overflow
    roundup_magnitude_division(min_i128(), 1);
}

#[test]
#[should_panic(expected: ('division by zero', 'roundup_magnitude_division',))]
fn given_division_by_0_when_roundup_magnitude_division_then_fails() {
    roundup_magnitude_division(4, 0);
}

#[test]
fn given_normal_conditions_when_sum_return_uint_128_then_works() {
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
fn given_i128_sub_overflow_when_sum_return_uint_128_then_fails() {
    // Because here min is 1 bigger than max, there is an overflow
    sum_return_uint_128(BoundedInt::max(), min_i128());
}

#[test]
#[should_panic(expected: ('u128_add Overflow',))]
fn given_add_overflow_when_sum_return_uint_128_then_fails() {
    sum_return_uint_128(BoundedInt::max(), i128_new(1, false););
}

#[test]
#[should_panic(expected: ('u128_sub Overflow',))]
fn given_u128_sub_overflow_when_sum_return_uint_128_then_fails() {
    sum_return_uint_128(0, -1);
}

#[test]
fn given_normal_conditions_when_sum_return_int_128_then_works() {
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
fn given_i128_overflow_when_sum_return_int_128_then_fails() {
    sum_return_int_128(max_i128_as_u128() + 1, 3);
}

#[test]
#[should_panic(expected: ('i128_add Overflow',))]
fn given_i128_add_overflow_when_sum_return_int_128_then_fails() {
    sum_return_int_128(max_i128_as_u128() - 1, 2);
}

#[test]
fn given_normal_conditions_when_diff_then_works() {
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
fn given_normal_conditions_when_bounded_add_then_works() {
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
fn given_normal_conditions_when_bounded_sub_then_works() {
    // This tests the first if 
    assert(bounded_sub(i128_new(0, false), i128_new(3, false)) == i128_new(3, true), 'Should be -3');
    assert(bounded_sub(i128_new(3, false), i128_new(0, false),) == i128_new(3, false), 'Should be 3');
    assert(bounded_sub(i128_new(42, false), i128_new(41, false)) == i128_new(1, false), 'Shoud be 1');
    assert(bounded_sub(i128_new(41, false), i128_new(42, false)) == i128_new(1, true), 'Should be -1');
    assert(bounded_sub(i128_new(10, true), i128_new(12, true)) == i128_new(2, false), 'Should be 2');
    assert(bounded_sub(i128_new(12, true), i128_new(10, true)) == i128_new(2, true), 'Should be -2');

    let max = max_i128();
    let min = min_i128();
    // This tests the second if 
    assert(bounded_sub(max, i128_new(1, true)) == max, 'Should be max (1)');
    assert(bounded_sub(max - i128_new(12, false), i128_new(1, true)) == max, 'Should be max (2)');
    // This tests the third if 
    assert(bounded_sub(min, i128_new(1, false)) == min, 'Should be min (1)');
    assert(bounded_sub(min + i128_new(1, false), i128_new(1, false)) == min, 'Should be min (2)');

    // Zero test case
    assert(bounded_sub(i128_new(10, false), i128_new(10, false)) == i128_new(0, false), 'Shoud be 0');
    // Mixing signing
    assert(bounded_sub(i128_new(10, true), i128_new(10, false)) == i128_new(20, true), 'Should be -20');
    assert(bounded_sub(i128_new(10, false), i128_new(10, true)) == i128_new(20, false), 'Should be 20');
}

#[test]
fn given_normal_conditions_when_to_signed_then_works() {
    assert(to_signed(12, true) == i128_new(12, false), 'Should be 12');
    assert(to_signed(12, false) == i128_new(12, true), 'Should be -12');

    let max = max_i128();
    let min = min_i128();
    assert(to_signed(max_i128_as_u128(), true) == max, 'Should be max');
    assert(to_signed(max_i128_as_u128(), false) == min + i128_new(1, false), 'Should be min)');
}

#[test]
#[should_panic(expected: ('i128 Overflow',))]
fn given_i128_overflow_when_to_signed_then_fails() {
    to_signed(BoundedInt::max(), true);
}


#[test]
#[should_panic(expected: ('i128 Overflow',))]
fn given_i128_overflow_neg_when_to_signed_then_fails() {
    to_signed(BoundedInt::max(), false);
}
