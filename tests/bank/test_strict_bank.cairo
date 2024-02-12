// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.

use result::ResultTrait;
use traits::{TryInto, Into};
use starknet::{ContractAddress, get_caller_address, contract_address_const, ClassHash,};
use integer::u256_from_felt252;
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait, ContractClass};

// Local imports.
use satoru::bank::bank::{IBankDispatcherTrait, IBankDispatcher};
use satoru::bank::strict_bank::{IStrictBankDispatcher, IStrictBankDispatcherTrait};
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;

/// Setup required contracts.
fn setup_contracts() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress,
    // This receiver address will be used with `start_prank` cheatcode to mock the receiver address.,
    ContractAddress,
    // Interface to interact with the `RoleStore` contract.
    IRoleStoreDispatcher,
    // Interface to interact with the `DataStore` contract.
    IDataStoreDispatcher,
    // Interface to interact with the `Bank` contract.
    IBankDispatcher,
    // Interface to interact with the `StrictBank` contract.
    IStrictBankDispatcher
) {
    // Deploy the role store contract.
    let role_store_address = deploy_role_store();

    // Create a role store dispatcher.
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let data_store_address = deploy_data_store(role_store_address);

    // Create a safe dispatcher to interact with the contract.
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    // Deploy the bank contract
    let bank_address = deploy_bank(data_store_address, role_store_address);

    //Create a safe dispatcher to interact with the Bank contract.
    let bank = IBankDispatcher { contract_address: bank_address };

    // Deploy the strict bank contract
    let strict_bank_address = deploy_strict_bank(data_store_address, role_store_address);

    //Create a safe dispatcher to interact with the StrictBank contract.
    let strict_bank = IStrictBankDispatcher { contract_address: strict_bank_address };

    // start prank and give controller role to caller_address
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let receiver_address: ContractAddress = 0x202.try_into().unwrap();
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    (caller_address, receiver_address, role_store, data_store, bank, strict_bank)
}

// /// Utility function to deploy a bank contract and return its address.
fn deploy_bank(
    data_store_address: ContractAddress, role_store_address: ContractAddress,
) -> ContractAddress {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let bank_address: ContractAddress = contract_address_const::<'bank'>();
    let contract = declare('Bank');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    start_prank(data_store_address, caller_address);
    contract.deploy_at(@constructor_calldata, bank_address).unwrap()
}

/// Utility function to deploy a strict bank contract and return its address.
fn deploy_strict_bank(
    data_store_address: ContractAddress, role_store_address: ContractAddress,
) -> ContractAddress {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let strict_bank_address: ContractAddress = contract_address_const::<'strict_bank'>();
    let contract = declare('StrictBank');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    start_prank(strict_bank_address, caller_address);
    contract.deploy_at(@constructor_calldata, strict_bank_address).unwrap()
}

/// Utility function to deploy a data store contract and return its address.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let data_store_address: ContractAddress = contract_address_const::<'data_store'>();
    let contract = declare('DataStore');
    let mut constructor_calldata = array![];
    constructor_calldata.append(role_store_address.into());
    start_prank(data_store_address, caller_address);
    contract.deploy_at(@constructor_calldata, data_store_address).unwrap()
}

/// Utility function to deploy a data store contract and return its address.
/// Copied from `tests/role/test_role_store.rs`.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let role_store_address: ContractAddress = contract_address_const::<'role_store'>();

    let constructor_arguments: @Array::<felt252> = @array![caller_address.into()];
    start_prank(role_store_address, caller_address);
    contract.deploy_at(constructor_arguments, role_store_address).unwrap()
}

// *********************************************************************************************
// *                              TEARDOWN                                                     *
// *********************************************************************************************
fn teardown(data_store: IDataStoreDispatcher, strict_bank: IStrictBankDispatcher) {
    stop_prank(data_store.contract_address);
    stop_prank(strict_bank.contract_address);
}


#[test]
#[should_panic(expected: ('already_initialized',))]
fn given_already_initialized_contract_when_initializing_then_fail() {
    let (caller_address, receiver_address, role_store, data_store, bank, strict_bank) =
        setup_contracts();
    // try initializing after previously initializing in setup
    strict_bank.initialize(data_store.contract_address, role_store.contract_address);
    teardown(data_store, strict_bank);
}

#[test]
fn given_normal_conditions_when_transfer_out_then_works() {
    let (caller_address, receiver_address, role_store, data_store, bank, strict_bank) =
        setup_contracts();

    // deploy erc20 token
    let erc20_contract = declare('ERC20');
    let constructor_calldata3 = array![
        'satoru', 'STU', 1000, 0, strict_bank.contract_address.into()
    ];
    let erc20_contract_address = erc20_contract.deploy(@constructor_calldata3).unwrap();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };

    // call the transfer_out function
    strict_bank.transfer_out(erc20_contract_address, receiver_address, 100_u128);
    // check that the contract balance reduces
    let contract_balance = erc20_dispatcher.balance_of(strict_bank.contract_address);
    assert(contract_balance == u256_from_felt252(900), 'transfer_out failed');
    // check that the balance of the receiver increases 
    let receiver_balance = erc20_dispatcher.balance_of(receiver_address);
    assert(receiver_balance == u256_from_felt252(100), 'transfer_out failed');
    // teardown
    teardown(data_store, strict_bank);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_caller_has_no_controller_role_when_transfer_out_then_fails() {
    let (caller_address, receiver_address, role_store, data_store, bank, strict_bank) =
        setup_contracts();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // deploy erc20 token
    let erc20_contract = declare('ERC20');
    let constructor_calldata3 = array![
        'satoru', 'STU', 1000, 0, strict_bank.contract_address.into()
    ];
    let erc20_contract_address = erc20_contract.deploy(@constructor_calldata3).unwrap();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };

    // stop prank as caller_address and start prank as receiver_address who has no controller role
    stop_prank(strict_bank.contract_address);
    start_prank(strict_bank.contract_address, receiver_address);
    // call the transfer_out function
    strict_bank.transfer_out(erc20_contract_address, caller_address, 100);
    // teardown
    teardown(data_store, strict_bank);
}

