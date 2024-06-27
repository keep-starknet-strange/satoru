//! Library for referral functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use result::ResultTrait;

// Local imports.
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::market::market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait};
use satoru::bank::bank;
use satoru::utils::precision;
use satoru::market::market_utils;
use satoru::data::keys;
use satoru::referral::referral_tier::ReferralTier;


/// Set the referral code for a trader.
/// # Arguments
/// * `referral_storage` - The referral storage instance to use.
/// * `account` - The account of the trader.
/// * `referral_code` - The referral code.
fn set_trader_referral_code(
    referral_storage: IReferralStorageDispatcher, account: ContractAddress, referral_code: felt252
) {
    if (referral_code == 0) {
        return;
    }
    referral_storage.set_trader_referral_code(account, referral_code);
}

/// Increments the affiliate's reward balance by the specified delta.
/// # Arguments
/// * `data_store` - The data store instance to use.
/// * `event_emitter` - The event emitter instance to use.
// / * `market` - The market address.
/// * `token` - The token address.
/// * `affiliate` - The affiliate address.
/// * `delta` - The amount to increment the reward balance by.
fn increment_affiliate_reward(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    affiliate: ContractAddress,
    delta: u256
) {
    if (delta == 0) {
        return;
    }
    let next_value: u256 = data_store
        .increment_u256(keys::affiliate_reward_for_account_key(market, token, affiliate), delta);
    let next_pool_value: u256 = data_store
        .increment_u256(keys::affiliate_reward_key(market, token), delta);

    event_emitter
        .emit_affiliate_reward_updated(
            market, token, affiliate, delta, next_value, next_pool_value
        );
}

/// Gets the referral information for the specified trader.
/// # Arguments
/// * `referral_storage` - The referral storage instance to use.
/// * `trader` - The trader address.
/// # Returns
/// The referral code, the affiliate's address, the total rebate, and the discount share.
fn get_referral_info(
    referral_storage: IReferralStorageDispatcher, trader: ContractAddress
) -> (felt252, ContractAddress, u256, u256) {
    let code: felt252 = referral_storage.trader_referral_codes(trader);
    let mut affiliate = contract_address_const::<0>();
    let mut total_rebate: u256 = 0;
    let mut discount_share: u256 = 0;
    if (code != 0) {
        affiliate = referral_storage.code_owners(code);
        let referral_tier_level: u256 = referral_storage.referrer_tiers(affiliate);
        let referral_tier: ReferralTier = referral_storage.tiers(referral_tier_level);
        total_rebate = referral_tier.total_rebate;
        discount_share = referral_tier.discount_share;
        let custom_discount_share: u256 = referral_storage.referrer_discount_shares(affiliate);
        if (custom_discount_share != 0) {
            discount_share = custom_discount_share;
        }
    }

    return (
        code,
        affiliate,
        precision::basis_points_to_float(total_rebate),
        precision::basis_points_to_float(discount_share)
    );
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
) -> u256 {
    let key: felt252 = keys::affiliate_reward_for_account_key(market, token, account);

    let reward_amount: u256 = data_store.get_u256(key);
    data_store.set_u256(key, 0);

    let next_pool_value: u256 = data_store
        .decrement_u256(keys::affiliate_reward_key(market, token), reward_amount);

    IMarketTokenDispatcher { contract_address: market }
        .transfer_out(market, token, receiver, reward_amount);

    market_utils::validate_market_token_balance_with_address(data_store, market);

    event_emitter
        .emit_affiliate_reward_claimed(
            market, token, account, receiver, reward_amount, next_pool_value
        );

    return reward_amount;
}
