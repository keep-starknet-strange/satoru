use starknet::{ContractAddress, contract_address_const};

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::order::order::Deposit;
use satoru::tests_lib::{setup, teardown};

use snforge_std::{PrintTrait, declare, start_prank, stop_prank, ContractClassTrait};

/// Utility function to deploy a `DataStore` contract and return its dispatcher.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a `RoleStore` contract and return its dispatcher.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@array![]).unwrap()
}


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
fn setup() -> (ContractAddress, IRoleStoreDispatcher, IDataStoreDispatcher) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    (caller_address, role_store, data_store)
}

#[test]
fn test_set_withdrawal_new_and_override() {
    // Setup
    let (caller_address, role_store, data_store) = setup();
    let account = 'account'.try_into().unwrap();
    // TODO make these Span32
    let long_token_swap_path: Span32<ContractAddress> = array![
        1.try_into().unwrap(), 2.try_into().unwrap(), 3.try_into().unwrap()
    ]
        .span32();
    let short_token_swap_path: Span32<ContractAddress> = array![
        4.try_into().unwrap(), 5.try_into().unwrap(), 6.try_into().unwrap()
    ]
        .span32();

    let key: felt252 = 123456789;
    let mut withdrawal = Withdrawal {
        key: key,
        account,
        receiver: account,
        callback_contract: 1.try_into().unwrap(),
        ui_fee_receiver: 1.try_into().unwrap(),
        market: 1.try_into().unwrap(),
        long_token_swap_path,
        short_token_swap_path,
        market_token_amount: 1,
        min_long_token_amount: 1,
        min_short_token_amount: 1,
        updated_at_block: 1,
        execution_fee: 1,
        callback_gas_limit: 1,
        should_unwrap_native_token: true,
    };

    // Test logic

    // Test set_withdrawal function with a new key.
    data_store.set_withdrawal(key, withdrawal);

    let withdrawal_by_key = data_store.get_withdrawal(key).unwrap();
    assert(withdrawal_by_key == withdrawal, 'Invalid withdrawal by key');

    let account_withdrawal_count = data_store.get_account_withdrawal_count(account);
    assert(account_withdrawal_count == 1, 'Invalid account withdrawl count');

    let account_withdrawal_keys = data_store.get_account_withdrawal_keys(account, 0, 10);
    assert(account_withdrawal_keys.len() == 1, 'Acc withdrawal # should be 1');

    // Update the withdrawal using the set_withdrawal function and then retrieve it to check the update was successful
    let receiver = 'receiver'.try_into().unwrap();
    withdrawal.receiver = receiver;
    data_store.set_withdrawal(key, withdrawal);

    let withdrawal_by_key = data_store.get_withdrawal(key).unwrap();
    assert(withdrawal_by_key == withdrawal, 'Invalid withdrawal by key');
    assert(withdrawal_by_key.receiver == receiver, 'Invalid withdrawal value');

    let account_withdrawal_count = data_store.get_account_withdrawal_count(account);
    assert(account_withdrawal_count == 1, 'Invalid account withdrawl count');

    let account_withdrawal_keys = data_store.get_account_withdrawal_keys(account, 0, 10);
    assert(account_withdrawal_keys.len() == 1, 'Acc withdrawal # should be 1');

    teardown(data_store.contract_address);
}
