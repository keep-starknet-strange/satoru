// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use clone::Clone;

// Local imports.
use satoru::order::base_order_utils::{ExecuteOrderParams, CreateOrderParams};
use satoru::order::base_order_utils;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::order::order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::market::market_utils;
use satoru::nonce::nonce_utils;
use satoru::utils::account_utils;
use satoru::referral::referral_utils;
use satoru::token::token_utils;
use satoru::callback::callback_utils;
use satoru::gas::gas_utils;
use satoru::order::order::Order;
use satoru::event::event_utils::LogData;
use satoru::order::error::OrderError;
use satoru::order::{increase_order_utils, decrease_order_utils, swap_order_utils};

/// Creates an order in the order store.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `order_vault` - The `OrderVault` contract dispatcher.
/// * `referral_store` - The referral storage instance to use.
/// * `account` - The order account.
/// * `params` - The parameters used to create the order.
/// # Returns
/// Return the key of the created order.
fn create_order(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    order_vault: IOrderVaultDispatcher,
    referral_storage: IReferralStorageDispatcher,
    account: ContractAddress,
    params: CreateOrderParams
) -> felt252 {
    0
    // account_utils::validate_account(account);
    // referral_utils::set_trader_referral_code(referral_storage, account, params.referral_code);

    // let initial_collateral_delta_amount = 0;

    // let wnt = token_utils::wnt(datadata_storeStore);

    // let should_record_separate_execution_fee_transfer = true;

    // if (
    //     params.order_type == OrderType::MarketSwap ||
    //     params.order_type == OrderType::LimitSwap ||
    //     params.order_type == OrderType::MarketIncrease ||
    //     params.order_type == OrderType::LimitIncrease
    // ) {
    //     // for swaps and increase orders, the initialCollateralDeltaAmount is set based on the amount of tokens
    //     // transferred to the orderVault
    //     initial_collateral_delta_amount = order_vault.record_transfer_in(params.addresses.initial_collateral_token);
    //     if (params.addresses.initial_collateral_token == wnt) {
    //         if (initial_collateral_delta_amount < params.numbers.execution_fee) {
    //             revert Errors.InsufficientWntAmountForExecutionFee(initialCollateralDeltaAmount, params.numbers.executionFee);
    //         }
    //         initial_collateral_delta_amount -= params.numbers.execution_fee;
    //         should_record_separate_execution_fee_transfer = false;
    //     }
    // } else if (
    //     params.orderType == OrderType::MarketDecrease ||
    //     params.orderType == OrderType::LimitDecrease ||
    //     params.orderType == OrderType::StopLossDecrease
    // ) {
    //     // for decrease orders, the initialCollateralDeltaAmount is based on the passed in value
    //     initial_collateral_delta_amount = params.numbers.initial_collateral_delta_amount;
    // } else {
    //     revert Errors.OrderTypeCannotBeCreated(uint256(params.orderType));
    // }

    // if (should_record_separate_execution_fee_transfer) {
    //     uint256 wnt_amount = order_vault.record_transfer_in(wnt);
    //     if (wnt_amount < params.numbers.execution_fee) {
    //         revert Errors.InsufficientWntAmountForExecutionFee(wntAmount, params.numbers.executionFee);
    //     }
    //     params.numbers.execution_fee = wnt_amount;
    // }

    // if (base_order_utils::is_position_order(params.orderType)) {
    //     market_utils::validate_position_market(data_store, params.addresses.market);
    // }

    // // validate swap path markets
    // market_utils::validate_swap_path(data_store, params.addresses.swap_path);

    // let order = Order {
    //     key: 0,
    //     order_type: params.order_type,
    //     decrease_position_swap_type: params.decrease_position_swap_type,
    //     account,
    //     receiver: params.addresses.receiver,
    //     callback_contract: params.addresses.callback_contract,
    //     ui_fee_receiver: params.addresses.ui_fee_receiver,
    //     market: params.addresses.market,
    //     initial_collateral_token: params.addresses.initial_collateral_token,
    //     swap_path: params.addresses.swap_path,
    //     size_delta_usd: params.numbers.size_delta_usd,
    //     initial_collateral_delta_amount,
    //     trigger_price: params.numbers.trigger_price,
    //     acceptable_price: params.numbers.acceptable_price,
    //     execution_fee: params.numbers.execution_fee,
    //     callback_gas_limit: params.numbers.callback_gas_limit,
    //     min_output_amount: params.numbers.min_output_amount,
    //     /// The block at which the order was last updated.
    //     updated_at_block: 0,
    //     is_long: params.is_long,
    //     should_unwrap_native_token: params.should_unwrap_native_token,
    //     /// Whether the order is frozen.
    //     is_frozen: false,
    // };

    // account_utils::validate_receiver(order.receiver);

    // callback_utils::validate_callback_gas_limit(data_store, order.callback_gas_limit);

    // let estimated_gas_limit = gas_utils::estimate_execute_order_gas_limit(data_store, order);
    // gas_utils::validate_execution_fee(data_store, estimated_gas_limit, order.execution_fee);

    // let key = nonce_utils::get_next_key(data_store);

    // order.touch();

    // base_order_utils::validate_non_empty_order(order);
    // data_store.set_order(key, order);

    // event_emitter.emit_order_created(key, order);

    // key
}

