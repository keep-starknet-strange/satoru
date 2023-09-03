//! Library for position pricing functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;
use traits::{Into, TryInto};
use option::OptionTrait;

// Local imports.
use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::market::market::Market;
use gojo::price::price::Price;
use gojo::position::position::Position;
use gojo::referral::referral_storage::interface::{
    IReferralStorageSafeDispatcher, IReferralStorageSafeDispatcherTrait
};

/// Struct used in get_position_fees.
#[derive(Drop, starknet::Store, Serde)]
struct GetPositionFeesParams {
    /// The `DataStore` contract dispatcher.
    data_store: IDataStoreSafeDispatcher,
    /// The `ReferralStorage` contract dispatcher.
    referral_storage: IReferralStorageSafeDispatcher,
    /// The position struct.
    position: Position,
    /// The price of the collateral token.
    collateral_token_price: Price,
    /// Wether it is for a positive impact.
    for_positive_impact: bool,
    /// The long token contract address.
    long_token: ContractAddress,
    /// The short token contract address.
    short_token: ContractAddress,
    /// The size variation in USD.
    size_delta_usd: u128,
    /// The ui fee receiver contract address.
    ui_fee_receiver: ContractAddress,
}

/// Struct used in get_price_impact_usd.
#[derive(Drop, starknet::Store, Serde)]
struct GetPriceImpactUsdParams {
    /// The `DataStore` contract dispatcher.
    data_store: IDataStoreSafeDispatcher,
    /// The market to check.
    market: Market,
    /// The change in position size in USD.
    usd_delta: u128, // TODO i128 when Storeable
    /// Whether the position is long or short.
    is_long: bool,
}

/// Struct used to store open interest.
#[derive(Drop, starknet::Store, Serde)]
struct OpenInterestParams {
    /// The amount of long open interest.
    long_open_interest: u128,
    /// The amount of short open interest.
    short_open_interest: u128,
    /// The updated amount of long open interest.
    next_long_open_interest: u128,
    /// The updated amount of short open interest.
    next_short_open_interest: u128,
}

/// Struct to store position fees data.
#[derive(Drop, starknet::Store, Serde)]
struct PositionFees {
    /// The referral fees.
    referral: PositionReferralFees,
    /// The funding fees.
    funding: PositionFundingFees,
    /// The borrowing fees.
    borrowing: PositionBorrowingFees,
    /// The ui fees.
    ui: PositionUiFees,
    /// The collateral_token_price.
    collateral_token_price: Price,
    /// The position fee factor.
    position_fee_factor: u128,
    /// The amount of fee to the protocol.
    protocol_fee_amount: u128,
    /// The factor of fee due to receiver.
    position_fee_receiver_factor: u128,
    /// The amount of fee due to receiver.
    fee_receiver_amount: u128,
    /// The amount of fee due to the pool.
    fee_amount_for_pool: u128,
    /// The position fee amount for the pool
    position_fee_amount_for_pool: u128,
    /// The fee amount for increasing / decreasing the position.
    position_fee_amount: u128,
    /// The total cost amount in tokens excluding funding.
    total_cost_amount_excluding_funding: u128,
    /// The total cost amount in tokens.
    total_cost_amount: u128,
}

/// Struct used to store referral parameters useful for fees computation.
#[derive(Drop, starknet::Store, Serde)]
struct PositionReferralFees {
    /// The referral code used.
    referral_code: felt252,
    /// The referral affiliate of the trader.
    affiliate: ContractAddress,
    /// The trader address.
    trader: ContractAddress,
    /// The total rebate factor.
    total_rebate_factor: u128,
    /// The trader discount factor.
    trader_discount_factor: u128,
    /// The total rebate amount.
    total_rebate_amount: u128,
    /// The discount amount for the trader.
    trader_discount_amount: u128,
    /// The affiliate reward amount.
    affiliate_reward_amount: u128,
}

/// Struct used to store position borrowing fees.
#[derive(Drop, starknet::Store, Serde)]
struct PositionBorrowingFees {
    /// The borrowing fees amount in USD.
    borrowing_fee_usd: u128,
    /// The borrowing fees amount in tokens.
    borrowing_fee_amount: u128,
    /// The borrowing fees factor for receiver.
    borrowing_fee_receiver_factor: u128,
    /// The borrowing fees amount in tokens for fee receiver.
    borrowing_fee_amount_for_fee_receiver: u128,
}

