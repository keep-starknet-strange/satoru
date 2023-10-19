//! Test file for `src/exchange/base_order_handler.cairo`.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use snforge_std::{
    declare, start_prank, stop_prank, start_mock_call, test_address, ContractClassTrait
};
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
use satoru::order::base_order_utils::ExecuteOrderParamsContracts;
use satoru::oracle::oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::oracle::oracle_utils::SetPricesParams;
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::utils::span32::{Span32, Array32};
use satoru::market::market::{Market, UniqueIdMarketImpl};

use satoru::exchange::base_order_handler::BaseOrderHandler;
use satoru::exchange::base_order_handler::{
    IBaseOrderHandlerDispatcher, IBaseOrderHandlerDispatcherTrait
};

// *********************************************************************************************
// *                                      TEST LOGIC                                           *
// *********************************************************************************************
#[test]
#[should_panic(expected: ('already_initialized',))]
fn given_already_intialized_state_when_initialize_then_fails() {
    let (
        caller_address,
        role_store,
        data_store,
        event_emitter,
        order_vault,
        swap_handler,
        referral_storage,
        oracle,
        mut base_order_handler_state
    ) =
        setup_contracts();
    BaseOrderHandler::BaseOrderHandlerImpl::initialize(
        ref base_order_handler_state,
        data_store.contract_address,
        role_store.contract_address,
        event_emitter.contract_address,
        order_vault.contract_address,
        oracle.contract_address,
        swap_handler.contract_address,
        referral_storage.contract_address,
    );
}

#[test]
fn given_normal_conditions_when_get_execute_order_params_then_works() {
    // Setup
    let (
        caller_address,
        role_store,
        data_store,
        event_emitter,
        order_vault,
        oracle,
        swap_handler,
        referral_storage,
        mut base_order_handler_state
    ) =
        setup_contracts();

    let key: felt252 = mock_key();
    let set_prices_params = mock_set_prices_params();
    let starting_gas = 10000;
    let secondary_order_type = SecondaryOrderType::Adl(());

    let option_mock_order: Option<Order> = Option::Some(Default::<Order>::default());
    start_mock_call(data_store.contract_address, 'get_order', option_mock_order);

    // test call
    let execute_order_params = BaseOrderHandler::InternalImpl::get_execute_order_params(
        ref base_order_handler_state,
        key,
        set_prices_params,
        caller_address,
        starting_gas,
        secondary_order_type
    );

    // assertions
    _assert_contracts_are_equals(
        contracts: execute_order_params.contracts,
        data_store_address: data_store.contract_address,
        event_emitter_address: event_emitter.contract_address,
        order_vault_address: order_vault.contract_address,
        oracle_address: oracle.contract_address,
        swap_handler_address: swap_handler.contract_address,
        referral_storage_address: referral_storage.contract_address
    );
    assert(execute_order_params.key == key, 'wrong key');
    assert(execute_order_params.order == Default::default(), 'wrong order');
    assert(
        execute_order_params.min_oracle_block_numbers == ArrayTrait::new(),
        'wrong min_oracle_block_numbers'
    );
    assert(
        execute_order_params.max_oracle_block_numbers == ArrayTrait::new(),
        'wrong max_oracle_block_numbers'
    );
    assert(execute_order_params.market == Default::default(), 'wrong execute_order_params');
    assert(execute_order_params.keeper == caller_address, 'wrong keeper');
    assert(execute_order_params.starting_gas == starting_gas, 'wrong starting_gas');
    assert(
        execute_order_params.secondary_order_type == secondary_order_type,
        'wrong secondary_order_type'
    );

    // teardown
    tests_lib::teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('order_not_found',))]
fn given_non_found_order_when_get_execute_order_params_then_fails() {
    let (
        caller_address,
        role_store,
        data_store,
        event_emitter,
        order_vault,
        oracle,
        swap_handler,
        referral_storage,
        mut base_order_handler_state
    ) =
        setup_contracts();

    let key: felt252 = mock_key();
    let set_prices_params = mock_set_prices_params();
    let starting_gas = 10000;
    let secondary_order_type = SecondaryOrderType::Adl(());

    let option_mock_order: Option<Order> = Option::<Order>::None(());
    let execute_order_params = BaseOrderHandler::InternalImpl::get_execute_order_params(
        ref base_order_handler_state,
        key,
        set_prices_params,
        caller_address,
        starting_gas,
        secondary_order_type
    );

    tests_lib::teardown(data_store.contract_address);
}

// TODO: more tests when all the functions are implemented (order utils ; oracle ...)

// *********************************************************************************************
// *                                ASSERTION UTILITIES                                        *
// *********************************************************************************************

