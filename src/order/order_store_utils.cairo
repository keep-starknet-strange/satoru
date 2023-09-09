use traits::Default;

use satoru::data::data_store::IDataStoreDispatcher;
use satoru::order::order::Order;

fn get(data_store: IDataStoreDispatcher, key: felt252) -> Order {
    // TODO
    Default::default()
}

fn set(data_store: IDataStoreDispatcher, key: felt252, value: @Order) {// TODO
}
