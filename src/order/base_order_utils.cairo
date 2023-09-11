// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use starknet::contract_address::ContractAddressZeroable;

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::order::{
    order::{Order, OrderTrait, SecondaryOrderType, OrderType, DecreasePositionSwapType},
    order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait}
};
use satoru::price::price::Price;
use satoru::market::market::Market;
use satoru::utils::store_arrays::{StoreMarketArray, StoreU64Array, StoreContractAddressArray};
use satoru::referral::referral_storage::interface::{
    IReferralStorageDispatcher, IReferralStorageDispatcherTrait
};

#[derive(Drop, starknet::Store, Serde)]
struct ExecuteOrderParams {
    contracts: ExecuteOrderParamsContracts,
    /// The key of the order to execute.
    key: felt252,
    /// The order to execute.
    order: Order,
    /// The market values of the markets in the swap_path.
    swap_path_markets: Array<Market>,
    /// The min oracle block numbers.
    min_oracle_block_numbers: Array<u64>,
    /// The max oracle block numbers.
    max_oracle_block_numbers: Array<u64>,
    /// The market values of the trading market.
    market: Market,
    /// The keeper sending the transaction.
    keeper: ContractAddress,
    /// The starting gas.
    starting_gas: u128,
    /// The secondary order type.
    secondary_order_type: SecondaryOrderType
}

#[derive(Drop, starknet::Store, Serde)]
struct ExecuteOrderParamsContracts {
    /// The dispatcher to interact with the `DataStore` contract
    data_store: IDataStoreDispatcher,
    /// The dispatcher to interact with the `EventEmitter` contract
    event_emitter: IEventEmitterDispatcher,
    /// The dispatcher to interact with the `OrderVault` contract
    order_vault: IOrderVaultDispatcher,
    /// The dispatcher to interact with the `Oracle` contract
    oracle: IOracleDispatcher,
    /// The dispatcher to interact with the `SwapHandler` contract
    swap_handler: ISwapHandlerDispatcher,
    /// The dispatcher to interact with the `ReferralStorage` contract
    referral_storage: IReferralStorageDispatcher
}

/// CreateOrderParams struct used in create_order.
#[derive(Drop, starknet::Store, Serde)]
struct CreateOrderParams {
    /// Meant to allow the output of an order to be
    /// received by an address that is different from the position.account
    /// address.
    /// For funding fees, the funds are still credited to the owner
    /// of the position indicated by order.account.
    receiver: ContractAddress,
    /// The contract to call for callbacks.
    callback_contract: ContractAddress,
    /// The UI fee receiver.
    ui_fee_receiver: ContractAddress,
    /// The trading market.
    market: ContractAddress,
    /// The initial collateral token for increase orders.
    initial_collateral_token: ContractAddress,
    /// An array of market addresses to swap through.
    swap_path: Array<ContractAddress>,
    /// The requested change in position size.
    size_delta_usd: u128,
    /// For increase orders, this is the amount of the initialCollateralToken sent in by the user.
    /// For decrease orders, this is the amount of the position's collateralToken to withdraw.
    /// For swaps, this is the amount of initialCollateralToken sent in for the swap.
    initial_collateral_delta_amount: u128,
    /// The trigger price for non-market orders.
    trigger_price: u128,
    /// The acceptable execution price for increase / decrease orders.
    acceptable_price: u128,
    /// The execution fee for keepers.
    execution_fee: u256,
    /// The gas limit for the callbackContract.
    callback_gas_limit: u128,
    /// The minimum output amount for decrease orders and swaps.
    min_output_amount: u128,
    /// The order type.
    order_type: OrderType,
    /// The swap type on decrease position.
    decrease_position_swap_type: DecreasePositionSwapType,
    /// Whether the order is for a long or short.
    is_long: bool,
    /// Whether to unwrap native tokens before transferring to the user.
    should_unwrap_native_token: bool,
    /// The referral code linked to this order.
    referral_code: felt252
}

