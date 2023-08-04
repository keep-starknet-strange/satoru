use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use debug::PrintTrait;
use cheatcodes::PreparedContract;

use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
use gojo::market::market_factory::{IMarketFactorySafeDispatcher, IMarketFactorySafeDispatcherTrait};
use gojo::market::market::{Market, UniqueIdMarketTrait};
use gojo::role::role;

#[test]
fn test_market_factory() {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();

    // Deploy the role store contract.
    let role_store_address = deploy_role_store();

    // Create a role store dispatcher.
    let role_store = IRoleStoreSafeDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let data_store_address = deploy_data_store(role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let data_store = IDataStoreSafeDispatcher { contract_address: data_store_address };

    // Deploy the market factory.
    let market_factory_address = deploy_market_factory(data_store_address, role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let market_factory = IMarketFactorySafeDispatcher { contract_address: market_factory_address };

    // Grant the caller the CONTROLLER role.
    // We use the same account to deploy data_store and role_store, so we can grant the role
    // because the caller is the owner of role_store contract.
    role_store.grant_role(caller_address, role::CONTROLLER).unwrap();

    // Prank the caller address for calls to data_store contract.
    // We need this so that the caller has the CONTROLLER role.
    start_prank(data_store_address, caller_address);

    // ****** LOGIC STARTS HERE ******
    // Create a market.
    let market_token = contract_address_const::<'market_token'>();
    let index_token = contract_address_const::<'index_token'>();
    let long_token = contract_address_const::<'long_token'>();
    let short_token = contract_address_const::<'short_token'>();
    let market_type = 'market_type';

    let new_market = Market { market_token, index_token, long_token, short_token, };

    market_factory.create_market(index_token, long_token, short_token, market_type).unwrap();

    // Compute the key of the market.
    let market_id = new_market.unique_id(market_type);

    let maybe_market = data_store.get_market(market_id).unwrap();
    match maybe_market {
        Option::Some(market) => {
            market.index_token.print();
        },
        Option::None(()) => 'None'.print(),
    }

    // Stop pranking the caller address.
    stop_prank(data_store_address);
}

/// Utility function to deploy a market factory contract and return its address.
fn deploy_market_factory(
    data_store_address: ContractAddress, role_store_address: ContractAddress
) -> ContractAddress {
    let class_hash = declare('MarketFactory');
    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
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
