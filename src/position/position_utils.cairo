//! Library for position functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use satoru::oracle::oracle::{IOracleSafeDispatcher, IOracleSafeDispatcherTrait};
use satoru::swap::swap_handler::{ISwapHandlerSafeDispatcher, ISwapHandlerSafeDispatcherTrait};
use satoru::market::market::Market;
use satoru::market::market_utils::MarketPrices;
use satoru::price::price::Price;
use satoru::position::position::Position;
use satoru::pricing::position_pricing_utils::PositionFees;
use satoru::order::order::{Order, SecondaryOrderType};
use satoru::referral::referral_storage::interface::{
    IReferralStorageSafeDispatcher, IReferralStorageSafeDispatcherTrait
};
use satoru::order::base_order_utils::ExecuteOrderParamsContracts;

/// Struct used in increasePosition and decreasePosition.
#[derive(Drop, starknet::Store, Serde)]
struct UpdatePositionParams {
    /// BaseOrderUtils.ExecuteOrderParamsContracts
    contracts: ExecuteOrderParamsContracts,
    /// The values of the trading market.
    market: Market,
    /// The decrease position order.
    order: Order,
    /// The key of the order.
    order_key: felt252,
    /// The order's position.
    position: Position,
    /// The key of the order's position.
    position_key: felt252,
    /// The secondary oder type.
    secondary_order_type: SecondaryOrderType,
}

/// Struct to determine wether position collateral will be sufficient.
#[derive(Drop, starknet::Store, Serde)]
struct WillPositionCollateralBeSufficientValues {
    position_size_in_usd: u128,
    position_collateral_amount: u128,
    realized_pnl_usd: u128, // TODO replace with i128 when it derives Store
    open_interest_delta: u128, // TODO replace with i128 when it derives Store
}

/// Struct used as decrease_position_collateral output.
#[derive(Drop, starknet::Store, Serde)]
struct DecreasePositionCollateralValuesOutput {
    /// The output token address.
    output_token: ContractAddress,
    /// The output amount in tokens.
    output_amount: u128,
    /// The seconary output token address.
    secondary_output_token: ContractAddress,
    /// The secondary output amount in tokens.
    secondary_output_amount: u128,
}

/// Struct used to contain the values in process_collateral
#[derive(Drop, starknet::Store, Serde)]
struct DecreasePositionCollateralValues {
    /// The order execution price.
    execution_price: u128,
    /// The remaining collateral amount of the position.
    remaining_collateral_amount: u128,
    /// The pnl of the position in USD.
    base_pnl_usd: u128, // TODO replace with i128 when it derives Store
    /// The uncapped pnl of the position in USD.
    uncapped_base_pnl_usd: u128, // TODO replace with i128 when it derives Store
    /// The change in position size in tokens.
    size_delta_in_tokens: u128,
    /// The price impact in usd.
    price_impact_usd: u128, // TODO replace with i128 when it derives Store
    /// The price impact difference in USD.
    price_imact_diff_usd: u128,
    /// The output struct.
    output: DecreasePositionCollateralValuesOutput
}

#[derive(Drop, starknet::Store, Serde)]
struct DecreasePositionCache {
    /// The prices of the tokens in the market.
    prices: MarketPrices,
    /// The estimated position pnl in USD.
    estimated_position_pnl_usd: u128, // TODO replace with i128 when it derives Store
    /// The estimated realized position pnl in USD after decrease.
    estimated_realized_pnl_usd: u128, // TODO replace with i128 when it derives Store
    /// The estimated remaining position pnl in USD.
    estimated_remaining_pnl_usd: u128, // TODO replace with i128 when it derives Store
    /// The token that the pnl for the user is in, for long positions.
    /// This is the market.longToken, for short positions this is the market.short_token.
    pnl_token: ContractAddress,
    /// The price of the pnl_token.
    pnl_token_price: Price,
    /// The price of the collateral token.
    collateral_token_price: Price,
    /// The initial collateral amount.
    initial_collateral_amount: u128,
    /// The new position size in USD.
    next_position_size_in_usd: u128,
    /// The new position borrowing factor.
    next_position_borrowing_factor: u128,
}

