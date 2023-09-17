use starknet::ContractAddress;
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};

use satoru::data::data_store::IDataStoreDispatcherTrait;
use satoru::feature::feature_utils::{is_feature_disabled, validate_feature};
use satoru::tests_lib::{setup, teardown};

#[test]
fn given_normal_conditions_when_nonexist_feature_then_works() {
    let (_, _, data_store) = setup();

    // Returns false because feature does not exist so cannot be disabled.
    let nonexist_feature = is_feature_disabled(data_store, 'NONEXIST_FEATURE');
    assert(!nonexist_feature, 'Nonexist feature wrong');
}

#[test]
fn given_normal_conditions_when_exist_disable_feature_then_works() {
    let (_, _, data_store) = setup();

    data_store.set_bool('EXIST_FEATURE', true);

    // Returns true because feature is disabled
    let exist_feature = is_feature_disabled(data_store, 'EXIST_FEATURE');
    assert(exist_feature, 'Exist feature wrong');
}

#[test]
fn given_normal_conditions_when_nonexist_feature_validate_then_works() {
    let (_, _, data_store) = setup();

    // Should not revert because feature does not exist
    validate_feature(data_store, 'NONEXIST_FEATURE');
}

#[test]
#[should_panic(expected: ('FeatureUtils: disabled feature',))]
fn given_exist_feature_when_validate_feature_then_fails() {
    let (_, _, data_store) = setup();

    data_store.set_bool('EXIST_FEATURE', true);

    validate_feature(data_store, 'EXIST_FEATURE'); // Should revert because feature is disabled
}

#[test]
fn given_exist_enabled_feature_when_validate_feature_then_works() {
    let (_, _, data_store) = setup();

    data_store.set_bool('EXIST_FEATURE', false);

    validate_feature(data_store, 'EXIST_FEATURE'); // Should work because feature is enabled
}
