use result::ResultTrait;
use traits::TryInto;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use snforge_std::{declare, start_prank, ContractClassTrait};


use satoru::role::role::{
    ROLE_ADMIN, TIMELOCK_ADMIN, TIMELOCK_MULTISIG, CONFIG_KEEPER, CONTROLLER, ROUTER_PLUGIN,
    MARKET_KEEPER, FEE_KEEPER, ORDER_KEEPER, FROZEN_ORDER_KEEPER, PRICING_KEEPER,
    LIQUIDATION_KEEPER, ADL_KEEPER
};
use satoru::role::role_module::IRoleModuleSafeDispatcher;
use satoru::role::role_module::IRoleModuleSafeDispatcherTrait;
use satoru::role::role_store::IRoleStoreSafeDispatcher;
use satoru::role::role_store::IRoleStoreSafeDispatcherTrait;

#[test]
fn test_role_module_timelock_multisig() {
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

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant timelock multisig role to account address.
    role_store.grant_role(account_address, TIMELOCK_MULTISIG).unwrap();
    // Check that the account address has the timelock multisig role.
    role_module.onlyTimelockMultisig();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

#[test]
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

    let account_address: ContractAddress = contract_address_const::<1>();

    // Check that the account address has the timelock multisig role, expect to fail.
    role_module.onlyTimelockMultisig();
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

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant timelock admin role to account address.
    role_store.grant_role(account_address, TIMELOCK_ADMIN).unwrap();
    // Check that the account address has the timelock admin role.
    role_module.onlyTimelockAdmin();
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

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant config keeper role to account address.
    role_store.grant_role(account_address, CONFIG_KEEPER).unwrap();
    // Check that the account address has the config keeper role.
    role_module.onlyConfigKeeper();
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

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant controller role to account address.
    role_store.grant_role(account_address, CONTROLLER).unwrap();
    // Check that the account address has the controller role.
    role_module.onlyController();
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

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant router plugin role to account address.
    role_store.grant_role(account_address, ROUTER_PLUGIN).unwrap();
    // Check that the account address has the router plugin role.
    role_module.onlyRouterPlugin();
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

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant market keeper role to account address.
    role_store.grant_role(account_address, MARKET_KEEPER).unwrap();
    // Check that the account address has the market keeper role.
    role_module.onlyMarketKeeper();
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

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant fee keeper role to account address.
    role_store.grant_role(account_address, FEE_KEEPER).unwrap();
    // Check that the account address has the fee keeper role.
    role_module.onlyFeeKeeper();
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

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant order keeper role to account address.
    role_store.grant_role(account_address, ORDER_KEEPER).unwrap();
    // Check that the account address has the order keeper role.
    role_module.onlyOrderKeeper();
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

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant pricing keeper role to account address.
    role_store.grant_role(account_address, PRICING_KEEPER).unwrap();
    // Check that the account address has the pricing keeper role.
    role_module.onlyPricingKeeper();
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

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant liquidation keeper role to account address.
    role_store.grant_role(account_address, LIQUIDATION_KEEPER).unwrap();
    // Check that the account address has the liquidation keeper role.
    role_module.onlyLiquidationKeeper();
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

    // Use the address that has been used to deploy role_store.
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    start_prank(role_store.contract_address, caller_address);

    let account_address: ContractAddress = contract_address_const::<1>();

    // Grant adl keeper role to account address.
    role_store.grant_role(account_address, LIQUIDATION_KEEPER).unwrap();
    // Check that the account address has the adl keeper role.
    role_module.onlyAdlKeeper();
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
