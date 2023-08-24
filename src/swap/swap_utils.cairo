use starknet::ContractAddress;
use result::ResultTrait;
use traits::{Into, TryInto};
use option::OptionTrait;

// Local imports.
use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use gojo::bank::bank::{IBankSafeDispatcher, IBankSafeDispatcherTrait};
use gojo::market::market::{Market};
use gojo::price::price::{Price};

#[derive(Drop, starknet::Store, Serde)]
struct SwapParams {
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    oracle: felt252, //TODO add IOracleDispatcher
    bank: IBankSafeDispatcher,
    key: felt252,
    token_in: ContractAddress,
    amount_int: u128,
    //swap_path_markets: Array<Market>,
    min_output_amount: u128,
    receiver: ContractAddress,
    ui_fee_receiver: ContractAddress,
    should_unwrap_native_token: bool,
}

#[derive(Drop, starknet::Store, Serde)]
struct _SwapParams {
    market: Market,
    token_in: ContractAddress,
    amount_int: u128,
    receiver: ContractAddress,
    should_unwrap_native_token: bool,
}

#[derive(Drop, starknet::Store, Serde)]
struct SwapCache {
    token_out: ContractAddress,
    token_in_price: Price,
    token_out_price: Price,
    amount_int: u128,
    amount_out: u128,
    pool_amount_out: u128,
    price_impact_usd: u128,
    price_impact_amount: u128,
}

#[external(v0)]
#[inline(always)]
fn swap(param: SwapParams) -> (ContractAddress, u128) {
    //TODO
    (0.try_into().unwrap(), 0)
}

#[inline(always)]
fn _swap(param: SwapParams, _params: _SwapParams) -> (ContractAddress, u128) {
    //TODO
    (0.try_into().unwrap(), 0)
}
