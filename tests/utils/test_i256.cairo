mod TestInteger256 {
    mod New {
        use integer::BoundedInt;

        use satoru::utils::i256::{i256, IntegerTrait};

        // Test new i256 max
        #[test]
        fn test_i256_max() {
            let i256_max = BoundedInt::max() / 2;
            let a = IntegerTrait::<i256>::new(i256_max - 1, false);

            assert(a.mag == i256_max - 1, 'new max pos value error');
            assert(a.sign == false, 'new max pos sign');

            let a = IntegerTrait::<i256>::new(i256_max, true);
            assert(a.mag == i256_max, 'new max neg value error');
            assert(a.sign == true, 'new max neg sign');
        }

        // Test new i256 min
        #[test]
        fn test_i256_min() {
            let a = IntegerTrait::<i256>::new(0, false);
            assert(a.mag == 0, 'new min value error');
            assert(a.sign == false, 'new max pos sign');

            let a = IntegerTrait::<i256>::new(1, true);
            assert(a.mag == 1, 'new min value error');
            assert(a.sign == true, 'new max neg sign');
        }
    }

    mod Add {
        use integer::BoundedInt;

        use satoru::utils::i256::{i256, IntegerTrait};

        // Test addition of two positive integers
        #[test]
        fn test_positive_x_positive() {
            let a = IntegerTrait::<i256>::new(129, false);
            let b = IntegerTrait::<i256>::new(10, false);
            let result = a + b;
            assert(result.mag == 139, '129 + 10 = 139');
            assert(result.sign == false, '42 + 13 -> positive');
        }

        // Test addition of two negative integers
        #[test]
        fn test_negative_x_negative() {
            let a = IntegerTrait::<i256>::new(129, true);
            let b = IntegerTrait::<i256>::new(10, true);
            let result = a + b;
            assert(result.mag == 139, '- 129 - 10 = -139');
            assert(result.sign == true, '- 42 - 13 -> negative');
        }

        // Test addition of a positive integer and a negative integer with the same magnitude
        #[test]
        fn test_positive_x_negative_same_mag() {
            let a = IntegerTrait::<i256>::new(42, false);
            let b = IntegerTrait::<i256>::new(42, true);
            let result = a + b;
            assert(result.mag == 0, '42 - 42 = 0');
            assert(result.sign == false, '42 - 42 -> positive');
        }

        // Test addition of a positive integer and a negative integer with different magnitudes
        #[test]
        fn test_positive_x_negative_diff_mag() {
            let a = IntegerTrait::<i256>::new(42, false);
            let b = IntegerTrait::<i256>::new(13, true);
            let result = a + b;
            assert(result.mag == 29, '42 - 13 = 29');
            assert(result.sign == false, '42 - 13 -> positive');
        }

        // Test addition of a negative integer and a positive integer with different magnitudes
        #[test]
        fn test_negative_x_positive_diff_mag() {
            let a = IntegerTrait::<i256>::new(42, true);
            let b = IntegerTrait::<i256>::new(13, false);
            let result = a + b;
            assert(result.mag == 29, '-42 + 13 = -29');
            assert(result.sign == true, '-42 + 13 -> negative');
        }

        // Test addition overflow
        #[test]
        #[should_panic]
        fn test_overflow() {
            let i256_max = BoundedInt::max() / 2;
            let a = IntegerTrait::<i256>::new(i256_max - 1, false);
            let b = IntegerTrait::<i256>::new(1, false);
            let result = a + b;
        }
    }

    mod Sub {
        use integer::BoundedInt;

        use satoru::utils::i256::{i256, IntegerTrait};

        // Test subtraction of two positive integers with larger first
        #[test]
        fn test_positive_x_positive_larger_first() {
            let a = IntegerTrait::<i256>::new(42, false);
            let b = IntegerTrait::<i256>::new(13, false);
            let result = a - b;
            assert(result.mag == 29, '42 - 13 = 29');
            assert(result.sign == false, '42 - 13 -> positive');
        }

        // Test subtraction of two positive integers with larger second
        #[test]
        fn test_positive_x_positive_larger_second() {
            let a = IntegerTrait::<i256>::new(13, false);
            let b = IntegerTrait::<i256>::new(42, false);
            let result = a - b;
            assert(result.mag == 29, '13 - 42 = -29');
            assert(result.sign == true, '13 - 42 -> negative');
        }

        // Test subtraction of two negative integers with larger first
        #[test]
        fn test_negative_x_negative_larger_first() {
            let a = IntegerTrait::<i256>::new(42, true);
            let b = IntegerTrait::<i256>::new(13, true);
            let result = a - b;
            assert(result.mag == 29, '-42 - -13 = 29');
            assert(result.sign == true, '-42 - -13 -> negative');
        }

        // Test subtraction of two negative integers with larger second
        #[test]
        fn test_negative_x_negative_larger_second() {
            let a = IntegerTrait::<i256>::new(13, true);
            let b = IntegerTrait::<i256>::new(42, true);
            let result = a - b;
            assert(result.mag == 29, '-13 - -42 = 29');
            assert(result.sign == false, '-13 - -42 -> positive');
        }

        // Test subtraction of a positive integer and a negative integer with the same magnitude
        #[test]
        fn test_positive_x_negative_same_mag() {
            let a = IntegerTrait::<i256>::new(42, false);
            let b = IntegerTrait::<i256>::new(42, true);
            let result = a - b;
            assert(result.mag == 84, '42 - -42 = 84');
            assert(result.sign == false, '42 - -42 -> postive');
        }

        // Test subtraction of a negative integer and a positive integer with the same magnitude
        #[test]
        fn test_negative_x_positive_same_mag() {
            let a = IntegerTrait::<i256>::new(42, true);
            let b = IntegerTrait::<i256>::new(42, false);
            let result = a - b;
            assert(result.mag == 84, '-42 - 42 = -84');
            assert(result.sign == true, '-42 - 42 -> negative');
        }

        // Test subtraction of a positive integer and a negative integer with different magnitudes
        #[test]
        fn test_positive_x_negative_diff_mag() {
            let a = IntegerTrait::<i256>::new(100, false);
            let b = IntegerTrait::<i256>::new(42, true);
            let result = a - b;
            assert(result.mag == 142, '100 - - 42 = 142');
            assert(result.sign == false, '100 - - 42 -> postive');
        }

        // Test subtraction of a negative integer and a positive integer with different magnitudes
        #[test]
        fn test_negative_x_positive_diff_mag() {
            let a = IntegerTrait::<i256>::new(42, true);
            let b = IntegerTrait::<i256>::new(100, false);
            let result = a - b;
            assert(result.mag == 142, '-42 - 100 = -142');
            assert(result.sign == true, '-42 - 100 -> negative');
        }

        // Test subtraction resulting in zero
        #[test]
        fn test_result_in_zero() {
            let a = IntegerTrait::<i256>::new(42, false);
            let b = IntegerTrait::<i256>::new(42, false);
            let result = a - b;
            assert(result.mag == 0, '42 - 42 = 0');
            assert(result.sign == false, '42 - 42 -> positive');
        }

        // Test subtraction overflow
        #[test]
        #[should_panic]
        fn test_overflow() {
            let i256_max = BoundedInt::max() / 2;
            let a = IntegerTrait::<i256>::new(i256_max, true);
            let b = IntegerTrait::<i256>::new(1, false);
            let result = a - b;
        }
    }

    mod Mul {
        use integer::BoundedInt;

        use satoru::utils::i256::{i256, IntegerTrait};

        // Test multiplication of positive integers
        #[test]
        fn test_positive_x_positive() {
            let a = IntegerTrait::<i256>::new(10, false);
            let b = IntegerTrait::<i256>::new(5, false);
            let result = a * b;
            assert(result.mag == 50, '10 * 5 = 50');
            assert(result.sign == false, '10 * 5 -> positive');
        }

        // Test multiplication of negative integers
        #[test]
        fn test_negative_x_negative() {
            let a = IntegerTrait::<i256>::new(10, true);
            let b = IntegerTrait::<i256>::new(5, true);
            let result = a * b;
            assert(result.mag == 50, '-10 * -5 = 50');
            assert(result.sign == false, '-10 * -5 -> positive');
        }

        // Test multiplication of positive and negative integers
        #[test]
        fn test_positive_x_negative() {
            let a = IntegerTrait::<i256>::new(10, false);
            let b = IntegerTrait::<i256>::new(5, true);
            let result = a * b;
            assert(result.mag == 50, '10 * -5 = -50');
            assert(result.sign == true, '10 * -5 -> negative');
        }

        // Test multiplication of negative and positive integers
        #[test]
        fn test_negative_x_positive() {
            let a = IntegerTrait::<i256>::new(10, true);
            let b = IntegerTrait::<i256>::new(5, false);
            let result = a * b;
            assert(result.mag == 50, '10 * -5 = -50');
            assert(result.sign == true, '10 * -5 -> negative');
        }

        // Test multiplication by zero
        #[test]
        fn test_by_zero() {
            let a = IntegerTrait::<i256>::new(10, false);
            let b = IntegerTrait::<i256>::new(0, false);
            let result = a * b;
            assert(result.mag == 0, '10 * 0 = 0');
            assert(result.sign == false, '10 * 0 -> positive');
        }

        // Test multiplication overflow
        #[test]
        #[should_panic]
        fn test_overflow() {
            let i256_max = BoundedInt::max() / 2;
            let a = IntegerTrait::<i256>::new(i256_max - 1, false);
            let b = IntegerTrait::<i256>::new(2, false);
            let result = a * b;
        }
    }

    mod DivRem {
        use integer::BoundedInt;

        use satoru::utils::i256::{i256, IntegerTrait};

        // Test division and remainder of positive integers
        #[test]
        fn test_rem_positive_x_positive() {
            let a = IntegerTrait::<i256>::new(13, false);
            let b = IntegerTrait::<i256>::new(5, false);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 2 && r.mag == 3, '13 // 5 = 2 r 3');
            assert((q.sign == false) & (r.sign == false), '13 // 5 -> positive');
        }

        // Test division and remainder of negative integers
        #[test]
        fn test_rem_negative_x_negative() {
            let a = IntegerTrait::<i256>::new(13, true);
            let b = IntegerTrait::<i256>::new(5, true);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 2 && r.mag == 3, '-13 // -5 = 2 r -3');
            assert(q.sign == false && r.sign == true, '-13 // -5 -> positive');
        }

        // Test division and remainder of positive and negative integers
        #[test]
        fn test_rem_positive_x_negative() {
            let a = IntegerTrait::<i256>::new(13, false);
            let b = IntegerTrait::<i256>::new(5, true);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 3 && r.mag == 2, '13 // -5 = -3 r -2');
            assert(q.sign == true && r.sign == true, '13 // -5 -> negative');
        }

        // Test division and remainder with a negative dividend and positive divisor
        #[test]
        fn test_rem_negative_x_positive() {
            let a = IntegerTrait::<i256>::new(13, true);
            let b = IntegerTrait::<i256>::new(5, false);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 3 && r.mag == 2, '-13 // 5 = -3 r 2');
            assert(q.sign == true && r.sign == false, '-13 // 5 -> negative');
        }

        // Test division with a = zero
        #[test]
        fn test_rem_z_eq_zero() {
            let a = IntegerTrait::<i256>::new(0, false);
            let b = IntegerTrait::<i256>::new(10, false);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 0 && r.mag == 0, '0 // 10 = 0 r 0');
            assert(q.sign == false && r.sign == false, '0 // 10 -> positive');
        }

        // Test division by zero
        #[test]
        #[should_panic]
        fn test_rem_by_zero() {
            let a = IntegerTrait::<i256>::new(1, false);
            let b = IntegerTrait::<i256>::new(0, false);
            let (q, r) = a.div_rem(b);
        }

        // Test to ensure that the results do not produce invalid 'negative' zeros
        #[test]
        fn test_denominator_gt_numerator_result_should_be_zero() {
            // -65 / 256 = 0   
            let a = IntegerTrait::<i256>::new(65, true);
            let b = IntegerTrait::<i256>::new(256, false);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 0 && r.mag == 65, '-65 // 256 = 0 r 65');
            assert(q.sign == false && r.sign == true, '-65 // 256 -> positive (bc 0)');

            // -55 / 256 = 0
            let a = IntegerTrait::<i256>::new(55, true);
            let b = IntegerTrait::<i256>::new(256, false);
            let result = a / b;
            assert(result.mag == 0, '-55 // 256 = 0');
            assert(result.sign == false, '-55 // 256 -> positive (bc 0)');
        }

        // Test to evaluate rounding behavior and zeros
        #[test]
        fn test_division_round_with_negative_result() {
            // -10/ 3 = 0   
            let a = IntegerTrait::<i256>::new(10, true);
            let b = IntegerTrait::<i256>::new(3, false);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 3 && r.mag == 1, '-10 / 3 = (-3, -1)'); // should be (-3, 1)?
            assert(q.sign == true && r.sign == true, '(neg, neg)');

            // -6 / 10 = -1
            let a = IntegerTrait::<i256>::new(6, true);
            let b = IntegerTrait::<i256>::new(10, false);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 1 && r.mag == 4, '-6 / 10 = (-1, 4)'); // should be (0, -4)?
            // Following the previous behavior, the rest should be negative!
            // TODO: Change r.sign to true
            assert(q.sign == true && r.sign == false, '(neg, neg)'); // assert fails

            // -5 / 10 = 0
            let a = IntegerTrait::<i256>::new(5, true);
            let b = IntegerTrait::<i256>::new(10, false);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 0 && r.mag == 5, '-5 // 10 = 0 r -4');
            assert(q.sign == false && r.sign == true, '-5 // 10 -> (q: +, r: -)');

            // 5 / 10 = 0
            let a = IntegerTrait::<i256>::new(5, false);
            let b = IntegerTrait::<i256>::new(10, false);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 0 && r.mag == 5, '5 // 10 = 0 r 5');
            assert(q.sign == false && r.sign == false, '5 // 10 -> (q: +, r: +)');

            // 5 / -10 = 0
            let a = IntegerTrait::<i256>::new(5, false);
            let b = IntegerTrait::<i256>::new(10, true);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 0 && r.mag == 5, '5 // -10 = 0 r -5');
            // TODO: Change r.sign to true
            assert(q.sign == false && r.sign == false, '5 // -10 -> (q: +, r: -)');

            // -4 / 10 = 0
            let a = IntegerTrait::<i256>::new(4, true);
            let b = IntegerTrait::<i256>::new(10, false);
            let (q, r) = a.div_rem(b);
            // TODO: verify r.mag 4
            assert(q.mag == 0 && r.mag == 4, '-4 / 10 = 0 r -4');
            assert(q.sign == false && r.sign == true, '-4 // 10 -> (q: +, r: -)');

            // -3 / 10 = 0
            let a = IntegerTrait::<i256>::new(3, true);
            let b = IntegerTrait::<i256>::new(10, false);
            let (q, r) = a.div_rem(b);
            // TODO: verify r.mag 3
            assert(q.mag == 0 && r.mag == 3, '-3 / 10 = 0 r -3');
            assert(q.sign == false && r.sign == true, '-3 // 10 -> (q: +, r: -)');

            // -2 / 10 = 0
            let a = IntegerTrait::<i256>::new(2, true);
            let b = IntegerTrait::<i256>::new(10, false);
            let (q, r) = a.div_rem(b);
            // TODO: verify r.mag 2
            assert(q.mag == 0 && r.mag == 2, '-2 / 10 = 0 r -2');
            assert(q.sign == false && r.sign == true, '-2 // 10 -> (q: +, r: -)');

            // -1 / 10 = 0
            let a = IntegerTrait::<i256>::new(1, true);
            let b = IntegerTrait::<i256>::new(10, false);
            let (q, r) = a.div_rem(b);
            // TODO: verify r.mag 1
            assert(q.mag == 0 && r.mag == 1, '-1 / 10 = 0 r -1');
            assert(q.sign == false && r.sign == true, '-1 // 10 -> (q: +, r: -)');
        }
    }

    mod i256IntoU256 {
        use integer::BoundedInt;

        use satoru::utils::i256::{i256, IntegerTrait};

        #[test]
        fn test_positive_conversion_within_range() {
            let val = IntegerTrait::<i256>::new(100, false);
            let result: u256 = val.try_into().unwrap();
            assert(result == 100, 'result should be 100');
        }

        #[test]
        fn test_zero_conversion() {
            let val = IntegerTrait::<i256>::new(0, false);
            let result: u256 = val.try_into().unwrap();
            assert(result == 0, 'result should be 0');
        }

        #[test]
        fn test_positive_conversion_i256_max() {
            let val = IntegerTrait::<i256>::new(BoundedInt::max() / 2 - 1, false);
            let result: u256 = val.try_into().unwrap();
            assert(result == BoundedInt::max() / 2 - 1, 'result should be max');
        }

        #[test]
        #[should_panic(expected: ('The sign must be positive',))]
        fn test_negative_conversion() {
            let val = IntegerTrait::<i256>::new(200, true);
            let result: u256 = val.try_into().unwrap();
        }
    }

    mod TwoComplementTests {
        use integer::BoundedInt;

        use satoru::utils::i256::{i256, two_complement_if_nec, IntegerTrait};

        // Some expected values where calculated in Python with a script

        // Two's complement expected is achieved by:
        // Step 1: starting with the equivalent positive number.
        // Step 2: inverting (or flipping) all bits – changing every 0 to 1, and every 1 to 0;
        // Step 3: adding 1 to the entire inverted number, ignoring any overflow. Accounting 
        // for overflow will produce the wrong value for the result.

        #[test]
        fn test_positive_min_mag() {
            let input = IntegerTrait::<i256>::new(0, false);
            let actual = two_complement_if_nec(input);
            let expected = i256 { mag: 0, sign: false };

            assert(actual == expected, 'positive min wrong val');
        }

        #[test]
        fn test_positive_max_mag() {
            let input = IntegerTrait::<i256>::new(BoundedInt::max() / 2 - 1, false);
            let actual = two_complement_if_nec(input);
            let expected = i256 { mag: BoundedInt::max() / 2 - 1, sign: false };

            assert(actual == expected, 'positive max wrong value');
        }

        #[test]
        fn test_negative_min_mag() {
            let input = IntegerTrait::<i256>::new(1, true);
            let actual = two_complement_if_nec(input);
            let expected = i256 { mag: BoundedInt::max(), sign: true };

            assert(actual == expected, 'negative min wrong val');
        }

        #[test]
        fn test_negative_max_mag() {
            let input = IntegerTrait::<i256>::new(BoundedInt::max() / 2, true);
            let actual = two_complement_if_nec(input);
            let expected = i256 {
                mag: 57896044618658097711785492504343953926634992332820282019728792003956564819969,
                sign: true
            };

            assert(actual == expected, 'negative max wrong val');
        }

        #[test]
        fn test_positive_non_zero_mag() {
            let input = IntegerTrait::<i256>::new(12345, false);
            let actual = two_complement_if_nec(input);
            let expected = i256 { mag: 12345, sign: false };

            assert(actual == expected, 'positive non zero wrong value');
        }

        #[test]
        fn test_negative_non_zero_mag() {
            let input = IntegerTrait::<i256>::new(54321, true);
            let actual = two_complement_if_nec(input);
            let expected = i256 {
                mag: 115792089237316195423570985008687907853269984665640564039457584007913129585615,
                sign: true
            };

            assert(actual == expected, 'negative non zero wrong value');
        }
    }
}
