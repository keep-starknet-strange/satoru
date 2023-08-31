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
use gojo::bank::bank::{IBankSafeDispatcher, IBankSafeDispatcherTrait};
use gojo::market::market::Market;
use gojo::price::price::Price;
use gojo::utils::store_arrays::StoreMarketArray;
use gojo::oracle::oracle::IOracleSafeDispatcher;

/// Parameters to execute a swap.
#[derive(Drop, starknet::Store, Serde)]
struct SwapParams {
    /// The contract that provides access to data stored on-chain.
    data_store: IDataStoreSafeDispatcher,
    /// The contract that emits events.
    event_emitter: IEventEmitterSafeDispatcher,
    /// The contract that provides access to price data from oracles.
    oracle: IOracleSafeDispatcher,
    /// The contract providing the funds for the swap.
    bank: IBankSafeDispatcher,
    /// An identifying key for the swap.
    key: felt252,
    /// The address of the token that is being swapped.
    token_in: ContractAddress,
    /// The amount of the token that is being swapped.
    amount_in: u128,
    /// An array of market properties, specifying the markets in which the swap should be executed.
    swap_path_markets: Array<Market>,
    /// The minimum amount of tokens that should be received as part of the swap.
    min_output_amount: u128,
    /// The minimum amount of tokens that should be received as part of the swap.
    receiver: ContractAddress,
    /// The address of the ui fee receiver.
    ui_fee_receiver: ContractAddress,
    /// A boolean indicating whether the received tokens should be unwrapped from
    /// the wrapped native token (WNT) if they are wrapped.
    should_unwrap_native_token: bool,
}

#[derive(Drop, starknet::Store, Serde)]
struct _SwapParams {
    /// The market in which the swap should be executed.
    market: Market,
    /// The address of the token that is being swapped.
    token_in: ContractAddress,
    /// The amount of the token that is being swapped.
    amount_in: u128,
    /// The address to which the swapped tokens should be sent.
    receiver: ContractAddress,
    /// A boolean indicating whether the received tokens should be unwrapped from
    /// the wrapped native token (WNT) if they are wrapped.
    should_unwrap_native_token: bool,
}

#[derive(Drop, starknet::Store, Serde)]
struct SwapCache {
    /// The address of the token that is being received as part of the swap.
    token_out: ContractAddress,
    /// The price of the token that is being swapped.
    token_in_price: Price,
    /// The price of the token that is being received as part of the swap.
    token_out_price: Price,
    /// The amount of the token that is being swapped.
    amount_in: u128,
    /// The amount of the token that is being received as part of the swap.
    amount_out: u128,
    /// The total amount of the token that is being received by all users in the swap pool.
    pool_amount_out: u128,
    /// The price impact of the swap in USD.
    price_impact_usd: u128,
    /// The price impact of the swap in tokens.
    price_impact_amount: u128,
}

/// Swaps a given amount of a given token for another token based on a
/// specified swap path.
/// # Arguments
/// * `params` - The parameters for the swap.
/// # Returns
/// A tuple containing the address of the token that was received as
/// part of the swap and the amount of the received token.
#[inline(always)]
fn swap(params: SwapParams) -> (ContractAddress, u128) {
    //TODO
    (0.try_into().unwrap(), 0)
}

/// Perform a swap on a single market.
/// * `params` - The parameters for the swap.
/// * `_params` - The parameters for the swap on this specific market.
/// # Returns
/// The amount that was swapped.
#[inline(always)]
fn _swap(params: SwapParams, _params: _SwapParams) -> (ContractAddress, u128) {
    //TODO
    (0.try_into().unwrap(), 0)
}
