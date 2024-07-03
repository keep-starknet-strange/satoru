//! Library for read functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;
use core::traits::TryInto;
use result::ResultTrait;

// Local imports.

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::market::{
    market_utils::GetNextFundingAmountPerSizeResult, market::Market, market_utils::MarketPrices,
    market_pool_value_info::MarketPoolValueInfo,
};
use satoru::price::price::Price;
use satoru::order::order::{Order};

use satoru::reader::{
    reader_utils::PositionInfo, reader_utils::BaseFundingValues,
    reader_pricing_utils::ExecutionPriceResult,
};

use satoru::withdrawal::withdrawal::Withdrawal;
use satoru::position::{position_utils, position::Position};
use satoru::pricing::swap_pricing_utils::SwapFees;
use satoru::deposit::deposit::Deposit;
use satoru::utils::i256::i256;

#[derive(Drop, starknet::Store, Serde)]
struct VirtualInventory {
    virtual_pool_amount_for_long_token: u256,
    virtual_pool_amount_for_short_token: u256,
    virtual_inventory_for_positions: i256,
}

#[derive(Drop, starknet::Store, Serde)]
struct MarketInfo {
    market: Market,
    borrowing_factor_per_second_for_longs: u256,
    borrowing_factor_per_second_for_shorts: u256,
    base_funding: BaseFundingValues,
    next_funding: GetNextFundingAmountPerSizeResult,
    virtual_inventory: VirtualInventory,
    is_disabled: bool,
}


// *************************************************************************
//                  Interface of the `Reader` contract.
// *************************************************************************
#[starknet::interface]
trait IReader<TContractState> {
    /// Retrieve market-related data using a provided key from a data store.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `key` - The contract address serving as the identifier for the specific market data.
    /// # Returns
    /// Returns a struct representing market-related information.
    fn get_market(
        self: @TContractState, data_store: IDataStoreDispatcher, key: ContractAddress
    ) -> Market;

    /// Retrieve market-related data using a provided salt value as an additional parameter.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `salt` - Serves as an additional identifier or parameter for retrieving specific market data.
    /// # Returns
    /// Returns a struct representing market-related information.
    fn get_market_by_salt(
        self: @TContractState, data_store: IDataStoreDispatcher, salt: felt252
    ) -> Market;

    /// Retrieve deposit-related data using a provided key value.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `key` - The key of the deposit.
    /// # Returns
    /// Returns a struct representing deposit-related information.
    fn get_deposit(
        self: @TContractState, data_store: IDataStoreDispatcher, key: felt252
    ) -> Deposit;

    /// Retrieve withdrawal-related data using a provided key value.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `key` - The key of the withdrawal.
    /// # Returns
    /// Returns a struct representing withdrawal-related information.
    fn get_withdrawal(
        self: @TContractState, data_store: IDataStoreDispatcher, key: felt252
    ) -> Withdrawal;

    /// Retrieve position-related data using a provided key value.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `key` - The key of the position.
    /// # Returns
    /// Returns a struct representing position-related information.
    fn get_position(
        self: @TContractState, data_store: IDataStoreDispatcher, key: felt252
    ) -> Position;

