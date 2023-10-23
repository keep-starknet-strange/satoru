use result::ResultTrait;
use traits::{TryInto, Into};
use starknet::{ContractAddress, get_caller_address, contract_address_const};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait, ContractClass};
use satoru::router::router::{IRouterDispatcher, IRouterDispatcherTrait};
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;


#[test]
fn given_normal_conditions_when_create_deposit_then_works() {
    let (
         caller_address,
         role_store, data_store,
         deposit_vault,
     ) = setup();

    // deploy erc20 token and mint to deposit_vault
    let erc20_contract_address = deploy_erc20_token(deposit_vault.contract_address);
    let erc20 = IERC20Dispatcher { contract_address: erc20_contract_address };


}
// *********************************************************************************************
// *                                      SETUP                                                *
// *********************************************************************************************
/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
/// * `IDepositVaultDispatcher` - The deposit vault dispatcher.
/// * `IERC20Dispatcher` - The ERC20 token dispatcher.
fn setup() -> (
    ContractAddress,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IDepositVaultDispatcher,
    IERC20Dispatcher
) {
    // Setup Oracle and Store
    let (caller_address, role_store, data_store, event_emitter, oracle) = tests_lib::setup_oracle_and_store();

    // Deploy deposit vault
    let deposit_vault_address = deploy_deposit_vault(
        data_store.contract_address, role_store.contract_address
    );
    let deposit_vault = IDepositVaultDispatcher { contract_address: deposit_vault_address };

    // Deploy deposit vault handler
    let deposit_handler_address = deploy_deposit_handler(
        data_store.contract_address, role_store.contract_address,
        event_emitter.contract_address,
        deposit_vault_address,
        oracle.contract_address
    );
    let deposit_handler = IDepositHandlerDispatcher { contract_address: deposit_handler_address };

    // Deploy withdrawal vault
    let withdrawal_vault_address = deploy_withdrawal_vault(
        data_store.contract_address, role_store.contract_address
    );
    let withdrawal_vault = IWithdrawalVaultDispatcher { contract_address: withdrawal_vault_address };

    // Deploy withdrawal vault handler
    let withdrawal_handler_address = deploy_withdrawal_handler(
        data_store.contract_address, role_store.contract_address,
        event_emitter.contract_address,
        withdrawal_vault_address,
        oracle.contract_address
    );
    let withdrawal_handler = IWithdrawalHandlerDispatcher { contract_address: withdrawal_handler_address };

    // Deploy order vault
    let order_vault_address = deploy_order_vault(
        data_store.contract_address, role_store.contract_address
    );
    let order_vault = IOrderVaultDispatcher { contract_address: order_vault_address };

    // Deploy swap handler
    let swap_handler_address = deploy_swap_handler(role_store.contract_address);
    let swap_handler = ISwapHandlerDispatcher { contract_address: swap_handler_address };

    // Deploy referral storage
    let referral_storage_address = deploy_referral_storage(event_emitter.contract_address);
    let referral_storage = IReferralStorageDispatcher {
        contract_address: referral_storage_address
    };

    // Deploy order handler
    let order_handler_state = deploy_order_handler(
        data_store.contract_address,
        role_store.contract_address,
        event_emitter.contract_address,
        order_vault_address,
        oracle.contract_address,
        swap_handler_address,
        referral_storage_address
    );

    // Deploy router
    let router_address = deploy_router(role_store.contract_address);
    let router = IRouterDispatcher { contract_address: router_address };

    // Deploy exchange router
    let exchange_router_address = deploy_exchange_router(
        router_address,
        data_store.contract_address,
        role_store.contract_address,
        event_emitter.contract_address,
        deposit_handler_address,
        withdrawal_handler_address,
        order_handler_address
    );
    let exchange_router = IExchangeRouterDispatcher { contract_address: exchange_router_address };

    // // deploy erc20 token
    // let erc20_contract_address = deploy_erc20_token(caller_address);
    // let erc20 = IERC20Dispatcher { contract_address: erc20_contract_address };

    // start prank and give controller role to caller_address
    //start_prank(deposit_vault.contract_address, caller_address);

    return (caller_address, role_store, data_store, deposit_vault, erc20);
}

