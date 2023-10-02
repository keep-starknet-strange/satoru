//! Library for read utils functions
//! convers some internal library functions into external functions to reduce
//! the Reader contract size.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use core::traits::TryInto;
use result::ResultTrait;

// Local imports.
use satoru::position::position::Position;
use satoru::pricing::position_pricing_utils::PositionFees;
use satoru::reader::reader_pricing_utils::ExecutionPriceResult;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::market::{
    market_utils, market::Market, market_utils::PositionType, market_utils::MarketPrices,
    market_utils::CollateralType, market_utils::GetNextFundingAmountPerSizeResult
};
use satoru::position::position_utils;
use satoru::reader::reader_pricing_utils;
use satoru::price::price::Price;
use satoru::pricing::position_pricing_utils;
use satoru::pricing::position_pricing_utils::PositionBorrowingFees;
use satoru::pricing::position_pricing_utils::PositionReferralFees;
use satoru::pricing::position_pricing_utils::PositionFundingFees;
use satoru::pricing::position_pricing_utils::PositionUiFees;
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::utils::{calc, i128::{I128Store, I128Serde, I128Div, I128Mul, I128Default}};

#[derive(Default, Drop, starknet::Store, Serde)]
struct PositionInfo {
    position: Position,
    fees: PositionFees,
    execution_price_result: ExecutionPriceResult,
    base_pnl_usd: i128,
    uncapped_base_pnl_usd: i128,
    pnl_after_price_impact_usd: i128,
}

#[derive(Default, Drop, starknet::Store, Serde)]
struct GetPositionInfoCache {
    market: Market,
    collateral_token_price: Price,
    pending_borrowing_fee_usd: u128,
}

#[derive(Default, Drop, starknet::Store, Serde)]
struct BaseFundingValues {
    funding_fee_amount_per_size: PositionType,
    claimable_funding_amount_per_size: PositionType,
}

/// Designed to calculate and return the next borrowing fees that a specific position within a market is expected to incur.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `position` - Struct representing the properties of the specific position for which borrowing fees are being calculated.
/// * `market` - The market.
/// * `prices` - Price of the market token.
/// # Returns
/// Returns an unsigned integer representing the calculated borrowing fees for the specified position within the market.
fn get_next_borrowing_fees(
    data_store: IDataStoreDispatcher, position: Position, market: Market, prices: MarketPrices
) -> u128 {
    market_utils::get_next_borrowing_fees(data_store, position, market, prices)
}

/// Designed to calculate and return borrowing fees for a specific position.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `collateral_token_price` - Struct representing the price properties of the collateral token used in the position.
/// * `borrowing_fee_usd` - Parameter representing the borrowing fees in USD.
/// # Returns
/// Struct containing information about the borrowing fees for the specified position.
fn get_borrowing_fees(
    data_store: IDataStoreDispatcher, collateral_token_price: Price, borrowing_fee_usd: u128
) -> PositionBorrowingFees {
    position_pricing_utils::get_borrowing_fees(
        data_store, collateral_token_price, borrowing_fee_usd
    )
}


/// Calculate and return base funding values for a specific market.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - The market.
/// # Returns
/// Struct containing base funding values.
fn get_base_funding_values(data_store: IDataStoreDispatcher, market: Market) -> BaseFundingValues {
    let mut values: BaseFundingValues = Default::default();
    values
        .funding_fee_amount_per_size
        .long
        .long_token =
            market_utils::get_funding_fee_amount_per_size(
                data_store, market.market_token, market.long_token, true // is_long
            );

    values
        .funding_fee_amount_per_size
        .long
        .short_token =
            market_utils::get_funding_fee_amount_per_size(
                data_store, market.market_token, market.short_token, true // is_long
            );

    values
        .funding_fee_amount_per_size
        .short
        .long_token =
            market_utils::get_funding_fee_amount_per_size(
                data_store, market.market_token, market.long_token, false // is_long
            );

    values
        .funding_fee_amount_per_size
        .short
        .short_token =
            market_utils::get_funding_fee_amount_per_size(
                data_store, market.market_token, market.short_token, false // is_long
            );

    values
        .claimable_funding_amount_per_size
        .long
        .long_token =
            market_utils::get_funding_fee_amount_per_size(
                data_store, market.market_token, market.long_token, true // is_long
            );

    values
        .claimable_funding_amount_per_size
        .long
        .short_token =
            market_utils::get_funding_fee_amount_per_size(
                data_store, market.market_token, market.short_token, true // is_long
            );

    values
        .claimable_funding_amount_per_size
        .short
        .long_token =
            market_utils::get_funding_fee_amount_per_size(
                data_store, market.market_token, market.long_token, false // is_long
            );

    values
        .claimable_funding_amount_per_size
        .short
        .short_token =
            market_utils::get_funding_fee_amount_per_size(
                data_store, market.market_token, market.short_token, false // is_long
            );

    values
}

/// Calculate and return the next funding amount per size for a specific market.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - The market.
/// * `prices` - Price of the market token.
/// # Returns
/// Struct containing funding-related values.
fn get_next_funding_amount_per_size(
    data_store: IDataStoreDispatcher, market: Market, prices: MarketPrices
) -> GetNextFundingAmountPerSizeResult {
    market_utils::get_next_funding_amount_per_size(data_store, market, prices)
}


