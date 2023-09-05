// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;

// Local imports.
use satoru::withdrawal::withdrawal::{Withdrawal};
use satoru::withdrawal::withdrawal_vault::{
    IWithdrawalVaultSafeDispatcher, IWithdrawalVaultSafeDispatcherTrait
};
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use satoru::swap::swap_utils::{SwapParams};
use satoru::market::market::{Market};
use satoru::utils::store_arrays::{StoreContractAddressArray, StoreU128Array};

#[inline(always)]
fn emit_withdrawal_created(
    event_emitter: IEventEmitterSafeDispatcher, key: felt252, withdrawal: Withdrawal,
) { // TODO
}

fn emit_withdrawal_executed(event_emitter: IEventEmitterSafeDispatcher, key: felt252,) { // TODO
}

fn emit_withdrawal_cancelled(
    event_emitter: IEventEmitterSafeDispatcher,
    key: felt252,
    reason: felt252,
    reason_bytes: Array<felt252>,
) { // TODO
}
