// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::data::keys;
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::position::position_utils::get_position_key;
use satoru::order::order::{SecondaryOrderType, OrderType, Order, DecreasePositionSwapType};
use satoru::callback::callback_utils::get_saved_callback_contract;
use satoru::utils::span32::{Span32, Array32Trait};
use satoru::nonce::nonce_utils::get_next_key;
use integer::BoundedInt;

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
    let key = get_position_key(account, market, collateral_token, is_long);
    let position = data_store.get_position(key).expect('no position found');
    let callback_contract = get_saved_callback_contract(data_store, account, market);
    let acceptable_price = if position.is_long {
        0
    } else {
        BoundedInt::<u128>::max()
    };
    let callback_gas_limit = data_store.get_u128(keys::max_callback_gas_limit());
    let swap_path = Array32Trait::<ContractAddress>::span32(@ArrayTrait::new());
    let updated_at_block = starknet::info::get_block_number();
    let size_delta_usd = position.size_in_usd;
    let trigger_price = 0;
    let min_output_amount = 0;

    let order = Order {
        key,
        order_type: OrderType::Liquidation,
        decrease_position_swap_type: DecreasePositionSwapType::SwapPnlTokenToCollateralToken,
        account,
        receiver: account,
        callback_contract,
        ui_fee_receiver: 0.try_into().unwrap(),
        market,
        initial_collateral_token: position.collateral_token,
        swap_path,
        size_delta_usd,
        initial_collateral_delta_amount: 0,
        trigger_price,
        acceptable_price,
        execution_fee: 0,
        callback_gas_limit,
        min_output_amount: 0,
        updated_at_block,
        is_long: position.is_long,
        is_frozen: false,
    };
    let nonce_key = get_next_key(data_store);
    data_store.set_order(nonce_key, order);
    event_emitter
        .emit_order_updated(
            nonce_key, size_delta_usd, acceptable_price, trigger_price, min_output_amount
        );

    nonce_key
}
