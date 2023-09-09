use traits::Default;

use satoru::data::data_store::IDataStoreSafeDispatcher;
use satoru::order::order::Order;

fn get(data_store: IDataStoreSafeDispatcher, key: felt252) -> Order {
    // TODO
    Default::default()
}

fn set(data_store: IDataStoreSafeDispatcher, key: felt252, value: @Order) { 
    // TODO
}
