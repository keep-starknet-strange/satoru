//! Test file for `src/exchange/base_order_handler.cairo`.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use snforge_std::{
    declare, start_prank, stop_prank, start_mock_call, test_address, ContractClassTrait,
    ContractClass, start_roll
};
use traits::Default;
use poseidon::poseidon_hash_span;
use debug::PrintTrait;
// Local imports.
use satoru::role::role;
use satoru::tests_lib;

use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::keys;
use satoru::order::order::{Order, OrderType, SecondaryOrderType, DecreasePositionSwapType};
use satoru::order::order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait};
use satoru::order::base_order_utils::{CreateOrderParams};
use satoru::oracle::oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::oracle::oracle_utils::SetPricesParams;
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::utils::span32::{Span32, Array32Trait};
use satoru::market::{
    market::{Market, UniqueIdMarketImpl},
    market_factory::{IMarketFactoryDispatcher, IMarketFactoryDispatcherTrait}
};
use satoru::exchange::order_handler::{
    OrderHandler, IOrderHandlerDispatcher, IOrderHandlerDispatcherTrait
};
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// *********************************************************************************************
// *                                      TESTS                                                *
// *********************************************************************************************
#[test]
fn given_right_swap_order_params_when_execute_order_then_success() {
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
        order_handler,
        market_factory
    ) =
        setup_contracts();
    let contract_address = contract_address_const::<0>();
    // Test
    // Create market.
    let market = data_store.get_market(create_market(market_factory));

    // Transfer tokens in the order_vault in order for initial_collateral_delta_amount to be non zero.
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    start_prank(contract_address_const::<'USDC'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 5000000000000000000000000000000);
    // IERC20Dispatcher {contract_address: contract_address_const::<'USDC'>()}
    //     .transfer(order_vault.contract_address, 5000000000000000000000000000000);

    // Fill the pool.
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(market.market_token, 100000000000000000000000000000);
    IERC20Dispatcher { contract_address: contract_address_const::<'USDC'>() }
        .transfer(market.market_token, 300000000000000000000000000000000);

    // Set pool amount in data_store.
    let mut key = keys::pool_amount_key(market.market_token, contract_address_const::<'ETH'>());
    data_store.set_u128(key, 100000000000000000000000000000);
    key = keys::pool_amount_key(market.market_token, contract_address_const::<'USDC'>());
    data_store.set_u128(key, 300000000000000000000000000000000);

    // Set max pool amount.
    data_store
        .set_u128(
            keys::max_pool_amount_key(market.market_token, contract_address_const::<'USDC'>()),
            5000000000000000000000000000000000000
        );
    data_store
        .set_u128(
            keys::max_pool_amount_key(market.market_token, contract_address_const::<'ETH'>()),
            5000000000000000000000000000000000000
        );
    // Set params in data_store.
    data_store.set_address(keys::fee_token(), market.index_token);
    data_store.set_u128(keys::max_swap_path_length(), 5);

    start_prank(market.long_token, caller_address);
    let order_params = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: contract_address,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 1000,
        initial_collateral_delta_amount: 5000000000000000000000000000000, // 10^18
        trigger_price: 0,
        acceptable_price: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketSwap(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: false,
        referral_code: 0
    };
    // Create the swap order.
    start_roll(order_handler.contract_address, 1910);
    let key = order_handler.create_order(caller_address, order_params);

    // data_store.set_u128(keys::pool_amount_key(market.market_token, contract_address_const::<'USDC'>()), );
    // data_store.set_u128(keys::pool_amount_key(market.market_token, contract_address_const::<'ETH'>()), 1000000);
    // Execute the swap order.
    let signatures: Span<felt252> = array![0].span();
    let set_price_params = SetPricesParams {
        signer_info: 1,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1900, 1900],
        compacted_max_oracle_block_numbers: array![1910, 1910],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };
    start_prank(order_handler.contract_address, caller_address);
    start_roll(order_handler.contract_address, 1915);
    // TODO add real signatures check on Oracle Account
    //order_handler.execute_order(key, set_price_params);

    // Teardown
    tests_lib::teardown(data_store.contract_address);
}

