use traits::Default;

use core::option::OptionTrait;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::order::order::Order;
use satoru::order::error::OrderError;

/// Retrieves an Order from the passed key
/// # Arguments
/// * `key` - The key linked to the Order.
/// # Return
/// Return the corresponding Order object
fn get(data_store: IDataStoreDispatcher, key: felt252) -> Order {
    Default::default()
}

/// Link an Order with a key
/// # Arguments
/// * `key` - The key linked to the Order.
/// * `value` - The snapshot of the Order.
fn set(data_store: IDataStoreDispatcher, key: felt252, value: @Order) {}
