// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;

// Local imports.
use satoru::withdrawal::withdrawal::{Withdrawal};
use satoru::withdrawal::withdrawal_vault::{
    IWithdrawalVaultDispatcher, IWithdrawalVaultDispatcherTrait
};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::swap::swap_utils::SwapParams;
use satoru::market::{market::Market, market_utils::MarketPrices};
use satoru::pricing::swap_pricing_utils::SwapFees;
use satoru::utils::store_arrays::{StoreContractAddressArray, StoreU64Array};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};

#[derive(Drop, starknet::Store, Serde)]
struct CreateWithdrawalParams {
    /// The address that will receive the withdrawal tokens.
    receiver: ContractAddress,
    /// The contract that will be called back.
    callback_contract: ContractAddress,
    /// The ui fee receiver.
    ui_fee_receiver: ContractAddress,
    /// The market on which the withdrawal will be executed.
    market: ContractAddress,
    /// The swap path for the long token
    long_token_swap_path: Array<ContractAddress>,
    /// The short token swap path
    short_token_swap_path: Array<ContractAddress>,
    /// The minimum amount of long tokens that must be withdrawn.
    min_long_token_amount: u128,
    /// The minimum amount of short tokens that must be withdrawn.
    min_short_token_amount: u128,
    /// Whether the native token should be unwrapped when executing the withdrawal.
    should_unwrap_native_token: bool,
    /// The execution fee for the withdrawal.
    execution_fee: u128,
    /// The gas limit for calling the callback contract.
    callback_gas_limit: u128,
}

#[derive(Drop, starknet::Store, Serde)]
struct ExecuteWithdrawalParams {
    /// The data store where withdrawal data is stored.
    data_store: IDataStoreDispatcher,
    /// The event emitter that is used to emit events.
    event_emitter: IEventEmitterDispatcher,
    /// The withdrawal vault.
    withdrawal_vault: IWithdrawalVaultDispatcher,
    /// The oracle that provides market prices.
    oracle: IOracleDispatcher,
    /// The unique identifier of the withdrawal to execute.
    key: felt252,
    /// The min block numbers for the oracle prices.
    min_oracle_block_numbers: Array<u64>,
    /// The max block numbers for the oracle prices.
    max_oracle_block_numbers: Array<u64>,
    /// The keeper that is executing the withdrawal.
    keeper: ContractAddress,
    /// The starting gas limit for the withdrawal execution.
    starting_gas: u128,
}

#[derive(Drop, starknet::Store, Serde)]
struct ExecuteWithdrawalCache {
    long_token_output_amount: u128,
    short_token_output_amount: u128,
    long_token_fees: SwapFees,
    short_token_fees: SwapFees,
    long_token_pool_amount_delta: u128,
    short_token_pool_amount_delta: u128,
}

#[derive(Drop, starknet::Store, Serde)]
struct ExecuteWithdrawalResult {
    output_token: ContractAddress,
    output_amount: u128,
    secondary_output_token: ContractAddress,
    secondary_output_amount: u128,
}

#[derive(Drop, starknet::Store, Serde)]
struct SwapCache {
    market: Market,
    swap_params: SwapParams,
    output_token: ContractAddress,
    output_amount: u128,
}

/// Creates a withdrawal in the withdrawal store.
/// # Arguments
/// * `data_store` - The data store where withdrawal data is stored.
/// * `event_emitter` - The event emitter that is used to emit events.
/// * `withdrawal_vault` - The withdrawal vault.
/// * `account` - The account that initiated the withdrawal.
/// * `params` - The parameters for creating the withdrawal.
/// # Returns
/// The unique identifier of the created withdrawal.
#[inline(always)]
fn create_withdrawal(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    withdrawal_vault: IWithdrawalVaultDispatcher,
    account: ContractAddress,
    params: CreateWithdrawalParams
) -> felt252 {
    // TODO
    0
}


/// Executes a withdrawal on the market.
/// # Arguments
/// * `params` - The parameters for executing the withdrawal.
#[inline(always)]
fn execute_withdrawal(params: ExecuteWithdrawalParams) { // TODO
}

/// Cancel a withdrawal.
/// # Arguments
/// * `data_store` - The data store where withdrawal data is stored.
/// * `event_emitter` - The event emitter that is used to emit events.
/// * `withdrawal_vault` - The withdrawal vault.
/// * `key` - The withdrawal key.
/// * `keeper` - The keeper sending the transaction.
/// * `starting_gas` - The starting gas for the transaction.
/// * `reason` - The reason for cancelling.
#[inline(always)]
fn cancel_withdrawal(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    withdrawal_vault: IWithdrawalVaultDispatcher,
    key: felt252,
    keeper: ContractAddress,
    starting_gas: u128,
    reason: felt252,
    reason_bytes: Array<felt252>,
) { // TODO
}

/// Executes a withdrawal.
/// # Arguments
/// * `params` - The parameters for executing the withdrawal.
/// * `withdrawal` - The withdrawal to execute.
/// # Returns
/// The unique identifier of the created withdrawal.
#[inline(always)]
fn execute_withdrawal_(
    params: ExecuteWithdrawalParams, withdrawal: Withdrawal
) -> ExecuteWithdrawalResult {
    // TODO
    let address_zero: ContractAddress = 0.try_into().unwrap();
    ExecuteWithdrawalResult {
        output_token: address_zero,
        output_amount: 0,
        secondary_output_token: address_zero,
        secondary_output_amount: 0,
    }
}

/// Swap tokens.
/// # Arguments
/// * `params` - The parameters for executing the withdrawal.
/// * `market` - The Market.
/// * `token_in` - The input token.
/// * `swap_path` - The swap path.
/// * `min_output_amount` - The minimum output amount.
/// * `receiver` - The receiver of the swap output.
/// * `ui_fee_receiver` - The ui fee receiver.
/// * `should_unwrap_native_token` - Weither native token should be unwraped or not.
/// # Returns
/// Output token and its amount.
#[inline(always)]
fn swap(
    params: ExecuteWithdrawalParams,
    market: Market,
    token_in: ContractAddress,
    amount_in: u128,
    swap_path: Array<ContractAddress>,
    min_output_amount: u128,
    receiver: ContractAddress,
    ui_fee_receiver: ContractAddress,
    should_unwrap_native_token: bool,
) -> (ContractAddress, u128) { // TODO
    (0.try_into().unwrap(), 0)
}

#[inline(always)]
fn get_output_amounts(
    params: ExecuteWithdrawalParams, market: Market, prices: MarketPrices, market_token_amount: u128
) -> (u128, u128) {
    // TODO
    (0, 0)
}
