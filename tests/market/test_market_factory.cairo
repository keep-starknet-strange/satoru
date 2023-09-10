// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.

use result::ResultTrait;
use traits::{TryInto, Into};
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
    ClassHash,
};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait, ContractClass};


// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::market::market_factory::{IMarketFactoryDispatcher, IMarketFactoryDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::market::market::{Market, UniqueIdMarket};
use satoru::market::market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait};
use satoru::role::role;

#[test]
fn given_normal_conditions_when_create_market_then_market_is_created() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a market.
    let index_token = contract_address_const::<'index_token'>();
    let long_token = contract_address_const::<'long_token'>();
    let short_token = contract_address_const::<'short_token'>();
    let market_type = 'market_type';

    let (market_token_deployed_address, market_id) = market_factory
        .create_market(index_token, long_token, short_token, market_type);

    // Get the market from the data store.
    // This must not panic, because the market was created in the previous step.
    // Hence the market must exist in the data store and it's safe to unwrap.
    let market = data_store.get_market(market_id).unwrap();

    // Check the market is as expected.
    assert(market.index_token == index_token, 'bad_market');
    assert(market.long_token == long_token, 'bad_market');
    assert(market.short_token == short_token, 'bad_market');

    // Check the market token was deployed.
    let market_token = IMarketTokenDispatcher { contract_address: market_token_deployed_address };
    // Query the name of the market token.
    let market_token_name = market_token.name();
    assert(market_token_name == 'Satoru Market', 'bad_market_token_name');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn given_bad_params_when_create_market_then_fail() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a market.
    let market_token = contract_address_const::<'market_token'>();
    // We use an invalid address as the index token.
    let index_token = contract_address_const::<0>();
    let long_token = contract_address_const::<'long_token'>();
    let short_token = contract_address_const::<'short_token'>();
    let market_type = 'market_type';

    let new_market = Market { market_token, index_token, long_token, short_token, };

    // Try to create a market.
    // This must fail because the index token is invalid.
    // For now it seems we cannot catch the panic handling the result.
    // TODO: Find a way to catch the panic.
    // let result = market_factory.create_market(index_token, long_token, short_token, market_type);
    // match result {
    //     // If the result is ok, then the test failed.
    //     Result::Ok(_) => assert(false, 'bad_result'),
    //     // If the result is err, then the test passed.
    //     Result::Err(_) => {}
    // }

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

/// Utility function to setup the test environment.
fn setup() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress,
    // Address of the `MarketFactory` contract.
    ContractAddress,
    // Address of the `RoleStore` contract.
    ContractAddress,
    // Address of the `DataStore` contract.
    ContractAddress,
    // The `MarketToken` class hash for the factory.
    ContractClass,
    // Interface to interact with the `MarketFactory` contract.
    IMarketFactoryDispatcher,
    // Interface to interact with the `RoleStore` contract.
    IRoleStoreDispatcher,
    // Interface to interact with the `DataStore` contract.
    IDataStoreDispatcher,
    // Interface to interact with the `EventEmitter` contract.
    IEventEmitterDispatcher,
) {
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        event_emitter,
    ) =
        setup_contracts();
    grant_roles_and_prank(caller_address, role_store, data_store, market_factory);
    (
        caller_address,
        market_factory.contract_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        event_emitter,
    )
}

// Utility function to grant roles and prank the caller address.
/// Grants roles and pranks the caller address.
///
/// # Arguments
///
/// * `caller_address` - The address of the caller.
/// * `role_store` - The interface to interact with the `RoleStore` contract.
/// * `data_store` - The interface to interact with the `DataStore` contract.
/// * `market_factory` - The interface to interact with the `MarketFactory` contract.
fn grant_roles_and_prank(
    caller_address: ContractAddress,
    role_store: IRoleStoreDispatcher,
    data_store: IDataStoreDispatcher,
    market_factory: IMarketFactoryDispatcher,
) {
    start_prank(role_store.contract_address, caller_address);

    // Grant the caller the `CONTROLLER` role.
    role_store.grant_role(caller_address, role::CONTROLLER);

    // Grant the call the `MARKET_KEEPER` role.
    // This role is required to create a market.
    role_store.grant_role(caller_address, role::MARKET_KEEPER);

    // Prank the caller address for calls to `DataStore` contract.
    // We need this so that the caller has the CONTROLLER role.
    start_prank(data_store.contract_address, caller_address);

    // Start pranking the `MarketFactory` contract. This is necessary to mock the behavior of the contract
    // for testing purposes.
    start_prank(market_factory.contract_address, caller_address);
}

/// Utility function to teardown the test environment.
fn teardown(data_store: IDataStoreDispatcher, market_factory: IMarketFactoryDispatcher) {
    stop_prank(data_store.contract_address);
    stop_prank(market_factory.contract_address);
}

/// Setup required contracts.
fn setup_contracts() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress,
    // Address of the `MarketFactory` contract.
    ContractAddress,
    // Address of the `RoleStore` contract.
    ContractAddress,
    // Address of the `DataStore` contract.
    ContractAddress,
    // The `MarketToken` class hash for the factory.
    ContractClass,
    // Interface to interact with the `MarketFactory` contract.
    IMarketFactoryDispatcher,
    // Interface to interact with the `RoleStore` contract.
    IRoleStoreDispatcher,
    // Interface to interact with the `DataStore` contract.
    IDataStoreDispatcher,
    // Interface to interact with the `EventEmitter` contract.
    IEventEmitterDispatcher,
) {
    // Deploy the role store contract.
    let role_store_address = deploy_role_store();

    // Create a role store dispatcher.
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let data_store_address = deploy_data_store(role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    // Declare the `MarketToken` contract.
    let market_token_class_hash = declare_market_token();

    // Deploy the event emitter contract.
    let event_emitter_address = deploy_event_emitter();
    // Create a safe dispatcher to interact with the contract.
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    // Deploy the market factory.
    let market_factory_address = deploy_market_factory(
        data_store_address,
        role_store_address,
        event_emitter_address,
        market_token_class_hash.clone()
    );
    // Create a safe dispatcher to interact with the contract.
    let market_factory = IMarketFactoryDispatcher { contract_address: market_factory_address };

    (
        0x101.try_into().unwrap(),
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        event_emitter,
    )
}

/// Utility function to declare a `MarketToken` contract.
fn declare_market_token() -> ContractClass {
    declare('MarketToken')
}

/// Utility function to deploy a market factory contract and return its address.
fn deploy_market_factory(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    market_token_class_hash: ContractClass,
) -> ContractAddress {
    let contract = declare('MarketFactory');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    constructor_calldata.append(event_emitter_address.into());
    constructor_calldata.append(market_token_class_hash.class_hash.into());
    contract.deploy(@constructor_calldata).unwrap()
}


/// Utility function to deploy a data store contract and return its address.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let mut constructor_calldata = array![];
    constructor_calldata.append(role_store_address.into());
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a data store contract and return its address.
/// Copied from `tests/role/test_role_store.rs`.
/// TODO: Find a way to share this code.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let constructor_arguments: @Array::<felt252> = @ArrayTrait::new();
    contract.deploy(constructor_arguments).unwrap()
}

/// Utility function to deploy a `EventEmitter` contract and return its address.
fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    let constructor_arguments: @Array::<felt252> = @ArrayTrait::new();
    contract.deploy(constructor_arguments).unwrap()
}
