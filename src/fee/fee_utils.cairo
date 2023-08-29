// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress};

// Local imports.
use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::event::event_emitter::{IEventEmitterSafeDispatcher, IEventEmitterSafeDispatcherTrait};

/// Increment the claimable fee amount.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `market` - The market to increment claimable fees for.
/// * `token` - The fee token.
/// * `delta` - The amount to increment.
/// * `fee_type` - The type of the fee.
fn increment_claimable_fee_amount(
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    delta: u128,
    fee_type: felt252,
) { //TODO
}

fn increment_claimable_ui_fee_amount(
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    uiFeeReceiver: ContractAddress,
    market: ContractAddress,
    token: ContractAddress,
    delta: u128,
    fee_type: felt252,
) { //TODO
}

/// Claim fees for the specified market.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `market` - The market to increment claimable fees for.
/// * `token` - The fee token.
/// * `receiver` - The receiver of the claimed fees.
fn claim_fees(
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    receiver: ContractAddress,
) { //TODO
}

fn claim_ui_fees(
    data_store: IDataStoreSafeDispatcher,
    event_emitter: IEventEmitterSafeDispatcher,
    ui_fee_receiver: ContractAddress,
    market: ContractAddress,
    token: ContractAddress,
    receiver: ContractAddress,
) -> u128 {
    //TODO
    0
}

fn emit_claimable_fee_amount_updated(
    event_emitter: IEventEmitterSafeDispatcher,
    market: ContractAddress,
    token: ContractAddress,
    delta: u128,
    next_value: u128,
    fee_type: felt252
) { //TODO
}

fn emit_claimable_ui_fee_amount_updated(
    event_emitter: IEventEmitterSafeDispatcher,
    ui_fee_receiver: ContractAddress,
    market: ContractAddress,
    token: ContractAddress,
    delta: u128,
    next_value: u128,
    next_pool_value: u128,
    fee_type: felt252
) { //TODO
}

fn emit_fees_claimed(
    event_emitter: IEventEmitterSafeDispatcher,
    market: ContractAddress,
    receiver: ContractAddress,
    fee_amount: u128
) { //TODO
}

fn emit_ui_fees_claimed(
    event_emitter: IEventEmitterSafeDispatcher,
    ui_fee_receiver: ContractAddress,
    market: ContractAddress,
    receiver: ContractAddress,
    fee_amount: u128,
    next_pool_value: u128,
) { //TODO
}
