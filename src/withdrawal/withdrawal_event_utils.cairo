// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;
use traits::{Into, TryInto};
use option::OptionTrait;

// Local imports.
use gojo::withdrawal::withdrawal::{Withdrawal};
use gojo::withdrawal::withdrawal_vault::{
    IWithdrawalVaultSafeDispatcher, IWithdrawalVaultSafeDispatcherTrait
};
use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use gojo::swap::swap_utils::{SwapParams};
use gojo::market::market::{Market};
use gojo::utils::store_arrays::{StoreContractAddressArray, StoreU128Array};

#[inline(always)]
fn emit_withdrawal_created(
    event_emitter: IEventEmitterSafeDispatcher, key: felt252, withdrawal: Withdrawal,
) { //TODO
}

fn emit_withdrawal_executed(event_emitter: IEventEmitterSafeDispatcher, key: felt252,) { //TODO
}

fn emit_withdrawal_cancelled(
    event_emitter: IEventEmitterSafeDispatcher,
    key: felt252,
    reason: felt252,
    reason_bytes: Array<felt252>,
) { //TODO
}
