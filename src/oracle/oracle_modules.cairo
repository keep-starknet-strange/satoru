//! Equivalent of solidity modifers with before functions to put at the beginning of
//! functions and after functions to put at the end.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::oracle::{
    oracle::{IOracleDispatcher, IOracleDispatcherTrait},
    oracle_utils::{SetPricesParams, SimulatePricesParams},
};
use satoru::price::price::Price;
use satoru::oracle::error::OracleError;

/// Sets oracle prices, perform any additional tasks required,
/// and clear the oracle prices after.
///
/// Care should be taken to avoid re-entrancy while using this call
/// since re-entrancy could allow functions to be called with prices
/// meant for a different type of transaction.
/// The tokensWithPrices.length check in oracle.set_prices should help
/// mitigate this.
/// # Arguments
/// * `oracle` - `Oracle` contract dispatcher
/// * `dataStore` - `DataStore` contract dispatcher
/// * `eventEmitter` - `EventEmitter` contract dispatcher
/// * `params` - parameters used to set oracle price
#[inline(always)]
fn with_oracle_prices_before(
    oracle: IOracleDispatcher,
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    params: @SetPricesParams
) {
    oracle.set_prices(data_store, event_emitter, params.clone());
}

#[inline(always)]
fn with_oracle_prices_after(oracle: IOracleDispatcher) {
    oracle.clear_all_prices();
}

/// Set oracle prices for a simulation.
/// TokensWithPrices is not set in this function.
/// It is possible for withSimulatedOraclePrices to be called and a function
/// using withOraclePrices to be called after or for a function using withOraclePrices
/// to be called and withSimulatedOraclePrices called after.
/// This should not cause an issue because this transaction should always revert
/// and any state changes based on simulated prices as well as the setting of simulated
/// prices should not be persisted
/// # Arguments
/// * `oracle` - `Oracle` contract dispatcher
/// * `params` - parameters used to set oracle price

fn with_simulated_oracle_prices_before(oracle: IOracleDispatcher, params: SimulatePricesParams) {
    if (params.primary_tokens.len() != params.primary_prices.len()) {
        OracleError::INVALID_PRIMARY_PRICES_FOR_SIMULATION(
            params.primary_tokens.len(), params.primary_prices.len()
        );
    }
    let cur_idx = 0;
    loop {
        if (cur_idx == params.primary_tokens.len()) {
            break ();
        }
        let token: ContractAddress = *params.primary_tokens.at(cur_idx);
        let price: Price = *params.primary_prices.at(cur_idx);
        oracle.set_primary_price(token, price);
    };
}

#[inline(always)]
fn with_simulated_oracle_prices_after() {
    OracleError::END_OF_ORACLE_SIMULATION();
}
