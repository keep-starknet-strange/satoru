// Satoru imports
use satoru::order::order::Order;
use satoru::event::event_utils::LogData;

// *************************************************************************
//                  Interface of the `OrderCallbackReceiver` contract.
// *************************************************************************
#[starknet::interface]
trait IOrderCallbackReceiver<TContractState> {
    /// Called after an order execution.
    /// # Arguments
    /// * `key` - They key of the order.
    /// * `order` - The order that was executed.
    /// * `log_data` - The log data.
    fn after_order_execution(
        ref self: TContractState, key: felt252, order: Order, log_data: LogData
    );

    /// Called after an order cancellation.
    /// # Arguments
    /// * `key` - They key of the order.
    /// * `order` - The order that was cancelled.
    /// * `log_data` - The log data.
    fn after_order_cancellation(
        ref self: TContractState, key: felt252, order: Order, log_data: LogData
    );

    /// Called after an order cancellation.
    /// # Arguments
    /// * `key` - They key of the order.
    /// * `order` - The order that was frozen.
    /// * `log_data` - The log data.
    fn after_order_frozen(ref self: TContractState, key: felt252, order: Order, log_data: LogData);
}
