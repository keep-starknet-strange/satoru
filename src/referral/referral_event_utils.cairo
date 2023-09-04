//! Library for referral event emitters.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;
use traits::{Into, TryInto};
use option::OptionTrait;

// Local imports.
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};

/// Emits event related to affiliate reward update.
/// # Arguments
/// * `event_emitter` - The `EventEmitter` safe dispatcher.
/// * `market` - The concerned market.
/// * `token` - The reward token address.
/// * `affiliate` - The affiliate address.
/// * `delta` - The reward variation.
/// * `next_value` - The new reward value.
/// * `next_pool_value` - The new pool value.
fn emit_affiliate_reward_update(
    event_emitter: IEventEmitterSafeDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    affiliate: ContractAddress,
    delta: u128,
    next_value: u128,
    next_pool_value: u128
) { // TODO
}

/// Emits event related to affiliate reward claim.
/// * `event_emitter` - The `EventEmitter` safe dispatcher.
/// * `market` - The concerned market.
/// * `token` - The reward token address.
/// * `affiliate` - The affiliate address.
/// * `receiver` - The receiver of the reward.
/// * `amount` - The amount claimed.
/// * `next_pool_value` - The new pool value.
fn emit_affiliate_reward_claimed(
    event_emitter: IEventEmitterSafeDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    affiliate: ContractAddress,
    receiver: ContractAddress,
    amount: u128,
    next_pool_value: u128
) { // TODO
}
