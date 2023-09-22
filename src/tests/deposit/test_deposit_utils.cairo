//! Test file for `src/deposit/deposit_utils.cairo`.
use starknet::{ContractAddress, contract_address_const};

use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::chain::chain::{IChainDispatcher, IChainDispatcherTrait};
use satoru::role::role;
use satoru::tests_lib;
use satoru::utils::span32::{Span32, Array32Trait};
use satoru::deposit::{
    deposit::Deposit, deposit_utils::CreateDepositParams, deposit_utils::create_deposit,
    deposit_utils::cancel_deposit,
    deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait}
};

use snforge_std::{declare, start_prank, ContractClassTrait};


#[test]
fn given_normal_conditions_when_deposit_then_works() {
    let (caller_address, data_store, event_emitter, deposit_vault, chain) = setup();
    let account: ContractAddress = 'account'.try_into().unwrap();
    let deposit_param = create_dummy_deposit_param();
// let key = create_deposit(
//     data_store, event_emitter, deposit_vault, chain, account, deposit_param
// );
}


#[test]
#[should_panic(expected: ('insffcient_wnt_amt_for_exec_fee',))]
fn given_unsufficient_wnt_amount_for_deposit_then_fails() {
    let (caller_address, data_store, event_emitter, deposit_vault, chain) = setup();
    let account: ContractAddress = 'account'.try_into().unwrap();
    let deposit_param = create_dummy_deposit_param();
    let key = create_deposit(
        data_store, event_emitter, deposit_vault, chain, account, deposit_param
    );
}

// #[test]
// #[should_panic(expected: ('empty_deposit_amounts',))]
// fn given_empty_deposit_amount_then_fails() {
//     let (caller_address, data_store, event_emitter, deposit_vault, chain) = setup();
//     let account: ContractAddress = 'account'.try_into().unwrap();
//     let deposit_param = create_dummy_deposit_param();
//     let key = create_deposit(
//         data_store, event_emitter, deposit_vault, chain, account, deposit_param
//     );
// }

#[test]
fn given_normal_conditions_when_cancel_deposit_then_works() {
    let (caller_address, data_store, event_emitter, deposit_vault, chain) = setup();
    let account: ContractAddress = 'account'.try_into().unwrap();
    let keeper: ContractAddress = 'keeper'.try_into().unwrap();
    let deposit_param = create_dummy_deposit_param();
    let key = 'key';
    let reason = 'key';
    let starting_gas = 2;
    let reason_bytes = array!['reason_bytes_1', 'reason_bytes_2',];
// let key = create_deposit(
//     data_store, event_emitter, deposit_vault, chain, account, deposit_param
// );

// cancel_deposit(
//     data_store, event_emitter, deposit_vault, key, keeper, starting_gas, reason, reason_bytes
// );
}


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IDataStoreDispatcher` - The data store dispatcher.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
fn setup() -> (
    ContractAddress,
    IDataStoreDispatcher,
    IEventEmitterDispatcher,
    IDepositVaultDispatcher,
    IChainDispatcher
) {
    let (caller_address, role_store, data_store) = tests_lib::setup();
    let (_, event_emitter) = tests_lib::setup_event_emitter();
    let deposit_vault_address = deploy_deposit_vault(
        data_store.contract_address, role_store.contract_address
    );
    let deposit_vault = IDepositVaultDispatcher { contract_address: deposit_vault_address };

    let chain_address = deploy_chain();
    let chain = IChainDispatcher { contract_address: chain_address };
    (caller_address, data_store, event_emitter, deposit_vault, chain)
}

/// Utility function to deploy a `DepositVault` contract and return its dispatcher.
fn deploy_deposit_vault(
    data_store_address: ContractAddress, role_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('DepositVault');
    contract.deploy(@array![data_store_address.into(), role_store_address.into()]).unwrap()
}

/// Utility function to deploy a `Chain` contract and return its dispatcher.
fn deploy_chain() -> ContractAddress {
    let contract = declare('Chain');
    contract.deploy(@array![]).unwrap()
}

fn create_dummy_deposit_param() -> CreateDepositParams {
    CreateDepositParams {
        /// The address to send the market tokens to.
        receiver: 'receiver'.try_into().unwrap(),
        /// The callback contract linked to this deposit.
        callback_contract: 'callback_contract'.try_into().unwrap(),
        /// The ui fee receiver.
        ui_fee_receiver: 'ui_fee_receiver'.try_into().unwrap(),
        /// The market to deposit into.
        market: 'market'.try_into().unwrap(),
        /// The initial long token address.
        initial_long_token: 'initial_long_token'.try_into().unwrap(),
        /// The initial short token address.
        initial_short_token: 'initial_short_token'.try_into().unwrap(),
        /// The swap path into markets for the long token.
        long_token_swap_path: array![
            1.try_into().unwrap(), 2.try_into().unwrap(), 3.try_into().unwrap()
        ]
            .span32(),
        /// The swap path into markets for the short token.
        short_token_swap_path: array![
            4.try_into().unwrap(), 5.try_into().unwrap(), 6.try_into().unwrap()
        ]
            .span32(),
        /// The minimum acceptable number of liquidity tokens.
        min_market_tokens: 10,
        /// Whether to unwrap the native token when sending funds back
        /// to the user in case the deposit gets cancelled.
        should_unwrap_native_token: false,
        /// The execution fee for keepers.
        execution_fee: 0,
        /// The gas limit for the callback_contract.
        callback_gas_limit: 20
    }
}

