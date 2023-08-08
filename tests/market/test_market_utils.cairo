// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
    ClassHash,
};
use cheatcodes::PreparedContract;

// Local imports.
use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
use gojo::market::market_factory::{IMarketFactorySafeDispatcher, IMarketFactorySafeDispatcherTrait};
use gojo::market::market::{Market, UniqueIdMarket, IntoMarketToken};
use gojo::market::market_token::{IMarketTokenSafeDispatcher, IMarketTokenSafeDispatcherTrait};
use gojo::market::market_utils;
use gojo::data::keys;
use gojo::role::role;

#[test]
fn given_normal_conditions_when_get_open_interest_then_works() {
    // Setup required contracts.
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
    ) =
        setup();

    // Grant the caller the `CONTROLLER` role.
    // We use the same account to deploy data_store and role_store, so we can grant the role
    // because the caller is the owner of role_store contract.
    role_store.grant_role(caller_address, role::CONTROLLER).unwrap();

    // Grant the call the `MARKET_KEEPER` role.
    // This role is required to create a market.
    role_store.grant_role(caller_address, role::MARKET_KEEPER).unwrap();

    // Prank the caller address for calls to data_store contract.
    // We need this so that the caller has the CONTROLLER role.
    start_prank(data_store_address, caller_address);

    // Prank the caller address for calls to market_factory contract.
    // We need this so that the caller has the MARKET_KEEPER role.
    start_prank(market_factory_address, caller_address);

    // ****** LOGIC STARTS HERE ******

    // Create a market.
    let index_token = contract_address_const::<'index_token'>();
    let long_token = contract_address_const::<'long_token'>();
    let short_token = contract_address_const::<'short_token'>();
    let market_type = 'market_type';

    let (market_token_deployed_address, market_id) = market_factory
        .create_market(index_token, long_token, short_token, market_type)
        .unwrap();

    // Get the market from the data store.
    // This must not panic, because the market was created in the previous step.
    // Hence the market must exist in the data store and it's safe to unwrap.
    let market = data_store.get_market(market_id).unwrap().unwrap();

    let collateral_token = contract_address_const::<'collateral_token'>();
    let is_long = true;
    let divisor = 3;

    let open_interest_data_store_key = keys::open_interest_key(
        market_token_deployed_address, collateral_token, is_long
    );
    data_store.set_u256(open_interest_data_store_key, 300);

    let open_interest = market_utils::get_open_interest(
        data_store, market_token_deployed_address, collateral_token, is_long, divisor
    );
    // Open interest is 300, so 300 / 3 = 100.
    assert(open_interest == 100, 'wrong open interest');

    let market_token = market.market_token();

    // Get the name of the market token.
    let market_token_name = market_token.name().unwrap();
    assert(market_token_name == 'Gojo Market', 'wrong market token name');

    // ****** LOGIC ENDS HERE ******

    // Stop pranking the caller address.
    stop_prank(data_store_address);
    stop_prank(market_factory_address);
}

