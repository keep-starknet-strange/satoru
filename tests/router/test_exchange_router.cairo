use result::ResultTrait;
use traits::{TryInto, Into};
use starknet::{ContractAddress, get_caller_address, contract_address_const};
use snforge_std::{
    declare, start_prank, stop_prank, start_mock_call, ContractClassTrait, ContractClass
};
use satoru::router::router::{IRouterDispatcher, IRouterDispatcherTrait};
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use satoru::role::role;
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::deposit::deposit_utils::CreateDepositParams;
use satoru::deposit::deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait};
use satoru::tests_lib;
use satoru::data::keys;
use satoru::exchange::{
    deposit_handler::{IDepositHandlerDispatcher, IDepositHandlerDispatcherTrait},
    withdrawal_handler::{IWithdrawalHandlerDispatcher, IWithdrawalHandlerDispatcherTrait},
    order_handler::{IOrderHandlerDispatcher, IOrderHandlerDispatcherTrait},
};
use satoru::withdrawal::withdrawal_vault::{
    IWithdrawalVaultDispatcher, IWithdrawalVaultDispatcherTrait
};
use satoru::order::order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::router::exchange_router::{IExchangeRouterDispatcher, IExchangeRouterDispatcherTrait};
use satoru::reader::reader::{IReaderDispatcher, IReaderDispatcherTrait};
use satoru::utils::span32::{Span32, Array32Trait, DefaultSpan32};
use satoru::market::market::Market;

