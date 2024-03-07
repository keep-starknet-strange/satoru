//! Library for referral tier struct.

#[derive(Drop, starknet::Store, Serde)]
struct ReferralTier {
    /// The total rebate for the tier (affiliate reward + trader discount).
    total_rebate: u256,
    /// The share of the totalRebate for traders.
    discount_share: u256
}
