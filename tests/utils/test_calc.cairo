use integer::BoundedInt;

use satoru::role::role;
use satoru::utils::calc::{
    roundup_division, roundup_magnitude_division, sum_return_uint_256, sum_return_int_256, diff,
    bounded_add, bounded_sub, to_signed, max_i256, min_i256
};

fn max_i256_as_u256() -> u256 {
    170_141_183_460_469_231_731_687_303_715_884_105_727
}
use satoru::utils::i256::{i256, i256_new};

#[test]
#[should_panic(expected: ('i256 Overflow',))]
fn given_overflow_when_max_i256_then_fails() {
    max_i256() + i256_new(1, false);
}

#[test]
#[should_panic(expected: ('i256 Overflow',))]
fn given_underflow_when_max_i256_then_fails() {
    min_i256() - i256_new(1, false);
}

#[test]
fn given_normal_conditions_when_roundup_division_then_works() {
    assert(roundup_division(12, 3) == 4, '12/3 should be 4');
    assert(roundup_division(13, 3) == 5, '13/3 should be 4');
    assert(roundup_division(13, 5) == 3, '13/5 should be 3');
    assert(roundup_division(9, 9) == 1, '9/9 should be 1');
    assert(roundup_division(9, 18) == 1, '9/18 should be 1');
    assert(roundup_division(9, 99) == 1, '9/99 should be 1');
    assert(roundup_division(0, 99) == 0, '0/99 should be 0');
}

#[test]
#[should_panic(expected: ('u256 is 0',))]
fn given_division_by_0_when_roundup_division_then_fails() {
    roundup_division(4, 0);
}

#[test]
fn given_normal_conditions_when_roundup_magnitude_division_then_works() { // TODO Check roundup_magnitude_division function
    assert(
        roundup_magnitude_division(i256_new(12, false), 3) == i256_new(4, false), '12/3 should be 4'
    );
// assert(roundup_magnitude_division(i256_new(12, true), 3) == i256_new(5, true), '-12/3 should be -4');
// assert(roundup_magnitude_division(i256_new(13, false), 3) == i256_new(5, false), '13/3 should be 4');
// assert(roundup_magnitude_division(i256_new(13, true), 3) == i256_new(5, true), '-13/3 should be -4');
// assert(roundup_magnitude_division(i256_new(13, false), 5) == i256_new(3, false), '13/5 should be 3');
// assert(roundup_magnitude_division(i256_new(13, true), 5) == i256_new(3, true), '-13/5 should be -2');
// assert(roundup_magnitude_division(i256_new(9, false), 9) == i256_new(1, false), '9/9 should be 1');
// assert(roundup_magnitude_division(i256_new(9, true), 9) == i256_new(1, true), '-9/9 should be -1');
// assert(roundup_magnitude_division(i256_new(9, false), 18) == i256_new(1, false), '9/18 should be 1');
// assert(roundup_magnitude_division(i256_new(9, true), 18) == i256_new(0, false), '-9/18 should be 0');
// assert(roundup_magnitude_division(i256_new(9, false), 99) == i256_new(1, false), '9/99 should be 1');
// assert(roundup_magnitude_division(i256_new(9, true), 99) == i256_new(0, false), '-9/99 should be 0');
// assert(roundup_magnitude_division(max_i256(), max_i256_as_u256()) == i256_new(1, false), 'max/max should be 1');
// assert(
//     roundup_magnitude_division(min_i256() + i256_new(1, false), max_i256_as_u256()) == i256_new(1, true), 'min/max should be -1'
// );
// assert(roundup_magnitude_division(i256_new(0, false), 12) == i256_new(0, false), '0/12 should be 0');
}

#[test]
#[should_panic(expected: ('i256 Overflow',))]
fn given_overflow_when_roundup_magnitude_division_then_works() {
    roundup_magnitude_division(min_i256(), 2);
}

