//                                  IMPORTS
// *************************************************************************
use starknet::{ContractAddress, contract_address_const};
use integer::u256_from_felt252;
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait, ContractClass};

use satoru::bank::bank::{IBankDispatcherTrait, IBankDispatcher};
use satoru::role::role_store::{IRoleStoreDispatcherTrait, IRoleStoreDispatcher};
use satoru::data::data_store::{IDataStoreDispatcherTrait, IDataStoreDispatcher};
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use satoru::role::role;

// *********************************************************************************************
// *                              SETUP                                                        *
// *********************************************************************************************
fn setup() -> (
    ContractAddress,
    ContractAddress,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IBankDispatcher,
    IERC20Dispatcher
) {
    // deploy role store
    let role_store_contract = declare('RoleStore');
    let role_store_contract_address = role_store_contract.deploy(@array![]).unwrap();
    let role_store_dispatcher = IRoleStoreDispatcher {
        contract_address: role_store_contract_address
    };

    // deploy data_store
    let data_store_contract = declare('DataStore');
    let constructor_calldata1 = array![role_store_contract_address.into()];
    let data_store_contract_address = data_store_contract.deploy(@constructor_calldata1).unwrap();
    let data_store_dispatcher = IDataStoreDispatcher {
        contract_address: data_store_contract_address
    };

    // deploy bank
    let bank_contract = declare('Bank');
    let constructor_calldata2 = array![
        data_store_contract_address.into(), role_store_contract_address.into()
    ];
    let bank_contract_address = bank_contract.deploy(@constructor_calldata2).unwrap();
    let bank_dispatcher = IBankDispatcher { contract_address: bank_contract_address };

    // deploy erc20 token
    let erc20_contract = declare('ERC20');
    let constructor_calldata3 = array!['satoru', 'STU', 1000, 0, bank_contract_address.into()];
    let erc20_contract_address = erc20_contract.deploy(@constructor_calldata3).unwrap();
    let erc20_dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };

    // start prank and give controller role to caller_address
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let receiver_address: ContractAddress = 0x202.try_into().unwrap();
    start_prank(role_store_contract_address, caller_address);
    role_store_dispatcher.grant_role(caller_address, role::CONTROLLER);
    start_prank(data_store_contract_address, caller_address);
    start_prank(bank_contract_address, caller_address);

    return (
        caller_address,
        receiver_address,
        role_store_dispatcher,
        data_store_dispatcher,
        bank_dispatcher,
        erc20_dispatcher
    );
}

// *********************************************************************************************
// *                              TEST LOGIC                                                   *
// *********************************************************************************************
#[test]
#[should_panic(expected: ('already_initialized',))]
fn test_initialize_fails_if_already_intialized() {
    let (caller_address, receiver_address, role_store, data_store, bank, erc20) = setup();
    // try initializing after previously initializing in setup
    bank.initialize(data_store.contract_address);
    teardown(data_store, bank);
}

#[test]
fn test_transfer_out() {
    let (caller_address, receiver_address, role_store, data_store, bank, erc20) = setup();
    // call the transfer_out function
    bank.transfer_out(erc20.contract_address, receiver_address, 100_u128);
    // check that the contract balance reduces
    let contract_balance = erc20.balance_of(bank.contract_address);
    assert(contract_balance == u256_from_felt252(900), 'transfer_out failed');
    // check that the balance of the receiver increases 
    let receiver_balance = erc20.balance_of(receiver_address);
    assert(receiver_balance == u256_from_felt252(100), 'transfer_out failed');
    // teardown
    teardown(data_store, bank);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn test_transfer_out_fails_if_caller_has_no_controller_role() {
    let (caller_address, receiver_address, role_store, data_store, bank, erc20) = setup();
    // stop prank as caller_address and start prank as receiver_address who has no controller role
    stop_prank(bank.contract_address);
    start_prank(bank.contract_address, receiver_address);
    // call the transfer_out function
    bank.transfer_out(erc20.contract_address, caller_address, 100_u128);
    // teardown
    teardown(data_store, bank);
}

#[test]
#[should_panic(expected: ('self_transfer_not_supported',))]
fn test_transfer_out_fails_if_receiver_is_contract() {
    let (caller_address, receiver_address, role_store, data_store, bank, erc20) = setup();
    // call the transfer_out function with receiver as bank contract address
    bank.transfer_out(erc20.contract_address, bank.contract_address, 100_u128);
    // teardown
    teardown(data_store, bank);
}

// *********************************************************************************************
// *                              TEARDOWN                                                     *
// *********************************************************************************************
fn teardown(data_store: IDataStoreDispatcher, bank: IBankDispatcher) {
    stop_prank(data_store.contract_address);
    stop_prank(bank.contract_address);
}
