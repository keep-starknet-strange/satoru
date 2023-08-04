// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;

// Local imports.
use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::data::keys;
use gojo::market::error::MarketError;

/// Get the long and short open interest for a market based on the collateral token used.
/// # Arguments
/// * `data_store` - The data store to use.
/// * `market` - The market to get the open interest for.
/// * `collateral_token` - The collateral token to check.
/// * `is_long` - Whether to get the long or short open interest.
/// * `divisor` - The divisor to use for the open interest.
fn get_open_interest(
    data_store: IDataStoreSafeDispatcher,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
    divisor: u256
) -> u256 {
    assert(divisor != 0, MarketError::DIVISOR_CANNOT_BE_ZERO);
    let key = keys::open_interest_key(market, collateral_token, is_long);
    data_store.get_u256(key).unwrap() / divisor
}
