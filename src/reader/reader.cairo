//! Library for read functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;

use core::traits::TryInto;
use result::ResultTrait;


// Local imports.

use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::market::{
    market_utils::GetNextFundingAmountPerSizeResult, market::Market, market_utils::MarketPrices,
    market_utils::PositionType, market_utils::CollateralType,
    market_pool_value_info::MarketPoolValueInfo,
};
use satoru::price::price::Price;
use satoru::order::order::Order;
use satoru::pricing::position_pricing_utils::PositionBorrowingFees;
use satoru::pricing::position_pricing_utils::PositionReferralFees;
use satoru::pricing::position_pricing_utils::PositionFundingFees;
use satoru::pricing::position_pricing_utils::PositionUiFees;
use satoru::pricing::position_pricing_utils::PositionFees;

use satoru::reader::{
    reader_utils::PositionInfo, reader_utils::BaseFundingValues,
    reader_pricing_utils::ExecutionPriceResult,
};

use satoru::withdrawal::withdrawal::Withdrawal;
use satoru::position::position::Position;
use satoru::order::order::OrderType;
use satoru::pricing::swap_pricing_utils::SwapFees;
use satoru::deposit::deposit::Deposit;
use satoru::referral::referral_storage::interface::{
    IReferralStorageSafeDispatcher, IReferralStorageSafeDispatcherTrait
};

#[derive(Drop, starknet::Store, Serde)]
struct VirtualInventory {
    virtual_pool_amount_for_long_token: u128,
    virtual_pool_amount_for_short_token: u128,
    virtual_inventory_for_positions: u128, // TODO replace with i128 when it derives Store
}

#[derive(Drop, starknet::Store, Serde)]
struct MarketInfo {
    market: Market,
    borrowing_factor_per_second_for_longs: u128,
    borrowing_factor_per_second_for_shorts: u128,
    virtual_inventory_for_positions: u128, // TODO replace with i128 when it derives Store
    base_funding: BaseFundingValues,
    next_funding: GetNextFundingAmountPerSizeResult,
    virtual_inventory: VirtualInventory,
    is_disabled: bool,
}

/// Retrieve market-related data using a provided key from a data store.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `key` - The contract address serving as the identifier for the specific market data.
/// # Returns
/// Returns a struct representing market-related information.
fn get_market(data_store: IDataStoreSafeDispatcher, key: ContractAddress) -> Market {
    // TODO
    Market {
        market_token: 0.try_into().unwrap(),
        index_token: 0.try_into().unwrap(),
        long_token: 0.try_into().unwrap(),
        short_token: 0.try_into().unwrap(),
    }
}

/// Retrieve market-related data using a provided salt value as an additional parameter.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `salt` - Serves as an additional identifier or parameter for retrieving specific market data.
/// # Returns
/// Returns a struct representing market-related information.
fn get_market_by_salt(data_store: IDataStoreSafeDispatcher, salt: felt252) -> Market {
    // TODO
    Market {
        market_token: 0.try_into().unwrap(),
        index_token: 0.try_into().unwrap(),
        long_token: 0.try_into().unwrap(),
        short_token: 0.try_into().unwrap(),
    }
}

/// Retrieve deposit-related data using a provided key value.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `key` - The key of the deposit.
/// # Returns
/// Returns a struct representing deposit-related information.
fn get_deposit(data_store: IDataStoreSafeDispatcher, key: felt252) -> Deposit {
    // TODO
    Default::default()
}

/// Retrieve withdrawal-related data using a provided key value.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `key` - The key of the withdrawal.
/// # Returns
/// Returns a struct representing withdrawal-related information.
fn get_withdrawl(data_store: IDataStoreSafeDispatcher, key: felt252) -> Withdrawal {
    // TODO
    Default::default()
}

/// Retrieve position-related data using a provided key value.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `key` - The key of the position.
/// # Returns
/// Returns a struct representing position-related information.
fn get_position(data_store: IDataStoreSafeDispatcher, key: felt252) -> Position {
    // TODO
    Position {
        account: 0.try_into().unwrap(),
        market: 0.try_into().unwrap(),
        collateral_token: 0.try_into().unwrap(),
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
    }
}

/// Retrieve order-related data using a provided key value.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `key` - The key of the order.
/// # Returns
/// Returns a struct representing order-related information.
fn get_order(data_store: IDataStoreSafeDispatcher, key: felt252) -> Order {
    // TODO
    Order {
        order_type: OrderType::MarketSwap(()),
        account: 0.try_into().unwrap(),
        receiver: 0.try_into().unwrap(),
        callback_contract: 0.try_into().unwrap(),
        ui_fee_receiver: 0.try_into().unwrap(),
        market: 0.try_into().unwrap(),
        initial_collateral_token: 0.try_into().unwrap(),
        swap_path: ArrayTrait::new(),
        size_delta_usd: 0,
        initial_collateral_delta_amount: 0,
        trigger_price: 0,
        acceptable_price: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        updated_at_block: 0,
        is_long: true,
        should_unwrap_native_token: true,
        is_frozen: true,
    }
}

