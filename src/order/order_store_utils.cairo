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
    let order_option = data_store.get_order(key);
    match (order_option) {
        Option::Some(order) => order,
        Option::None(_) => panic_with_felt252(OrderError::EMPTY_ORDER)
    }
}

/// Link an Order with a key
/// # Arguments
/// * `key` - The key linked to the Order.
/// * `value` - The snapshot of the Order.
fn set(data_store: IDataStoreDispatcher, key: felt252, value: @Order) {
    data_store.set_order(key, *value);
}
