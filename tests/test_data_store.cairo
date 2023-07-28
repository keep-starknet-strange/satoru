use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;
use cheatcodes::PreparedContract;

use gojo::data::data_store::IDataStoreSafeDispatcher;
use gojo::data::data_store::IDataStoreSafeDispatcherTrait;

// Utility function to deploy a data store contract and return its address.
fn deploy_data_store() -> ContractAddress {
    let class_hash = declare('DataStore').unwrap();
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @ArrayTrait::new()
    };
    let contract_address = deploy(prepared).unwrap();

    let contract_address: ContractAddress = contract_address.try_into().unwrap();

    contract_address
}

#[test]
fn test_get_and_set_felt252() {
    // Deploy the contract.
    let contract_address = deploy_data_store();
    // Create a safe dispatcher to interact with the contract.
    let safe_dispatcher = IDataStoreSafeDispatcher { contract_address };

    // Set key 1 to value 42.
    safe_dispatcher.set_felt252(1, 42).unwrap();
    let value = safe_dispatcher.get_felt252(1).unwrap();
    // Check that the value read is 42.
    assert(value == 42, 'Invalid value');
}