#[test]
#[should_panic(expected: ('self_transfer_not_supported',))]
fn given_receiver_is_contract_when_transfer_out_then_fails() {
    let (caller_address, receiver_address, role_store, data_store, bank, strict_bank) =
        setup_contracts();

    // deploy erc20 token. Mint to bank since we call transfer out in bank contract which restricts sending to self
    let erc20_contract = declare('ERC20');
    let constructor_calldata3 = array![
        'satoru', 'STU', 1000, 0, strict_bank.contract_address.into()
    ];
    let erc20_contract_address = erc20_contract.deploy(@constructor_calldata3).unwrap();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };

    strict_bank.transfer_out(erc20_contract_address, strict_bank.contract_address, 100_u128);

    //teardown
    teardown(data_store, strict_bank);
}

#[test]
fn given_normal_conditions_when_record_transfer_in_works() {
    let (caller_address, receiver_address, role_store, data_store, bank, strict_bank) =
        setup_contracts();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // deploy erc20 token
    let erc20_contract = declare('ERC20');
    let constructor_calldata3 = array!['satoru', 'STU', 1000, 0, caller_address.into()];
    let erc20_contract_address = erc20_contract.deploy(@constructor_calldata3).unwrap();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };

    start_prank(erc20_contract_address, caller_address);

    // send tokens into strict bank 
    erc20_dispatcher.transfer(strict_bank.contract_address, u256_from_felt252(50));

    let new_balance: u128 = erc20_dispatcher
        .balance_of(strict_bank.contract_address)
        .try_into()
        .unwrap();

    assert(
        strict_bank.record_transfer_in(erc20_contract_address) == new_balance,
        'unsuccessful transfer in'
    );

    // teardown
    teardown(data_store, strict_bank);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_caller_has_no_controller_role_when_record_transfer_in_then_fails() {
    let (caller_address, receiver_address, role_store, data_store, bank, strict_bank) =
        setup_contracts();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // deploy erc20 token
    let erc20_contract = declare('ERC20');
    let constructor_calldata3 = array![
        'satoru', 'STU', 1000, 0, strict_bank.contract_address.into()
    ];
    let erc20_contract_address = erc20_contract.deploy(@constructor_calldata3).unwrap();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };

    // stop prank as caller_address and start prank as receiver_address who has no controller role
    stop_prank(strict_bank.contract_address);
    start_prank(strict_bank.contract_address, receiver_address);
    // call the transfer_out function with receiver address 
    strict_bank.record_transfer_in(erc20_contract_address);
    // teardown
    teardown(data_store, strict_bank);
}

#[test]
fn given_normal_conditions_when_sync_token_balance_passes() {
    let (caller_address, receiver_address, role_store, data_store, bank, strict_bank) =
        setup_contracts();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // deploy erc20 token
    let erc20_contract = declare('ERC20');
    let constructor_calldata3 = array!['satoru', 'STU', 1000, 0, caller_address.into()];
    let erc20_contract_address = erc20_contract.deploy(@constructor_calldata3).unwrap();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };

    start_prank(erc20_contract_address, caller_address);

    // send tokens into strict bank 
    erc20_dispatcher.transfer(strict_bank.contract_address, u256_from_felt252(50));

    strict_bank.sync_token_balance(erc20_contract_address);

    // teardown
    teardown(data_store, strict_bank);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_caller_has_no_controller_role_when_sync_token_balance_then_fails() {
    let (caller_address, receiver_address, role_store, data_store, bank, strict_bank) =
        setup_contracts();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // deploy erc20 token
    let erc20_contract = declare('ERC20');
    let constructor_calldata3 = array!['satoru', 'STU', 1000, 0, caller_address.into()];
    let erc20_contract_address = erc20_contract.deploy(@constructor_calldata3).unwrap();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };

    start_prank(erc20_contract_address, caller_address);

    // send tokens into strict bank 
    erc20_dispatcher.transfer(strict_bank.contract_address, u256_from_felt252(50));

    // stop prank as caller_address and start prank as receiver_address who has no controller role
    stop_prank(strict_bank.contract_address);
    start_prank(strict_bank.contract_address, receiver_address);
    // call the sync_token_balance function with receiver address 
    strict_bank.sync_token_balance(erc20_contract_address);
    // teardown
    teardown(data_store, strict_bank);
}

