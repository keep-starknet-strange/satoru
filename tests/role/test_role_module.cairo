use result::ResultTrait;
use traits::TryInto;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use snforge_std::{declare, start_prank, ContractClassTrait};


use satoru::role::{
    role_module::{IRoleModuleSafeDispatcher, IRoleModuleSafeDispatcherTrait},
    role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait},
    role::{
        ROLE_ADMIN, TIMELOCK_ADMIN, TIMELOCK_MULTISIG, CONFIG_KEEPER, CONTROLLER, ROUTER_PLUGIN,
        MARKET_KEEPER, FEE_KEEPER, ORDER_KEEPER, FROZEN_ORDER_KEEPER, PRICING_KEEPER,
        LIQUIDATION_KEEPER, ADL_KEEPER
    }
};

#[test]
fn test_role_module_only_self() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, role_module.contract_address);

    // Check that only self is allowed.
    role_module.only_self().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn test_role_module_not_self() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Check that only self is allowed, expect to fail.
    role_module.only_self().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn test_role_module_only_timelock_multisig() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Grant timelock_multisig role to account address.
    role_store.grant_role(caller_address, TIMELOCK_MULTISIG).unwrap();
    // Check that the account address has the timelock_multisig role.
    role_module.only_timelock_multisig().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn test_role_module_not_timelock_multisig() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Check that the account address has the timelock_multisig role, expect to fail.
    role_module.only_timelock_multisig().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn test_role_module_only_timelock_admin() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************

    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Grant timelock_admin role to account address.
    role_store.grant_role(caller_address, TIMELOCK_ADMIN).unwrap();
    // Check that the account address has the timelock_admin role.
    role_module.only_timelock_admin().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn test_role_module_not_timelock_admin() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************

    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Check that the account address has the timelock_admin role, expect to fail.
    role_module.only_timelock_admin().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn test_role_module_only_config_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************

    let (role_store, role_module) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Grant config_keeper role to account address.
    role_store.grant_role(caller_address, CONFIG_KEEPER).unwrap();
    // Check that the account address has the config_keeper role.
    role_module.only_config_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn test_role_module_not_config_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************

    let (role_store, role_module) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Check that the account address has the config_keeper role, expect to fail.
    role_module.only_config_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn test_role_module_only_controller() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Grant controller_role to account address.
    role_store.grant_role(caller_address, CONTROLLER).unwrap();
    // Check that the account address has the controller_role.
    role_module.only_controller().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn test_role_module_not_controller() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Check that the account address has the controller_role, expect to fail.
    role_module.only_controller().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn test_role_module_only_router_plugin() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Grant router_plugin role to account address.
    role_store.grant_role(caller_address, ROUTER_PLUGIN).unwrap();
    // Check that the account address has the router_plugin role.
    role_module.only_router_plugin().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn test_role_module_not_router_plugin() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Check that the account address has the router_plugin role, expect to fail.
    role_module.only_router_plugin().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn test_role_module_only_market_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Grant market_keeper role to account address.
    role_store.grant_role(caller_address, MARKET_KEEPER).unwrap();
    // Check that the account address has the market_keeper role.
    role_module.only_market_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn test_role_module_not_market_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Check that the account address has the market_keeper role, expect to fail.
    role_module.only_market_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn test_role_module_only_fee_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Grant fee keeper_role to account address.
    role_store.grant_role(caller_address, FEE_KEEPER).unwrap();
    // Check that the account address has the fee keeper_role.
    role_module.only_fee_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn test_role_module_not_fee_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Check that the account address has the fee keeper_role, expect to fail.
    role_module.only_fee_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn test_role_module_only_order_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Grant order_keeper role to account address.
    role_store.grant_role(caller_address, ORDER_KEEPER).unwrap();
    // Check that the account address has the order_keeper role.
    role_module.only_order_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn test_role_module_not_order_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Check that the account address has the order_keeper role, expect to fail.
    role_module.only_order_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn test_role_module_only_pricing_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Grant pricing_keeper role to account address.
    role_store.grant_role(caller_address, PRICING_KEEPER).unwrap();
    // Check that the account address has the pricing_keeper role.
    role_module.only_pricing_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn test_role_module_not_pricing_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Check that the account address has the pricing_keeper role, expect to fail.
    role_module.only_pricing_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn test_role_module_only_liquidation_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Grant liquidation_keeper role to account address.
    role_store.grant_role(caller_address, LIQUIDATION_KEEPER).unwrap();
    // Check that the account address has the liquidation_keeper role.
    role_module.only_liquidation_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn test_role_module_not_liquidation_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Check that the account address has the liquidation_keeper role, expect to fail.
    role_module.only_liquidation_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}


#[test]
fn test_role_module_only_adl_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Grant adl_keeper role to account address.
    role_store.grant_role(caller_address, ADL_KEEPER).unwrap();
    // Check that the account address has the adl_keeper role.
    role_module.only_adl_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn test_role_module_not_adl_keeper() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (role_store, role_module) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);
    start_prank(role_module.contract_address, caller_address);

    // Check that the account address has the adl_keeper role, expect to fail.
    role_module.only_adl_keeper().unwrap();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

fn setup() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    IRoleStoreSafeDispatcher, // Interface to interact with the `MarketToken` contract.
    IRoleModuleSafeDispatcher,
) {
    let role_store = IRoleStoreSafeDispatcher { contract_address: deploy_role_store() };
    let role_module = IRoleModuleSafeDispatcher {
        contract_address: deploy_role_module(role_store.contract_address)
    };

    (role_store, role_module)
}

/// Utility function to teardown the test environment.
fn teardown() {}

// Utility function to deploy a role store contract and return its address.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@ArrayTrait::new()).unwrap()
}

// Utility function to deploy a role module contract and return its address.
fn deploy_role_module(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('RoleModule');
    let mut constructor_calldata = array![];
    constructor_calldata.append(role_store_address.into());
    contract.deploy(@constructor_calldata).unwrap()
}
