use snforge_std::{declare, ContractClassTrait};
use satoru::utils::{i128, calc::{max_i128, min_i128}};

// Add
#[test]
fn test_i128_sum() {
    assert(
        i128::i128_new(12, false) + i128::i128_new(3, false) == i128::i128_new(15, false),
        'should be 15'
    );
}

#[test]
fn test_i128_sum_lhs_neg() {
    assert(
        i128::i128_new(12, true) + i128::i128_new(3, false) == i128::i128_new(9, true),
        'should be -9'
    );
}

#[test]
fn test_i128_sum_rhs_neg() {
    assert(
        i128::i128_new(12, false) + i128::i128_new(3, true) == i128::i128_new(9, false),
        'should be 9'
    );
}

#[test]
fn test_i128_sum_both_neg() {
    assert(
        i128::i128_new(12, true) + i128::i128_new(3, true) == i128::i128_new(15, true),
        'should be 4'
    );
}

#[test]
fn test_i128_sum_zero() {
    assert(
        i128::i128_new(0, false) + i128::i128_new(3, true) == i128::i128_new(3, true),
        'should be 3'
    );
}

#[test]
fn test_i128_sum_limit_max() {
    assert(
        max_i128() + i128::i128_new(3, true) + i128::i128_new(2, false) == max_i128() - i128::i128_new(1, false),
        'should be max - 1'
    );
}

#[test]
fn test_i128_sum_limit_min() {
    assert(
        min_i128() + i128::i128_new(3, false) + i128::i128_new(2, true) == min_i128() + i128::i128_new(1, false),
        'should be min + 1'
    );
}

#[test]
#[should_panic(expected: ('i128 Overflow',))]
fn test_i128_sum_max_overflow() {
    max_i128() + i128::i128_new(1, false);
}

#[test]
#[should_panic(expected: ('i128 Overflow',))]
fn test_i128_sum_max_underflow() {
    min_i128() + i128::i128_new(1, true);
}

// Sub
#[test]
fn test_i128_sub() {
    assert(
        i128::i128_new(12, false) - i128::i128_new(3, false) == i128::i128_new(9, false),
        'should be 9'
    );
}

#[test]
fn test_i128_sub_lhs_neg() {
    assert(
        i128::i128_new(12, true) - i128::i128_new(3, false) == i128::i128_new(15, true),
        'should be -15'
    );
}

#[test]
fn test_i128_sub_rhs_neg() {
    assert(
        i128::i128_new(12, false) - i128::i128_new(3, true) == i128::i128_new(15, false),
        'should be 15'
    );
}

#[test]
fn test_i128_sub_both_neg() {
    assert(
        i128::i128_new(12, true) - i128::i128_new(3, true) == i128::i128_new(9, true),
        'should be -9'
    );
}

#[test]
fn test_i128_sub_zero() {
    assert(
        i128::i128_new(0, false) - i128::i128_new(3, true) == i128::i128_new(3, false),
        'should be 3'
    );
}

#[test]
fn test_i128_sub_limit_max() {
    assert(
        max_i128() - i128::i128_new(3, false) - i128::i128_new(2, true) == max_i128() - i128::i128_new(1, false),
        'should be max - 1'
    );
}

#[test]
fn test_i128_sub_limit_min() {
    assert(
        min_i128() - i128::i128_new(3, true) - i128::i128_new(2, false) == min_i128() - i128::i128_new(1, true),
        'should be min + 1'
    );
}

#[test]
#[should_panic(expected: ('i128 Overflow',))]
fn test_i128_sub_max_overflow() {
    max_i128() - i128::i128_new(1, true);
}

#[test]
#[should_panic(expected: ('i128 Overflow',))]
fn test_i128_sub_max_underflow() {
    min_i128() - i128::i128_new(1, false);
}

// Div
#[test]
fn test_i128_division() {
    assert(
        i128::i128_new(12, false) / i128::i128_new(3, false) == i128::i128_new(4, false),
        'should be 4'
    );
}

#[test]
fn test_i128_division_lhs_neg() {
    assert(
        i128::i128_new(12, true) / i128::i128_new(3, false) == i128::i128_new(4, true),
        'should be -4'
    );
}

#[test]
fn test_i128_division_rhs_neg() {
    assert(
        i128::i128_new(12, false) / i128::i128_new(3, true) == i128::i128_new(4, true),
        'should be -4'
    );
}

#[test]
fn test_i128_division_both_neg() {
    assert(
        i128::i128_new(12, true) / i128::i128_new(3, true) == i128::i128_new(4, false),
        'should be 4'
    );
}

#[test]
fn test_i128_division_zero() {
    assert(
        i128::i128_new(0, false) / i128::i128_new(3, true) == i128::i128_new(0, false),
        'should be 0'
    );
}

#[test]
#[should_panic(expected: ('Division by 0',))]
fn test_i128_division_by_zero() {
    i128::i128_new(12, true) / i128::i128_new(0, false);
}

// Mul 
#[test]
fn test_i128_multiplication() {
    assert(
        i128::i128_new(12, false) * i128::i128_new(3, false) == i128::i128_new(36, false),
        'should be 36'
    );
}

#[test]
fn test_i128_multiplication_lhs_neg() {
    assert(
        i128::i128_new(12, true) * i128::i128_new(3, false) == i128::i128_new(36, true),
        'should be -36'
    );
}

#[test]
fn test_i128_multiplication_rhs_neg() {
    assert(
        i128::i128_new(12, false) * i128::i128_new(3, true) == i128::i128_new(36, true),
        'should be -36'
    );
}

#[test]
fn test_i128_multiplication_both_neg() {
    assert(
        i128::i128_new(12, true) * i128::i128_new(3, true) == i128::i128_new(36, false),
        'should be 36'
    );
}

#[test]
fn test_i128_multiplication_zero() {
    assert(
        i128::i128_new(0, false) * i128::i128_new(3, true) == i128::i128_new(0, false),
        'should be 0'
    );
}

#[test]
fn test_i128_multiplication_by_zero() {
    assert(
        i128::i128_new(3, true) * i128::i128_new(0, false) == i128::i128_new(0, false),
        'should be 0'
    );
}
// #[starknet::interface]
// trait ITestI128Storage<TContractState> {
//     fn set_i128(ref self: TContractState, i128_new_val: i128);
//     fn get_i128(self: @TContractState) -> i128;
// }

// fn deploy() -> ITestI128StorageDispatcher {
//     let contract = declare('test_i128_storage_contract');
//     let contract_address = contract.deploy(@array![]).unwrap();
//     ITestI128StorageDispatcher { contract_address }
// }

// #[test]
// fn test_i128_storage() {
//     let dispatcher = deploy();
//     assert(dispatcher.get_i128() == 0, 'should be 0');
//     dispatcher.set_i128(12);
//     assert(dispatcher.get_i128() == 12, 'should be 12');
//     dispatcher.set_i128(-42);
//     assert(dispatcher.get_i128() == -42, 'should be -42');
//     dispatcher.set_i128(0);
//     assert(dispatcher.get_i128() == 0, 'should be back to 0');
// }