/// Calculates various pieces of information related to a specific position within a financial market.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `referral_storage` - The referral storage instance to use.
/// * `position_key` - Represent the unique identifier of the position.
/// * `prices` - Price of the market token.
/// * `size_delta_usd` - Representing the change in position size in USD.
/// * `ui_fee_receiver` - The ui fee receiver.
/// * `use_position_size_as_size_delta_usd` - Indicating whether to use the position's size in USD as the size delta.
/// # Returns
/// Struct containing detailed information about the position, including execution prices, fees, and funding data.
fn get_position_info(
    data_store: IDataStoreDispatcher,
    referral_storage: IReferralStorageDispatcher,
    position_key: felt252,
    prices: MarketPrices,
    mut size_delta_usd: u128,
    ui_fee_receiver: ContractAddress,
    use_position_size_as_size_delta_usd: bool
) -> PositionInfo {
    let mut position_info: PositionInfo = Default::default();
    let mut cache: GetPositionInfoCache = Default::default();

    position_info.position = data_store.get_position(position_key).unwrap();
    cache.market = data_store.get_market(position_info.position.market).unwrap();
    cache
        .collateral_token_price =
            market_utils::get_cached_token_price(
                position_info.position.collateral_token, cache.market, prices
            );

    if (use_position_size_as_size_delta_usd) {
        size_delta_usd = position_info.position.size_in_usd;
    }

    let size_delta_usd_int = calc::to_signed(size_delta_usd, true);

    position_info
        .execution_price_result =
            reader_pricing_utils::get_execution_price(
                data_store,
                cache.market,
                prices.index_token_price,
                position_info.position.size_in_usd,
                position_info.position.size_in_tokens,
                -size_delta_usd_int,
                position_info.position.is_long
            );

    let get_position_fees_params = position_pricing_utils::GetPositionFeesParams {
        data_store,
        referral_storage,
        position: position_info.position,
        collateral_token_price: cache.collateral_token_price,
        for_positive_impact: position_info.execution_price_result.price_impact_usd > 0,
        long_token: cache.market.long_token,
        short_token: cache.market.short_token,
        size_delta_usd,
        ui_fee_receiver
    };

    position_info.fees = position_pricing_utils::get_position_fees(get_position_fees_params);

    // borrowing and funding fees need to be overwritten with pending values otherwise they
    // would be using storage values that have not yet been updated
    cache
        .pending_borrowing_fee_usd =
            get_next_borrowing_fees(data_store, position_info.position, cache.market, prices);

    position_info
        .fees
        .borrowing =
            get_borrowing_fees(
                data_store, cache.collateral_token_price, cache.pending_borrowing_fee_usd
            );

    let next_funding_amount_result = market_utils::get_next_funding_amount_per_size(
        data_store, cache.market, prices
    );

    position_info
        .fees
        .funding
        .latest_funding_fee_amount_per_size =
            market_utils::get_funding_fee_amount_per_size(
                data_store,
                position_info.position.market,
                position_info.position.collateral_token,
                position_info.position.is_long
            );

    position_info
        .fees
        .funding
        .latest_long_token_claimable_funding_amount_per_size =
            market_utils::get_claimable_funding_amount_per_size(
                data_store,
                position_info.position.market,
                cache.market.long_token,
                position_info.position.is_long
            );

    position_info
        .fees
        .funding
        .latest_short_token_claimable_funding_amount_per_size =
            market_utils::get_claimable_funding_amount_per_size(
                data_store,
                position_info.position.market,
                cache.market.short_token,
                position_info.position.is_long
            );

    if (position_info.position.is_long) {
        position_info
            .fees
            .funding
            .latest_long_token_claimable_funding_amount_per_size += next_funding_amount_result
            .claimable_funding_amount_per_size_delta
            .long
            .long_token;
        position_info
            .fees
            .funding
            .latest_short_token_claimable_funding_amount_per_size += next_funding_amount_result
            .claimable_funding_amount_per_size_delta
            .long
            .short_token;

        if (position_info.position.collateral_token == cache.market.long_token) {
            position_info
                .fees
                .funding
                .latest_funding_fee_amount_per_size += next_funding_amount_result
                .funding_fee_amount_per_size_delta
                .long
                .long_token;
        } else {
            position_info
                .fees
                .funding
                .latest_funding_fee_amount_per_size += next_funding_amount_result
                .funding_fee_amount_per_size_delta
                .long
                .short_token;
        }
    } else {
        position_info
            .fees
            .funding
            .latest_long_token_claimable_funding_amount_per_size += next_funding_amount_result
            .claimable_funding_amount_per_size_delta
            .short
            .long_token;
        position_info
            .fees
            .funding
            .latest_short_token_claimable_funding_amount_per_size += next_funding_amount_result
            .claimable_funding_amount_per_size_delta
            .short
            .short_token;

        if (position_info.position.collateral_token == cache.market.long_token) {
            position_info
                .fees
                .funding
                .latest_funding_fee_amount_per_size += next_funding_amount_result
                .funding_fee_amount_per_size_delta
                .short
                .long_token;
        } else {
            position_info
                .fees
                .funding
                .latest_funding_fee_amount_per_size += next_funding_amount_result
                .funding_fee_amount_per_size_delta
                .short
                .short_token;
        }
    }

    position_info
        .fees
        .funding =
            position_pricing_utils::get_funding_fees(
                position_info.fees.funding, position_info.position
            );

    let (base_pnl_usd, uncapped_base_pnl_usd, _) = position_utils::get_position_pnl_usd(
        data_store, cache.market, prices, position_info.position, size_delta_usd
    );

    position_info.base_pnl_usd = base_pnl_usd;
    position_info.uncapped_base_pnl_usd = uncapped_base_pnl_usd;

    position_info.pnl_after_price_impact_usd = position_info.execution_price_result.price_impact_usd
        + position_info.base_pnl_usd;
    position_info
}
