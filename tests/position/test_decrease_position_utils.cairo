use starknet::{get_caller_address, ContractAddress, contract_address_const};
use core::array::ArrayTrait;
use core::traits::Into;

use snforge_std::{declare, ContractClassTrait, start_prank};
use satoru::tests_lib::{teardown, deploy_role_store, deploy_swap_handler_address};
use satoru::utils::span32::{Span32, Array32Trait};

use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::role::{role, role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait}};
use satoru::market::market::Market;
use satoru::order::{
    order::{Order, SecondaryOrderType, OrderType, DecreasePositionSwapType},
    order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait},
    base_order_utils::ExecuteOrderParamsContracts
};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};

use satoru::position::{
    position::Position, decrease_position_utils, position_utils::UpdatePositionParams
};


#[test]
fn given_normal_conditions_when_partially_decrease_position() {
    let (caller_address, swap_handler) = setup();

    let mut params = create_new_update_position_params(OrderType::LimitSwap, swap_handler);
    params.order.size_delta_usd = 800;
    // TODO: implement update params to not be 
    //decrease_position_utils::decrease_position(ref params);
    assert(true, 'Not implemented yet');
}

#[test]
fn given_normal_conditions_when_totally_decrease_position() {
    let (caller_address, swap_handler) = setup();

    let mut params = create_new_update_position_params(OrderType::LimitSwap, swap_handler);

    // TODO: implement update params to not be 
    //decrease_position_utils::decrease_position(ref params);
    assert(true, 'Not implemented yet');
}
#[test]
#[should_panic]
fn given_invalid_decrease_order_size_when_decrease_position_then_fails() {
    let (caller_address, swap_handler) = setup();

    let mut params = create_new_update_position_params(OrderType::LimitSwap, swap_handler);
    params.order.size_delta_usd = 1500;

    // TODO: implement update params to not be 
    //decrease_position_utils::decrease_position(ref params);
    panic(array!['Not implemented yet']);
}

#[test]
#[should_panic]
fn given_unable_to_withdraw_collateral_when_decrease_position_then_fails() {
    let (caller_address, swap_handler) = setup();

    let mut params = create_new_update_position_params(OrderType::LimitDecrease, swap_handler);
    params.order.size_delta_usd = 1000;
    params.position.collateral_amount = 1000;
    // TODO: implement update params to not be 
    //decrease_position_utils::decrease_position(ref params);
    panic(array!['Not implemented yet']);
}

#[test]
#[should_panic]
fn given_position_should_be_liquidated_when_decrease_position_then_fails() {
    let (caller_address, swap_handler) = setup();

    let mut params = create_new_update_position_params(OrderType::Liquidation, swap_handler);
    params.order.size_delta_usd = 800;

    // TODO: implement update params to not be 
    //decrease_position_utils::decrease_position(ref params);
    panic(array!['Not implemented yet']);
}


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `ISwapHandlerDispatcher` - The swap handler dispatcher.
fn setup() -> (ContractAddress, ISwapHandlerDispatcher) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();

    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    let swap_handler_address = deploy_swap_handler_address(role_store_address);
    let swap_handler = ISwapHandlerDispatcher { contract_address: swap_handler_address };

    start_prank(role_store_address, caller_address);
    start_prank(swap_handler_address, caller_address);

    (caller_address, swap_handler)
}


/// Utility function to create new UpdatePositionParams struct
fn create_new_update_position_params(
    order_type: OrderType, swap_handler: ISwapHandlerDispatcher
) -> UpdatePositionParams {
    let data_store = contract_address_const::<'data_store'>();
    let event_emitter = contract_address_const::<'event_emitter'>();
    let order_vault = contract_address_const::<'order_vault'>();
    let oracle = contract_address_const::<'oracle'>();
    let referral_storage = contract_address_const::<'referral_storage'>();

    let contracts = ExecuteOrderParamsContracts {
        data_store: IDataStoreDispatcher { contract_address: data_store },
        event_emitter: IEventEmitterDispatcher { contract_address: event_emitter },
        order_vault: IOrderVaultDispatcher { contract_address: order_vault },
        oracle: IOracleDispatcher { contract_address: oracle },
        swap_handler,
        referral_storage: IReferralStorageDispatcher { contract_address: referral_storage }
    };

    let market = Market {
        market_token: contract_address_const::<'market_token'>(),
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>()
    };

    let order = Order {
        key: 123456789,
        order_type,
        decrease_position_swap_type: DecreasePositionSwapType::SwapCollateralTokenToPnlToken,
        account: contract_address_const::<'account'>(),
        receiver: contract_address_const::<'receiver'>(),
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
        market: contract_address_const::<'market'>(),
        initial_collateral_token: contract_address_const::<'token1'>(),
        swap_path: array![
            contract_address_const::<'swap_path_0'>(), contract_address_const::<'swap_path_1'>()
        ]
            .span32(),
        size_delta_usd: 1000,
        initial_collateral_delta_amount: 1000,
        trigger_price: 11111,
        acceptable_price: 11111,
        execution_fee: 10,
        callback_gas_limit: 300000,
        min_output_amount: 10,
        updated_at_block: 1,
        is_long: false,
        is_frozen: false
    };

    let position = Position {
        key: 123456789,
        account: contract_address_const::<'account'>(),
        market: contract_address_const::<'market'>(),
        collateral_token: contract_address_const::<'collateral_token'>(),
        size_in_usd: 1000,
        size_in_tokens: 1000,
        collateral_amount: 10000,
        borrowing_factor: 10,
        funding_fee_amount_per_size: 10,
        long_token_claimable_funding_amount_per_size: 10,
        short_token_claimable_funding_amount_per_size: 10,
        increased_at_block: 1,
        decreased_at_block: 3,
        is_long: false,
    };

    let params = UpdatePositionParams {
        contracts,
        market,
        order,
        order_key: 123456789,
        position,
        position_key: 123456789,
        secondary_order_type: SecondaryOrderType::None
    };

    params
}
