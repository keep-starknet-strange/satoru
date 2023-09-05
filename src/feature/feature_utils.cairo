//! Feature is a library contract that allows to validate if a feature is enabled or disabled.
//! Disabling a feature should only be used if it is absolutely necessary.
//! Disabling of features could lead to unexpected effects, e.g. increasing / decreasing of orders
//! could be disabled while liquidations may remain enabled.
//! This could also occur if the chain is not producing blocks and lead to liquidatable positions
//! when block production resumes.
//! The effects of disabling features should be carefully considered.

use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::feature::error::FeatureError;

/// Return if a feature is disabled.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `key` - The feature key.
/// # Returns
/// whether the feature is disabled.
fn is_feature_disabled(data_store: IDataStoreSafeDispatcher, key: felt252) -> bool {
    let response = match data_store.get_bool(key) {
        Result::Ok(v) => v,
        Result::Err => Option::None
    };

    match response {
        Option::Some(v) => !v,
        Option::None => true
    }
}

/// Validate whether a feature is enabled, reverts if the feature is disabled.
/// # Arguments
/// * `data_store` - The data storage contract dispatcher.
/// * `key` - The feature key.
fn validate_feature(data_store: IDataStoreSafeDispatcher, key: felt252) {
    assert(!is_feature_disabled(data_store, key), FeatureError::DISABLED_FEATURE);
}
