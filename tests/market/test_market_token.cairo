use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use cheatcodes::PreparedContract;

use gojo::market::market_token::{IMarketTokenSafeDispatcher, IMarketTokenSafeDispatcherTrait};
use gojo::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
use gojo::role::role;
use gojo::market::market_utils;

#[test]
fn given_normal_conditions_when_mint_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP TEST ENVIRONMENT                                       *
    // *********************************************************************************************
    let (caller_address, role_store, market_token) = setup_test_environment();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************
    // Check that the total supply is 0.
    assert(market_token.total_supply().unwrap() == 0, 'wrong supply');

    // Mint 100 tokens to the caller.
    market_token.mint(caller_address, 100).unwrap();

    // Check that the total supply is 100.
    assert(market_token.total_supply().unwrap() == 100, 'wrong supply');

    // Check that the caller has 100 tokens.
    assert(market_token.balance_of(caller_address).unwrap() == 100, 'wrong balance');

    // *********************************************************************************************
    // *                              TEARDOWN TEST ENVIRONMENT                                    *
    // *********************************************************************************************
    teardown_test_environment(market_token.contract_address);
}

/// Utility function to setup the test environment.
fn setup_test_environment() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress, // Interface to interact with the `RoleStore` contract.
    IRoleStoreSafeDispatcher, // Interface to interact with the `MarketToken` contract.
    IMarketTokenSafeDispatcher,
) {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();

    // Deploy the role store contract.
    let role_store_address = deploy_role_store();

    // Create a role store dispatcher.
    let role_store = IRoleStoreSafeDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let market_token_address = deploy_market_token(role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let market_token = IMarketTokenSafeDispatcher { contract_address: market_token_address };
    // Grant the caller the CONTROLLER role.
    // We use the same account to deploy data_store and role_store, so we can grant the role
    // because the caller is the owner of role_store contract.
    role_store.grant_role(caller_address, role::CONTROLLER).unwrap();

    // Prank the caller address for calls to data_store contract.
    // We need this so that the caller has the CONTROLLER role.
    start_prank(market_token_address, caller_address);

    (caller_address, role_store, market_token)
}

/// Utility function to teardown the test environment.
///
/// # Arguments
///
/// * `market_token_address` - The address of the `MarketToken` contract.
fn teardown_test_environment(market_token_address: ContractAddress) {
    stop_prank(market_token_address);
}

/// Utility function to deploy a market token and return its address.
fn deploy_market_token(role_store_address: ContractAddress) -> ContractAddress {
    let class_hash = declare('MarketToken');
    let mut constructor_calldata = array![];
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
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @array![] };
    deploy(prepared).unwrap()
}
