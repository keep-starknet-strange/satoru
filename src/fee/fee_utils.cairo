// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::keys::{
    claim_fee_amount_key, claim_ui_fee_amount_key, claim_ui_fee_amount_for_account_key
};
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
    delta: u128,
    fee_type: felt252,
) {
    if delta == 0 {
        return;
    }

    let key = claim_fee_amount_key(market, token);

    let next_value = data_store.increment_u128(key, delta);

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
    delta: u128,
    fee_type: felt252,
) {
    if delta == 0 {
        return;
    }

    let next_value = data_store
        .increment_u128(claim_ui_fee_amount_for_account_key(market, token, ui_fee_receiver), delta);

    let next_pool_value = data_store.increment_u128(claim_ui_fee_amount_key(market, token), delta);

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
) { // TODO
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
) -> u128 {
    // TODO
    0
}
