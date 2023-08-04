use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use cheatcodes::PreparedContract;

use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::data::keys;
use gojo::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
use gojo::role::role;
use gojo::market::market_utils;
use debug::PrintTrait;

#[test]
fn test_market_utils() {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();

    // Deploy the role store contract.
    let role_store_address = deploy_role_store();

    // Create a role store dispatcher.
    let role_store = IRoleStoreSafeDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let data_store_address = deploy_data_store(role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let data_store = IDataStoreSafeDispatcher { contract_address: data_store_address };
    // Grant the caller the CONTROLLER role.
    // We use the same account to deploy data_store and role_store, so we can grant the role
    // because the caller is the owner of role_store contract.
    role_store.grant_role(caller_address, role::CONTROLLER).unwrap();

    // Prank the caller address for calls to data_store contract.
    // We need this so that the caller has the CONTROLLER role.
    start_prank(data_store_address, caller_address);

    let market = contract_address_const::<'market'>();
    let collateral_token = contract_address_const::<'collateral_token'>();
    let is_long = true;
    let divisor = 3;

    let open_interest_data_store_key = keys::open_interest_key(market, collateral_token, is_long);
    data_store.set_u256(open_interest_data_store_key, 300);

    let open_interest = market_utils::get_open_interest(
        data_store, market, collateral_token, is_long, divisor
    );
    // Open interest is 300, so 300 / 3 = 100.
    assert(open_interest == 100, 'wrong open interest');
    // Stop pranking the caller address.
    stop_prank(data_store_address);
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
