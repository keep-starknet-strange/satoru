use satoru::data::keys;
use starknet::{ContractAddress, contract_address_const};

#[test]
fn given_constant_keys_when_tested_then_expected_results() {
    let fee_token_key = keys::fee_token();
    assert(
        fee_token_key == 0x32251f2c8577168e89dfd8e561b2f327cd63d892a6d58f90955cf548db4f64f,
        'wrong_key'
    );

    let account_1: ContractAddress = contract_address_const::<1>();
    let account_deposit_list_key_account_1 = keys::account_deposit_list_key(account_1);
    assert(
        account_deposit_list_key_account_1 == 0x3d260a67237e2a5babde11feb7ae50a519c48b36fccb6337e2975e0545410a5,
        'wrong_key'
    );
}