/// Struct used as cache in get_position_pnl.
#[derive(Drop, starknet::Store, Serde)]
struct GetPositionPnlUsdCache {
    /// The position value.
    position_value: u128, // TODO replace with i128 when it derives Store
    /// The total position pnl.
    total_position_pnl: u128, // TODO replace with i128 when it derives Store
    /// The uncapped total position pnl.
    uncapped_total_position_pnl: u128, // TODO replace with i128 when it derives Store
    /// The pnl token address.
    pnl_token: ContractAddress,
    /// The amount of token in pool.
    pool_token_amount: u128,
    /// The price of pool token.
    pool_token_price: u128,
    /// The pool token value in usd.
    pool_token_usd: u128,
    /// The total pool pnl.
    pool_pnl: u128, // TODO replace with i128 when it derives Store
    /// The capped pool pnl.
    capped_pool_pnl: u128, // TODO replace with i128 when it derives Store
    /// The size variation in tokens.
    size_delta_in_tokens: u128,
    /// The positions pnl in usd.
    position_pnl_usd: u128, // TODO replace with i128 when it derives Store
    /// The uncapped positions pnl in usd.
    uncapped_position_pnl_usd: u128, // TODO replace with i128 when it derives Store.
}

/// Struct used as cache in is_position_liquidatable.
#[derive(Drop, starknet::Store, Serde)]
struct IsPositionLiquidatableCache {
    /// The position's pnl in USD.
    position_pnlUsd: u128, // TODO replace with i128 when it derives Store 
    /// The min collateral factor.
    min_collateral_factor: u128,
    /// The collateral token price.
    collateral_token_price: Price,
    /// The position's collateral in USD.
    collateral_usd: u128,
    /// The usd_delta value for the price impact calculation.
    usd_delta_for_price_impact: u128, // TODO replace with i128 when it derives Store
    /// The price impact of closing the position in USD.
    price_impact_usd: u128, // TODO replace with i128 when it derives Store
    has_positive_impact: bool,
    /// The minimum allowed collateral in USD.
    min_collateral_usd: u128, // TODO replace with i128 when it derives Store
    min_collateral_usd_for_leverage: u128, // TODO replace with i128 when it derives Store
    /// The remaining position collateral in USD.
    remaining_collateral_usd: u128, // TODO replace with i128 when it derives Store
}

/// Get the position pnl in USD.
///
/// For long positions, pnl is calculated as:
/// (position.sizeInTokens * indexTokenPrice) - position.sizeInUsd
/// If position.sizeInTokens is larger for long positions, the position will have
/// larger profits and smaller losses for the same changes in token price.
///
/// For short positions, pnl is calculated as:
/// position.sizeInUsd -  (position.sizeInTokens * indexTokenPrice)
/// If position.sizeInTokens is smaller for long positions, the position will have
/// larger profits and smaller losses for the same changes in token price.
/// # Arguments
/// *`data_store` - The data store dispatcher
/// *`market` - The market
/// *`position` - The position values
/// *`size_delta_usd` - The change in position size
/// # Returns
/// (position_pnl_usd, uncapped_position_pnl_usd, size_delta_in_tokens)
fn get_position_pnl_usd(
    data_store: IDataStoreSafeDispatcher,
    market: Market,
    prices: MarketPrices,
    position: Position,
    size_delta_usd: u128,
) -> (i128, i128, u128) {
    // TODO
    (0, 0, 0)
}

/// Get the key for a position.
/// # Arguments
/// *`account` - The position's account.
/// *`market` - The market to get the position from.
/// *`collateral_token` - The position's collateralToken.
/// *`is_long` - The position is long or short.
/// # Returns
/// The position key.
fn get_position_key(
    account: ContractAddress, market: Market, collateral_token: ContractAddress, is_long: bool,
) -> felt252 {
    // TODO
    0
}

/// Validate that a position is not empty.
/// # Arguments
/// *`position` - The position to validate.
fn validate_non_empty_position(position: Position,) { // TODO
}

