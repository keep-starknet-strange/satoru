// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.

use result::ResultTrait;
use traits::{TryInto, Into};
use starknet::{ContractAddress, get_caller_address, contract_address_const, ClassHash,};
use debug::PrintTrait;
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};


// Local imports.
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use satoru::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};

use satoru::bank::strict_bank::{IStrictBankSafeDispatcher, IStrictBankSafeDispatcherTrait};
use satoru::bank::bank::{IBankSafeDispatcher, IStrictBankSafeDispatcherTrait};

#[test]
fn test_initialize() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************

    let (
        strict_bank_address,
        bank_address,
        role_store_address,
        data_store_address,
        role_store,
        data_store,
        bank,
        strict_bank
    ) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************
    strict_bank.initialize(data_store_address, role_store_address);

    // TODO: IMPLEMENT THIS
    

}

#[test]
fn test_transfer_out() {
     // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************

    let (
        strict_bank_address,
        bank_address,
        role_store_address,
        data_store_address,
        role_store,
        data_store,
        bank,
        strict_bank
    ) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************
    //bank transfer out is not implemented yet

}

#[test]
fn test_record_transfer_in() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************

    let (
        strict_bank_address,
        bank_address,
        role_store_address,
        data_store_address,
        role_store,
        data_store,
        bank,
        strict_bank
    ) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************
    
    // create token 
    let token1 = contract_address_const::<'token1'>();

    //check initial amount of token
    let amount_initial: u128 = strict_bank.token_balances.read(token1);
    assert(amount_initial == 0, 'amount not 0');

    // after calling the function 
    strict_bank.record_transfer_in(token1);
    let amount_updated: u128 = strict_bank.token_balances.read(token1);

    assert (amount_updated > amount_initial, 'no balance update'); 

}

#[test]
fn test_sync_token_balance() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************

    let (
        strict_bank_address,
        bank_address,
        role_store_address,
        data_store_address,
        role_store,
        data_store,
        bank,
        strict_bank
    ) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************
    
     // create token 
    let token1 = contract_address_const::<'token1'>();

    //check initial amount of token
    let amount_initial: u128 = strict_bank.token_balances.read(token1);
    
    strict_bank.sync_token_balance(token1);

    let amount_updated: u128 = strict_bank.token_balances.read(token1);

    assert(amount_initial != amount_updated, 'no change in balances');

}

/// Utility function to setup the test environment.
fn setup() -> (
    // Address of the `StrictBank` contract.
    ContractAddress,
    // Address of the `Bank` contract.
    ContractAddress,
    // Address of the `RoleStore` contract.
    ContractAddress,
    // Address of the `DataStore` contract.
    ContractAddress,
    // Interface to interact with the `RoleStore` contract.
    IRoleStoreSafeDispatcher,
    // Interface to interact with the `DataStore` contract.
    IDataStoreSafeDispatcher,
    // Interface to interact with the `Bank` contract.
    IBankDispatcher,
    // Interface to interact with the `StrictBank` contract.
    IStrictBankDispatcher,
){
    let (
        strict_bank_address,
        bank_address,
        role_store_address,
        data_store_address,
        role_store,
        data_store,
        bank,
        strict_bank
    ) = setup_contracts();

    

}

/// Setup required contracts.
fn setup_contracts() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress,
    // Address of the `Bank` contract.
    ContractAddress,
    // Interface to interact with the `Bank` contract.
    IBankDispatcher,
    // Address of the `StrictBank` contract.
    ContractAddress,
    // Interface to interact with the `StrictBank` contract.
    IStrictBankDispatcher,
    // Address of the `RoleStore` contract.
    ContractAddress,
    // Interface to interact with the `RoleStore` contract.
    IRoleStoreSafeDispatcher,
    // Address of the `DataStore` contract.
    ContractAddress,
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

    // Deploy the bank contract
    let bank_address = deploy_bank(
        data_store_address,
        role_store_address
    );

    // Deploy the strict bank contract
    let strict_bank_address = deploy_strict_bank(
        data_store_address,
        role_store_address
    );

    //Create a safe dispatcher to interact with the Bank contract.
    let bank = IBankDispatcher{contract_address: bank_address};

    //Create a safe dispatcher to interact with the StrictBank contract.
    let strict_bank = IStrictBankDispatcher{contract_address: strict_bank_address};

    (
        0x101.try_into().unwrap(),
        bank_address,
        bank,
        strict_bank_address,
        strict_bank,
        role_store_address,
        role_store,
        data_store_address,
        data_store,
    )
}



/// Utility function to deploy a bank contract and return its address.
fn deploy_bank(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
) -> ContractAddress {
    let contract = declare('Bank');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a strict bank contract and return its address.
fn deploy_strict_bank(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
) -> ContractAddress {
    let contract = declare('StrictBank');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
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