/// Intended to calculate and return various metrics related to the profit and loss (PNL) of a position within a market.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Market to check.
/// * `prices` - Price of the market token.
/// * `position_key` - Serving as a key or identifier for the position.
/// * `size_delta_usd` - Representing the change in position size in USD.
/// # Returns
/// Returns (positionPnlUsd, uncappedPositionPnlUsd, sizeDeltaInTokens).
fn get_position_pnl_usd(
    data_store: IDataStoreSafeDispatcher,
    market: Market,
    prices: MarketPrices,
    position_key: felt252,
    size_delta_usd: u128
) -> (i128, i128, u128) {
    // TODO
    (0, 0, 0)
}

/// Retrieve an array of position data associated with a specific account within a specified range.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `account` - The position's account.
/// * `start` - Representing the starting point of the range for position retrieval.
/// * `end` - Representing the ending point of the range for position retrieval.
/// # Returns
/// Returns an array of Position.
fn get_account_positions(
    data_store: IDataStoreSafeDispatcher, account: ContractAddress, start: u128, end: u128
) -> Array<Position> {
    // TODO
    ArrayTrait::new()
}

/// Retrieve an array of position data associated with a specific account within a specified range.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `referral_storage` - The referral storage instance to use.
/// * `position_keys` - The position keys for which information is to be retrieved.
/// * `prices` - Price of the market token.
/// * `ui_fee_receiver` - The ui fee receiver.
/// # Returns
/// Returns an array of PositionInfo representing position-related information.
fn get_account_position_info_list(
    data_store: IDataStoreSafeDispatcher,
    referral_storage: IReferralStorageSafeDispatcher,
    position_keys: Array<felt252>,
    prices: Array<MarketPrices>,
    ui_fee_receiver: ContractAddress
) -> Array<PositionInfo> {
    // TODO
    ArrayTrait::new()
}

