//! Test file for `src/exchange/base_order_handler.cairo`.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use snforge_std::{declare, start_prank, stop_prank, start_mock_call, ContractClassTrait};
use traits::Default;
use poseidon::poseidon_hash_span;

// Local imports.
use satoru::role::role;
use satoru::tests_lib;

use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::bank::strict_bank::{IStrictBankDispatcher, IStrictBankDispatcherTrait};
use satoru::order::order::{Order, OrderType, SecondaryOrderType, DecreasePositionSwapType};
use satoru::order::order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait};
use satoru::oracle::oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::oracle::oracle_utils::SetPricesParams;
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::exchange::base_order_handler::{
    IBaseOrderHandlerDispatcher, IBaseOrderHandlerDispatcherTrait
};
use satoru::utils::starknet_utils;
use satoru::utils::span32::{Span32, Array32Trait};

// *********************************************************************************************
// *                                      TEST LOGIC                                           *
// *********************************************************************************************
#[test]
#[should_panic(expected: ('already_initialized',))]
fn given_already_intialized_when_initialize_then_fails() {
    let (_, role_store, data_store, base_order_handler) = setup();
    let dummy_address: ContractAddress = 0x202.try_into().unwrap();
    base_order_handler
        .initialize(
            dummy_address,
            dummy_address,
            dummy_address,
            dummy_address,
            dummy_address,
            dummy_address,
            dummy_address,
        );
    tests_lib::teardown(data_store.contract_address);
}

/// TODO: implement unit tests here when BaseOrderHandler is implemented
#[test]
#[should_panic(expected: ('NOT IMPLEMENTED YET',))]
fn given_normal_conditions_then_TODO_work() {
    assert(true == false, 'NOT IMPLEMENTED YET');
}

// *********************************************************************************************
// *                                       MOCKS                                               *
// *********************************************************************************************
fn mock_key() -> felt252 {
    poseidon_hash_span(array!['my', 'amazing', 'key'].span())
}

fn mock_set_prices_params() -> SetPricesParams {
    SetPricesParams {
        signer_info: 1,
        tokens: array![
            contract_address_const::<'ETH'>(),
            contract_address_const::<'USDC'>(),
            contract_address_const::<'DAI'>()
        ],
        compacted_min_oracle_block_numbers: array![0, 0, 0],
        compacted_max_oracle_block_numbers: array![6400, 6400, 6400],
        compacted_oracle_timestamps: array![0, 0, 0],
        compacted_decimals: array![18, 18, 18],
        compacted_min_prices: array![0, 0, 0],
        compacted_min_prices_indexes: array![1, 2, 3],
        compacted_max_prices: array![0, 0, 0],
        compacted_max_prices_indexes: array![1, 2, 3],
        signatures: array![1, 2, 3],
        price_feed_tokens: array![
            contract_address_const::<'ETH'>(),
            contract_address_const::<'USDC'>(),
            contract_address_const::<'DAI'>()
        ]
    }
}

fn mock_swap_path() -> Span32<ContractAddress> {
    array![contract_address_const::<'swap_path_0'>(), contract_address_const::<'swap_path_1'>()]
        .span32()
}

fn mock_order(key: felt252) -> Order {
    let swap_path: Span32<ContractAddress> = mock_swap_path();
    Order {
        key,
        order_type: OrderType::StopLossDecrease,
        decrease_position_swap_type: DecreasePositionSwapType::SwapPnlTokenToCollateralToken(()),
        account: contract_address_const::<'account'>(),
        receiver: contract_address_const::<'receiver'>(),
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
        market: contract_address_const::<'market'>(),
        initial_collateral_token: contract_address_const::<'initial_collateral_token'>(),
        swap_path,
        size_delta_usd: 1000,
        initial_collateral_delta_amount: 500,
        trigger_price: 2000,
        acceptable_price: 2500,
        execution_fee: 100,
        callback_gas_limit: 300000,
        min_output_amount: 100,
        updated_at_block: 0,
        is_long: true,
        is_frozen: false,
    }
}

// *********************************************************************************************
// *                                      SETUP                                                *
// *********************************************************************************************
/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
/// * `IBaseOrderHandlerDispatcher` - The base order handler dispatcher.
fn setup() -> (
    ContractAddress, IRoleStoreDispatcher, IDataStoreDispatcher, IBaseOrderHandlerDispatcher
) {
    let (caller_address, role_store, data_store, event_emitter, oracle) =
        tests_lib::setup_oracle_and_store();

    let order_vault_address = deploy_order_vault(
        data_store.contract_address, role_store.contract_address
    );
    let swap_handler_address = deploy_swap_handler(role_store.contract_address);
    let referral_storage_address = deploy_referral_storage(event_emitter.contract_address);

    let base_order_handler_address = deploy_base_order_handler(
        data_store.contract_address,
        role_store.contract_address,
        event_emitter.contract_address,
        order_vault_address,
        oracle.contract_address,
        swap_handler_address,
        referral_storage_address
    );
    let base_order_handler = IBaseOrderHandlerDispatcher {
        contract_address: base_order_handler_address
    };

    (caller_address, role_store, data_store, base_order_handler)
}

/// Utility function to deploy a `BaseOrderhandler` contract and return its address.
fn deploy_base_order_handler(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    order_vault_address: ContractAddress,
    oracle_address: ContractAddress,
    swap_handler_address: ContractAddress,
    referral_storage_address: ContractAddress
) -> ContractAddress {
    let contract = declare('BaseOrderHandler');
    let constructor_calldata = array![
        data_store_address.into(),
        role_store_address.into(),
        event_emitter_address.into(),
        order_vault_address.into(),
        oracle_address.into(),
        swap_handler_address.into(),
        referral_storage_address.into(),
    ];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy an `OrderVault` contract and return its address.
fn deploy_order_vault(
    data_store_address: ContractAddress, role_store_address: ContractAddress,
) -> ContractAddress {
    let contract = declare('OrderVault');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a `SwapHandler` contract and return its address.
fn deploy_swap_handler(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('SwapHandler');
    contract.deploy(@array![role_store_address.into()]).unwrap()
}

/// Utility function to deploy a `ReferralStorage` contract and return its address.
fn deploy_referral_storage(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('ReferralStorage');
    contract.deploy(@array![event_emitter_address.into()]).unwrap()
}
