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
    market::Market, market_utils::PositionType, market_utils::MarketPrices,
    market_utils::CollateralType, market_utils::GetNextFundingAmountPerSizeResult
};
use satoru::price::price::Price;
use satoru::pricing::position_pricing_utils::PositionBorrowingFees;
use satoru::pricing::position_pricing_utils::PositionReferralFees;
use satoru::pricing::position_pricing_utils::PositionFundingFees;
use satoru::pricing::position_pricing_utils::PositionUiFees;
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::utils::i128::{I128Store, I128Serde, I128Div, I128Mul};

#[derive(Drop, starknet::Store, Serde)]
struct PositionInfo {
    position: Position,
    fees: PositionFees,
    execution_price_result: ExecutionPriceResult,
    base_pnl_usd: i128,
    uncapped_base_pnl_usd: i128,
    pnl_after_price_impact_usd: i128,
}

#[derive(Drop, starknet::Store, Serde)]
struct GetPositionInfoCache {
    market: Market,
    collateral_token_price: Price,
    pending_borrowing_fee_usd: u128,
}

#[derive(Drop, starknet::Store, Serde)]
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
    // TODO
    0
}

/// Designed to calculate and return borrowing fees for a specific position.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `collateral_token_price` - Struct representing the price properties of the collateral token used in the position.
/// * `borrwing_fee_usd` - Parameter representing the borrowing fees in USD.
/// # Returns
/// Struct containing information about the borrowing fees for the specified position.
fn get_borrowing_fees(
    data_store: IDataStoreDispatcher, collateral_token_price: Price, borrwing_fee_usd: u128
) -> PositionBorrowingFees {
    // TODO
    PositionBorrowingFees {
        borrowing_fee_usd: 0,
        borrowing_fee_amount: 0,
        borrowing_fee_receiver_factor: 0,
        borrowing_fee_amount_for_fee_receiver: 0,
    }
}


/// Calculate and return base funding values for a specific market.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - The market.
/// # Returns
/// Struct containing base funding values.
fn get_base_funding_values(data_store: IDataStoreDispatcher, market: Market) -> BaseFundingValues {
    // TODO
    let collateral_type = CollateralType { long_token: 0, short_token: 0, };

    let funding_fee_amount_per_size_collateral_type_long = CollateralType {
        long_token: 0, short_token: 0,
    };
    let funding_fee_amount_per_size_collateral_type_short = CollateralType {
        long_token: 0, short_token: 0,
    };
    let claimable_funding_amount_per_size_type_long = CollateralType {
        long_token: 0, short_token: 0,
    };
    let claimable_funding_amount_per_size_type_short = CollateralType {
        long_token: 0, short_token: 0,
    };

    let funding_fee_amount_per_size = PositionType {
        long: funding_fee_amount_per_size_collateral_type_long,
        short: funding_fee_amount_per_size_collateral_type_short,
    };

    let claimable_funding_amount_per_size = PositionType {
        long: claimable_funding_amount_per_size_type_long,
        short: claimable_funding_amount_per_size_type_short,
    };
    BaseFundingValues { funding_fee_amount_per_size, claimable_funding_amount_per_size, }
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
    // TODO
    let funding_fee_amount_per_size_collateral_type_long = CollateralType {
        long_token: 0, short_token: 0,
    };
    let funding_fee_amount_per_size_collateral_type_short = CollateralType {
        long_token: 0, short_token: 0,
    };
    let claimable_funding_amount_per_size_type_long = CollateralType {
        long_token: 0, short_token: 0,
    };
    let claimable_funding_amount_per_size_type_short = CollateralType {
        long_token: 0, short_token: 0,
    };

    let funding_fee_amount_per_size = PositionType {
        long: funding_fee_amount_per_size_collateral_type_long,
        short: funding_fee_amount_per_size_collateral_type_short,
    };

    let claimable_funding_amount_per_size = PositionType {
        long: claimable_funding_amount_per_size_type_long,
        short: claimable_funding_amount_per_size_type_short,
    };
    GetNextFundingAmountPerSizeResult {
        longs_pay_shorts: true,
        funding_factor_per_second: 0,
        funding_fee_amount_per_size_delta: funding_fee_amount_per_size,
        claimable_funding_amount_per_size_delta: claimable_funding_amount_per_size,
    }
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
    size_delta_usd: u128,
    ui_fee_receiver: ContractAddress,
    use_position_size_as_size_delta_usd: bool
) -> PositionInfo {
    let position_referral_fees = PositionReferralFees {
        referral_code: 0,
        affiliate: contract_address_const::<0>(),
        trader: contract_address_const::<0>(),
        total_rebate_factor: 0,
        trader_discount_factor: 0,
        total_rebate_amount: 0,
        trader_discount_amount: 0,
        affiliate_reward_amount: 0,
    };

    let position = Position {
        key: 0,
        account: contract_address_const::<0>(),
        market: contract_address_const::<0>(),
        collateral_token: contract_address_const::<0>(),
        size_in_usd: 0,
        size_in_tokens: 0,
        collateral_amount: 0,
        borrowing_factor: 0,
        funding_fee_amount_per_size: 0,
        long_token_claimable_funding_amount_per_size: 0,
        short_token_claimable_funding_amount_per_size: 0,
        increased_at_block: 0,
        decreased_at_block: 0,
        is_long: true,
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
        ui_fee_receiver: contract_address_const::<0>(), ui_fee_receiver_factor: 0, ui_fee_amount: 0,
    };

    let execution_price_result = ExecutionPriceResult {
        price_impact_usd: 0, price_impact_diff_usd: 0, execution_price: 0,
    };

    let price = Price { min: 0, max: 0, };

    let position_fees = PositionFees {
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
    };

    PositionInfo {
        position: position,
        fees: position_fees,
        execution_price_result: execution_price_result,
        base_pnl_usd: 0,
        uncapped_base_pnl_usd: 0,
        pnl_after_price_impact_usd: 0,
    }
}
