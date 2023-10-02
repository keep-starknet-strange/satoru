# Referral Module

The Referral Module handles user referrals, giving discounts and paybacks. It’s key for encouraging people to bring in others and rewarding them for helping the platform grow.

It contains the following Cairo library files:

- [referral_tier.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/referral/referral_tier.cairo): Defines the `ReferralTier` struct and contains related functionalities.
- [referral_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/referral/referral_utils.cairo): Houses various referral utility functions essential for managing referrals within the platform.

## Structures and Types

### `ReferralTier`
This struct encapsulates the total rebate for the tier, which is the sum of the affiliate reward and trader discount, and the share of the total rebate designated for traders.

## Functions

### `set_trader_referral_code`
This function sets the referral code for a trader and is vital for linking traders to their referrers, ensuring that the correct users receive their due rewards.

### `increment_affiliate_reward`
It increments the affiliate's reward balance by a specified delta, updating the reward balance and emitting an event signaling the update.

### `get_referral_info`
Retrieves the referral information for a specified trader, returning the referral code, the affiliate's address, the total rebate, and the discount share. It plays a crucial role in fetching referral details needed for various operations, like calculating rebates and discounts.

### `claim_affiliate_reward`
Allows claiming of the affiliate reward. It returns the reward amount and updates relevant balances and states to reflect the claimed reward.

## Errors

Specific error handling would be defined to manage any anomalies in referral operations, such as invalid referral codes, non-existent affiliates, etc., ensuring the robustness and reliability of the referral system.

## Imports

### Core Library Imports
- `starknet`: Used for core functionalities and structures in Starknet contracts.
- Several other local imports from the `satoru` project for various functionalities like data storage, event emission, and market utilities.

### Local Imports from `satoru` project
- `referral_storage`: For managing referral-related data storage operations.
- `data_store`: Centralized data storage used for storing and retrieving information about referrals, rewards, etc.
- `event_emitter`: Utilized for emitting events on the blockchain, allowing users and other contracts to track changes in the system.