    /// Retrieve order-related data using a provided key value.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `key` - The key of the order.
    /// # Returns
    /// Returns a struct representing order-related information.
    fn get_order(self: @TContractState, data_store: IDataStoreDispatcher, key: felt252) -> Order;

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
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        market: Market,
        prices: MarketPrices,
        position_key: felt252,
        size_delta_usd: u256
    ) -> (i256, i256, u256);

    /// Retrieve an array of position data associated with a specific account within a specified range.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `account` - The position's account.
    /// * `start` - Representing the starting point of the range for position retrieval.
    /// * `end` - Representing the ending point of the range for position retrieval.
    /// # Returns
    /// Returns an array of Position.
    fn get_account_positions(
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        account: ContractAddress,
        start: u32,
        end: u32
    ) -> Array<Position>;

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
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        referral_storage: IReferralStorageDispatcher,
        position_keys: Array<felt252>,
        prices: Array<MarketPrices>,
        ui_fee_receiver: ContractAddress
    ) -> Array<PositionInfo>;

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
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        referral_storage: IReferralStorageDispatcher,
        position_key: felt252,
        prices: MarketPrices,
        size_delta_usd: u256,
        ui_fee_receiver: ContractAddress,
        use_position_size_as_size_delta_usd: bool
    ) -> PositionInfo;
    /// Retrieve an array of Order associated with a specific account within a specified range of order keys.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `account` - The orders's account.
    /// * `start` - Representing the starting point in the order key range.
    /// * `end` - Representing the ending point in the order key range.
    /// # Returns
    /// Returns an array of Order structs representing the properties of orders associated with the specified account within the specified range.
    fn get_account_orders(
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        account: ContractAddress,
        start: u32,
        end: u32
    ) -> Array<Order>;

    /// Retrieve an array of Market within a specified range of market keys.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `start` - Representing the starting point in the market key range.
    /// * `end` - Representing the ending point in the market key range.
    /// # Returns
    /// Returns an array of Market structs representing the properties of markets within the specified range.
    fn get_markets(
        self: @TContractState, data_store: IDataStoreDispatcher, start: u32, end: u32
    ) -> Array<Market>;

    /// Retrieve an array of MarketInfo structures, which contain comprehensive information about multiple markets within a specified range of market keys.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `market_price_list` - An array of MarketPrices structures representing market prices for the corresponding markets.
    /// * `start` - Representing the starting point in the market key range.
    /// * `end` - Representing the ending point in the market key range.
    /// # Returns
    /// Returns an array of MarketInfo structures representing comprehensive information about multiple markets within the specified range.
    fn get_market_info_list(
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        market_price_list: Array<MarketPrices>,
        start: usize,
        end: usize
    ) -> Array<MarketInfo>;

    /// Retrieves comprehensive information about a specific market identified by market_key.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `prices` - Price of the market token.
    /// * `market_key` - An address parameter representing the unique identifier of the market for which information is being retrieved.
    /// # Returns
    /// Returns MarketInfo struct containing comprehensive information about the specified market.
    fn get_market_info(
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        prices: MarketPrices,
        market_key: ContractAddress
    ) -> MarketInfo;

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
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        market: Market,
        index_token_price: Price,
        long_token_price: Price,
        short_token_price: Price,
        pnl_factor_type: felt252,
        maximize: bool
    ) -> (i256, MarketPoolValueInfo);

    /// Calculate and return the net profit and loss (PnL) for a specific market based on various input parameters.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `market` - Market to check.
    /// * `index_token_price` - Price of the market's index token.
    /// * `maximize` - Whether to maximize or minimize the net PNL.
    /// # Returns
    /// Returns an integer representing the calculated net profit and loss (PnL) for the specified market.
    fn get_net_pnl(
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        market: Market,
        index_token_price: Price,
        maximize: bool
    ) -> i256;

    /// Calculate and return the profit and loss (PnL) for a specific market position, either long or short, based on various input parameters.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `market` - Market to check.
    /// * `index_token_price` - Price of the market's index token.
    /// * `is_long` - Indicates whether to check the long or short side of the market.
    /// # Returns
    /// Returns an integer representing the calculated profit and loss (PnL) for the specified market position.
    fn get_pnl(
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        market: Market,
        index_token_price: Price,
        is_long: bool,
        maximize: bool
    ) -> i256;

    /// Calculate and return the open interest with profit and loss (PnL) for a specific market position.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `market` - Market to check.
    /// * `index_token_price` - Price of the market's index token.
    /// * `is_long` - Indicates whether to check the long or short side of the market.
    /// # Returns
    /// Returns an integer representing the calculated open interest with profit and loss (PnL) for the specified market position.
    fn get_open_interest_with_pnl(
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        market: Market,
        index_token_price: Price,
        is_long: bool,
        maximize: bool
    ) -> i256;


    /// Calculate and return the profit and loss (PnL) to pool factor for a specific market position.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `market` - Market to check.
    /// * `prices` - Price of the market token.
    /// * `is_long` - Indicates whether to check the long or short side of the market.
    /// # Returns
    /// Returns an integer representing the calculated profit and loss (PnL) to pool factor for the specified market position.
    fn get_pnl_to_pool_factor(
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        market_address: ContractAddress,
        prices: MarketPrices,
        is_long: bool,
        maximize: bool
    ) -> i256;

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
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        market: Market,
        prices: MarketPrices,
        token_in: ContractAddress,
        amount_in: u256,
        ui_fee_receiver: ContractAddress
    ) -> (u256, i256, SwapFees);

    /// Calculate and return information about the virtual inventory for a specific market.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `market` - Market to check.
    /// # Returns
    /// Returns VirtualInventory struct containing information about the virtual inventory for the specified market.
    fn get_virtual_inventory(
        self: @TContractState, data_store: IDataStoreDispatcher, market: Market
    ) -> VirtualInventory;

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
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        market_key: ContractAddress,
        index_token_price: Price,
        position_size_in_usd: u256,
        position_size_in_token: u256,
        size_delta_usd: i256,
        is_long: bool
    ) -> ExecutionPriceResult;

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
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        market_key: ContractAddress,
        token_in: ContractAddress,
        token_out: ContractAddress,
        amount_in: u256,
        token_in_price: Price,
        token_out_price: Price
    ) -> (i256, i256);

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
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        market: ContractAddress,
        is_long: bool,
        prices: MarketPrices
    ) -> (u64, bool, i256, u256);

    fn is_position_liquidable(
        self: @TContractState,
        data_store: IDataStoreDispatcher,
        referral_storage: IReferralStorageDispatcher,
        position: Position,
        market: Market,
        prices: MarketPrices,
        should_validate_min_collateral_usd: bool,
    ) -> (bool, felt252);
}

