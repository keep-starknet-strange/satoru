use satoru::data::keys;
use starknet::{ContractAddress, contract_address_const};

#[test]
fn given_constant_keys_when_tested_then_expected_results() {
    let wnt = keys::wnt();
    assert(wnt == 0x74d98a44e50c39f5a55e16dec65fc43c09ca04efa146e762ab2e4cf8a02ae0e, 'wrong_key');

    let account_1: ContractAddress = contract_address_const::<1>();
    let account_deposit_list_key_account_1 = keys::account_deposit_list_key(account_1);
    assert(
        account_deposit_list_key_account_1 == 0x3d260a67237e2a5babde11feb7ae50a519c48b36fccb6337e2975e0545410a5,
        'wrong_key'
    );
}
