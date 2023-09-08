// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress};

// Local imports.
use satoru::data::data_store::{IDataStoreSafeDispatcher};
use satoru::market::market::Market;

// TODO Doc
fn get(data_store: IDataStoreSafeDispatcher, market: ContractAddress) -> Market {
    // TODO Impl
    Market { market_token: market, index_token: market, long_token: market, short_token: market }
}
