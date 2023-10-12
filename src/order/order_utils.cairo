// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::order::base_order_utils::{ExecuteOrderParams, CreateOrderParams};
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
    account_utils::validate_account(account);
    referral_utils::set_trader_referral_code(referral_storage, account, params.referral_code);

    let initial_collateral_delta_amount = 0;

    let wnt = token_utils::wnt(datadata_storeStore);

    let should_record_separate_execution_fee_transfer = true;

    if (
        params.order_type == OrderType::MarketSwap ||
        params.order_type == OrderType::LimitSwap ||
        params.order_type == OrderType::MarketIncrease ||
        params.order_type == OrderType::LimitIncrease
    ) {
        // for swaps and increase orders, the initialCollateralDeltaAmount is set based on the amount of tokens
        // transferred to the orderVault
        initial_collateral_delta_amount = order_vault.record_transfer_in(params.addresses.initial_collateral_token);
        if (params.addresses.initial_collateral_token == wnt) {
            if (initial_collateral_delta_amount < params.numbers.execution_fee) {
                revert Errors.InsufficientWntAmountForExecutionFee(initialCollateralDeltaAmount, params.numbers.executionFee);
            }
            initial_collateral_delta_amount -= params.numbers.execution_fee;
            should_record_separate_execution_fee_transfer = false;
        }
    } else if (
        params.orderType == OrderType::MarketDecrease ||
        params.orderType == OrderType::LimitDecrease ||
        params.orderType == OrderType::StopLossDecrease
    ) {
        // for decrease orders, the initialCollateralDeltaAmount is based on the passed in value
        initial_collateral_delta_amount = params.numbers.initial_collateral_delta_amount;
    } else {
        revert Errors.OrderTypeCannotBeCreated(uint256(params.orderType));
    }

    if (should_record_separate_execution_fee_transfer) {
        uint256 wnt_amount = order_vault.record_transfer_in(wnt);
        if (wnt_amount < params.numbers.execution_fee) {
            revert Errors.InsufficientWntAmountForExecutionFee(wntAmount, params.numbers.executionFee);
        }
        params.numbers.execution_fee = wnt_amount;
    }

    if (base_order_utils::is_position_order(params.orderType)) {
        market_utils::validate_position_market(data_store, params.addresses.market);
    }

    // validate swap path markets
    market_utils::validate_swap_path(data_store, params.addresses.swap_path);

    let order = Order {
        key: 0,
        order_type: params.order_type,
        decrease_position_swap_type: params.decrease_position_swap_type,
        account,
        receiver: params.addresses.receiver,
        callback_contract: params.addresses.callback_contract,
        ui_fee_receiver: params.addresses.ui_fee_receiver,
        market: params.addresses.market,
        initial_collateral_token: params.addresses.initial_collateral_token,
        swap_path: params.addresses.swap_path,
        size_delta_usd: params.numbers.size_delta_usd,
        initial_collateral_delta_amount,
        trigger_price: params.numbers.trigger_price,
        acceptable_price: params.numbers.acceptable_price,
        execution_fee: params.numbers.execution_fee,
        callback_gas_limit: params.numbers.callback_gas_limit,
        min_output_amount: params.numbers.min_output_amount,
        /// The block at which the order was last updated.
        updated_at_block: 0,
        is_long: params.is_long,
        should_unwrap_native_token: params.should_unwrap_native_token,
        /// Whether the order is frozen.
        is_frozen: false,
    };

    account_utils::validate_receiver(order.receiver);

    callback_utils::validate_callback_gas_limit(data_store, order.callback_gas_limit);

    let estimated_gas_limit = gas_utils::estimate_execute_order_gas_limit(data_store, order);
    gas_utils::validate_execution_fee(data_store, estimated_gas_limit, order.execution_fee);

    let key = nonce_utils::get_next_key(data_store);

    order.touch();

    base_order_utils::validate_non_empty_order(order);
    data_store.set_order(key, order);

    event_emitter.emit_order_created(key, order);

    key
}

/// Executes an order.
/// # Arguments
/// * `params` - The parameters used to execute the order.
#[inline(always)]
fn execute_order(params: ExecuteOrderParams) { //TODO
}

/// Process an order execution.
/// # Arguments
/// * `params` - The parameters used to process the order.
#[inline(always)]
fn process_order(params: ExecuteOrderParams) { //TODO
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
) { //TODO
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
) { //TODO
}
