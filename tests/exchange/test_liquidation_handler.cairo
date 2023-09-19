
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait, ContractClass};
use satoru::exchange::liquidation_handler::{LiquidationHandler, ILiquidationHandlerDispatcher, ILiquidationHandler, ILiquidationHandlerDispatcherTrait};
use starknet::{ContractAddress, contract_address_const, ClassHash, Felt252TryIntoContractAddress};
use debug::PrintTrait;
use satoru::referral::referral_storage;
use traits::Default;
use satoru::oracle::oracle_utils::SetPricesParams;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait, IDataStore};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::role::role_module::{IRoleModuleDispatcher, IRoleModuleDispatcherTrait};
use satoru::order::order::{Order, OrderType, OrderTrait, DecreasePositionSwapType};
use satoru::utils::span32::{Span32, Array32Trait};

#[test]
fn test_exec_liquidation_true(){
    let collateral_token: ContractAddress = contract_address_const::<1>();
    let (data_store, liquidation_keeper, liquidation_handler_address, liquidation_handler_dispatcher) = _setup();
    start_prank(liquidation_handler_address, liquidation_keeper);
    //TODO: add test for execute_liquidation
    liquidation_handler_dispatcher.execute_liquidation(
        account: contract_address_const::<'account'>(),
        market: contract_address_const::<'market'>(),
        collateral_token: collateral_token,
        is_long: true,
        oracle_params: Default::default()
    );
}

fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@array![]).unwrap()
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    contract.deploy(@array![]).unwrap()
}

fn deploy_order_vault(data_store_address: ContractAddress, role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('OrderVault');
    contract.deploy(@array![data_store_address.into(), role_store_address.into()]).unwrap()
}

fn deploy_liquidation_handler(role_store_address: ContractAddress, data_store_address: ContractAddress, event_emitter_address: ContractAddress, order_vault_address: ContractAddress, swap_handler_address: ContractAddress, oracle_address: ContractAddress) -> ContractAddress {
    let contract = declare('LiquidationHandler');
    contract.deploy(@array![
        data_store_address.into(),
        role_store_address.into(),
        event_emitter_address.into(),
        order_vault_address.into(),
        oracle_address.into(),
        swap_handler_address.into(),
        Default::default()//referal_storage::IReferralStorage
    ]).unwrap()
}

fn deploy_oracle(role_store_address: ContractAddress, oracle_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('Oracle');
    contract.deploy(@array![role_store_address.into(), oracle_store_address.into()]).unwrap()
}

fn deploy_swap_handler(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('SwapHandler');
    contract.deploy(@array![role_store_address.into()]).unwrap()
}

fn deploy_referral_storage() -> ContractAddress {
    let contract = declare('ReferralStorage');
    contract.deploy(@array![]).unwrap()
}

fn deploy_oracle_store(role_store_address: ContractAddress, event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('OracleStore');
    contract.deploy(@array![role_store_address.into(), event_emitter_address.into()]).unwrap()
}

fn deploy_role_module(role_store_address: ContractAddress) -> IRoleModuleDispatcher {
    let contract = declare('RoleModule');
    let role_module_address = contract.deploy(@array![role_store_address.into()]).unwrap();
    IRoleModuleDispatcher { contract_address: role_module_address }
}

fn _setup() -> (IDataStoreDispatcher, ContractAddress, ContractAddress, ILiquidationHandlerDispatcher) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let liquidation_keeper: ContractAddress = 0x2233.try_into().unwrap();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    let event_emitter_address = deploy_event_emitter();
    let order_vault_address = deploy_order_vault(data_store_address, role_store_address);
    let swap_handler_address = deploy_swap_handler(role_store_address);
    let oracle_store_address = deploy_oracle_store(role_store_address, event_emitter_address);
    let oracle_address = deploy_oracle(role_store_address, oracle_store_address);
    //let referral_storage_address = deploy_referral_storage();
    let liquidation_handler_address = deploy_liquidation_handler(role_store_address, data_store_address, event_emitter_address, order_vault_address, swap_handler_address, oracle_address);
    let liquidation_handler_dispatcher = ILiquidationHandlerDispatcher{ contract_address: liquidation_handler_address};
    let role_module = deploy_role_module(role_store_address);
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    role_store.grant_role(liquidation_keeper, role::LIQUIDATION_KEEPER);
    role_store.grant_role(liquidation_keeper, role::ORDER_KEEPER);
    role_store.grant_role(liquidation_handler_address, role::FROZEN_ORDER_KEEPER);
    role_store.grant_role(liquidation_handler_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    (data_store, liquidation_keeper, liquidation_handler_address, liquidation_handler_dispatcher)
}