#[test]
fn given_normal_conditions_when_get_pool_amount_then_works() {
    // Setup required contracts.
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
    ) =
        setup();

    // Grant the caller the `CONTROLLER` role.
    // We use the same account to deploy data_store and role_store, so we can grant the role
    // because the caller is the owner of role_store contract.
    role_store.grant_role(caller_address, role::CONTROLLER).unwrap();

    // Grant the call the `MARKET_KEEPER` role.
    // This role is required to create a market.
    role_store.grant_role(caller_address, role::MARKET_KEEPER).unwrap();

    // Prank the caller address for calls to data_store contract.
    // We need this so that the caller has the CONTROLLER role.
    start_prank(data_store_address, caller_address);

    // Prank the caller address for calls to market_factory contract.
    // We need this so that the caller has the MARKET_KEEPER role.
    start_prank(market_factory_address, caller_address);

    // ****** LOGIC STARTS HERE ******

    // *************************************************************************
    //                     Case 1: long_token != short_token.
    // *************************************************************************
    let market_token_address = contract_address_const::<'market_token'>();
    let token_address = contract_address_const::<'token_address'>();
    let market = Market {
        market_token: market_token_address,
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };
    let pool_amount_key = keys::pool_amount_key(market_token_address, token_address);
    data_store.set_u128(pool_amount_key, 1000);

    let pool_amount = market_utils::get_pool_amount(data_store, @market, token_address);
    // long_token != short_token, so the pool amount is 1000 because the divisor is 1.
    assert(pool_amount == 1000, 'wrong pool amount');

    // *************************************************************************
    //                     Case 1: long_token == short_token.
    // *************************************************************************
    let market_token_address_2 = contract_address_const::<'market_token_2'>();
    let token_address_2 = contract_address_const::<'token_address_2'>();
    let market_2 = Market {
        market_token: market_token_address_2,
        index_token: contract_address_const::<'index_token_2'>(),
        long_token: contract_address_const::<'same_token'>(),
        short_token: contract_address_const::<'same_token'>(),
    };
    let pool_amount_key_2 = keys::pool_amount_key(market_token_address_2, token_address_2);
    data_store.set_u128(pool_amount_key_2, 1000);
    let pool_amount_2 = market_utils::get_pool_amount(data_store, @market_2, token_address_2);
    // long_token == short_token, so the pool amount is 500 because the divisor is 2.
    assert(pool_amount_2 == 500, 'wrong pool amount');

    // ****** LOGIC ENDS HERE ******

    // Stop pranking the caller address.
    stop_prank(data_store_address);
    stop_prank(market_factory_address);
}

#[test]
fn given_normal_conditions_when_get_pool_divisor_then_works() {
    // long token == short token, should return 2.
    assert(
        market_utils::get_pool_divisor(
            contract_address_const::<1>(), contract_address_const::<1>()
        ) == 2,
        'wrong pool divisor'
    );
    // long token != short token, should return 1.
    assert(
        market_utils::get_pool_divisor(
            contract_address_const::<1>(), contract_address_const::<2>()
        ) == 1,
        'wrong pool divisor'
    );
}


/// Setup required contracts.
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
    ClassHash,
    // Interface to interact with the `MarketFactory` contract.
    IMarketFactorySafeDispatcher,
    // Interface to interact with the `RoleStore` contract.
    IRoleStoreSafeDispatcher,
    // Interface to interact with the `DataStore` contract.
    IDataStoreSafeDispatcher,
) {
    // Deploy the role store contract.
    let role_store_address = deploy_role_store();

    // Create a role store dispatcher.
    let role_store = IRoleStoreSafeDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let data_store_address = deploy_data_store(role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let data_store = IDataStoreSafeDispatcher { contract_address: data_store_address };

    // Declare the `MarketToken` contract.
    let market_token_class_hash = declare_market_token();

    // Deploy the market factory.
    let market_factory_address = deploy_market_factory(
        data_store_address, role_store_address, market_token_class_hash
    );
    // Create a safe dispatcher to interact with the contract.
    let market_factory = IMarketFactorySafeDispatcher { contract_address: market_factory_address };

    (
        contract_address_const::<'caller'>(),
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store
    )
}

/// Utility function to declare a `MarketToken` contract.
fn declare_market_token() -> ClassHash {
    declare('MarketToken')
}

/// Utility function to deploy a market factory contract and return its address.
fn deploy_market_factory(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    market_token_class_hash: ClassHash,
) -> ContractAddress {
    let class_hash = declare('MarketFactory');
    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    constructor_calldata.append(market_token_class_hash.into());
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @constructor_calldata
    };
    deploy(prepared).unwrap()
}


/// Utility function to deploy a data store contract and return its address.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let class_hash = declare('DataStore');
    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append(role_store_address.into());
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @constructor_calldata
    };
    deploy(prepared).unwrap()
}

/// Utility function to deploy a data store contract and return its address.
/// Copied from `tests/role/test_role_store.rs`.
/// TODO: Find a way to share this code.
fn deploy_role_store() -> ContractAddress {
    let class_hash = declare('RoleStore');
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @ArrayTrait::new()
    };
    deploy(prepared).unwrap()
}