// *********************************************************************************************
// *                                      SETUP                                                *
// *********************************************************************************************

/// Utility function to setup the test environment.
fn setup_contracts() -> (
    ContractAddress,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IEventEmitterDispatcher,
    IOrderVaultDispatcher,
    IOracleDispatcher,
    ISwapHandlerDispatcher,
    IReferralStorageDispatcher,
    IOrderHandlerDispatcher,
    IMarketFactoryDispatcher
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

    let order_handler_address = deploy_order_handler(
        data_store.contract_address,
        role_store.contract_address,
        event_emitter.contract_address,
        order_vault_address,
        oracle.contract_address,
        swap_handler_address,
        referral_storage_address
    );
    let order_handler = IOrderHandlerDispatcher { contract_address: order_handler_address };

    let market_token_class_hash = declare_market_token();
    let market_factory_address = deploy_market_factory(
        data_store.contract_address,
        role_store.contract_address,
        event_emitter.contract_address,
        market_token_class_hash
    );
    // Create a safe dispatcher to interact with the contract.
    let market_factory = IMarketFactoryDispatcher { contract_address: market_factory_address };

    role_store.grant_role(caller_address, role::MARKET_KEEPER);
    role_store.grant_role(caller_address, role::ORDER_KEEPER);
    role_store.grant_role(order_handler.contract_address, role::CONTROLLER);

    return (
        caller_address,
        role_store,
        data_store,
        event_emitter,
        order_vault,
        oracle,
        swap_handler,
        referral_storage,
        order_handler,
        market_factory
    );
}

fn create_market(market_factory: IMarketFactoryDispatcher) -> ContractAddress {
    // Create a market.
    let (index_token, short_token) = deploy_tokens();
    let market_type = 'market_type';

    // Index token is the same as long token here.
    market_factory.create_market(index_token, index_token, short_token, market_type)
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

/// Utility functions to deploy tokens for a market.
fn deploy_tokens() -> (ContractAddress, ContractAddress) {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let contract = declare('ERC20');

    let eth_address = contract_address_const::<'ETH'>();

    let constructor_calldata = array![
        'Ethereum', 'ETH', 50000000000000000000000000000000000000, 0, caller_address.into()
    ];
    contract.deploy_at(@constructor_calldata, eth_address).unwrap();

    let usdc_address = contract_address_const::<'USDC'>();
    let constructor_calldata = array![
        'usdc', 'USDC', 50000000000000000000000000000000000000, 0, caller_address.into()
    ];
    contract.deploy_at(@constructor_calldata, usdc_address).unwrap();
    (eth_address, usdc_address)
}

/// Utility function to deploy an `OrderHandler` contract and return its address.
fn deploy_order_handler(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    order_vault_address: ContractAddress,
    oracle_address: ContractAddress,
    swap_handler_address: ContractAddress,
    referral_storage_address: ContractAddress
) -> ContractAddress {
    let contract = declare('OrderHandler');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    constructor_calldata.append(event_emitter_address.into());
    constructor_calldata.append(order_vault_address.into());
    constructor_calldata.append(oracle_address.into());
    constructor_calldata.append(swap_handler_address.into());
    constructor_calldata.append(referral_storage_address.into());
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

/// Utility function to deploy a market factory contract and return its address.
fn deploy_market_factory(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    market_token_class_hash: ContractClass,
) -> ContractAddress {
    let contract = declare('MarketFactory');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'market_factory'>();
    start_prank(deployed_contract_address, caller_address);
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    constructor_calldata.append(event_emitter_address.into());
    constructor_calldata.append(market_token_class_hash.class_hash.into());
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

/// Utility function to declare a `MarketToken` contract.
fn declare_market_token() -> ContractClass {
    declare('MarketToken')
}
