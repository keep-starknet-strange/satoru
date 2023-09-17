use satoru::{I128Div, I1288Mul, I128Serde};
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

#[starknet::contract]
mod test_i128_storage_contract {
    use satoru::{StoreI128, I128Serde};
    use super::ITestI128Storage;


    #[storage]
    struct Storage {
        my_i128: i128
    }

    #[external(v0)]
    impl Public of ITestI128Storage<ContractState> {
        fn set_i128(ref self: ContractState, new_val: i128) {
            self.my_i128.write(new_val);
        }
        fn get_i128(self: @ContractState) -> i128 {
            self.my_i128.read()
        }
    }
}

use starknet::{deploy_syscall, ClassHash};

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