fn _assert_contracts_are_equals(
    contracts: ExecuteOrderParamsContracts,
    data_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    order_vault_address: ContractAddress,
    oracle_address: ContractAddress,
    swap_handler_address: ContractAddress,
    referral_storage_address: ContractAddress
) {
    assert(contracts.data_store.contract_address == data_store_address, 'wrong data_store');
    assert(
        contracts.event_emitter.contract_address == event_emitter_address, 'wrong event_emitter'
    );
    assert(contracts.order_vault.contract_address == order_vault_address, 'wrong order_vault');
    assert(contracts.oracle.contract_address == oracle_address, 'wrong oracle');
    assert(contracts.swap_handler.contract_address == swap_handler_address, 'wrong swap_handler');
    assert(
        contracts.referral_storage.contract_address == referral_storage_address,
        'wrong referral_storage'
    );
}

// *********************************************************************************************
// *                                       MOCKS                                               *
// *********************************************************************************************
fn mock_market() -> Market {
    let address_zero = contract_address_const::<0>();
    let key = contract_address_const::<123456789>();

    Market {
        market_token: key,
        index_token: address_zero,
        long_token: address_zero,
        short_token: address_zero,
    }
}

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
    array![contract_address_const::<'ETH'>(), contract_address_const::<'DAI'>()].span32()
}

fn mock_order(
    key: felt252, market_address: ContractAddress, swap_path: Span32<ContractAddress>
) -> Order {
    Order {
        key,
        order_type: OrderType::StopLossDecrease,
        decrease_position_swap_type: DecreasePositionSwapType::SwapPnlTokenToCollateralToken(()),
        account: contract_address_const::<'account'>(),
        receiver: contract_address_const::<'receiver'>(),
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
        market: market_address,
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
/// * `IEventEmitterDispatcher` - The event emitter dispatcher.
/// * `IOrderVaultDispatcher` - The order vault dispatcher.
/// * `IOracleDispatcher` - The base order handler dispatcher.
/// * `BaseOrderHandler::ContractState` - The base order handler state.
fn setup_contracts() -> (
    ContractAddress,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IEventEmitterDispatcher,
    IOrderVaultDispatcher,
    IOracleDispatcher,
    ISwapHandlerDispatcher,
    IReferralStorageDispatcher,
    BaseOrderHandler::ContractState
) {
    let (caller_address, role_store, data_store, event_emitter, oracle) =
        tests_lib::setup_oracle_and_store();

    let order_vault_address = deploy_order_vault(
        data_store.contract_address, role_store.contract_address
    );
    let order_vault = IOrderVaultDispatcher { contract_address: order_vault_address };

    let swap_handler_address = deploy_swap_handler(role_store.contract_address);
    let swap_handler = ISwapHandlerDispatcher { contract_address: swap_handler_address };

    let referral_storage_address = deploy_referral_storage(event_emitter.contract_address);
    let referral_storage = IReferralStorageDispatcher {
        contract_address: referral_storage_address
    };

    let base_order_handler_state = setup_base_order_handler_state(
        data_store.contract_address,
        role_store.contract_address,
        event_emitter.contract_address,
        order_vault_address,
        oracle.contract_address,
        swap_handler_address,
        referral_storage_address
    );

    role_store.grant_role(caller_address, role::MARKET_KEEPER);

    return (
        caller_address,
        role_store,
        data_store,
        event_emitter,
        order_vault,
        oracle,
        swap_handler,
        referral_storage,
        base_order_handler_state
    );
}

/// Utility function to deploy a `BaseOrderhandler` contract and return its address.
fn setup_base_order_handler_state(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    order_vault_address: ContractAddress,
    oracle_address: ContractAddress,
    swap_handler_address: ContractAddress,
    referral_storage_address: ContractAddress
) -> BaseOrderHandler::ContractState {
    let mut base_order_handler_state = BaseOrderHandler::contract_state_for_testing();

    BaseOrderHandler::BaseOrderHandlerImpl::initialize(
        ref base_order_handler_state,
        data_store_address,
        role_store_address,
        event_emitter_address,
        order_vault_address,
        oracle_address,
        swap_handler_address,
        referral_storage_address,
    );
    return base_order_handler_state;
}

/// Utility function to deploy an `OrderVault` contract and return its address.
fn deploy_order_vault(
    data_store_address: ContractAddress, role_store_address: ContractAddress,
) -> ContractAddress {
    let contract = declare('OrderVault');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    tests_lib::deploy_mock_contract(contract, @constructor_calldata)
}

/// Utility function to deploy a `SwapHandler` contract and return its address.
fn deploy_swap_handler(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('SwapHandler');
    let constructor_calldata = array![role_store_address.into()];
    tests_lib::deploy_mock_contract(contract, @constructor_calldata)
}

/// Utility function to deploy a `ReferralStorage` contract and return its address.
fn deploy_referral_storage(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('ReferralStorage');
    let constructor_calldata = array![event_emitter_address.into()];
    tests_lib::deploy_mock_contract(contract, @constructor_calldata)
}
