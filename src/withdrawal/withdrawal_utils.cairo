// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, get_block_timestamp, contract_address_const};

// Local imports.
use satoru::bank::{bank::{IBankDispatcher, IBankDispatcherTrait},};
use satoru::data::{data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait}, keys};
use satoru::callback::callback_utils;
use satoru::event::{
    event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait},
    event_utils::EventLogData
};
use satoru::fee::fee_utils;
use satoru::gas::gas_utils;
use satoru::market::{
    market::Market, market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait},
    market_utils, market_utils::MarketPrices
};
use satoru::nonce::nonce_utils;
use satoru::oracle::{oracle::{IOracleDispatcher, IOracleDispatcherTrait}, oracle_utils};
use satoru::pricing::{swap_pricing_utils, swap_pricing_utils::SwapFees};
use satoru::swap::{swap_utils, swap_utils::SwapParams};
use satoru::utils::{
    calc, account_utils, error_utils, precision, starknet_utils, span32::Span32,
    store_arrays::{StoreContractAddressArray, StoreU128Array}
};
use satoru::withdrawal::{
    error::WithdrawalError, withdrawal::Withdrawal,
    withdrawal_vault::{IWithdrawalVaultDispatcher, IWithdrawalVaultDispatcherTrait}
};

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
    long_token_swap_path: Span32<ContractAddress>,
    /// The short token swap path
    short_token_swap_path: Span32<ContractAddress>,
    /// The minimum amount of long tokens that must be withdrawn.
    min_long_token_amount: u128,
    /// The minimum amount of short tokens that must be withdrawn.
    min_short_token_amount: u128,
    /// The execution fee for the withdrawal.
    execution_fee: u128,
    /// The gas limit for calling the callback contract.
    callback_gas_limit: u128,
}

#[derive(Drop, Serde)]
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

#[derive(Default, Drop, starknet::Store, Serde)]
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

#[derive(Drop, Serde)]
struct SwapCache {
    swap_path_markets: Array<Market>,
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
    mut params: CreateWithdrawalParams
) -> felt252 {
    account_utils::validate_account(account);

    let fee_token = data_store.get_address(keys::fee_token());

    let fee_token_amount = withdrawal_vault.record_transfer_in(fee_token);

    if fee_token_amount < params.execution_fee {
        WithdrawalError::INSUFFICIENT_FEE_TOKEN_AMOUNT(fee_token_amount, params.execution_fee);
    }

    account_utils::validate_receiver(params.receiver);

    let market_token_amount = withdrawal_vault.record_transfer_in(params.market);

    if market_token_amount.is_zero() {
        WithdrawalError::EMPTY_WITHDRAWAL_AMOUNT;
    }

    params.execution_fee = fee_token_amount.into();

    market_utils::validate_enabled_market_address(@data_store, params.market);

    market_utils::validate_swap_path(data_store, params.long_token_swap_path);

    market_utils::validate_swap_path(data_store, params.short_token_swap_path);

    let mut withdrawal = Withdrawal {
        key: 0,
        account: contract_address_const::<0>(),
        receiver: contract_address_const::<0>(),
        callback_contract: contract_address_const::<0>(),
        ui_fee_receiver: contract_address_const::<0>(),
        market: contract_address_const::<0>(),
        long_token_swap_path: Default::default(),
        short_token_swap_path: Default::default(),
        market_token_amount: 0,
        min_long_token_amount: 0,
        min_short_token_amount: 0,
        updated_at_block: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
    };

    withdrawal.account = account;
    withdrawal.receiver = params.receiver;
    withdrawal.callback_contract = params.callback_contract;
    withdrawal.ui_fee_receiver = params.ui_fee_receiver;
    withdrawal.market = params.market;
    withdrawal.long_token_swap_path = params.long_token_swap_path;
    withdrawal.short_token_swap_path = params.short_token_swap_path;
    withdrawal.market_token_amount = market_token_amount;
    withdrawal.min_long_token_amount = params.min_long_token_amount;
    withdrawal.min_short_token_amount = params.min_short_token_amount;
    withdrawal.updated_at_block = get_block_timestamp();
    withdrawal.execution_fee = params.execution_fee;
    withdrawal.callback_gas_limit = params.callback_gas_limit;

    callback_utils::validate_callback_gas_limit(data_store, withdrawal.callback_gas_limit);

    let estimated_gas_limit = gas_utils::estimate_execute_withdrawal_gas_limit(
        data_store, withdrawal
    );

    gas_utils::validate_execution_fee(data_store, estimated_gas_limit, params.execution_fee);

    let key = nonce_utils::get_next_key(data_store);

    data_store.set_withdrawal(key, withdrawal);

    event_emitter.emit_withdrawal_created(key, withdrawal);

    key
}


