use starknet::{ContractAddress, contract_address_const};
use satoru::utils::account_utils::{validate_account, validate_receiver};

#[test]
fn given_normal_conditions_when_validate_account_then_works() {
    let account = contract_address_const::<0x69420>();
    validate_account(account);
}

#[test]
#[should_panic(expected: ('null_account',))]
fn given_account_null_when_validate_account_then_fails() {
    let account = contract_address_const::<0>();
    validate_account(account);
}

#[test]
fn given_normal_conditions_when_validate_receiver_then_works() {
    let account = contract_address_const::<0x69420>();
    validate_receiver(account);
}

#[test]
#[should_panic(expected: ('null_receiver',))]
fn given_account_null_when_validate_receiver_then_fails() {
    let account = contract_address_const::<0>();
    validate_receiver(account);
}
