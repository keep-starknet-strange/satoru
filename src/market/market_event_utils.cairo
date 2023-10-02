use starknet::ContractAddress;

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::market::market_pool_value_info::MarketPoolValueInfo;

fn emit_market_pool_value_info(
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    props: MarketPoolValueInfo,
    market_tokens_supply: u128
) {}

fn emit_virtual_swap_inventory_updated(
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    is_long_token: bool,
    virtual_market_id: felt252,
    delta: i128,
    next_value: u128
) {}

fn emit_virtual_position_inventory_updated(
    event_emitter: IEventEmitterDispatcher,
    token: ContractAddress,
    virtual_token_id: felt252,
    delta: i128,
    next_value: i128
) {}