/// Retrieve an array of position data associated with a specific account within a specified range.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `referral_storage` - The referral storage instance to use.
/// * `position_key` - Represent the unique identifier of the position.
/// * `prices` - Price of the market token.
/// * `size_delta_usd` - Representing the change in position size in USD.
/// * `ui_fee_receiver` - The ui fee receiver.
/// * `use_position_size_as_size_delta_usd` - Indicates whether to use the position's current size as the size delta in USD calculation.
/// # Returns
/// Returns a struct representing comprehensive information about the specified position.
fn get_position_info(
    data_store: IDataStoreSafeDispatcher,
    referral_storage: IReferralStorageSafeDispatcher,
    position_key: felt252,
    prices: MarketPrices,
    size_delta_usd: u128,
    ui_fee_receiver: ContractAddress,
    use_position_size_as_size_delta_usd: bool
) -> PositionInfo {
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

    let position = Position {
        account: 0.try_into().unwrap(),
        market: 0.try_into().unwrap(),
        collateral_token: 0.try_into().unwrap(),
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
        ui_fee_receiver: address_zero, ui_fee_receiver_factor: 0, ui_fee_amount: 0,
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

/// Retrieve an array of Order associated with a specific account within a specified range of order keys.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `account` - The position's account.
/// * `start` - Representing the starting point in the order key range.
/// * `end` - Representing the ending point in the order key range.
/// # Returns
/// Returns an array of Order structs representing the properties of orders associated with the specified account within the specified range.
fn get_account_orders(
    data_store: IDataStoreSafeDispatcher, account: ContractAddress, start: u128, end: u128
) -> Array<Order> {
    ArrayTrait::new()
}

/// Retrieve an array of Market within a specified range of market keys.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `start` - Representing the starting point in the market key range.
/// * `end` - Representing the ending point in the market key range.
/// # Returns
/// Returns an array of Market structs representing the properties of markets within the specified range.
fn get_markets(data_store: IDataStoreSafeDispatcher, start: u128, end: u128) -> Array<Market> {
    // TODO
    ArrayTrait::new()
}

/// Retrieve an array of MarketInfo structures, which contain comprehensive information about multiple markets within a specified range of market keys.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market_price_list` - An array of MarketPrices structures representing market prices for the corresponding markets.
/// * `start` - Representing the starting point in the market key range.
/// * `end` - Representing the ending point in the market key range.
/// # Returns
/// Returns an array of MarketInfo structures representing comprehensive information about multiple markets within the specified range.
fn get_market_info_list(
    data_store: IDataStoreSafeDispatcher,
    market_price_list: Array<MarketPrices>,
    start: u128,
    end: u128
) -> Array<MarketInfo> {
    // TODO
    ArrayTrait::new()
}

/// Retrieves comprehensive information about a specific market identified by market_key.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `prices` - Price of the market token.
/// * `market_key` - An address parameter representing the unique identifier of the market for which information is being retrieved.
/// # Returns
/// Returns MarketInfo struct containing comprehensive information about the specified market.
fn get_market_info(
    data_store: IDataStoreSafeDispatcher, prices: MarketPrices, market_key: ContractAddress
) -> MarketInfo {
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
    let base_funding_values = BaseFundingValues {
        funding_fee_amount_per_size: PositionType {
            long: CollateralType { long_token: 0, short_token: 0, },
            short: CollateralType { long_token: 0, short_token: 0, },
        },
        claimable_funding_amount_per_size: PositionType {
            long: CollateralType { long_token: 0, short_token: 0, },
            short: CollateralType { long_token: 0, short_token: 0, },
        },
    };

    let get_next_funding_amount_per_size_result = GetNextFundingAmountPerSizeResult {
        longs_pay_shorts: true,
        funding_factor_per_second: 0,
        funding_fee_amount_per_size_delta: funding_fee_amount_per_size,
        claimable_funding_amount_per_size_delta: claimable_funding_amount_per_size,
    };

    let market = Market {
        market_token: 0.try_into().unwrap(),
        index_token: 0.try_into().unwrap(),
        long_token: 0.try_into().unwrap(),
        short_token: 0.try_into().unwrap(),
    };

    let virtual_inventory = VirtualInventory {
        virtual_pool_amount_for_long_token: 0,
        virtual_pool_amount_for_short_token: 0,
        virtual_inventory_for_positions: 0,
    };

    MarketInfo {
        market: market,
        borrowing_factor_per_second_for_longs: 0,
        borrowing_factor_per_second_for_shorts: 0,
        virtual_inventory_for_positions: 0,
        base_funding: base_funding_values,
        next_funding: get_next_funding_amount_per_size_result,
        virtual_inventory: virtual_inventory,
        is_disabled: true,
    }
}

/// Retrieves comprehensive information about a specific market identified by market_key.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Market to check.
/// * `index_token_price` - Price of the market's index token.
/// * `long_token_price` - Price of the market's long token.
/// * `short_token_price` - Price of the market's short token.
/// * `pnl_factor_type` - The pnl factor type.
/// * `maximize` - Whether to maximize or minimize the net PNL.
/// # Returns
/// Returns an integer representing the calculated market token price and MarketPoolValueInfo struct containing additional information related to market pool value.
fn get_market_token_price(
    data_store: IDataStoreSafeDispatcher,
    market: Market,
    index_token_price: Price,
    long_token_price: Price,
    short_token_price: Price,
    pnl_factor_type: felt252,
    maximize: bool
) -> (i128, MarketPoolValueInfo) {
    // TODO
    let market_pool_value_info = MarketPoolValueInfo {
        pool_value: 0,
        long_pnl: 0,
        short_pnl: 0,
        net_pnl: 0,
        long_token_amount: 0,
        short_token_amount: 0,
        long_token_usd: 0,
        short_token_usd: 0,
        total_borrowing_fees: 0,
        borrowing_fee_pool_factor: 0,
        impact_pool_amount: 0,
    };
    (0, market_pool_value_info)
}

/// Calculate and return the net profit and loss (PnL) for a specific market based on various input parameters.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Market to check.
/// * `index_token_price` - Price of the market's index token.
/// * `maximize` - Whether to maximize or minimize the net PNL.
/// # Returns
/// Returns an integer representing the calculated net profit and loss (PnL) for the specified market.
fn get_net_pnl(
    data_store: IDataStoreSafeDispatcher, market: Market, index_token_price: Price, maximize: bool
) -> u128 {
    // TODO
    0
}

/// Calculate and return the profit and loss (PnL) for a specific market position, either long or short, based on various input parameters.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Market to check.
/// * `index_token_price` - Price of the market's index token.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// # Returns
/// Returns an integer representing the calculated profit and loss (PnL) for the specified market position.
fn get_pnl(
    data_store: IDataStoreSafeDispatcher,
    market: Market,
    index_token_price: Price,
    is_long: bool,
    maximize: bool
) -> u128 {
    // TODO
    0
}

/// Calculate and return the open interest with profit and loss (PnL) for a specific market position.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Market to check.
/// * `index_token_price` - Price of the market's index token.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// # Returns
/// Returns an integer representing the calculated open interest with profit and loss (PnL) for the specified market position.
fn get_open_interest_with_pnl(
    data_store: IDataStoreSafeDispatcher,
    market: Market,
    index_token_price: Price,
    is_long: bool,
    maximize: bool
) -> i128 {
    // TODO
    0
}

/// Calculate and return the profit and loss (PnL) to pool factor for a specific market position.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Market to check.
/// * `prices` - Price of the market token.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// # Returns
/// Returns an integer representing the calculated profit and loss (PnL) to pool factor for the specified market position.
fn get_pnl_to_pool_factor(
    data_store: IDataStoreSafeDispatcher,
    market_address: ContractAddress,
    prices: MarketPrices,
    is_long: bool,
    maximize: bool
) -> i128 {
    // TODO
    0
}

/// Calculate and return various values related to a swap operation, including the amount of the output token, fees associated with the swap, and other information.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Market to check.
/// * `prices` - Price of the market token.
/// * `token_in` - The input token.
/// * `amount_in` - The amount of the input token.
/// * `ui_fee_receiver` - The ui fee receiver.
/// # Returns
/// Returns an unsigned integer representing the calculated amount of the output token resulting from the swap operation,
/// a signed integer representing the fees associated with the swap operation and SwapFees struct containing additional information related to swap fees,
/// which may include factors and values used in fee calculations.
fn get_swap_amount_out(
    data_store: IDataStoreSafeDispatcher,
    market: Market,
    prices: MarketPrices,
    token_in: ContractAddress,
    amount_in: u128,
    ui_fee_receiver: ContractAddress
) -> (u128, u128, SwapFees) {
    // TODO
    (
        0,
        0,
        SwapFees {
            fee_receiver_amount: 0,
            fee_amount_for_pool: 0,
            amount_after_fees: 0,
            ui_fee_receiver: 0.try_into().unwrap(),
            ui_fee_receiver_factor: 0,
            ui_fee_amount: 0,
        }
    )
}

/// Calculate and return information about the virtual inventory for a specific market.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Market to check.
/// # Returns
/// Returns VirtualInventory struct containing information about the virtual inventory for the specified market.
fn get_virtual_inventory(data_store: IDataStoreSafeDispatcher, market: Market) -> VirtualInventory {
    // TODO
    VirtualInventory {
        virtual_pool_amount_for_long_token: 0,
        virtual_pool_amount_for_short_token: 0,
        virtual_inventory_for_positions: 0,
    }
}

/// Calculate and return information related to the execution price for a specific market position.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market_key` - An address parameter representing the unique identifier of the market for which information is being retrieved.
/// * `index_token_price` - Price of the market's index token.
/// * `position_size_in_usd` - Representing the size of the position in USD.
/// * `position_size_in_token` - Representing the size of the position in tokens.
/// * `size_delta_usd` - Representing the change in position size in USD.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// # Returns
/// Returns ExecutionPriceResult struct containing detailed information related to the execution price for the specified market position.
fn get_execution_price(
    data_store: IDataStoreSafeDispatcher,
    market_key: ContractAddress,
    index_token_price: Price,
    position_size_in_usd: u128,
    position_size_in_token: u128,
    size_delta_usd: u128, // TODO replace with i128 when it derives Store
    is_long: bool
) -> ExecutionPriceResult {
    ExecutionPriceResult { price_impact_usd: 0, price_impact_diff_usd: 0, execution_price: 0, }
}

/// Calculate and return the price impact of a swap operation between two tokens within a specific market.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market_key` - An address parameter representing the unique identifier of the market for which information is being retrieved.
/// * `index_token_price` - Price of the market's index token.
/// * `position_size_in_usd` - Representing the size of the position in USD.
/// * `position_size_in_token` - Representing the size of the position in tokens.
/// * `size_delta_usd` - Representing the change in position size in USD.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// # Returns
/// Returns an integer representing the price impact of the swap operation and an integer representing the slippage, which is another way to measure the price impact.
fn get_swap_price_impact(
    data_store: IDataStoreSafeDispatcher,
    market_key: ContractAddress,
    token_in: ContractAddress,
    token_out: ContractAddress,
    amount_in: u128,
    token_in_price: Price,
    token_out_price: Price
) -> (i128, i128) {
    // TODO
    (0, 0)
}

/// Retrieve and return the state of the Account Deleveraging (ADL) system for a specific market and position (either long or short).
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market` - Market to check.
/// * `is_long` - Indicates whether to check the long or short side of the market.
/// * `prices` - Price of the market token.
/// # Returns
/// Returns an unsigned integer representing the latest ADL block, a boolean value indicating whether ADL should be enabled for the specified market and position, 
/// signed integer representing the PnL to pool factor, which is a metric used to assess the position's impact on the and an unsigned integer representing the maximum PnL factor.
fn get_adl_state(
    data_store: IDataStoreSafeDispatcher,
    market: ContractAddress,
    is_long: bool,
    prices: MarketPrices
) -> (u128, bool, i128, u128) {
    // TODO
    (0, true, 0, 0)
}
