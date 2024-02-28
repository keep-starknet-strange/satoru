use traits::Into;

use satoru::data::data_store::IDataStoreDispatcherTrait;
use satoru::utils::starknet_utils::{sn_gasleft, sn_gasprice};
use satoru::tests_lib::{setup, teardown};

#[test]
fn given_normal_conditions_when_sn_gasleft_then_works() {
    // No value provided, so returns 0
    let default_value = sn_gasleft(array![]);
    assert(default_value == 0_u256, 'default value wrong');

    // Value provided then returns that value
    let value_as_felt: felt252 = 55_u256.into();
    let some_value = sn_gasleft(array![value_as_felt]);
    assert(some_value == 55_u256, 'some value wrong');
}

#[test]
fn given_normal_conditions_when_gasprice_then_works() {
    // No value provided, so returns 0
    let default_value = sn_gasprice(array![]);
    assert(default_value == 0_u256, 'default value wrong');

    // Value provided then returns that value
    let value_as_felt: felt252 = 35_u256.into();
    let some_value = sn_gasprice(array![value_as_felt]);
    assert(some_value == 35_u256, 'some value wrong');
}
