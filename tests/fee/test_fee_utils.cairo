use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const
};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};

use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::data::keys::{
    claimable_fee_amount_key, claimable_ui_fee_amount_key, claimable_ui_fee_amount_for_account_key
};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::fee::fee_utils::{increment_claimable_fee_amount, increment_claimable_ui_fee_amount};

#[test]
fn given_normal_conditions_when_increment_claimable_fee_amount_then_works() {
    let (caller_address, data_store, event_emitter) = setup();

    let market: ContractAddress = 0x555.try_into().unwrap();
    let token: ContractAddress = 0x666.try_into().unwrap();

    let key = claimable_fee_amount_key(
        market, token
    ); // Calculate slot key to get initial value of slot.

    let initial_value = data_store.get_u256(key);
    assert(initial_value == 0_u256, 'initial value wrong');

    // Change value with util function.

    let delta = 50_u256;
    let fee_type = 'FEE_TYPE';

    increment_claimable_fee_amount(data_store, event_emitter, market, token, delta, fee_type);

    let final_value = data_store.get_u256(key);

    assert(final_value == delta, 'Final value wrong');
}

#[test]
fn given_normal_conditions_when_increment_claimable_ui_fee_amount_then_works() {
    let (caller_address, data_store, event_emitter) = setup();

    let market: ContractAddress = 0x555.try_into().unwrap();
    let token: ContractAddress = 0x666.try_into().unwrap();
    let ui_fee_receiver: ContractAddress = 0x777.try_into().unwrap();

    let key = claimable_ui_fee_amount_for_account_key(market, token, ui_fee_receiver);
    let pool_key = claimable_ui_fee_amount_key(market, token);

    let initial_value = data_store.get_u256(key);
    let initial_pool_value = data_store.get_u256(pool_key);

    assert(initial_value == 0, 'Initial value wrong');
    assert(initial_pool_value == 0, 'Initial pool value wrong');

    let delta = 75_u256;
    let fee_type = 'UI_FEE_TYPE';

    increment_claimable_ui_fee_amount(
        data_store, event_emitter, ui_fee_receiver, market, token, delta, fee_type
    );

    let final_value = data_store.get_u256(key);
    let final_pool_value = data_store.get_u256(pool_key);

    assert(final_value == delta, 'Final value wrong');
    assert(final_pool_value == delta, 'Final pool value wrong');
}

fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'data_store'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'role_store'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![caller_address.into()], deployed_contract_address).unwrap()
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'event_emitter'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![], deployed_contract_address).unwrap()
}

/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
fn setup() -> (ContractAddress, IDataStoreDispatcher, IEventEmitterDispatcher) {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    (caller_address, data_store, event_emitter)
}