#[test]
fn given_normal_conditions_when_create_deposit_then_works() {
    let (caller_address, role_store, data_store, reader, exchange_router, deposit_vault) = setup();

    // Grant market keeper role to allow adding market to the data store
    role_store.grant_role(caller_address, role::MARKET_KEEPER);

    let market_key = contract_address_const::<'market'>();
    let market = Market {
        market_token: contract_address_const::<'market_token'>(),
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };
    data_store.set_market(market_key, 0, market);

    // Mock deposit fee token in deposit vault
    start_mock_call(deposit_vault.contract_address, 'record_transfer_in', 10);

    let deposit_params = CreateDepositParams {
        receiver: contract_address_const::<'receiver'>(),
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
        market: market_key,
        initial_long_token: contract_address_const::<'long_token'>(),
        initial_short_token: contract_address_const::<'short_token'>(),
        long_token_swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        short_token_swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        min_market_tokens: 10,
        execution_fee: 0,
        callback_gas_limit: 10,
    };

    // Create deposit
    let deposit_key = exchange_router.create_deposit(deposit_params);

    // Check deposit
    let deposit = reader.get_deposit(data_store, deposit_key);

    assert(deposit.key == deposit_key, 'unexp. key');
    assert(deposit.account == caller_address, 'unexp. account');
    assert(deposit.receiver == contract_address_const::<'receiver'>(), 'unexp. receiver');
    assert(
        deposit.callback_contract == contract_address_const::<'callback_contract'>(),
        'unexp. callback_contract'
    );
    assert(
        deposit.ui_fee_receiver == contract_address_const::<'ui_fee_receiver'>(),
        'unexp. ui_fee_receiver'
    );
    assert(deposit.market == market.market_token, 'unexp. market');
    assert(
        deposit.initial_long_token == contract_address_const::<'long_token'>(),
        'unexp. initial_long_token'
    );
    assert(
        deposit.initial_short_token == contract_address_const::<'short_token'>(),
        'unexp. initial_short_token'
    );
    assert(deposit.min_market_tokens == 10, 'unexp. min_market_tokens');
    assert(
        deposit.execution_fee == 10, 'unexp. execution_fee'
    ); // Since mock deposit fee token in deposit vault, execution fee is set to 10
    assert(deposit.callback_gas_limit == 10, 'unexp. callback_gas_limit');
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
/// * `IReaderDispatcher` - The reader dispatcher.
/// * `IExchangeRouterDispatcher` - The exchange router dispatcher.
/// * `IDepositVaultDispatcher` - The deposit vault dispatcher.
fn setup() -> (
    ContractAddress,
    IRoleStoreDispatcher,
    IDataStoreDispatcher,
    IReaderDispatcher,
    IExchangeRouterDispatcher,
    IDepositVaultDispatcher
) {
    // Setup Oracle and Store
    let (caller_address, role_store, data_store, event_emitter, oracle) =
        tests_lib::setup_oracle_and_store();

    // Deploy tokens 
    deploy_erc20_tokens(caller_address);

    // Set fee token address
    data_store.set_address(keys::fee_token(), contract_address_const::<'fee_token'>());

    // Set max callback gas limit
    data_store.set_u128(keys::max_callback_gas_limit(), 100);

    // Deploy deposit vault
    let deposit_vault_address = deploy_deposit_vault(
        data_store.contract_address, role_store.contract_address
    );
    let deposit_vault = IDepositVaultDispatcher { contract_address: deposit_vault_address };
    start_prank(deposit_vault_address, caller_address);

    // Deploy deposit vault handler
    let deposit_handler_address = deploy_deposit_handler(
        data_store.contract_address,
        role_store.contract_address,
        event_emitter.contract_address,
        deposit_vault_address,
        oracle.contract_address
    );
    let deposit_handler = IDepositHandlerDispatcher { contract_address: deposit_handler_address };
    start_prank(deposit_handler_address, caller_address);

    // Deploy withdrawal vault
    let withdrawal_vault_address = deploy_withdrawal_vault(
        data_store.contract_address, role_store.contract_address
    );
    let withdrawal_vault = IWithdrawalVaultDispatcher {
        contract_address: withdrawal_vault_address
    };

    // Deploy withdrawal vault handler
    let withdrawal_handler_address = deploy_withdrawal_handler(
        data_store.contract_address,
        role_store.contract_address,
        event_emitter.contract_address,
        withdrawal_vault_address,
        oracle.contract_address
    );
    let withdrawal_handler = IWithdrawalHandlerDispatcher {
        contract_address: withdrawal_handler_address
    };

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
    let order_handler_address = deploy_order_handler(
        data_store.contract_address,
        role_store.contract_address,
        event_emitter.contract_address,
        order_vault_address,
        oracle.contract_address,
        swap_handler_address,
        referral_storage_address
    );
    let order_handler = IOrderHandlerDispatcher { contract_address: order_handler_address };

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
    start_prank(exchange_router_address, caller_address);

    // Deploy reader
    let reader_address = deploy_reader();
    let reader = IReaderDispatcher { contract_address: reader_address };

    // // deploy erc20 token
    // let erc20_contract_address = deploy_erc20_token(caller_address);
    // let erc20 = IERC20Dispatcher { contract_address: erc20_contract_address };

    // start prank and give controller role to caller_address
    //start_prank(deposit_vault.contract_address, caller_address);

    return (caller_address, role_store, data_store, reader, exchange_router, deposit_vault);
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
    let mut constructor_calldata = array![data_store_address.into(), role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
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
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
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
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
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
) -> ContractAddress {
    let contract = declare('OrderHandler');
    let deployed_contract_address = contract_address_const::<'order_handler'>();
    let constructor_calldata = array![
        data_store_address.into(),
        role_store_address.into(),
        event_emitter_address.into(),
        order_vault_address.into(),
        oracle_address.into(),
        swap_handler_address.into(),
        referral_storage_address.into()
    ];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

/// Utility function to deploy a record_transfer_in.
///
/// # Arguments
///
/// # Returns
///
/// * `ContractAddress` - The address of the reader.
fn deploy_reader() -> ContractAddress {
    let contract = declare('Reader');
    let deployed_contract_address = contract_address_const::<'reader'>();
    let constructor_calldata = array![];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
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
fn deploy_erc20_tokens(mint_address: ContractAddress) {
    let erc20_contract = declare('ERC20');

    let deployed_fee_token_address = contract_address_const::<'fee_token'>();
    let constructor_fee_token_calldata = array!['fee_token', 'FEE', 1000, 0, mint_address.into()];
    erc20_contract.deploy_at(@constructor_fee_token_calldata, deployed_fee_token_address);

    let deployed_long_token_address = contract_address_const::<'long_token'>();
    let constructor_long_token_calldata = array!['long_token', 'LNG', 1000, 0, mint_address.into()];
    erc20_contract.deploy_at(@constructor_long_token_calldata, deployed_long_token_address);

    let deployed_short_token_address = contract_address_const::<'short_token'>();
    let constructor_short_token_calldata = array![
        'short_token', 'SRT', 1000, 0, mint_address.into()
    ];
    erc20_contract.deploy_at(@constructor_short_token_calldata, deployed_short_token_address);
}
