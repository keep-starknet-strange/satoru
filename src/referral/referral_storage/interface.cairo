// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::order::order::Order;
use satoru::event::event_utils::EventLogData;

// *************************************************************************
//                  Interface of the `ReferralStorage` contract.
// *************************************************************************
#[starknet::interface]
trait IReferralStorage<TContractState> {
    /// Get the owner of a referral code.
    /// # Arguments
    /// * `code` - The referral code.
    /// # Returns
    /// The owner of the referral code.
    fn code_owners(self: @TContractState, code: felt252) -> ContractAddress;

    /// Get the referral code of a trader.
    /// # Arguments
    /// * `account` - The address of the trader.
    /// # Returns
    /// The referral code.
    fn trader_referral_codes(self: @TContractState, account: ContractAddress) -> felt252;

    /// Get the trader discount share for an affiliate.
    /// # Arguments
    /// * `account` - The address of the affiliate.
    /// # Returns
    /// The trader discount share.
    fn referrer_discount_share(self: @TContractState, account: ContractAddress) -> u128;

    /// Get the tier level of an affiliate.
    /// # Arguments
    /// * `account` - The address of the affiliate.
    /// # Returns
    /// The tier level of the affiliate.
    fn referrer_tiers(self: @TContractState, account: ContractAddress) -> u128;

    /// Get the referral info for a trader.
    /// # Arguments
    /// * `account` - The address of the trader.
    /// # Returns
    /// (referral code, affiliate).
    fn get_trader_referral_info(
        self: @TContractState, account: ContractAddress
    ) -> (felt252, ContractAddress);

    /// Set the referral code for a trader.
    /// # Arguments
    /// * `account` - The address of the trader.
    /// * `code` - The referral code of the trader.
    fn set_trader_referral_info(ref self: TContractState, account: ContractAddress);

    /// Set the values for a tier.
    /// # Arguments
    /// * `tier_id` - The tier level.
    /// * `total_rebate` - The total rebate for the tier (affiliate reward + trader discount).
    /// * `discount_share` - The share of the total_rebate for traders.
    fn set_tier(ref self: TContractState, tier_id: u128, total_rebate: u128, discount_share: u128);

    /// Set the tier for an affiliate.
    /// # Arguments
    /// * `referrer` - The referrer.
    /// * `tier_id` - The tier level.
    fn set_referrer_tier(ref self: TContractState, referrer: ContractAddress, tier_id: u128);

    /// Set the owner for a referral code.
    /// # Arguments
    /// * `code` - The referral code.
    /// * `new_account` - The new owner.
    fn gov_set_code_owner(ref self: TContractState, code: felt252, new_account: ContractAddress);

    /// Get the tier values for a tier level.
    /// # Arguments
    /// * `tier_level` - The tier level.
    /// # Returns
    /// (totalRebate, discountShare).
    fn tiers(self: @TContractState, tier_level: u128) -> (u128, u128);
}
