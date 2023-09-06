use starknet::{ContractAddress, contract_address_const};
use satoru::utils::account_utils::{validate_account, validate_receiver};

#[test]
fn test_validate_account() {
    let account = contract_address_const::<0x69420>();
    validate_account(account);
}

#[test]
#[should_panic(expected: ('null_account',))]
fn test_validate_account_fail() {
    let account = contract_address_const::<0>();
    validate_account(account);
}

#[test]
fn test_validate_receiver() {
    let account = contract_address_const::<0x69420>();
    validate_receiver(account);
}

#[test]
#[should_panic(expected: ('null_receiver',))]
fn test_validate_receiver_fail() {
    let account = contract_address_const::<0>();
    validate_receiver(account);
}
