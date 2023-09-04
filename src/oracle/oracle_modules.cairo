//! Equivalent of solidity modifers with before functions to put at the beginning of
//! functions and after functions to put at the end.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.

// Local imports.
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use satoru::oracle::{
    oracle::{IOracleDispatcher}, oracle_utils::{SetPricesParams, SimulatePricesParams},
};

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
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    params: SetPricesParams
) { //TODO
}

#[inline(always)]
fn with_oracle_prices_after() { //TODO
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
#[inline(always)]
fn with_simulated_oracle_prices_before(
    oracle: IOracleDispatcher, params: SimulatePricesParams
) { //TODO
}

#[inline(always)]
fn with_simulated_oracle_prices_after() { //TODO
}
