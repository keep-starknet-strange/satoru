// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress};


// Local imports.
use satoru::data::data_store::{IDataStoreSafeDispatcher};
use satoru::market::market::Market;

// const MARKET_SALT = keccak256(abi.encode("MARKET_SALT"));
// const MARKET_KEY = keccak256(abi.encode("MARKET_KEY"));
// const MARKET_TOKEN = keccak256(abi.encode("MARKET_TOKEN"));
// const INDEX_TOKEN = keccak256(abi.encode("INDEX_TOKEN"));
// const LONG_TOKEN = keccak256(abi.encode("LONG_TOKEN"));
// const SHORT_TOKEN = keccak256(abi.encode("SHORT_TOKEN"));

fn get(data_store: IDataStoreSafeDispatcher, market: ContractAddress) -> Market {
    // TODO
    Market { market_token: market, index_token: market, long_token: market, short_token: market }
}
