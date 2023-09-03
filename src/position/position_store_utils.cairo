// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;
use traits::{Into, TryInto};
use option::OptionTrait;

// Local imports.

use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use gojo::order::order::OrderType;
use gojo::position::position::Position;
use gojo::price::price::Price;

/// Struct used for a position increase.
#[derive(Drop, starknet::Store, Serde)]
struct PositionIncreaseParams {
    /// The `EventEmitter` contract dispatcher.
    event_emitter: IEventEmitterSafeDispatcher,
    /// The key of the order.
    order_key: felt252,
    /// The key of the position.
    position_key: felt252,
    /// The position struct.
    position: Position,
    /// The index token price.
    index_token_price: Price,
    /// The collateral token price.
    collateral_token_price: Price,
    /// The execution price.
    execution_price: u128,
    /// The size variation in USD.
    size_delta_usd: u128,
    /// The size variation in tokens.
    size_delta_in_tokens: u128,
    /// The collateral variation in tokens.
    collateral_delta_amount: u128, // TODO i128 when storeable
    /// The price impact of the position increase in USD.
    price_impact_usd: u128, // TODO i128 when storeable
    /// The price impact of the position increase in tokens.
    price_impact_amount: u128, // TODO i128 when storeable
    /// The order type.
    order_type: OrderType
}

/// Get a position with its key.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `key` - The key of the position to retrieve.
/// # Returns
/// Position linked to key.
fn get(data_store: IDataStoreSafeDispatcher, key: felt252) -> Position {
    // TODO
    let address_zero: ContractAddress = 0.try_into().unwrap();
    Position {
        account: address_zero,
        market: address_zero,
        collateral_token: address_zero,
        size_in_usd: 0,
        size_in_tokens: 0,
        collateral_amount: 0,
        borrowing_factor: 0,
        funding_fee_amount_per_size: 0,
        long_token_claimable_funding_amount_per_size: 0,
        short_token_claimable_funding_amount_per_size: 0,
        increased_at_block: 0,
        decreased_at_block: 0,
        is_long: true
    }
}

/// Store a position with its key.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `key` - The key of the position to store.
/// * `position` - The position to store.
#[inline(always)]
fn set(data_store: IDataStoreSafeDispatcher, key: felt252, position: Position) { // TODO
}

/// Remove a position at key.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `key` - The key of the position to remove.
/// * `account` - The account of user.
fn remove(data_store: IDataStoreSafeDispatcher, key: felt252, account: ContractAddress) { // TODO
}

/// Get positions length.
fn get_position_count(data_store: IDataStoreSafeDispatcher) -> u128 {
    // TODO
    0
}

/// Get positions between keys.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `start` - The starting index, included.
/// * `key` - The ending index, excluded.
fn get_position_keys(
    data_store: IDataStoreSafeDispatcher, start: u128, end: u128
) -> Array<felt252> {
    // TODO
    ArrayTrait::new()
}

/// Get amount of positions linked to an address.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `account` - The account address to get postitions from.
fn get_account_position_count(
    data_store: IDataStoreSafeDispatcher, account: ContractAddress
) -> u128 {
    // TODO
    0
}

/// Get positions keys linked to an address.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `account` - The account address to get postitions from.
/// * `start` - The starting index, included.
/// * `key` - The ending index, excluded.
fn get_account_position_keys(
    data_store: IDataStoreSafeDispatcher, account: ContractAddress, start: u128, end: u128
) -> Array<felt252> {
    // TODO
    ArrayTrait::new()
}
