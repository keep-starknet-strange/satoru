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
use satoru::utils::store_arrays::StoreContractAddressArray;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::deposit::deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait};

/// Helps with deposit creation.
#[derive(Drop, starknet::Store, Serde)]
struct CreateDepositParams {
    /// The address to send the market tokens to.
    receiver: ContractAddress,
    /// The callback contract linked to this deposit.
    callback_contract: ContractAddress,
    /// The ui fee receiver.
    ui_fee_receiver: ContractAddress,
    /// The market to deposit into.
    market: ContractAddress,
    /// The initial long token address.
    initial_long_token: ContractAddress,
    /// The initial short token address.
    initial_short_token: ContractAddress,
    /// The swap path into markets for the long token.
    long_token_swap_path: Array<ContractAddress>,
    /// The swap path into markets for the short token.
    short_token_swap_path: Array<ContractAddress>,
    /// The minimum acceptable number of liquidity tokens.
    min_market_tokens: u128,
    /// Whether to unwrap the native token when sending funds back
    /// to the user in case the deposit gets cancelled.
    should_unwrap_native_token: bool,
    /// The execution fee for keepers.
    execution_fee: u128,
    /// The gas limit for the callback_contract.
    callback_gas_limit: u128,
}


/// Creates a deposit.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `deposit_vault` - The `DepositVault` contract dispatcher.
/// * `account` - The depositing account.
/// * `params` - The parameters used to process the deposit.
fn create_deposit(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    deposit_vault: IDepositVaultDispatcher,
    account: ContractAddress,
    params: CreateDepositParams
) -> felt252 {
    //TODO
    0
}

/// Cancels a deposit, funds are sent back to the user.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `deposit_vault` - The `DepositVault` contract dispatcher.
/// * `key` - The key of the deposit to cancel.
/// * `keeper` - The address of the keeper.
/// * `starting_gas` - Tthe starting gas amount.
/// * `reason` - The reason the deposit was cancelled.
fn cancel_deposit(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    deposit_vault: IDepositVaultDispatcher,
    key: felt252,
    address: ContractAddress,
    starting_gas: u128,
    reason: felt252,
    reason_bytes: Array<felt252>
) { //TODO
}
