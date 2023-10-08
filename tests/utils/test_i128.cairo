use satoru::utils::i128::{I128Div, I128Mul, I128Serde};
use snforge_std::{declare, ContractClassTrait};


// Div
#[test]
fn test_i128_division() {
    assert(12_i128 / 3 == 4, 'should be 4');
}

#[test]
fn test_i128_division_lhs_neg() {
    assert(-12_i128 / 3 == -4, 'should be -4');
}

#[test]
fn test_i128_division_rhs_neg() {
    assert(12_i128 / -3 == -4, 'should be -4');
}

#[test]
fn test_i128_division_both_neg() {
    assert(-12_i128 / -3 == 4, 'should be 4');
}

#[test]
fn test_i128_division_zero() {
    assert(0_i128 / -3 == 0, 'should be 0');
}

#[test]
#[should_panic(expected: ('Division by 0',))]
fn test_i128_division_by_zero() {
    -12_i128 / 0;
}

// Mul 
#[test]
fn test_i128_multiplication() {
    assert(12_i128 * 3 == 36, 'should be 36');
}

#[test]
fn test_i128_multiplication_lhs_neg() {
    assert(-12_i128 * 3 == -36, 'should be -36');
}

#[test]
fn test_i128_multiplication_rhs_neg() {
    assert(12_i128 * -3 == -36, 'should be -36');
}

#[test]
fn test_i128_multiplication_both_neg() {
    assert(-12_i128 * -3 == 36, 'should be 36');
}

#[test]
fn test_i128_multiplication_zero() {
    assert(0_i128 * -3 == 0, 'should be 0');
}

#[test]
fn test_i128_multiplication_by_zero() {
    assert(-3_i128 * 0 == 0, 'should be 0');
}

#[starknet::interface]
trait ITestI128Storage<TContractState> {
    fn set_i128(ref self: TContractState, new_val: i128);
    fn get_i128(self: @TContractState) -> i128;
}

fn deploy() -> ITestI128StorageDispatcher {
    let contract = declare('test_i128_storage_contract');
    let contract_address = contract.deploy(@array![]).unwrap();
    ITestI128StorageDispatcher { contract_address }
}

#[test]
fn test_i128_storage() {
    let dispatcher = deploy();
    assert(dispatcher.get_i128() == 0, 'should be 0');
    dispatcher.set_i128(12);
    assert(dispatcher.get_i128() == 12, 'should be 12');
    dispatcher.set_i128(-42);
    assert(dispatcher.get_i128() == -42, 'should be -42');
    dispatcher.set_i128(0);
    assert(dispatcher.get_i128() == 0, 'should be back to 0');
}
