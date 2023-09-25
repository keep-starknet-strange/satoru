//! Library for position store utility functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::position::position;

fn get(data_store: IDataStoreDispatcher, key: felt252) -> position::Position { // TODO
    Default::default()
}