/// Executes a withdrawal on the market.
/// # Arguments
/// * `params` - The parameters for executing the withdrawal.
#[inline(always)]
fn execute_withdrawal(
    mut params: ExecuteWithdrawalParams
) { // 63/64 gas is forwarded to external calls, reduce the startingGas to account for this
    // TODO: change the following line once once equivalent function is available in starknet.
    params.starting_gas -= (starknet_utils::sn_gasleft(array![]) / 63);
    let result = params.data_store.get_withdrawal(params.key);

    match result {
        Option::Some(withdrawal) => {
            params.data_store.remove_withdrawal(params.key, withdrawal.account);
            if withdrawal.account.is_zero() {
                WithdrawalError::EMPTY_WITHDRAWAL;
            }

            if withdrawal.market_token_amount.is_zero() {
                WithdrawalError::EMPTY_WITHDRAWAL_AMOUNT;
            }

            oracle_utils::validate_block_number_within_range(
                params.min_oracle_block_numbers.span(),
                params.max_oracle_block_numbers.span(),
                withdrawal.updated_at_block
            );

            let market_token_balance = IMarketTokenDispatcher {
                contract_address: withdrawal.market
            }
                .balance_of(params.withdrawal_vault.contract_address);

            if market_token_balance < withdrawal.market_token_amount {
                WithdrawalError::INSUFFICIENT_MARKET_TOKENS(
                    market_token_balance, withdrawal.market_token_amount
                );
            }

            let result = execute_withdrawal_(@params, withdrawal);

            params.event_emitter.emit_withdrawal_executed(params.key);

            gas_utils::pay_execution_fee(
                params.data_store,
                params.event_emitter,
                params.withdrawal_vault,
                withdrawal.execution_fee,
                params.starting_gas,
                params.keeper,
                withdrawal.account
            )
        },
        Option::None => {
            WithdrawalError::INVALID_WITHDRAWAL_KEY(params.key);
        }
    }
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
    mut starting_gas: u128,
    reason: felt252,
    reason_bytes: Array<felt252>,
) {
    // 63/64 gas is forwarded to external calls, reduce the startingGas to account for this
    // startingGas -= gasleft() / 63;
    starting_gas -= (starknet_utils::sn_gasleft(array![]) / 63);

    let withdrawal = data_store.get_withdrawal(key).expect('get_withdrawal failed');

    if withdrawal.account.is_zero() {
        WithdrawalError::EMPTY_WITHDRAWAL;
    }

    if withdrawal.market_token_amount.is_zero() {
        WithdrawalError::EMPTY_WITHDRAWAL_AMOUNT;
    }

    data_store.remove_withdrawal(key, withdrawal.account);

    withdrawal_vault
        .transfer_out(withdrawal.market, withdrawal.account, withdrawal.market_token_amount);

    event_emitter.emit_withdrawal_cancelled(key, reason, reason_bytes.span());

    gas_utils::pay_execution_fee(
        data_store,
        event_emitter,
        withdrawal_vault,
        withdrawal.execution_fee,
        starting_gas,
        keeper,
        withdrawal.account
    )
}

