use result::ResultTrait;
use traits::{TryInto, Into};
use starknet::{ContractAddress, get_caller_address};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait, ContractClass};
use satoru::router::router::{IRouterDispatcher, IRouterDispatcherTrait};
use satoru::token::erc20::interface::{IERC20SafeDispatcher, IERC20SafeDispatcherTrait};
use satoru::role::role_store::{IRoleStoreSafeDispatcher, IRoleStoreSafeDispatcherTrait};
use satoru::role::role;


#[test]
fn given_normal_conditions_when_transfer_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let mint_amount = 10000;
    let transfer_amount: u128 = 100;
    let receiver_address: ContractAddress = 0x103.try_into().unwrap();
    let (sender_address, caller_address, router, test_token) = setup(mint_amount);

    let sender_initial_balance = test_token.balance_of(sender_address).unwrap();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Add allowance to the router contract.
    start_prank(test_token.contract_address, sender_address);
    test_token.approve(router.contract_address, mint_amount).unwrap();
    stop_prank(test_token.contract_address);

    // Transfer tokens from the sender address to the receiver address.
    start_prank(router.contract_address, caller_address);
    router
        .plugin_transfer(
            test_token.contract_address, sender_address, receiver_address, transfer_amount
        );

    // Assert that the tokens have been transfered.
    assert(
        test_token.balance_of(receiver_address).unwrap() == transfer_amount.into(),
        'unexp. receiver final balance'
    );
    assert(
        sender_initial_balance
            - transfer_amount.into() == test_token.balance_of(sender_address).unwrap(),
        'unexp. sender final balance'
    );

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(router.contract_address, test_token.contract_address);
}

#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_bad_caller_when_transfer_then_fail() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let mint_amount = 10000;
    let transfer_amount: u128 = 100;
    let receiver_address: ContractAddress = 0x103.try_into().unwrap();
    let (sender_address, _, router, test_token) = setup(mint_amount);

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Add allowance to the router contract.
    start_prank(test_token.contract_address, sender_address);
    test_token.approve(router.contract_address, mint_amount).unwrap();
    stop_prank(test_token.contract_address);

    // Prank with a not authorized caller.
    start_prank(router.contract_address, receiver_address);
    // Try to ransfer tokens from the sender address to the receiver address.
    // We expect this call to panic with `unauthorized_access`.
    router
        .plugin_transfer(
            test_token.contract_address, sender_address, receiver_address, transfer_amount
        );

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(router.contract_address, test_token.contract_address);
}

/// Utility function to setup the test environment.
///
/// # Arguments
///
/// * `mint_amount` - The amount of test token to be minted during deployment.
fn setup(
    mint_amount: u256
) -> (
    ContractAddress, // Minter address.
    ContractAddress, // Caller address.
    IRouterDispatcher, // Interface to interact with the `Router` contract.
    IERC20SafeDispatcher,
) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let minter_address: ContractAddress = 0x102.try_into().unwrap();

    // Deploy the test token.
    let test_token_address = deploy_mock_token(minter_address, mint_amount);
    // Create a test token dispatcher.
    let test_token = IERC20SafeDispatcher { contract_address: test_token_address };

    // Deploy the role store contract.
    let role_store_address = deploy_role_store();
    // Grant the caller the `ROUTER_PLUGIN` role.
    let role_store = IRoleStoreSafeDispatcher { contract_address: role_store_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::ROUTER_PLUGIN).unwrap();
    stop_prank(role_store_address);

    // Deploy the router contract.
    let router_address = deploy_router(role_store_address);
    // Create a dispatcher to interact with the contract.
    let router = IRouterDispatcher { contract_address: router_address };

    (minter_address, caller_address, router, test_token)
}

/// Utility function to teardown the test environment.
///
/// # Arguments
///
/// * `test_token_address` - The address of the Test Token contract.
/// * `router_address` - The address of the `Router` contract.
fn teardown(test_token_address: ContractAddress, router_address: ContractAddress) {
    stop_prank(test_token_address);
    stop_prank(router_address);
}

/// Utility function to deploy a test token and return its address.
///
/// # Arguments
///
/// * `minter_address` - The address of the wallet who will get the initial supply.
/// * `initial_amount` - The amount of token minted during the deployment.
fn deploy_mock_token(minter_address: ContractAddress, initial_amount: u256) -> ContractAddress {
    let contract = declare('ERC20');
    let mut constructor_calldata: Array::<felt252> = array![];
    constructor_calldata.append('TestToken');
    constructor_calldata.append('TST');
    constructor_calldata.append(initial_amount.low.into());
    constructor_calldata.append(initial_amount.high.into());
    constructor_calldata.append(minter_address.into());
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy the `Router` contract and return its address.
///
/// # Arguments
///
/// * `role_store_address` - The address of the `RoleStore` contract associated with the `Router`.
fn deploy_router(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('Router');
    let mut constructor_calldata: Array::<felt252> = array![];
    constructor_calldata.append(role_store_address.into());
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a data store contract and return its address.
/// Copied from `tests/role/test_role_store.rs`.
/// TODO: Find a way to share this code.
fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let constructor_arguments: @Array::<felt252> = @ArrayTrait::new();
    contract.deploy(constructor_arguments).unwrap()
}
