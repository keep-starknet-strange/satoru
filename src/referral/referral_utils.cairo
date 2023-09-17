//! Library for referral functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;

// Local imports.
use satoru::mock::referral_storage::{
    IReferralStorageDispatcher, IReferralStorageDispatcherTrait
};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::keys;
/// Set the referral code for a trader.
/// # Arguments
/// * `referral_storage` - The referral storage instance to use.
/// * `account` - The account of the trader.
/// * `referral_code` - The referral code.
fn set_trader_referral_code(
    referral_storage: IReferralStorageDispatcher, account: ContractAddress, referral_code: felt252
){
    if (referral_code == 0){
        return;
    }
    referral_storage.set_trader_referral_code(account, referral_code);
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
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    affiliate: ContractAddress,
    delta: u128
) {
    if (delta == 0){
        return;
    }
    let next_value: u128 = data_store.increment_u128(keys::affiliate_reward_for_account_key(market, token, affiliate), delta);
    let next_pool_value: u128 = data_store.increment_u128(keys::affiliate_reward_key(market, token), delta);

    event_emitter.emit_affiliate_reward_updated(market, token, affiliate, delta, next_value, next_pool_value);
}

/// Gets the referral information for the specified trader.
/// # Arguments
/// * `referral_storage` - The referral storage instance to use.
/// * `trader` - The trader address.
/// # Returns
/// The referral code, the affiliate's address, the total rebate, and the discount share.
fn get_referral_info(
    referral_storage: IReferralStorageDispatcher, trader: ContractAddress
) -> (felt252, ContractAddress, u128, u128) {
    // TODO
    let code: felt252 = referral_storage.trader_referral_codes(trader);
    let affiliate: ContractAddress = ContractAddressZeroable::zero();
    let total_rebate: u128 = 0;
    let discount_share: u128 = 0;
    if (code != 0){
        affiliate = referral_storage.code_owners(code);
        referral_tier_level = referral_storage.referrer_tiers(affiliate);
        (total_rebate, discount_share) = referral_storage.tiers(referral_tier_level);
        custom_discount_share = referral_storage.referrer_discount_shares(affiliate);
        if (custom_discount_share != 0){
            discount_share = custom_discount_share;
        }
    }

    return (code, affiliate,precision::basis_points_to_float(total_rebate),precision::basis_points_to_float(discount_share));
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
fn claim_affiliate_reward(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    account: ContractAddress,
    receiver: ContractAddress
) -> u128 {
    let key: felt252 = keys::affiliate_reward_for_account_key(market, token, account);

    let reward_amount: u128 = data_store.get_u128(key);
    data_store.set_u128(key, 0);

    let next_pool_value: u128 = data_store.decrement_u128(keys::affiliate_reward_key(market, token), reward_amount);

    market_utils::validate_market_token_balance(data_store, market);

    event_emitter.emit_affiliate_reward_claimed(market, token, account, receiver, reward_amount, next_pool_value);

    return reward_amount;

}