impl CreateOrderParamsClone of Clone<CreateOrderParams> {
    fn clone(self: @CreateOrderParams) -> CreateOrderParams {
        CreateOrderParams {
            receiver: *self.receiver,
            callback_contract: *self.callback_contract,
            ui_fee_receiver: *self.ui_fee_receiver,
            market: *self.market,
            initial_collateral_token: *self.initial_collateral_token,
            swap_path: self.swap_path.clone(),
            size_delta_usd: *self.size_delta_usd,
            initial_collateral_delta_amount: *self.initial_collateral_delta_amount,
            trigger_price: *self.trigger_price,
            acceptable_price: *self.acceptable_price,
            execution_fee: *self.execution_fee,
            callback_gas_limit: *self.callback_gas_limit,
            min_output_amount: *self.min_output_amount,
            order_type: *self.order_type,
            decrease_position_swap_type: *self.decrease_position_swap_type,
            is_long: *self.is_long,
            should_unwrap_native_token: *self.should_unwrap_native_token,
            referral_code: *self.referral_code
        }
    }
}

#[derive(Drop, starknet::Store, Serde)]
struct GetExecutionPriceCache {
    price: u128,
    execution_price: u128,
    adjusted_price_impact_usd: u128
}

/// Check if an order_type is a market order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is a market order
#[inline(always)]
fn is_market_order(order_type: OrderType) -> bool {
    //TODO
    true
}

/// Check if an orderType is a limit order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is a limit order
#[inline(always)]
fn is_limit_order(order_type: OrderType) -> bool {
    //TODO
    true
}

/// Check if an orderType is a swap order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is a swap order
#[inline(always)]
fn is_swap_order(order_type: OrderType) -> bool {
    //TODO
    true
}

/// Check if an orderType is a position order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is a position order
#[inline(always)]
fn is_position_order(order_type: OrderType) -> bool {
    //TODO
    true
}

/// Check if an orderType is an increase order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is an increase order
#[inline(always)]
fn is_increase_order(order_type: OrderType) -> bool {
    //TODO
    true
}

/// Check if an orderType is a decrease order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is a decrease order
#[inline(always)]
fn is_decrease_order(order_type: OrderType) -> bool {
    //TODO
    true
}

/// Check if an orderType is a liquidation order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is a liquidation order
#[inline(always)]
fn is_liquidation_order(order_type: OrderType) -> bool {
    //TODO
    true
}

/// Validate the price for increase / decrease orders based on the trigger_price
/// the acceptablePrice for increase / decrease orders is validated in get_execution_price
/// it is possible to update the oracle to support a primary_price and a secondary_price
/// which would allow for stop-loss orders to be executed at exactly the trigger_price.
/// # Arguments
/// * `oracle` - Oracle.
/// * `index_token` - The index token.
/// * `order_type` - The order type.
/// * `trigger_price` - the order's trigger_price.
/// * `is_long` - Whether the order is for a long or short.
#[inline(always)]
fn validate_order_trigger_price(
    oracle: IOracleDispatcher,
    index_token: ContractAddress,
    order_type: OrderType,
    trigger_price: u128,
    is_long: bool
) { //TODO
}

fn get_execution_price_for_increase(
    size_delta_usd: u128, size_delta_in_tokens: u128, acceptable_price: u128, is_long: bool
) -> u128 { //TODO
    0
}

#[inline(always)]
fn get_execution_price_for_decrease(
    index_token_price: Price,
    position_size_in_usd: u128,
    position_size_in_tokens: u128,
    size_delta_usd: u128,
    price_impact_usd: i128,
    acceptable_price: u128,
    is_long: bool
) -> u128 { //TODO
    0
}

/// Validates that an order exists.
/// # Arguments
/// * `order` - The order to check.
fn validate_non_empty_order(order: @Order) {
    assert(*order.account != ContractAddressZeroable::zero(), 'EmptyOrder');
    assert(*order.size_delta_usd != 0 || *order.initial_collateral_delta_amount != 0, 'EmptyOrder');
}
