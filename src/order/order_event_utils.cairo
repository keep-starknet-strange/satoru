use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};

fn emit_order_updated(
    event_emitter: IEventEmitterDispatcher,
    key: felt252,
    size_delta_usd: u128,
    acceptable_price: u128,
    trigger_price: u128,
    min_output_amount: u128
) { // TODO
}
