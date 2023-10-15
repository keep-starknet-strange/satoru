use satoru::tests_lib::{teardown};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::role::{role, role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait}};
use satoru::swap::swap_utils::SwapParams;
use core::traits::Into;
use satoru::market::market::Market;
use satoru::position::{
    position::Position, decrease_position_swap_utils,
    position_utils::{
        UpdatePositionParams, DecreasePositionCollateralValues,
        DecreasePositionCollateralValuesOutput
    }
};
use satoru::order::{
    order::{SecondaryOrderType, OrderType, Order, DecreasePositionSwapType},
    order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait},
    base_order_utils::{ExecuteOrderParams, ExecuteOrderParamsContracts}, order_utils
};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::utils::span32::{Span32, Array32Trait};

use snforge_std::{declare, ContractClassTrait, start_prank};
use starknet::{get_caller_address, ContractAddress, contract_address_const};
use array::ArrayTrait;

//TODO Tests need to be added after implementation of decrease_position_swap_utils

/// Utility function to deploy a `SwapHandler` contract and return its dispatcher.
fn deploy_swap_handler_address(
    role_store_address: ContractAddress, data_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('SwapHandler');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'swap_handler'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'role_store'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![], deployed_contract_address).unwrap()
}

/// Utility function to deploy a `DataStore` contract and return its dispatcher.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `ISwapHandlerDispatcher` - The swap handler dispatcher.
fn setup() -> (ContractAddress, IRoleStoreDispatcher, ISwapHandlerDispatcher) {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();

    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    let swap_handler_address = deploy_swap_handler_address(role_store_address, data_store_address);
    let swap_handler = ISwapHandlerDispatcher { contract_address: swap_handler_address };

    start_prank(role_store_address, caller_address);
    start_prank(swap_handler_address, caller_address);

    // Grant the caller the `CONTROLLER` role.
    role_store.grant_role(caller_address, role::CONTROLLER);

    (caller_address, role_store, swap_handler)
}


#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_unauthorized_access_role_when_swap_to_pnl_token_then_fails() {
    let (caller_address, role_store, swap_handler) = setup();

    // Revoke the caller the `CONTROLLER` role.
    role_store.revoke_role(caller_address, role::CONTROLLER);

    let params = create_new_update_position_params(
        DecreasePositionSwapType::SwapCollateralTokenToPnlToken, swap_handler
    );

    let output = DecreasePositionCollateralValuesOutput {
        output_token: contract_address_const::<'output_token'>(),
        output_amount: 10,
        secondary_output_token: contract_address_const::<'secondary_output_token'>(),
        secondary_output_amount: 5
    };

    let values = create_new_decrease_position_collateral_values(output);

    decrease_position_swap_utils::swap_withdrawn_collateral_to_pnl_token(params, values);
}

// TODO: uncomment after implementation of i128 and all function required by swap()
// #[test]
// fn given_normal_conditions_when_swap_to_pnl_token_then_works() {
//     let (caller_address, role_store, swap_handler) = setup();

//     let params = create_new_update_position_params(
//         DecreasePositionSwapType::SwapCollateralTokenToPnlToken, swap_handler
//     );

//     let output = DecreasePositionCollateralValuesOutput {
//         output_token: contract_address_const::<'output_token'>(),
//         output_amount: 10,
//         secondary_output_token: 0.try_into().unwrap(),
//         secondary_output_amount: 5
//     };

//     let values = create_new_decrease_position_collateral_values(output);

//     let decrease_position_values =
//         decrease_position_swap_utils::swap_withdrawn_collateral_to_pnl_token(
//         params, values
//     );

//     assert(decrease_position_values.output.output_token == (0.try_into().unwrap()), 'Error');

//     teardown(role_store.contract_address);
// }

/// Utility function to create new UpdatePositionParams struct
fn create_new_update_position_params(
    decrease_position_swap_type: DecreasePositionSwapType, swap_handler: ISwapHandlerDispatcher
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
        order_type: OrderType::StopLossDecrease,
        decrease_position_swap_type,
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
        collateral_amount: 1000,
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

/// Utility function to create new DecreasePositionCollateralValues struct
fn create_new_decrease_position_collateral_values(
    output: DecreasePositionCollateralValuesOutput,
) -> DecreasePositionCollateralValues {
    let value = DecreasePositionCollateralValues {
        execution_price: 10,
        remaining_collateral_amount: 1000,
        base_pnl_usd: 10,
        uncapped_base_pnl_usd: 10,
        size_delta_in_tokens: 1000,
        price_impact_usd: 1000,
        price_impact_diff_usd: 500,
        output
    };

    value
}
