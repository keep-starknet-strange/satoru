// Gojo imports
use gojo::deposit::deposit::Deposit;
use gojo::event::event_utils::EventLogData;

// *************************************************************************
//                  Interface of the `DepositCallbackReceiver` contract.
// *************************************************************************
#[starknet::interface]
trait IDepositCallbackReceiver<TContractState> {
    /// Called after a deposit execution.
    /// # Arguments
    /// * `key` - They key of the deposit.
    /// * `event_data` - The event log data.
    /// * `deposit` - The deposit that was executed.
    fn after_deposit_execution(
        ref self: TContractState, key: felt252, deposit: Deposit, event_data: EventLogData,
    );

    /// Called after a deposit cancellation.
    /// # Arguments
    /// * `key` - They key of the deposit.
    /// * `event_data` - The event log data.
    /// * `deposit` - The deposit that was cancelled.
    fn after_deposit_cancellation(
        ref self: TContractState, key: felt252, deposit: Deposit, event_data: EventLogData,
    );
}