/// Struct used to store position funding fees.
#[derive(Drop, starknet::Store, Serde)]
struct PositionFundingFees {
    /// The amount of funding fees in tokens.
    funding_fee_amount: u128,
    /// The negative funding fee in long token that is claimable.
    claimable_long_token_amount: u128,
    /// The negative funding fee in short token that is claimable.
    claimable_short_token_amount: u128,
    /// The latest long token funding fee amount per size for the market.
    latest_funding_fee_amount_per_size: u128,
    /// The latest long token funding amount per size for the market.
    latest_long_token_claimable_funding_amount_per_size: u128,
    /// The latest short token funding amount per size for the market.
    latest_short_token_claimable_funding_amount_per_size: u128,
}

/// Struct used to store position ui fees
#[derive(Drop, starknet::Store, Serde)]
struct PositionUiFees {
    /// The ui fee receiver address
    ui_fee_receiver: ContractAddress,
    /// The factor for fee receiver.
    ui_fee_receiver_factor: u128,
    /// The ui fee amount in tokens.
    ui_fee_amount: u128,
}

/// Get the price impact in USD for a position increase / decrease.
fn get_price_impact_usd(params: GetPriceImpactUsdParams) -> i128 {
    // TODO
    0
}

/// Called internally by get_price_impact_params().
fn get_price_impact_usd_(
    params: GetPriceImpactUsdParams,
    market: ContractAddress,
    open_interest_params: OpenInterestParams,
) -> i128 {
    // TODO
    0
}

/// Compute new open interest.
/// # Arguments
/// * `params` - Price impact in usd.
/// # Returns
/// New open interest.
fn get_next_open_interest(params: GetPriceImpactUsdParams) -> OpenInterestParams {
    // TODO
    OpenInterestParams {
        long_open_interest: 0,
        short_open_interest: 0,
        next_long_open_interest: 0,
        next_short_open_interest: 0,
    }
}

/// Compute new open interest for virtual inventory.
/// # Arguments
/// * `params` - Price impact in usd.
/// * `virtual_inventory` - Price impact in usd.
/// # Returns
/// New open interest for virtual inventory.
fn get_next_open_interest_for_virtual_inventory(
    params: GetPriceImpactUsdParams, virtual_inventory: i128,
) -> OpenInterestParams {
    // TODO
    OpenInterestParams {
        long_open_interest: 0,
        short_open_interest: 0,
        next_long_open_interest: 0,
        next_short_open_interest: 0,
    }
}

/// Compute new open interest.
/// # Arguments
/// * `params` - Price impact in usd.
/// * `long_open_interest` - Long positions open interest.
/// * `long_open_interest` - Short positions open interest.
/// # Returns
/// New open interest.
fn get_next_open_interest_params(
    params: GetPriceImpactUsdParams, long_open_interest: u128, short_open_interest: u128
) -> OpenInterestParams {
    // TODO
    OpenInterestParams {
        long_open_interest: 0,
        short_open_interest: 0,
        next_long_open_interest: 0,
        next_short_open_interest: 0,
    }
}

/// Compute position fees.
/// # Arguments
/// * `params` - parameters to compute position fees.
/// # Returns
/// Position fees.
fn get_position_fees(params: GetPositionFeesParams,) -> PositionFees {
    // TODO
    let address_zero: ContractAddress = 0.try_into().unwrap();
    let position_referral_fees = PositionReferralFees {
        referral_code: 0,
        affiliate: address_zero,
        trader: address_zero,
        total_rebate_factor: 0,
        trader_discount_factor: 0,
        total_rebate_amount: 0,
        trader_discount_amount: 0,
        affiliate_reward_amount: 0,
    };
    let position_funding_fees = PositionFundingFees {
        funding_fee_amount: 0,
        claimable_long_token_amount: 0,
        claimable_short_token_amount: 0,
        latest_funding_fee_amount_per_size: 0,
        latest_long_token_claimable_funding_amount_per_size: 0,
        latest_short_token_claimable_funding_amount_per_size: 0,
    };
    let position_borrowing_fees = PositionBorrowingFees {
        borrowing_fee_usd: 0,
        borrowing_fee_amount: 0,
        borrowing_fee_receiver_factor: 0,
        borrowing_fee_amount_for_fee_receiver: 0,
    };
    let position_ui_fees = PositionUiFees {
        ui_fee_receiver: address_zero, ui_fee_receiver_factor: 0, ui_fee_amount: 0,
    };
    let price = Price { min: 0, max: 0, };
    PositionFees {
        referral: position_referral_fees,
        funding: position_funding_fees,
        borrowing: position_borrowing_fees,
        ui: position_ui_fees,
        collateral_token_price: price,
        position_fee_factor: 0,
        protocol_fee_amount: 0,
        position_fee_receiver_factor: 0,
        fee_receiver_amount: 0,
        fee_amount_for_pool: 0,
        position_fee_amount_for_pool: 0,
        position_fee_amount: 0,
        total_cost_amount_excluding_funding: 0,
        total_cost_amount: 0,
    }
}

