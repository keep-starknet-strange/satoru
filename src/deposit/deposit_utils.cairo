//! Library for deposit functions, to help with the depositing of liquidity
//! into a market in return for market tokens.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use starknet::info::get_block_number;
use result::ResultTrait;
use satoru::utils::traits::ContractAddressDefault;
use traits::Default;

// Local imports.
use satoru::utils::{
    starknet_utils, store_arrays::StoreContractAddressArray, account_utils::validate_account,
    account_utils::validate_receiver, span32::Span32
};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::deposit::deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait};
use satoru::chain::chain::{IChainDispatcher, IChainDispatcherTrait};
use satoru::deposit::{deposit::Deposit, error::DepositError};
use satoru::market::market_utils;
use satoru::gas::{error::GasError, gas_utils};
use satoru::callback::callback_utils::{validate_callback_gas_limit, after_deposit_cancellation};
use satoru::nonce::nonce_utils;
use satoru::token::token_utils;
use starknet::contract_address::ContractAddressZeroable;
use satoru::event::event_utils::LogData;

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
    long_token_swap_path: Span32<ContractAddress>,
    /// The swap path into markets for the short token.
    short_token_swap_path: Span32<ContractAddress>,
    /// The minimum acceptable number of liquidity tokens.
    min_market_tokens: u128,
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
    mut params: CreateDepositParams
) -> felt252 {
    validate_account(account);

    //let market = data_store.get_market(data_store,params.market);
    let market = market_utils::get_enabled_market(data_store, params.market);
    market_utils::validate_swap_path(data_store, params.long_token_swap_path);
    market_utils::validate_swap_path(data_store, params.short_token_swap_path);

    // if the initialLongToken and initialShortToken are the same, only the initialLongTokenAmount would
    // be non-zero, the initialShortTokenAmount would be zero
    let mut initial_long_token_amount = deposit_vault.record_transfer_in(params.initial_long_token);
    let mut initial_short_token_amount = deposit_vault
        .record_transfer_in(params.initial_short_token);

    let fee_token: ContractAddress = token_utils::fee_token(data_store);

    if params.initial_long_token == fee_token {
        initial_long_token_amount -= params.execution_fee;
    } else if params.initial_short_token == fee_token {
        initial_short_token_amount -= params.execution_fee;
    } else {
        let fee_token_amount = deposit_vault.record_transfer_in(fee_token);
        assert(fee_token_amount >= params.execution_fee, GasError::INSUFF_EXEC_FEE);

        params.execution_fee = fee_token_amount;
    }

    assert(
        initial_long_token_amount > 0 || initial_short_token_amount > 0,
        DepositError::EMPTY_DEPOSIT_AMOUNTS
    );

    validate_receiver(params.receiver);
    let key = nonce_utils::get_next_key(data_store);
    let deposit = Deposit {
        key,
        account: account,
        receiver: params.receiver,
        callback_contract: params.callback_contract,
        ui_fee_receiver: params.ui_fee_receiver,
        market: market.market_token,
        initial_long_token: params.initial_long_token,
        initial_short_token: params.initial_short_token,
        long_token_swap_path: params.long_token_swap_path,
        short_token_swap_path: params.short_token_swap_path,
        initial_long_token_amount: initial_long_token_amount,
        initial_short_token_amount: initial_short_token_amount,
        min_market_tokens: params.min_market_tokens,
        updated_at_block: get_block_number(),
        execution_fee: params.execution_fee,
        callback_gas_limit: params.callback_gas_limit,
    };

    validate_callback_gas_limit(data_store, deposit.callback_gas_limit);
    let estimated_gas_limit = gas_utils::estimate_execute_deposit_gas_limit(data_store, deposit);
    gas_utils::validate_execution_fee(data_store, estimated_gas_limit, params.execution_fee);

    // add deposit values in data_store 
    data_store.set_deposit(key, deposit);

    // emit event
    event_emitter.emit_deposit_created(key, deposit);
    key
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
    keeper: ContractAddress,
    mut starting_gas: u128,
    reason: felt252,
    reason_bytes: Array<felt252>
) {
    starting_gas -= (starknet_utils::sn_gasleft(array![]) / 63);

    // get deposit info from data_store
    let mut deposit = Default::default();
    match data_store.get_deposit(key) {
        Option::Some(stored_deposit) => deposit = stored_deposit,
        Option::None => panic(array![DepositError::EMPTY_DEPOSIT, key])
    }

    assert(ContractAddressZeroable::is_non_zero(deposit.account), DepositError::EMPTY_DEPOSIT);
    assert(
        deposit.initial_long_token_amount > 0 || deposit.initial_short_token_amount > 0,
        DepositError::EMPTY_DEPOSIT_AMOUNTS
    );

    // remove key,account from data_store
    data_store.remove_deposit(key, deposit.account);

    if deposit.initial_long_token_amount > 0 {
        deposit_vault
            .transfer_out(
                deposit.initial_long_token, deposit.account, deposit.initial_long_token_amount
            );
    }

    if deposit.initial_short_token_amount > 0 {
        deposit_vault
            .transfer_out(
                deposit.initial_short_token, deposit.account, deposit.initial_short_token_amount
            );
    }

    event_emitter.emit_deposit_cancelled(key, reason, reason_bytes.span());

    //TODO use log data instead
    let log_data: LogData = Default::default();
    after_deposit_cancellation(key, deposit, log_data);

    gas_utils::pay_execution_fee_deposit(
        data_store,
        event_emitter,
        deposit_vault,
        deposit.execution_fee,
        starting_gas,
        keeper,
        deposit.account
    );
}

