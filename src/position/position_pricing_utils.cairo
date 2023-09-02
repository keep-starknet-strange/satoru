//! Library for position pricing functions

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;
use traits::{Into, TryInto};
use option::OptionTrait;
use core::integer::i128;

// Local imports.
use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use gojo::bank::bank::{IBankSafeDispatcher, IBankSafeDispatcherTrait};
//use gojo::oracle::oracle::{IOracleSafeDispatcher, IOracleSafeDispatcherTrait}; TODO
use gojo::swap::swap_handler::{ISwapHandlerSafeDispatcher, ISwapHandlerSafeDispatcherTrait};
use gojo::market::market::{Market};
use gojo::market::market_utils::{MarketPrices};
use gojo::price::price::{Price};
use gojo::position::position::{Position};
use gojo::order::order::{Order, SecondaryOrderType};

#[derive(Drop, starknet::Store, Serde)]
struct GetPositionFeesParams {
    data_store: IDataStoreSafeDispatcher,
    referral_storage: u128, // TODO Referral storage dispatcher
    position: Position,
    collateral_token_price: Price,
    for_positive_impact: bool,
    long_token: ContractAddress,
    short_token: ContractAddress,
    size_delta_usd: u128,
    ui_fee_receiver: ContractAddress,
}

#[derive(Drop, starknet::Store, Serde)]
struct GetPriceImpactUsdParams {
    data_store: IDataStoreSafeDispatcher,
    /// The market to check
    market: Market,
    /// The change in position size in USD
    usd_delta: u128, // TODO i128 when Storeable
    /// Whether the position is long or short
    is_long: bool,
}

#[derive(Drop, starknet::Store, Serde)]
struct OpenInterestParams {
    /// The amount of long open interest
    long_open_interest: u128,
    /// The amount of short open interest
    short_open_interest: u128,
    /// The updated amount of long open interest
    next_long_open_interest: u128,
    /// The updated amount of short open interest
    next_short_open_interest: u128,
}

#[derive(Drop, starknet::Store, Serde)]
struct PositionFees {
    referral: PositionReferralFees,
    funding: PositionFundingFees,
    borrowing: PositionBorrowingFees,
    ui: PositionUiFees,
    collateral_token_price: Price,
    position_fee_factor: u128,
    protocol_fee_amount: u128,
    position_fee_receiver_factor: u128,
    fee_receiver_amount: u128,
    fee_amount_for_pool: u128,
    position_fee_amount_for_pool: u128,
    position_fee_amount: u128,
    total_cost_amount_excluding_funding: u128,
    total_cost_amount: u128,
}

#[derive(Drop, starknet::Store, Serde)]
struct PositionReferralFees {
    referral_code: felt252,
    /// The referral affiliate of the trader
    affiliate: ContractAddress,
    trader: ContractAddress,
    total_rebate_factor: u128,
    /// The discount amount for the trader
    trader_discount_factor: u128,
    total_rebate_amount: u128,
    trader_discount_amount: u128,
    /// The affiliate reward amount
    affiliate_reward_amount: u128,
}

#[derive(Drop, starknet::Store, Serde)]
struct PositionBorrowingFees {
    borrowing_fee_usd: u128,
    borrowing_fee_amount: u128,
    borrowing_fee_receiver_factor: u128,
    borrowing_fee_amount_for_fee_receiver: u128,
}

#[derive(Drop, starknet::Store, Serde)]
struct PositionFundingFees {
    /// The position's funding fee amount
    funding_fee_amount: u128,
    /// The negative funding fee in long token that is claimable
    claimable_long_token_amount: u128,
    /// The negative funding fee in short token that is claimable
    claimable_short_token_amount: u128,
    /// The latest long token funding fee amount per size for the market
    latest_funding_fee_amount_per_size: u128,
    /// The latest long token funding amount per size for the market
    latest_long_token_claimable_funding_amount_per_size: u128,
    /// The latest short token funding amount per size for the market
    latest_short_token_claimable_funding_amount_per_size: u128,
}

#[derive(Drop, starknet::Store, Serde)]
struct PositionUiFees {
    ui_fee_receiver: ContractAddress,
    ui_fee_receiver_factor: u128,
    ui_fee_amount: u128,
}
