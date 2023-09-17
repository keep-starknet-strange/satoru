//! Library for deposit functions, to help with the depositing of liquidity
//! into a market in return for market tokens.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;

use debug::PrintTrait;
// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::deposit::deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::price::price::Price;
use satoru::market::market::Market;
use satoru::utils::span32::Span32;

/// Struct used in executeDeposit to avoid stack too deep errors
#[derive(Drop, Serde)]
struct ExecuteDepositParams {
    /// `data_store` contract dispatcher.
    data_store: IDataStoreDispatcher,
    /// `event_emitter` contract dispatcher.
    event_emitter: IEventEmitterDispatcher,
    /// `deposit_vault` contract dispatcher.
    deposit_vault: IDepositVaultDispatcher,
    /// `oracle` contract dispatcher.
    oracle: IOracleDispatcher,
    /// `key` the key of the deposit to execute.
    key: felt252,
    /// `min_oracle_block_numbers` the min oracle block numbers.
    min_oracle_block_numbers: Array<u64>,
    /// `max_oracle_block_numbers` the max oracle block numbers
    max_oracle_block_numbers: Array<u64>,
    /// `keeper` the address of the keeper executing the deposit.
    keeper: ContractAddress,
    /// `starting_gas` the starting amount of gas.
    starting_gas: u128
}

/// Struct used in executeDeposit to avoid stack too deep errors
#[derive(Drop, starknet::Store, Serde)]
struct _ExecuteDepositParams {
    /// `market` The market to deposit into.
    market: Market,
    /// `account` The depositing account.
    account: ContractAddress,
    /// `receiver` The account to send the market tokens to.
    receiver: ContractAddress,
    /// `ui_fee_receiver` The ui fee receiver account.
    ui_fee_receiver: ContractAddress,
    /// `token_in` The token to deposit.
    token_in: ContractAddress,
    /// `token_out` The other token.
    token_out: ContractAddress,
    /// `token_in_price` Price of token_in.
    token_in_price: Price,
    /// `token_out_price` Price of token_out.
    token_out_price: Price,
    /// `amount` Amount of token_in.
    amount: u128,
    /// `price_impact_usd` Price impact in USD.
    price_impact_usd: u128
}

struct ExecuteDepositCache {
    long_token_amount: u128,
    short_token_amount: u128,
    long_token_usd: u128,
    short_token_usd: u128,
    received_market_tokens: u128,
    price_impact_usd: i128
}

/// Executes a deposit.
/// # Arguments
/// * `params` - ExecuteDepositParams.
#[inline(always)]
fn execute_deposit(params: ExecuteDepositParams) { //TODO
}

/// Executes a deposit.
/// # Arguments
/// * `params` - ExecuteDepositParams.
/// * `_params` - _ExecuteDepositParams.
#[inline(always)]
fn _execute_deposit(params: ExecuteDepositParams, _params: _ExecuteDepositParams) -> u128 {
    //TODO
    0
}

#[inline(always)]
fn swap(
    params: ExecuteDepositParams,
    swap_path: Span32<ContractAddress>,
    initial_token: ContractAddress,
    intput_amount: u128,
    market: ContractAddress,
    expected_output_token: ContractAddress,
    ui_fee_receiver: ContractAddress
) -> u128 {
    //TODO
    0
}
