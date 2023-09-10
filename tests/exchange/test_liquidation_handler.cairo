
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait, ContractClass};
use satoru::exchange::liquidation_handler::{LiquidationHandler, ILiquidationHandlerDispatcher, ILiquidationHandler};
use test::test_data_store;
use starknet::{ConstractAddress, contract_address_const, ClassHash, Felt252TryIntoContractAddress};

#[test]
fn test_exec_liquidation_true(){
    
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

fn deploy_order_vault() -> ContractAddress {
    let contract = declare('OrderVault');
    contract.deploy(@array![]).unwrap()
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

fn deploy_oracle() -> ContractAddress {
    let contract = declare('Oracle');
    contract.deploy(@array![]).unwrap()
}

fn deploy_swap_handler() -> ContractAddress {
    let contract = declare('SwapHandler');
    contract.deploy(@array![]).unwrap()
}

fn deploy_referral_storage() -> ContractAddress {
    let contract = declare('ReferralStorage');
    contract.deploy(@array![]).unwrap()
}

fn setup() -> (ContractAddress, ILiquidationHandlerDispatcher) {
    let role_store_address = deploy_role_store();
    let data_store_address = deploy_data_store(role_store_address);
    let event_emitter_address = deploy_event_emitter();
    let order_vault_address = deploy_order_vault();
    let swap_handler_address = deploy_swap_handler();
    let oracle_address = deploy_oracle();
    let referral_storage_address = deploy_referral_storage();
    let liquidation_handler_address = deploy_liquidation_handler(role_store_address, data_store_address, event_emitter_address, order_vault_address, swap_handler_address, oracle_address, referral_storage_address);
    let liquidation_handler_dispatcher = ILiquidationHandlerDispatcher::new(liquidation_handler);
    (liquidation_handler_address, liquidation_handler_dispatcher)
}
