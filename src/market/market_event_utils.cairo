use starknet::ContractAddress;

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::market::market_pool_value_info::MarketPoolValueInfo;

fn emit_market_pool_value_info(
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    props: MarketPoolValueInfo,
    market_tokens_supply: u128
) {}

