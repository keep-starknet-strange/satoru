// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};

/// Creates a liquidation order for a position.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `event_emitter` - The `EventEmitter` contract dispatcher.
/// * `account` - The position's account.
/// * `market` - The position's market.
/// * `collateral_token` - The position's collateralToken.
/// * `is_long` - Whether the position is long or short.
fn create_liquidation_order(
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    account: ContractAddress,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool
) -> felt252 {
    // TODO
    0
}
