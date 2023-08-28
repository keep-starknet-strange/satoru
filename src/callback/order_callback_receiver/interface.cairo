// Gojo imports
use gojo::order::order::{Order};
use gojo::event::event_utils::{EventLogData};

// *************************************************************************
//                  Interface of the `OrderCallbackReceiver` contract.
// *************************************************************************
#[starknet::interface]
trait IOrderCallbackReceiver<TContractState> {
    /// Called after an order execution.
    /// # Arguments
    /// * `key` - They key of the order.
    /// * `order` - The order that was executed.
    /// * `event_data` - The event log data.
    fn after_order_execution(
        ref self: TContractState, key: felt252, order: Order, event_data: EventLogData,
    );
    /// Called after an order cancellation.
    /// # Arguments
    /// * `key` - They key of the order.
    /// * `order` - The order that was cancelled.
    /// * `event_data` - The event log data.
    fn after_order_cancellation(
        ref self: TContractState, key: felt252, order: Order, event_data: EventLogData,
    );
    /// Called after an order cancellation.
    /// # Arguments
    /// * `key` - They key of the order.
    /// * `order` - The order that was frozen.
    /// * `event_data` - The event log data.
    fn after_order_frozen(
        ref self: TContractState, key: felt252, order: Order, event_data: EventLogData,
    );
}
