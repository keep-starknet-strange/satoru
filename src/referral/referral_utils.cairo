//! Library for referral functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;

// Local imports.
use satoru::referral::referral_storage::interface::{
    IReferralStorageSafeDispatcher, IReferralStorageSafeDispatcherTrait
};
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};

/// Set the referral code for a trader.
/// # Arguments
/// * `referral_storage` - The referral storage instance to use.
/// * `account` - The account of the trader.
/// * `referral_code` - The referral code.
fn set_trader_referral_code(
    referral_storage: IReferralStorageSafeDispatcher,
    account: ContractAddress,
    referral_code: felt252
) { // TODO
}

/// Increments the affiliate's reward balance by the specified delta.
/// # Arguments
/// * `data_store` - The data store instance to use.
/// * `event_emitter` - The event emitter instance to use.
/// * `market` - The market address.
/// * `token` - The token address.
/// * `affiliate` - The affiliate address.
/// * `delta` - The amount to increment the reward balance by.
fn increment_affiliate_reward(
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    affiliate: ContractAddress,
    delta: u128
) { // TODO
}

/// Gets the referral information for the specified trader.
/// # Arguments
/// * `referral_storage` - The referral storage instance to use.
/// * `trader` - The trader address.
/// # Returns
/// The referral code, the affiliate's address, the total rebate, and the discount share.
fn get_referral_info(
    referral_storage: IReferralStorageSafeDispatcher, trader: ContractAddress
) -> (felt252, ContractAddress, u128, u128) {
    // TODO
    let address_zero: ContractAddress = 0.try_into().unwrap();
    (0, address_zero, 0, 0)
}

/// Gets the referral information for the specified trader.
/// # Arguments
/// * `data_store` - The data store instance to use.
/// * `event_emitter` - The event emitter instance to use.
/// * `market` - The market address.
/// * `token` - The token address.
/// * `account` - The affiliate address.
/// * `receiver` - The receiver of the rewards.
/// # Returns
/// The reward amount.
fn claim_affiliate_rewards(
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    affiliate: ContractAddress,
    receiver: ContractAddress
) -> u128 {
    // TODO
    0
}