#[test]
#[should_panic(expected: ('division by zero', 'roundup_magnitude_division',))]
fn given_division_by_0_when_roundup_magnitude_division_then_fails() {
    roundup_magnitude_division(i256_new(4, false), 0);
}

#[test]
fn given_normal_conditions_when_sum_return_uint_256_then_works() {
    assert(sum_return_uint_256(12, i256_new(3, false)) == 15, 'Should be 15');
    assert(sum_return_uint_256(12, i256_new(3, true)) == 9, 'Should be 9');
    assert(sum_return_uint_256(0, i256_new(3, false)) == 3, 'Should be 3');
    assert(sum_return_uint_256(12, i256_new(0, false)) == 12, 'Should be 12');
    assert(
        sum_return_uint_256(BoundedInt::max(), i256_new(0, false)) == BoundedInt::max(),
        'Should be max'
    );

    assert(
        sum_return_uint_256(BoundedInt::max(), i256_new(1, true)) == BoundedInt::max() - 1,
        'Should be max - 1'
    );
    // assert(
    //     sum_return_uint_256(BoundedInt::max(), min_i256() + i256_new(1, false)) == max_i256_as_u256() + 1,
    //     'Should be max/2 +1 (1)'
    // );

    assert(sum_return_uint_256(0, max_i256()) == max_i256_as_u256(), 'Should be max/2 (2)');
}

#[test]
#[should_panic(expected: ('u256_add Overflow',))]
fn given_add_overflow_when_sum_return_uint_256_then_fails() {
    sum_return_uint_256(BoundedInt::max(), i256_new(1, false));
}

#[test]
#[should_panic(expected: ('u256_sub Overflow',))]
fn given_u256_sub_overflow_when_sum_return_uint_256_then_fails() {
    sum_return_uint_256(0, i256_new(1, true));
}

#[test]
fn given_normal_conditions_when_sum_return_int_256_then_works() {
    assert(sum_return_int_256(12, i256_new(3, false)) == i256_new(15, false), 'Should be 15');
    assert(sum_return_int_256(12, i256_new(3, true)) == i256_new(9, false), 'Should be 9');
    assert(sum_return_int_256(0, i256_new(3, false)) == i256_new(3, false), 'Should be 3');
    assert(sum_return_int_256(0, i256_new(3, true)) == i256_new(3, true), 'Should be -3');

    assert(
        sum_return_int_256(max_i256_as_u256() - 3, i256_new(2, false)) == max_i256()
            - i256_new(1, false),
        'Should be max_i256 -1 (1)'
    );

    assert(
        sum_return_int_256(max_i256_as_u256() - 1, i256_new(1, false)) == max_i256(),
        'Should be max_i256'
    );
    assert(
        sum_return_int_256(max_i256_as_u256(), i256_new(1, true)) == max_i256()
            - i256_new(1, false),
        'Should be max_i256 - 1 (2)'
    );
}

#[test]
#[should_panic(expected: ('i256 Overflow',))]
fn given_i256_overflow_when_sum_return_int_256_then_fails() {
    sum_return_int_256(max_i256_as_u256() + 1, i256_new(3, false));
}

