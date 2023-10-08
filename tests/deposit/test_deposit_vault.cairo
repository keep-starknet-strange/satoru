//! Test file for `src/deposit/deposit_vault.cairo`.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use integer::{u128_from_felt252, u256_from_felt252};
use result::ResultTrait;
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
    ClassHash,
};
use snforge_std::{declare, start_prank, stop_prank, start_mock_call, ContractClassTrait};
use traits::{TryInto, Into};

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::deposit::deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::tests_lib;
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// *********************************************************************************************
// *                                     TEST CONSTANTS                                        *
// *********************************************************************************************
/// Initial amount of ERC20 tokens minted to the deposit vault
const INITIAL_TOKENS_MINTED: felt252 = 1000;

// *********************************************************************************************
// *                                      TEST LOGIC                                           *
// *********************************************************************************************
#[test]
#[should_panic(expected: ('already_initialized',))]
fn given_already_intialized_when_initialize_then_fails() {
    let (_, _, role_store, data_store, deposit_vault, _) = setup();
    deposit_vault.initialize(data_store.contract_address, role_store.contract_address);
    teardown(data_store, deposit_vault);
}

#[test]
fn given_normal_conditions_when_transfer_out_then_works() {
    let (_, receiver_address, _, data_store, deposit_vault, erc20) = setup();

    let amount_to_transfer: u128 = 100;
    deposit_vault.transfer_out(erc20.contract_address, receiver_address, amount_to_transfer);

    // check that the contract balance reduces
    let contract_balance = erc20.balance_of(deposit_vault.contract_address);
    let expected_balance: u256 = u256_from_felt252(
        INITIAL_TOKENS_MINTED - amount_to_transfer.into()
    );
    assert(contract_balance == expected_balance, 'transfer_out failed');

    // check that the balance of the receiver increases 
    let receiver_balance = erc20.balance_of(receiver_address);
    let expected_balance: u256 = amount_to_transfer.into();
    assert(receiver_balance == expected_balance, 'transfer_out failed');

    teardown(data_store, deposit_vault);
}