/// Executes a withdrawal.
/// # Arguments
/// * `params` - The parameters for executing the withdrawal.
/// * `withdrawal` - The withdrawal to execute.
/// # Returns
/// The unique identifier of the created withdrawal.
#[inline(always)]
fn execute_withdrawal_(
    params: @ExecuteWithdrawalParams, withdrawal: Withdrawal
) -> ExecuteWithdrawalResult {
    let market = market_utils::get_enabled_market(*params.data_store, withdrawal.market);

    let prices = market_utils::get_market_prices(*params.oracle, market);

    let mut cache: ExecuteWithdrawalCache = Default::default();

    let (long_token_output_amount, short_token_output_amount) = get_output_amounts(
        params, market, @prices, withdrawal.market_token_amount
    );
    cache.long_token_output_amount = long_token_output_amount;
    cache.short_token_output_amount = short_token_output_amount;

    cache
        .long_token_fees =
            swap_pricing_utils::get_swap_fees(
                *params.data_store,
                market.market_token,
                cache.long_token_output_amount,
                false,
                withdrawal.ui_fee_receiver
            );

    fee_utils::increment_claimable_fee_amount(
        *params.data_store,
        *params.event_emitter,
        market.market_token,
        market.long_token,
        cache.long_token_fees.fee_receiver_amount,
        keys::withdrawal_fee_type()
    );

    fee_utils::increment_claimable_ui_fee_amount(
        *params.data_store,
        *params.event_emitter,
        withdrawal.ui_fee_receiver,
        market.market_token,
        market.long_token,
        cache.long_token_fees.ui_fee_amount,
        keys::withdrawal_fee_type()
    );

    cache
        .short_token_fees =
            swap_pricing_utils::get_swap_fees(
                *params.data_store,
                market.market_token,
                cache.short_token_output_amount,
                false,
                withdrawal.ui_fee_receiver
            );

    fee_utils::increment_claimable_fee_amount(
        *params.data_store,
        *params.event_emitter,
        market.market_token,
        market.short_token,
        cache.short_token_fees.fee_receiver_amount,
        keys::withdrawal_fee_type()
    );

    fee_utils::increment_claimable_ui_fee_amount(
        *params.data_store,
        *params.event_emitter,
        withdrawal.ui_fee_receiver,
        market.market_token,
        market.short_token,
        cache.short_token_fees.ui_fee_amount,
        keys::withdrawal_fee_type()
    );

    cache.long_token_pool_amount_delta = cache.long_token_output_amount
        - cache.long_token_fees.fee_amount_for_pool;

    cache.long_token_output_amount = cache.long_token_fees.amount_after_fees;

    cache.short_token_pool_amount_delta = cache.short_token_output_amount
        - cache.short_token_fees.fee_amount_for_pool;

    cache.short_token_output_amount = cache.short_token_fees.amount_after_fees;

    // it is rare but possible for withdrawals to be blocked because pending borrowing fees
    // have not yet been deducted from position collateral and credited to the poolAmount value
    market_utils::apply_delta_to_pool_amount(
        *params.data_store,
        *params.event_emitter,
        market,
        market.long_token,
        calc::to_signed(cache.long_token_pool_amount_delta, false)
    );

    market_utils::apply_delta_to_pool_amount(
        *params.data_store,
        *params.event_emitter,
        market,
        market.short_token,
        calc::to_signed(cache.short_token_pool_amount_delta, false)
    );

    market_utils::validate_reserve(*params.data_store, market, @prices, true);

    market_utils::validate_reserve(*params.data_store, market, @prices, false);

    market_utils::validate_max_pnl(
        *params.data_store,
        market,
        @prices,
        keys::max_pnl_factor_for_withdrawals(),
        keys::max_pnl_factor_for_withdrawals()
    );

    IMarketTokenDispatcher { contract_address: market.market_token }
        .burn(*params.withdrawal_vault.contract_address, withdrawal.market_token_amount);

    (*params.withdrawal_vault).sync_token_balance(market.market_token);

    let mut result = ExecuteWithdrawalResult {
        output_token: Zeroable::zero(),
        output_amount: 0,
        secondary_output_token: Zeroable::zero(),
        secondary_output_amount: 0
    };

    let (output_token, output_amount) = swap(
        params,
        market,
        market.long_token,
        cache.long_token_output_amount,
        withdrawal.long_token_swap_path,
        withdrawal.min_long_token_amount,
        withdrawal.receiver,
        withdrawal.ui_fee_receiver
    );
    result.output_token = output_token;
    result.output_amount = output_amount;

    let (secondary_output_token, secondary_output_amount) = swap(
        params,
        market,
        market.short_token,
        cache.short_token_output_amount,
        withdrawal.short_token_swap_path,
        withdrawal.min_short_token_amount,
        withdrawal.receiver,
        withdrawal.ui_fee_receiver
    );
    result.secondary_output_token = secondary_output_token;
    result.secondary_output_amount = secondary_output_amount;

    (*params.event_emitter)
        .emit_swap_fees_collected(
            market.market_token,
            market.long_token,
            prices.long_token_price.min,
            'withdrawal',
            cache.long_token_fees
        );

    (*params.event_emitter)
        .emit_swap_fees_collected(
            market.market_token,
            market.short_token,
            prices.short_token_price.min,
            'withdrawal',
            cache.short_token_fees
        );

    // if the native token was transferred to the receiver in a swap
    // it may be possible to invoke external contracts before the validations are called
    market_utils::validate_market_token_balance(*params.data_store, market);

    result
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
/// # Returns
/// Output token and its amount.
#[inline(always)]
fn swap(
    params: @ExecuteWithdrawalParams,
    market: Market,
    token_in: ContractAddress,
    amount_in: u128,
    swap_path: Span32<ContractAddress>,
    min_output_amount: u128,
    receiver: ContractAddress,
    ui_fee_receiver: ContractAddress,
) -> (ContractAddress, u128) {
    let mut cache = SwapCache {
        swap_path_markets: Default::default(),
        swap_params: Default::default(),
        output_token: Zeroable::zero(),
        output_amount: 0,
    };

    cache.swap_path_markets = market_utils::get_swap_path_markets(*params.data_store, swap_path);

    cache.swap_params.data_store = *params.data_store;

    cache.swap_params.event_emitter = *params.event_emitter;

    cache.swap_params.oracle = *params.oracle;

    cache.swap_params.bank = IBankDispatcher { contract_address: market.market_token };

    cache.swap_params.key = *params.key;

    cache.swap_params.token_in = token_in;

    cache.swap_params.amount_in = amount_in;

    cache.swap_params.swap_path_markets = cache.swap_path_markets.span();

    cache.swap_params.min_output_amount = min_output_amount;

    cache.swap_params.receiver = receiver;

    cache.swap_params.ui_fee_receiver = ui_fee_receiver;

    let cache_swap_params = @cache.swap_params;
    let (output_token, output_amount) = swap_utils::swap(cache_swap_params);

    // validate that internal state changes are correct before calling external callbacks
    market_utils::validate_markets_token_balance(
        *params.data_store, cache.swap_params.swap_path_markets
    );

    (cache.output_token, cache.output_amount)
}

#[inline(always)]
fn get_output_amounts(
    params: @ExecuteWithdrawalParams,
    market: Market,
    prices: @MarketPrices,
    market_token_amount: u128
) -> (u128, u128) {
    // the max pnl factor for withdrawals should be the lower of the max pnl factor values
    // which means that pnl would be capped to a smaller amount and the pool
    // value would be higher even if there is a large pnl
    // this should be okay since MarketUtils.validateMaxPnl is called after the withdrawal
    // which ensures that the max pnl factor for withdrawals was not exceeded
    let pool_value_info = market_utils::get_pool_value_info(
        *params.data_store,
        market,
        (*params.oracle).get_primary_price(market.index_token),
        *prices.long_token_price,
        *prices.short_token_price,
        keys::max_pnl_factor_for_withdrawals(),
        false
    );

    if pool_value_info.pool_value <= 0 {
        WithdrawalError::INVALID_POOL_VALUE_FOR_WITHDRAWAL(pool_value_info.pool_value);
    }

    let pool_value = calc::to_unsigned(pool_value_info.pool_value);

    let market_tokens_supply = market_utils::get_market_token_supply(
        IMarketTokenDispatcher { contract_address: market.market_token }
    );

    (*params.event_emitter)
        .emit_market_pool_value_info(market.market_token, pool_value_info, market_tokens_supply);

    let long_token_pool_amount = market_utils::get_pool_amount(
        *params.data_store, @market, market.long_token
    );

    let short_token_pool_amount = market_utils::get_pool_amount(
        *params.data_store, @market, market.short_token
    );

    let long_token_pool_usd = long_token_pool_amount * *prices.long_token_price.max;

    let short_token_pool_usd = short_token_pool_amount * *prices.short_token_price.max;

    let total_pool_usd = long_token_pool_usd + short_token_pool_usd;

    let market_token_usd = market_utils::market_token_amount_to_usd(
        market_token_amount, pool_value, market_tokens_supply
    );

    let long_token_output_usd = precision::mul_div(
        market_token_usd, long_token_pool_usd, total_pool_usd
    );

    let short_token_output_usd = precision::mul_div(
        market_token_usd, short_token_pool_usd, total_pool_usd
    );

    error_utils::check_division_by_zero(*prices.long_token_price.max, 'long_token_price.max');
    error_utils::check_division_by_zero(*prices.short_token_price.max, 'short_token_price.max');

    (
        long_token_output_usd / *prices.long_token_price.max,
        short_token_output_usd / *prices.short_token_price.max
    )
}
