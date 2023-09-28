use result::ResultTrait;
use traits::{TryInto, Into};
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};


use satoru::market::market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::market::market_utils;

#[test]
fn given_normal_conditions_when_mint_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, role_store, market_token) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************
    // Check that the total supply is 0.
    assert(market_token.total_supply() == 0, 'wrong supply');

    // Mint 100 tokens to the caller.
    market_token.mint(caller_address, 100);

    // Check that the total supply is 100.
    assert(market_token.total_supply() == 100, 'wrong supply');

    // Check that the caller has 100 tokens.
    assert(market_token.balance_of(caller_address) == 100, 'wrong balance');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(market_token.contract_address);
}

/// Utility function to setup the test environment.
fn setup() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress, // Interface to interact with the `RoleStore` contract.
    IRoleStoreDispatcher, // Interface to interact with the `MarketToken` contract.
    IMarketTokenDispatcher,
) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();

    // Deploy the role store contract.
    let role_store_address = deploy_role_store();

    // Create a role store dispatcher.
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let market_token_address = deploy_market_token(role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let market_token = IMarketTokenDispatcher { contract_address: market_token_address };

    start_prank(role_store.contract_address, caller_address);

    // Grant the caller the CONTROLLER role.
    // We use the same account to deploy data_store and role_store, so we can grant the role
    // because the caller is the owner of role_store contract.
    role_store.grant_role(caller_address, role::CONTROLLER);

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
fn teardown(market_token_address: ContractAddress) {
    stop_prank(market_token_address);
}

/// Utility function to deploy a market token and return its address.
fn deploy_market_token(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('MarketToken');
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