#[test]
#[should_panic(expected: ('u256_sub Overflow',))]
fn given_not_enough_token_when_transfer_out_then_fails() {
    let (_, receiver_address, _, data_store, deposit_vault, erc20) = setup();

    let amount_to_transfer: u128 = u128_from_felt252(INITIAL_TOKENS_MINTED + 1);
    deposit_vault.transfer_out(erc20.contract_address, receiver_address, amount_to_transfer);

    teardown(data_store, deposit_vault);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_caller_has_no_controller_role_when_transfer_out_then_fails() {
    let (caller_address, receiver_address, _, data_store, deposit_vault, erc20) = setup();
    stop_prank(deposit_vault.contract_address);
    start_prank(deposit_vault.contract_address, receiver_address);
    deposit_vault.transfer_out(erc20.contract_address, caller_address, 100_u128);
    teardown(data_store, deposit_vault);
}

#[test]
#[should_panic(expected: ('self_transfer_not_supported',))]
fn given_receiver_is_contract_when_transfer_out_then_fails() {
    let (caller_address, receiver_address, _, data_store, deposit_vault, erc20) = setup();
    deposit_vault.transfer_out(erc20.contract_address, deposit_vault.contract_address, 100_u128);
    teardown(data_store, deposit_vault);
}

#[test]
fn given_normal_conditions_when_record_transfer_in_then_works() {
    let (_, _, _, data_store, deposit_vault, erc20) = setup();

    let initial_balance: u128 = u128_from_felt252(INITIAL_TOKENS_MINTED);
    let tokens_received: u128 = deposit_vault.record_transfer_in(erc20.contract_address);
    assert(tokens_received == initial_balance, 'should be initial balance');

    teardown(data_store, deposit_vault);
}

#[test]
fn given_more_balance_when_2nd_record_transfer_in_then_works() {
    let (_, _, _, data_store, deposit_vault, erc20) = setup();

    let initial_balance: u128 = u128_from_felt252(INITIAL_TOKENS_MINTED);
    let tokens_received: u128 = deposit_vault.record_transfer_in(erc20.contract_address);
    assert(tokens_received == initial_balance, 'should be initial balance');

    let tokens_transfered_in: u128 = 250;
    let mock_balance_with_more_tokens: u256 = (initial_balance + tokens_transfered_in).into();
    start_mock_call(erc20.contract_address, 'balance_of', mock_balance_with_more_tokens);

    let tokens_received: u128 = deposit_vault.record_transfer_in(erc20.contract_address);
    assert(tokens_received == tokens_transfered_in, 'incorrect received amount');

    teardown(data_store, deposit_vault);
}

#[test]
#[should_panic(expected: ('u128_sub Overflow',))]
fn given_less_balance_when_2nd_record_transfer_in_then_fails() {
    let (_, _, _, data_store, deposit_vault, erc20) = setup();

    let initial_balance: u128 = u128_from_felt252(INITIAL_TOKENS_MINTED);
    let tokens_received: u128 = deposit_vault.record_transfer_in(erc20.contract_address);
    assert(tokens_received == initial_balance, 'should be initial balance');

    let tokens_transfered_out: u128 = 250;
    let mock_balance_with_less_tokens: u256 = (initial_balance - tokens_transfered_out).into();
    start_mock_call(erc20.contract_address, 'balance_of', mock_balance_with_less_tokens);

    deposit_vault.record_transfer_in(erc20.contract_address);

    teardown(data_store, deposit_vault);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_caller_is_not_controller_when_record_transfer_in_then_fails() {
    let (caller_address, _, role_store, data_store, deposit_vault, erc20) = setup();

    role_store.revoke_role(caller_address, role::CONTROLLER);
    deposit_vault.record_transfer_in(erc20.contract_address);

    teardown(data_store, deposit_vault);
}

// *********************************************************************************************
// *                                      SETUP                                                *
// *********************************************************************************************
/// Utility function to setup the test environment.
///
/// Complete statement to retrieve everything:
///     let (
///         caller_address, receiver_address,
///         role_store, data_store,
///         deposit_vault,
///         erc20
///     ) = setup();
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `ContractAddress` - The address of the receiver.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
/// * `IDepositVaultDispatcher` - The deposit vault dispatcher.
/// * `IERC20Dispatcher` - The ERC20 token dispatcher.
fn setup() -> (
    ContractAddress,
    ContractAddress,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IDepositVaultDispatcher,
    IERC20Dispatcher
) {
    // get caller_address, role store and data_store from tests_lib::setup()
    let (caller_address, role_store, data_store) = tests_lib::setup();

    // get receiver_address
    let receiver_address: ContractAddress = 0x202.try_into().unwrap();

    // deploy deposit vault
    let deposit_vault_address = deploy_deposit_vault(
        data_store.contract_address, role_store.contract_address
    );
    let deposit_vault = IDepositVaultDispatcher { contract_address: deposit_vault_address };

    // deploy erc20 token
    let erc20_contract_address = deploy_erc20_token(deposit_vault_address);
    let erc20 = IERC20Dispatcher { contract_address: erc20_contract_address };

    // start prank and give controller role to caller_address
    start_prank(deposit_vault.contract_address, caller_address);

    return (caller_address, receiver_address, role_store, data_store, deposit_vault, erc20);
}

/// Utility function to deploy a deposit vault.
///
/// # Arguments
///
/// * `data_store_address` - The address of the data store contract.
/// * `role_store_address` - The address of the role store contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the deposit vault.
fn deploy_deposit_vault(
    data_store_address: ContractAddress, role_store_address: ContractAddress
) -> ContractAddress {
    let deposit_vault_contract = declare('DepositVault');
    let constructor_calldata2 = array![data_store_address.into(), role_store_address.into()];
    deposit_vault_contract.deploy(@constructor_calldata2).unwrap()
}

/// Utility function to deploy an ERC20 token.
/// When deployed, 1000 tokens are minted to the deposit vault address.
///
/// # Arguments
///
/// * `deposit_vault_address` - The address of the deposit vault address.
///
/// # Returns
///
/// * `ContractAddress` - The address of the ERC20 token.
fn deploy_erc20_token(deposit_vault_address: ContractAddress) -> ContractAddress {
    let erc20_contract = declare('ERC20');
    let constructor_calldata3 = array![
        'satoru', 'STU', INITIAL_TOKENS_MINTED, 0, deposit_vault_address.into()
    ];
    erc20_contract.deploy(@constructor_calldata3).unwrap()
}

// *********************************************************************************************
// *                                     TEARDOWN                                              *
// *********************************************************************************************
fn teardown(data_store: IDataStoreDispatcher, deposit_vault: IDepositVaultDispatcher) {
    tests_lib::teardown(data_store.contract_address);
    stop_prank(deposit_vault.contract_address);
}
