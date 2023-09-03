// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};
use gojo::oracle::oracle::{IOracleSafeDispatcher, IOracleSafeDispatcherTrait};
use gojo::swap::swap_handler::{ISwapHandlerSafeDispatcher, ISwapHandlerSafeDispatcherTrait};
use gojo::order::{
    order::{Order, SecondaryOrderType, OrderType, DecreasePositionSwapType},
    order_vault::{IOrderVaultSafeDispatcher, IOrderVaultSafeDispatcherTrait}
};
use gojo::market::market::Market;
use gojo::utils::store_arrays::{StoreMarketArray, StoreU64Array, StoreContractAddressArray};
use gojo::referral::referral_storage::interface::{
    IReferralStorageSafeDispatcher, IReferralStorageSafeDispatcherTrait
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
    data_store: IDataStoreSafeDispatcher,
    /// The dispatcher to interact with the `EventEmitter` contract
    event_emitter: IEventEmitterSafeDispatcher,
    /// The dispatcher to interact with the `OrderVault` contract
    order_vault: IOrderVaultSafeDispatcher,
    /// The dispatcher to interact with the `Oracle` contract
    oracle: IOracleSafeDispatcher,
    /// The dispatcher to interact with the `SwapHandler` contract
    swap_handler: ISwapHandlerSafeDispatcher,
    /// The dispatcher to interact with the `ReferralStorage` contract
    referral_storage: IReferralStorageSafeDispatcher
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
    execution_fee: u128,
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