#[test]
#[should_panic(expected: ('i256 Overflow',))]
fn given_i256_add_overflow_when_sum_return_int_256_then_fails() {
    sum_return_int_256(max_i256_as_u256() - 1, i256_new(2, false));
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
    assert(
        bounded_add(i256_new(0, false), i256_new(3, false)) == i256_new(3, false), 'Should be 3'
    );
    assert(
        bounded_add(i256_new(4, false), i256_new(0, false)) == i256_new(4, false), 'Should be 4'
    );
    assert(
        bounded_add(i256_new(42, false), i256_new(41, false)) == i256_new(83, false), 'Shoud be 83'
    );
    assert(
        bounded_add(i256_new(42, false), i256_new(42, false)) == i256_new(84, false), 'Should be 84'
    );
    assert(
        bounded_add(i256_new(10, true), i256_new(12, true)) == i256_new(22, true), 'Should be -22'
    );
    assert(
        bounded_add(i256_new(10, true), i256_new(10, true)) == i256_new(20, true), 'Should be -20'
    );

    let max = max_i256();
    let min = min_i256();
    // This tests the second if 
    // TODO fix calc file
    // assert(bounded_add(min, i256_new(1, true)) == min, 'Should be min (1)');
    // assert(bounded_add(min + i256_new(1, false), i256_new(1, true)) == min, 'Should be min (2)');
    // This tests the third if 
    assert(bounded_add(max, i256_new(1, false)) == max, 'Should be max (1)');
    assert(bounded_add(max - i256_new(1, false), i256_new(1, false)) == max, 'Should be max (2)');

    // Mixing signing
    assert(
        bounded_add(i256_new(10, true), i256_new(10, false)) == i256_new(0, false),
        'Should be 0 (1)'
    );
    assert(
        bounded_add(i256_new(10, false), i256_new(10, true)) == i256_new(0, false),
        'Should be 0 (2)'
    );
    assert(
        bounded_add(i256_new(10, true), i256_new(10, true)) == i256_new(20, true), 'Shoud be -20'
    );
}

#[test]
fn given_normal_conditions_when_bounded_sub_then_works() {
    // This tests the first if 
    assert(
        bounded_sub(i256_new(0, false), i256_new(3, false)) == i256_new(3, true), 'Should be -3'
    );
    assert(
        bounded_sub(i256_new(3, false), i256_new(0, false),) == i256_new(3, false), 'Should be 3'
    );
    assert(
        bounded_sub(i256_new(42, false), i256_new(41, false)) == i256_new(1, false), 'Shoud be 1'
    );
    assert(
        bounded_sub(i256_new(41, false), i256_new(42, false)) == i256_new(1, true), 'Should be -1'
    );
    assert(
        bounded_sub(i256_new(10, true), i256_new(12, true)) == i256_new(2, false), 'Should be 2'
    );
    assert(
        bounded_sub(i256_new(12, true), i256_new(10, true)) == i256_new(2, true), 'Should be -2'
    );

    let max = max_i256();
    let min = min_i256();
    // This tests the second if 
    assert(bounded_sub(max, i256_new(1, true)) == max, 'Should be max (1)');
    assert(bounded_sub(max - i256_new(1, false), i256_new(2, true)) == max, 'Should be max (2)');
    // This tests the third if 
    // TODO fix calc file
    // assert(bounded_sub(min, i256_new(1, false)) == min, 'Should be min (1)');
    // assert(bounded_sub(min + i256_new(1, false), i256_new(1, false)) == min, 'Should be min (2)');

    // Zero test case
    assert(
        bounded_sub(i256_new(10, false), i256_new(10, false)) == i256_new(0, false), 'Shoud be 0'
    );
    // Mixing signing
    assert(
        bounded_sub(i256_new(10, true), i256_new(10, false)) == i256_new(20, true), 'Should be -20'
    );
    assert(
        bounded_sub(i256_new(10, false), i256_new(10, true)) == i256_new(20, false), 'Should be 20'
    );
}

#[test]
fn given_normal_conditions_when_to_signed_then_works() {
    assert(to_signed(12, true) == i256_new(12, false), 'Should be 12');
    assert(to_signed(12, false) == i256_new(12, true), 'Should be -12');

    let max = max_i256();
    let min = min_i256();
    assert(to_signed(max_i256_as_u256(), true) == max, 'Should be max');
    assert(to_signed(max_i256_as_u256(), false) == min + i256_new(1, false), 'Should be min + 1');
}

#[test]
#[should_panic(expected: ('i256 Overflow',))]
fn given_i256_overflow_when_to_signed_then_fails() {
    to_signed(BoundedInt::max(), true);
}


#[test]
#[should_panic(expected: ('i256 Overflow',))]
fn given_i256_overflow_neg_when_to_signed_then_fails() {
    to_signed(BoundedInt::max(), false);
}