/// Check if a position is valid.
/// # Arguments
/// *`data_store` - The data store dispatcher.
/// *`referral_storage` - The Referral Storage dispatcher.
/// *`position` - The position values.
/// *`market` - The market values.
/// *`prices` - The prices of the tokens in the market.
/// *`should_validate_min_collateral_usd` - Whether min collateral usd needs to be validated.
/// Validation is skipped for decrease position to prevent reverts in case the order size
/// is just slightly smaller than the position size.
/// In decrease position, the remaining collateral is estimated at the start, and the order
/// size is updated to match the position size if the remaining collateral will be less than
/// the min collateral usd.
/// Since this is an estimate, there may be edge cases where there is a small remaining position size
/// and small amount of collateral remaining.
/// Validation is skipped for this case as it is preferred for the order to be executed
/// since the small amount of collateral remaining only impacts the potential payment of liquidation
/// keepers.
fn validate_position(
    data_store: IDataStoreSafeDispatcher,
    referral_storage: IReferralStorageSafeDispatcher,
    position: Position,
    market: Market,
    prices: MarketPrices,
    should_validate_min_position_size: bool,
    should_validate_min_collateral_usd: bool,
) { // TODO
}

/// Check if a position is liquiditable.
/// # Arguments
/// *`data_store` - The data store dispatcher.
/// *`referral_storage` - The Referral Storage dispatcher.
/// *`position` - The position values.
/// *`market` - The market values.
/// *`prices` - The prices of the tokens in the market.
/// # Returns
/// True if liquiditable and reason of liquiditability, false else.
fn is_position_liquiditable(
    data_store: IDataStoreSafeDispatcher,
    referral_storage: IReferralStorageSafeDispatcher,
    position: Position,
    market: Market,
    prices: MarketPrices,
) -> (bool, felt252) {
    // TODO
    (true, '0')
}


/// Fees and price impact are not included for the willPositionCollateralBeSufficient validation
/// this is because this validation is meant to guard against a specific scenario of price impact
/// gaming.
///
/// Price impact could be gamed by opening high leverage positions, if the price impact
/// that should be charged is higher than the amount of collateral in the position
/// then a user could pay less price impact than what is required, and there is a risk that
/// price manipulation could be profitable if the price impact cost is less than it should be.
///
/// This check should be sufficient even without factoring in fees as fees should have a minimal impact
/// it may be possible that funding or borrowing fees are accumulated and need to be deducted which could
/// lead to a user paying less price impact than they should, however gaming of this form should be difficult
/// since the funding and borrowing fees would still add up for the user's cost.
///
/// Another possibility would be if a user opens a large amount of both long and short positions, and
/// funding fees are paid from one side to the other, but since most of the open interest is owned by the
/// user the user earns most of the paid cost, in this scenario the borrowing fees should still be significant
/// since some time would be required for the funding fees to accumulate.
///
/// Fees and price impact are validated in the validatePosition check.
/// # Arguments
/// *`data_store` - The data store dispatcher.
/// *`market` - The market values.
/// *`prices` - The prices of the tokens in the market.
/// *`collateral_token` - The collateral token of the position.
/// *`values` - The prices of the tokens in the market.
/// # Returns
/// True if position collateral will be sufficient and remaining collateral in usd, false else.
fn will_position_collateral_be_sufficient(
    data_store: IDataStoreSafeDispatcher,
    market: Market,
    prices: MarketPrices,
    collateral_token: ContractAddress,
    values: WillPositionCollateralBeSufficientValues,
) -> (bool, i128) {
    // TODO
    (true, 0)
}

fn update_funding_and_borrowing_state(params: UpdatePositionParams, prices: MarketPrices,) { // TODO
}

fn update_total_borrowing(
    params: UpdatePositionParams,
    next_position_size_in_usd: u128,
    next_position_borrowing_factor: u128,
) { // TODO
}

/// The order.receiver is meant to allow the output of an order to be
/// received by an address that is different from the position.account
/// address.
/// For funding fees, the funds are still credited to the owner
/// of the position indicated by order.account.
fn increment_claimable_funding_amount(params: UpdatePositionParams, fees: PositionFees,) { // TODO
}

fn update_open_interest(
    params: UpdatePositionParams, size_delta_usd: i128, size_delta_in_tokens: i128,
) { // TODO
}

fn handle_referral(params: UpdatePositionParams, fees: PositionFees,) { // TODO
}
