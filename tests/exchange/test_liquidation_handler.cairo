
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait, ContractClass};
use satoru::exchange::liquidation_handler::{LiquidationHandler, ILiquidationHandlerDispatcher, ILiquidationHandler};
use starknet::{ContractAddress, contract_address_const, ClassHash, Felt252TryIntoContractAddress};
use debug::PrintTrait;

#[test]
fn test_exec_liquidation_true(){
    let (liquidation_handler_address, liquidation_handler_dispatcher) = _setup();
    //liquidation_handler_dispatcher.exec_liquidation();
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

fn deploy_liquidation_handler(role_store_address: ContractAddress, data_store_address: ContractAddress, event_emitter_address: ContractAddress, order_vault_address: ContractAddress, swap_handler_address: ContractAddress, oracle_address: ContractAddress, referral_storage_address: ContractAddress) -> ContractAddress {
    let contract = declare('LiquidationHandler');
    contract.deploy(@array![
        data_store_address.into(),
        role_store_address.into(),
        event_emitter_address.into(),
        order_vault_address.into(),
        oracle_address.into(),
        swap_handler_address.into(),
        referral_storage_address.into()
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

fn _setup() -> (ContractAddress, ILiquidationHandlerDispatcher) {
    let role_store_address = deploy_role_store();
    let data_store_address = deploy_data_store(role_store_address);
    let event_emitter_address = deploy_event_emitter();
    let order_vault_address = deploy_order_vault(data_store_address, role_store_address);
    let swap_handler_address = deploy_swap_handler(role_store_address);
    let oracle_store_address = deploy_oracle_store(role_store_address, event_emitter_address);
    let oracle_address = deploy_oracle(role_store_address, oracle_store_address);
    let referral_storage_address = deploy_referral_storage();
    let liquidation_handler_address = deploy_liquidation_handler(role_store_address, data_store_address, event_emitter_address, order_vault_address, swap_handler_address, oracle_address, referral_storage_address);
    let liquidation_handler_dispatcher = ILiquidationHandlerDispatcher{ contract_address: liquidation_handler_address};
    (liquidation_handler_address, liquidation_handler_dispatcher)
}