/// Utility function to deploy an exchange router.
///
/// # Arguments
///
/// * `router_address` - The address of the router contract.
/// * `data_store_address` - The address of the data store contract.
/// * `role_store_address` - The address of the role store contract.
/// * `event_emitter_address` - The address of the event emitter contract.
/// * `deposit_handler_address` - The address of the deposit handler contract.
/// * `withdrawal_handler_address` - The address of the withdrawal handler contract.
/// * `order_handler_address` - The address of the order handler contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the exchange router.
fn deploy_exchange_router(
    router_address: ContractAddress,
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    deposit_handler_address: ContractAddress,
    withdrawal_handler_address: ContractAddress,
    order_handler_address: ContractAddress
) -> ContractAddress {
    let contract = declare('ExchangeRouter');
    let deployed_contract_address = contract_address_const::<'exchange_router'>();
    let constructor_calldata = array![
        router_address.into(),
        data_store_address.into(),
        role_store_address.into(),
        event_emitter_address.into(),
        deposit_handler_address.into(),
        withdrawal_handler_address.into(),
        order_handler_address.into()
    ];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

/// Utility function to deploy the a router.
///
/// # Arguments
///
/// * `role_store_address` - The address of the role store contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the router.
fn deploy_router(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('Router');
    let deployed_contract_address = contract_address_const::<'router'>();
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

/// Utility function to deploy a deposit vault.
///
/// # Arguments
///
/// * `data_store_address` - The address of the data store contract.
/// * `role_store_address` - The address of the role store contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the deposit vault.
fn deploy_deposit_vault(
    data_store_address: ContractAddress, role_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('DepositVault');
    let deployed_contract_address = contract_address_const::<'deposit_vault'>();
    let constructor_calldata = array![data_store_address.into(), role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

/// Utility function to deploy a deposit handler.
///
/// # Arguments
///
/// * `data_store_address` - The address of the data store contract.
/// * `role_store_address` - The address of the role store contract.
/// * `event_emitter_address` - The address of the event emitter contract.
/// * `deposit_vault_address` - The address of the deposit vault contract.
/// * `oracle_address` - The address of the oracle contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the deposit handler.
fn deploy_deposit_handler(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    deposit_vault_address: ContractAddress,
    oracle_address: ContractAddress
) -> ContractAddress {
    let contract = declare('DepositHandler');
    let deployed_contract_address = contract_address_const::<'deposit_handler'>();
    let constructor_calldata = array![
        data_store_address.into(),
        role_store_address.into(),
        event_emitter_address.into(),
        deposit_vault_address.into(),
        oracle_address.into()
        ];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

/// Utility function to deploy a withdrawal vault.
///
/// # Arguments
///
/// * `data_store_address` - The address of the data store contract.
/// * `role_store_address` - The address of the role store contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the withdrawal vault.
fn deploy_withdrawal_vault(
    data_store_address: ContractAddress, role_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('WithdrawalVault');
    let deployed_contract_address = contract_address_const::<'withdrawal_vault'>();
    let constructor_calldata = array![data_store_address.into(), role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

/// Utility function to deploy a withdrawal handler.
///
/// # Arguments
///
/// * `data_store_address` - The address of the data store contract.
/// * `role_store_address` - The address of the role store contract.
/// * `event_emitter_address` - The address of the event emitter contract.
/// * `withdrawal_vault_address` - The address of the withdrawal vault contract.
/// * `oracle_address` - The address of the oracle contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the withdrawal handler.
fn deploy_withdrawal_handler(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    withdrawal_vault_address: ContractAddress,
    oracle_address: ContractAddress
) -> ContractAddress {
    let contract = declare('WithdrawalHandler');
    let deployed_contract_address = contract_address_const::<'withdrawal_handler'>();
    let constructor_calldata = array![
        data_store_address.into(),
        role_store_address.into(),
        event_emitter_address.into(),
        withdrawal_vault_address.into(),
        oracle_address.into()
    ];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

/// Utility function to deploy an order vault.
///
/// # Arguments
///
/// * `data_store_address` - The address of the data store contract.
/// * `role_store_address` - The address of the role store contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the order vault.
fn deploy_order_vault(
    data_store_address: ContractAddress, role_store_address: ContractAddress,
) -> ContractAddress {
    let contract = declare('OrderVault');
    let deployed_contract_address = contract_address_const::<'order_vault'>();
    let mut constructor_calldata = array![data_store_address.into(),role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address)
}

/// Utility function to deploy a swap handler.
///
/// # Arguments
///
/// * `role_store_address` - The address of the role store contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the swap handler.
fn deploy_swap_handler(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('SwapHandler');
    let deployed_contract_address = contract_address_const::<'swap_handler'>();
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address)
}

/// Utility function to deploy a referral storage.
///
/// # Arguments
///
/// * `event_emitter_address` - The address of the event emitter contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the referral storage.
fn deploy_referral_storage(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('ReferralStorage');
    let deployed_contract_address = contract_address_const::<'referral_storage'>();
    let constructor_calldata = array![event_emitter_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address)
}

/// Utility function to deploy an order handler.
///
/// # Arguments
///
/// * `data_store_address` - The address of the data store contract.
/// * `role_store_address` - The address of the role store contract.
/// * `event_emitter_address` - The address of the event emitter contract.
/// * `order_vault_address` - The address of the order vault contract.
/// * `oracle_address` - The address of the oracle contract.
/// * `swap_handler_address` - The address of the swap handler contract.
/// * `referral_storage_address` - The address of the referral storage contract.
///
/// # Returns
///
/// * `ContractAddress` - The address of the withdrawal handler.
fn deploy_order_handler(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    order_vault_address: ContractAddress,
    oracle_address: ContractAddress,
    swap_handler_address: ContractAddress,
    referral_storage_address: ContractAddress
) -> BaseOrderHandler::ContractState {
    let contract = declare('OrderHandler');
    let deployed_contract_address = contract_address_const::<'order_handler'>();
    let constructor_calldata = array![
        data_store_address,
        role_store_address,
        event_emitter_address,
        order_vault_address,
        oracle_address,
        swap_handler_address,
        referral_storage_address
    ];
    contract.deploy_at(@constructor_calldata, deployed_contract_address)
}

/// Utility function to deploy an ERC20 token.
/// When deployed, 1000 tokens are minted to the specified address.
///
/// # Arguments
///
/// * `mint_address` - The address to mint tokens.
///
/// # Returns
///
/// * `ContractAddress` - The address of the ERC20 token.
fn deploy_erc20_token(mint_address: ContractAddress) -> ContractAddress {
    let erc20_contract = declare('ERC20');
    let constructor_calldata = array![
        'satoru', 'STU', 1000, 0, mint_address.into()
    ];
    erc20_contract.deploy_at(@constructor_calldata).unwrap()
}