/// Executes an order.
/// # Arguments
/// * `params` - The parameters used to execute the order.
#[inline(always)]
fn execute_order(params: ExecuteOrderParams) {
    // 63/64 gas is forwarded to external calls, reduce the startingGas to account for this
    // TODO GAS NOT AVAILABLE params.startingGas -= gasleft() / 63;
    params.contracts.data_store.remove_order(params.key, params.order.account);

    base_order_utils::validate_non_empty_order(@params.order);

    base_order_utils::validate_order_trigger_price(
        params.contracts.oracle,
        params.market.index_token,
        params.order.order_type,
        params.order.trigger_price,
        params.order.is_long
    );

    let params_process = ExecuteOrderParams {
        contracts: params.contracts,
        key: params.key,
        order: params.order,
        swap_path_markets: params.swap_path_markets.clone(),
        min_oracle_block_numbers: params.min_oracle_block_numbers.clone(),
        max_oracle_block_numbers: params.max_oracle_block_numbers.clone(),
        market: params.market,
        keeper: params.keeper,
        starting_gas: params.starting_gas,
        secondary_order_type: params.secondary_order_type
    };

    let event_data : LogData = process_order(params_process);

    // validate that internal state changes are correct before calling
    // external callbacks
    // if the native token was transferred to the receiver in a swap
    // it may be possible to invoke external contracts before the validations
    // are called
    if (params.market.market_token != contract_address_const::<0>()) {
        market_utils::validate_market_token_balance_check(params.contracts.data_store, params.market);
    }
    market_utils::validate_market_token_balance_array(params.contracts.data_store, params.swap_path_markets);

    params.contracts.event_emitter.emit_order_executed(
        params.key,
        params.secondary_order_type
    );

    callback_utils::after_order_execution(params.key, params.order, event_data);

    // the order.executionFee for liquidation / adl orders is zero
    // gas costs for liquidations / adl is subsidised by the treasury
    gas_utils::pay_execution_fee_order(
        params.contracts.data_store,
        params.contracts.event_emitter,
        params.contracts.order_vault,
        params.order.execution_fee,
        params.starting_gas,
        params.keeper,
        params.order.account
    );
}

/// Process an order execution.
/// # Arguments
/// * `params` - The parameters used to process the order.
#[inline(always)]
fn process_order(params: ExecuteOrderParams) -> LogData {
    if (base_order_utils::is_increase_order(params.order.order_type)) {
        return increase_order_utils::process_order(params);
    }

    if (base_order_utils::is_decrease_order(params.order.order_type)) {
        return decrease_order_utils::process_order(params);
    }

    if (base_order_utils::is_swap_order(params.order.order_type)) {
        return swap_order_utils::process_order(params);
    }

    panic_with_felt252(OrderError::UNSUPPORTED_ORDER_TYPE)
}

/// Cancels an order.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `order_vault` - The `OrderVault` contract dispatcher.
/// * `key` - The key of the order to cancel
/// * `keeper` - The keeper sending the transaction.
/// * `starting_gas` - The starting gas of the transaction.
/// * `reason` - The reason for cancellation.
/// # Returns
/// Return the key of the created order.
fn cancel_order(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    order_vault: IOrderVaultDispatcher,
    key: felt252,
    keeper: ContractAddress,
    starting_gas: u128,
    reason: felt252,
    reason_bytes: Array<felt252>
) {
    // 63/64 gas is forwarded to external calls, reduce the startingGas to account for this
    // starting_gas -= gas_left() / 63;

    let order = data_store.get_order(key);
    base_order_utils::validate_non_empty_order(@order);

    data_store.remove_order(key, order.account);

    if (base_order_utils::is_increase_order(order.order_type) || base_order_utils::is_swap_order(order.order_type)) {
        if (order.initial_collateral_delta_amount > 0) {
            order_vault.transfer_out(
                order.initial_collateral_token,
                order.account,
                order.initial_collateral_delta_amount,
            );
        }
    }

    event_emitter.emit_order_cancelled(key, reason, reason_bytes.span());

    let event_data = Default::default();
    callback_utils::after_order_cancellation(key, order, event_data);

    gas_utils::pay_execution_fee_order(
        data_store,
        event_emitter,
        order_vault,
        order.execution_fee,
        starting_gas,
        keeper,
        order.account
    );
}

/// Freezes an order.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `order_vault` - The `OrderVault` contract dispatcher.
/// * `key` - The key of the order to freeze
/// * `keeper` - The keeper sending the transaction.
/// * `starting_gas` - The starting gas of the transaction.
/// * `reason` - The reason the order was frozen.
/// # Returns
/// Return the key of the created order.
fn freeze_order(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    order_vault: IOrderVaultDispatcher,
    key: felt252,
    keeper: ContractAddress,
    starting_gas: u128,
    reason: felt252,
    reason_bytes: Array<felt252>
) {
    // 63/64 gas is forwarded to external calls, reduce the startingGas to account for this
    // startingGas -= gas_left() / 63;

    let mut order = data_store.get_order(key);
    base_order_utils::validate_non_empty_order(@order);

    if (order.is_frozen) {
        panic_with_felt252(OrderError::ORDER_ALREADY_FROZEN)
    }

    let execution_fee = order.execution_fee;

    order.execution_fee = 0;
    order.is_frozen = true;
    data_store.set_order(key, order);

    event_emitter.emit_order_frozen(key, reason, reason_bytes.span());

    let event_data = Default::default();
    callback_utils::after_order_frozen(key, order, event_data);

    gas_utils::pay_execution_fee_order(
        data_store,
        event_emitter,
        order_vault,
        execution_fee,
        starting_gas,
        keeper,
        order.account
    );
}
