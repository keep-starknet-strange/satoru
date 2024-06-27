// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::market::{market, market_utils::validate_market_token_balance_with_address};
use satoru::data::keys;
use satoru::utils::account_utils::validate_receiver;

/// Increment the claimable fee amount for the specified market.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `market` - The market to increment claimable fees for.
/// * `token` - The fee token.
/// * `delta` - The amount to increment.
/// * `fee_type` - The type of the fee.
fn increment_claimable_fee_amount(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    delta: u256,
    fee_type: felt252,
) {
    if delta == 0 {
        return;
    }

    let key = keys::claimable_fee_amount_key(market, token);

    let next_value = data_store.increment_u256(key, delta);

    event_emitter.emit_claimable_fee_amount_updated(market, token, delta, next_value, fee_type);
}

/// Increment the claimable ui fee amount for the specified market.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `ui_fee_receiver` - The ui fees receiver.
/// * `market` - The market to increment claimable fees for.
/// * `token` - The fee token.
/// * `delta` - The amount to increment.
/// * `fee_type` - The type of the fee.
fn increment_claimable_ui_fee_amount(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    ui_fee_receiver: ContractAddress,
    market: ContractAddress,
    token: ContractAddress,
    delta: u256,
    fee_type: felt252,
) {
    if delta == 0 {
        return;
    }

    let next_value = data_store
        .increment_u256(
            keys::claimable_ui_fee_amount_for_account_key(market, token, ui_fee_receiver), delta
        );

    let next_pool_value = data_store
        .increment_u256(keys::claimable_ui_fee_amount_key(market, token), delta);
    event_emitter
        .emit_claimable_ui_fee_amount_updated(
            ui_fee_receiver, market, token, delta, next_value, next_pool_value, fee_type
        );
}

/// Claim fees for the specified market.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `market` - The market to increment claimable fees for.
/// * `token` - The fee token.
/// * `receiver` - The receiver of the claimed fees.
fn claim_fees(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    receiver: ContractAddress,
) {
    validate_receiver(receiver);

    let key = keys::claimable_fee_amount_key(market, token);

    let fee_amount = data_store.get_u256(key);
    data_store.set_u256(key, 0);

    IBankDispatcher { contract_address: market }.transfer_out(market, token, receiver, fee_amount);

    validate_market_token_balance_with_address(data_store, market);

    event_emitter.emit_fees_claimed(market, receiver, fee_amount);
}

/// Claim ui fees for the specified market.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `ui_fee_receiver` - The ui fees receiver.
/// * `market` - The market to increment claimable fees for.
/// * `token` - The fee token.
/// * `receiver` - The receiver of the claimed fees.
fn claim_ui_fees(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    ui_fee_receiver: ContractAddress,
    market: ContractAddress,
    token: ContractAddress,
    receiver: ContractAddress,
) -> u256 {
    validate_receiver(receiver);

    let key = keys::claimable_ui_fee_amount_for_account_key(market, token, ui_fee_receiver);
    let fee_amount = data_store.get_u256(key);
    data_store.set_u256(key, 0);

    let next_pool_value = data_store
        .decrement_u256(keys::claimable_ui_fee_amount_key(market, token), fee_amount);

    IBankDispatcher { contract_address: market }.transfer_out(market, token, receiver, fee_amount);

    validate_market_token_balance_with_address(data_store, market);

    event_emitter
        .emit_ui_fees_claimed(ui_fee_receiver, market, receiver, fee_amount, next_pool_value);

    fee_amount
}
