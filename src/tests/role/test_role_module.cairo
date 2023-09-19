use result::ResultTrait;
use traits::TryInto;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use snforge_std::{declare, start_prank, ContractClassTrait};


use satoru::role::{
    role_module::{IRoleModuleDispatcher, IRoleModuleDispatcherTrait},
    role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait},
    role::{
        ROLE_ADMIN, TIMELOCK_ADMIN, TIMELOCK_MULTISIG, CONFIG_KEEPER, CONTROLLER, ROUTER_PLUGIN,
        MARKET_KEEPER, FEE_KEEPER, ORDER_KEEPER, FROZEN_ORDER_KEEPER, PRICING_KEEPER,
        LIQUIDATION_KEEPER, ADL_KEEPER
    }
};

#[test]
fn given_normal_conditions_when_only_self_then_works() {
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
    role_module.only_self();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn given_not_self_when_only_self_then_fails() {
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
    role_module.only_self();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn given_not_self_when_only_timelock_multisig_then_works() {
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
    role_store.grant_role(caller_address, TIMELOCK_MULTISIG);
    // Check that the account address has the timelock_multisig role.
    role_module.only_timelock_multisig();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn given_not_timelock_multisig_when_only_timelock_multisig_then_fails() {
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
    role_module.only_timelock_multisig();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn given_normal_conditions_when_only_timelock_admin_then_works() {
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
    role_store.grant_role(caller_address, TIMELOCK_ADMIN);
    // Check that the account address has the timelock_admin role.
    role_module.only_timelock_admin();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn given_not_timelock_admin_when_only_timelock_admin_then_fails() {
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
    role_module.only_timelock_admin();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn given_normal_conditions_when_only_config_keeper_then_works() {
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
    role_store.grant_role(caller_address, CONFIG_KEEPER);
    // Check that the account address has the config_keeper role.
    role_module.only_config_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn given_not_config_keeper_when_only_config_keeper_then_fails() {
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
    role_module.only_config_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn given_normal_conditions_when_only_controller_then_works() {
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
    role_store.grant_role(caller_address, CONTROLLER);
    // Check that the account address has the controller_role.
    role_module.only_controller();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn given_not_controller_when_only_controller_then_fails() {
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
    role_module.only_controller();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn given_normal_conditions_when_only_router_plugin_then_works() {
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
    role_store.grant_role(caller_address, ROUTER_PLUGIN);
    // Check that the account address has the router_plugin role.
    role_module.only_router_plugin();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn given_not_router_plugin_when_only_router_plugin_then_fails() {
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
    role_module.only_router_plugin();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn given_normal_conditions_when_only_market_keeper_then_works() {
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
    role_store.grant_role(caller_address, MARKET_KEEPER);
    // Check that the account address has the market_keeper role.
    role_module.only_market_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn given_not_market_keeper_when_only_market_keeper_then_fails() {
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
    role_module.only_market_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn given_normal_conditions_when_only_fee_keeper_then_works() {
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
    role_store.grant_role(caller_address, FEE_KEEPER);
    // Check that the account address has the fee keeper_role.
    role_module.only_fee_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn given_not_fee_keeper_when_only_fee_keeper_then_fails() {
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
    role_module.only_fee_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn given_normal_conditions_when_only_order_keeper_then_works() {
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
    role_store.grant_role(caller_address, ORDER_KEEPER);
    // Check that the account address has the order_keeper role.
    role_module.only_order_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn given_not_order_keeper_when_only_order_keeper_then_fails() {
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
    role_module.only_order_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn given_normal_conditions_when_only_pricing_keeper_then_works() {
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
    role_store.grant_role(caller_address, PRICING_KEEPER);
    // Check that the account address has the pricing_keeper role.
    role_module.only_pricing_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn given_not_pricing_keeper_when_only_pricing_keeper_then_fails() {
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
    role_module.only_pricing_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
fn given_normal_conditions_when_only_liquidation_keeper_then_works() {
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
    role_store.grant_role(caller_address, LIQUIDATION_KEEPER);
    // Check that the account address has the liquidation_keeper role.
    role_module.only_liquidation_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn given_not_liquidation_keeper_when_only_liquidation_keeper_then_fails() {
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
    role_module.only_liquidation_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}


#[test]
fn given_normal_conditions_when_only_adl_keeper_then_works() {
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
    role_store.grant_role(caller_address, ADL_KEEPER);
    // Check that the account address has the adl_keeper role.
    role_module.only_adl_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
#[should_panic]
fn given_not_adl_keeper_when_only_adl_keeper_then_works() {
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
    role_module.only_adl_keeper();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

fn setup() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    IRoleStoreDispatcher, // Interface to interact with the `MarketToken` contract.
    IRoleModuleDispatcher,
) {
    let role_store = IRoleStoreDispatcher { contract_address: deploy_role_store() };
    let role_module = IRoleModuleDispatcher {
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