/// Compute borrowing fees data.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `collateral_token_price` - The price of the collateral token.
/// * `borrowing_fee_usd` - Borrowing fee amount in USD.
/// # Returns
/// Borrowing fees.
fn get_borrowing_fees(
    data_store: IDataStoreSafeDispatcher, collateral_token_price: Price, borrowing_fee_usd: u128,
) -> PositionBorrowingFees {
    // TODO
    PositionBorrowingFees {
        borrowing_fee_usd: 0,
        borrowing_fee_amount: 0,
        borrowing_fee_receiver_factor: 0,
        borrowing_fee_amount_for_fee_receiver: 0,
    }
}

/// Compute funding fees.
/// # Arguments
/// * `funding_fees` - The position funding fees struct to store fees.
/// * `position` - The position to compute funding fees for.
/// # Returns
/// Borrowing fees.
fn get_funding_fees(funding_fees: PositionFundingFees, position: Position,) -> PositionFundingFees {
    // TODO
    PositionFundingFees {
        funding_fee_amount: 0,
        claimable_long_token_amount: 0,
        claimable_short_token_amount: 0,
        latest_funding_fee_amount_per_size: 0,
        latest_long_token_claimable_funding_amount_per_size: 0,
        latest_short_token_claimable_funding_amount_per_size: 0,
    }
}

/// Compute ui fees.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `collateral_token_price` - The price of the collateral token.
/// * `ui_fee receiver` - The ui fee receiver address.
/// # Returns
/// Borrowing fees.
fn get_ui_fees(
    data_store: IDataStoreSafeDispatcher,
    collateral_token_price: Price,
    size_delta_usd: u128,
    ui_fee_receiver: ContractAddress
) -> PositionUiFees {
    // TODO
    let address_zero: ContractAddress = 0.try_into().unwrap();
    PositionUiFees { ui_fee_receiver: address_zero, ui_fee_receiver_factor: 0, ui_fee_amount: 0, }
}

/// Get position fees after applying referral rebates / discounts.
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `referral_storage` - The `ReferralStorage` contract dispatcher.
/// * `collateral_token_price` - The price of the collateral token.
/// * `for_positive_impact` - Wether it is for a positive impact.
/// * `account` - The user account address.
/// * `market` - The concerned market.
/// * `size_delta_usd` - The size variation in usd.
/// # Returns
/// Updated position fees.
fn get_position_fees_after_referral(
    data_store: IDataStoreSafeDispatcher,
    referral_storage: IReferralStorageSafeDispatcher,
    collateral_token_price: Price,
    for_positive_impact: bool,
    account: ContractAddress,
    market: ContractAddress,
    size_delta_usd: u128,
) -> PositionFees {
    // TODO
    let address_zero: ContractAddress = 0.try_into().unwrap();
    let position_referral_fees = PositionReferralFees {
        referral_code: 0,
        affiliate: address_zero,
        trader: address_zero,
        total_rebate_factor: 0,
        trader_discount_factor: 0,
        total_rebate_amount: 0,
        trader_discount_amount: 0,
        affiliate_reward_amount: 0,
    };
    let position_funding_fees = PositionFundingFees {
        funding_fee_amount: 0,
        claimable_long_token_amount: 0,
        claimable_short_token_amount: 0,
        latest_funding_fee_amount_per_size: 0,
        latest_long_token_claimable_funding_amount_per_size: 0,
        latest_short_token_claimable_funding_amount_per_size: 0,
    };
    let position_borrowing_fees = PositionBorrowingFees {
        borrowing_fee_usd: 0,
        borrowing_fee_amount: 0,
        borrowing_fee_receiver_factor: 0,
        borrowing_fee_amount_for_fee_receiver: 0,
    };
    let position_ui_fees = PositionUiFees {
        ui_fee_receiver: address_zero, ui_fee_receiver_factor: 0, ui_fee_amount: 0,
    };
    let price = Price { min: 0, max: 0, };
    PositionFees {
        referral: position_referral_fees,
        funding: position_funding_fees,
        borrowing: position_borrowing_fees,
        ui: position_ui_fees,
        collateral_token_price: price,
        position_fee_factor: 0,
        protocol_fee_amount: 0,
        position_fee_receiver_factor: 0,
        fee_receiver_amount: 0,
        fee_amount_for_pool: 0,
        position_fee_amount_for_pool: 0,
        position_fee_amount: 0,
        total_cost_amount_excluding_funding: 0,
        total_cost_amount: 0,
    }
}