#[starknet::contract]
mod Reader {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::ContractAddress;

    use core::traits::TryInto;
    use result::ResultTrait;
    use core::option::OptionTrait;


    // Local imports.
    use super::{MarketInfo, VirtualInventory, IDataStoreDispatcher, IDataStoreDispatcherTrait};
    use satoru::mock::referral_storage::{
        IReferralStorageDispatcher, IReferralStorageDispatcherTrait
    };
    use satoru::market::{
        market_utils, market_utils::GetNextFundingAmountPerSizeResult, market::Market,
        market_utils::MarketPrices, market_pool_value_info::MarketPoolValueInfo,
    };
    use satoru::utils::i256::i256;
    use satoru::withdrawal::withdrawal::Withdrawal;
    use satoru::position::{position_utils, position::Position};
    use satoru::pricing::swap_pricing_utils::SwapFees;
    use satoru::deposit::deposit::Deposit;
    use satoru::price::price::Price;
    use satoru::order::order::{Order};
    use satoru::data::keys;
    use satoru::adl::adl_utils;

    use satoru::reader::{
        reader_utils, reader_utils::PositionInfo, reader_utils::BaseFundingValues,
        reader_pricing_utils, reader_pricing_utils::ExecutionPriceResult,
    };

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {}


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl Reader of super::IReader<ContractState> {
        fn get_market(
            self: @ContractState, data_store: IDataStoreDispatcher, key: ContractAddress
        ) -> Market {
            data_store.get_market(key)
        }

        fn get_market_by_salt(
            self: @ContractState, data_store: IDataStoreDispatcher, salt: felt252
        ) -> Market {
            data_store.get_by_salt_market(salt)
        }


        fn get_deposit(
            self: @ContractState, data_store: IDataStoreDispatcher, key: felt252
        ) -> Deposit {
            data_store.get_deposit(key)
        }

        fn get_withdrawal(
            self: @ContractState, data_store: IDataStoreDispatcher, key: felt252
        ) -> Withdrawal {
            data_store.get_withdrawal(key)
        }

        fn get_position(
            self: @ContractState, data_store: IDataStoreDispatcher, key: felt252
        ) -> Position {
            data_store.get_position(key)
        }

        fn get_order(
            self: @ContractState, data_store: IDataStoreDispatcher, key: felt252
        ) -> Order {
            data_store.get_order(key)
        }

        fn get_position_pnl_usd(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            market: Market,
            prices: MarketPrices,
            position_key: felt252,
            size_delta_usd: u256
        ) -> (i256, i256, u256) {
            let position = data_store.get_position(position_key);
            position_utils::get_position_pnl_usd(
                data_store, market, prices, position, size_delta_usd
            )
        }

        fn get_account_positions(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            account: ContractAddress,
            start: u32,
            end: u32
        ) -> Array<Position> {
            let position_keys = data_store.get_account_position_keys(account, start, end);
            let length = position_keys.len();
            let mut positions = ArrayTrait::<Position>::new();
            let mut i = 0;
            loop {
                if i == length {
                    break;
                }
                let position = data_store.get_position(*position_keys.at(i));
                positions.append(position);
                i += 1;
            };
            positions
        }

        fn get_account_position_info_list(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            referral_storage: IReferralStorageDispatcher,
            position_keys: Array<felt252>,
            prices: Array<MarketPrices>,
            ui_fee_receiver: ContractAddress
        ) -> Array<PositionInfo> {
            let mut position_info_list = ArrayTrait::<PositionInfo>::new();
            let length = position_keys.len();
            let mut i = 0;
            loop {
                if i == length {
                    break;
                }
                let position_key = *position_keys.at(i);
                let info = self
                    .get_position_info(
                        data_store,
                        referral_storage,
                        position_key,
                        *prices.at(i),
                        0,
                        ui_fee_receiver,
                        true
                    );
                position_info_list.append(info);
                i += 1;
            };
            position_info_list
        }

        fn get_position_info(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            referral_storage: IReferralStorageDispatcher,
            position_key: felt252,
            prices: MarketPrices,
            size_delta_usd: u256,
            ui_fee_receiver: ContractAddress,
            use_position_size_as_size_delta_usd: bool
        ) -> PositionInfo {
            reader_utils::get_position_info(
                data_store,
                referral_storage,
                position_key,
                prices,
                size_delta_usd,
                ui_fee_receiver,
                use_position_size_as_size_delta_usd
            )
        }

        fn get_account_orders(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            account: ContractAddress,
            start: u32,
            end: u32
        ) -> Array<Order> {
            let order_keys = data_store.get_account_order_keys(account, start, end);
            let length = order_keys.len();
            let mut orders = ArrayTrait::<Order>::new();
            let mut i = 0;
            loop {
                if i == length {
                    break;
                }
                let order = data_store.get_order(*order_keys.at(i));
                orders.append(order);
                i += 1;
            };
            orders
        }

        fn get_markets(
            self: @ContractState, data_store: IDataStoreDispatcher, start: u32, end: u32
        ) -> Array<Market> {
            let market_keys = data_store.get_market_keys(start, end);
            let length = market_keys.len();
            let mut markets = ArrayTrait::<Market>::new();
            let mut i = 0;
            loop {
                if i == length {
                    break;
                }
                let market = data_store.get_market(*market_keys.at(i));
                markets.append(market);
                i += 1;
            };
            markets
        }

        fn get_market_info_list(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            market_price_list: Array<MarketPrices>,
            start: usize,
            end: usize
        ) -> Array<MarketInfo> {
            let market_keys = data_store.get_market_keys(start, end);
            let mut market_info_list = ArrayTrait::<MarketInfo>::new();
            let length = market_keys.len();
            let mut i = 0;
            loop {
                if i == length {
                    break;
                }
                let position_key = *market_keys.at(i);
                let info = self.get_market_info(data_store, *market_price_list.at(i), position_key);
                market_info_list.append(info);
                i += 1;
            };
            market_info_list
        }

        fn get_market_info(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            prices: MarketPrices,
            market_key: ContractAddress
        ) -> MarketInfo {
            let market = data_store.get_market(market_key);
            let borrowing_factor_per_second_for_longs =
                market_utils::get_borrowing_factor_per_second(
                data_store, market, prices, true
            );
            let borrowing_factor_per_second_for_shorts =
                market_utils::get_borrowing_factor_per_second(
                data_store, market, prices, false
            );

            let base_funding = reader_utils::get_base_funding_values(data_store, market);
            let next_funding = reader_utils::get_next_funding_amount_per_size(
                data_store, market, prices
            );

            let virtual_inventory = self.get_virtual_inventory(data_store, market);

            let is_disabled = data_store
                .get_bool(keys::is_market_disabled_key(market.market_token));
            MarketInfo {
                market,
                borrowing_factor_per_second_for_longs,
                borrowing_factor_per_second_for_shorts,
                base_funding,
                next_funding,
                virtual_inventory,
                is_disabled
            }
        }

        fn get_market_token_price(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            market: Market,
            index_token_price: Price,
            long_token_price: Price,
            short_token_price: Price,
            pnl_factor_type: felt252,
            maximize: bool
        ) -> (i256, MarketPoolValueInfo) {
            market_utils::get_market_token_price(
                data_store,
                market,
                index_token_price,
                long_token_price,
                short_token_price,
                pnl_factor_type,
                maximize
            )
        }

        fn get_net_pnl(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            market: Market,
            index_token_price: Price,
            maximize: bool
        ) -> i256 {
            market_utils::get_net_pnl(data_store, @market, @index_token_price, maximize)
        }

        fn get_pnl(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            market: Market,
            index_token_price: Price,
            is_long: bool,
            maximize: bool
        ) -> i256 {
            market_utils::get_pnl(data_store, @market, @index_token_price, is_long, maximize)
        }

        fn get_open_interest_with_pnl(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            market: Market,
            index_token_price: Price,
            is_long: bool,
            maximize: bool
        ) -> i256 {
            market_utils::get_open_interest_with_pnl(
                data_store, @market, @index_token_price, is_long, maximize
            )
        }

        fn get_pnl_to_pool_factor(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            market_address: ContractAddress,
            prices: MarketPrices,
            is_long: bool,
            maximize: bool
        ) -> i256 {
            let market = data_store.get_market(market_address);
            market_utils::get_pnl_to_pool_factor_from_prices(
                data_store, @market, @prices, is_long, maximize
            )
        }

        fn get_swap_amount_out(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            market: Market,
            prices: MarketPrices,
            token_in: ContractAddress,
            amount_in: u256,
            ui_fee_receiver: ContractAddress
        ) -> (u256, i256, SwapFees) {
            reader_pricing_utils::get_swap_amount_out(
                data_store, market, prices, token_in, amount_in, ui_fee_receiver
            )
        }

        fn get_virtual_inventory(
            self: @ContractState, data_store: IDataStoreDispatcher, market: Market
        ) -> VirtualInventory {
            let (_, virtual_pool_amount_for_long_token, virtual_pool_amount_for_short_token) =
                market_utils::get_virtual_inventory_for_swaps(
                data_store, market.market_token
            );
            let (_, virtual_inventory_for_positions) =
                market_utils::get_virtual_inventory_for_positions(
                data_store, market.index_token
            );
            VirtualInventory {
                virtual_pool_amount_for_long_token,
                virtual_pool_amount_for_short_token,
                virtual_inventory_for_positions
            }
        }

        fn get_execution_price(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            market_key: ContractAddress,
            index_token_price: Price,
            position_size_in_usd: u256,
            position_size_in_token: u256,
            size_delta_usd: i256,
            is_long: bool
        ) -> ExecutionPriceResult {
            let market = data_store.get_market(market_key);
            reader_pricing_utils::get_execution_price(
                data_store,
                market,
                index_token_price,
                position_size_in_usd,
                position_size_in_token,
                size_delta_usd,
                is_long
            )
        }

        fn get_swap_price_impact(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            market_key: ContractAddress,
            token_in: ContractAddress,
            token_out: ContractAddress,
            amount_in: u256,
            token_in_price: Price,
            token_out_price: Price
        ) -> (i256, i256) {
            let market = data_store.get_market(market_key);
            reader_pricing_utils::get_swap_price_impact(
                data_store, market, token_in, token_out, amount_in, token_in_price, token_out_price
            )
        }

        fn get_adl_state(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            market: ContractAddress,
            is_long: bool,
            prices: MarketPrices
        ) -> (u64, bool, i256, u256) {
            let latest_adl_block = adl_utils::get_latest_adl_block(data_store, market, is_long);
            let _market = market_utils::get_enabled_market(data_store, market);
            let (should_enabled_ald, pnl_to_pool_factor, max_pnl_factor) =
                market_utils::is_pnl_factor_exceeded_check(
                data_store, _market, prices, is_long, keys::max_pnl_factor_for_adl()
            );
            (latest_adl_block, should_enabled_ald, pnl_to_pool_factor, max_pnl_factor)
        }

        fn is_position_liquidable(
            self: @ContractState,
            data_store: IDataStoreDispatcher,
            referral_storage: IReferralStorageDispatcher,
            position: Position,
            market: Market,
            prices: MarketPrices,
            should_validate_min_collateral_usd: bool
        ) -> (bool, felt252) {
            position_utils::is_position_liquiditable(
                data_store,
                referral_storage,
                position,
                market,
                prices,
                should_validate_min_collateral_usd
            )
        }
    }
}

