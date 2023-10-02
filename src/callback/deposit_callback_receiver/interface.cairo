// Satoru imports
use satoru::deposit::deposit::Deposit;
use satoru::event::event_utils::LogData;

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
        ref self: TContractState, key: felt252, deposit: Deposit, log_data: LogData,
    );

    /// Called after a deposit cancellation.
    /// # Arguments
    /// * `key` - They key of the deposit.
    /// * `event_data` - The event log data.
    /// * `deposit` - The deposit that was cancelled.
    fn after_deposit_cancellation(
        ref self: TContractState, key: felt252, deposit: Deposit, log_data: LogData,
    );
}
