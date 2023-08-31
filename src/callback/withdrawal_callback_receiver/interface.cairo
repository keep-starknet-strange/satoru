// Gojo imports
// use gojo::withdrawal::withdrawal::{Withdrawal}; TODO & then remove comments here and on params
use gojo::event::event_utils::EventLogData;

// *************************************************************************
//                  Interface of the `WithdrawalCallbackReceiver` contract.
// *************************************************************************
#[starknet::interface]
trait IWithdrawalCallbackReceiver<TContractState> {
    /// Called after a withdrawal execution.
    /// # Arguments
    /// * `key` - They key of the withdrawal.
    /// * `withdrawal` - The withdrawal that was executed.
    /// * `event_data` - The event log data.
    // TODO uncomment withdrawal when available
    fn after_withdrawal_execution(
        ref self: TContractState, key: felt252, //withdrawal: Withdrawal,
         event_data: EventLogData,
    );

    /// Called after an withdrawal cancellation.
    /// # Arguments
    /// * `key` - They key of the withdrawal.
    /// * `withdrawal` - The withdrawal that was cancelled.
    /// * `event_data` - The event log data.
    // TODO uncomment withdrawal when available
    fn after_withdrawal_cancellation(
        ref self: TContractState, key: felt252, //withdrawal: Withdrawal,
         event_data: EventLogData,
    );
}
