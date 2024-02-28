// Core lib imports.
use snforge_std::{declare, ContractClassTrait, start_prank, ContractClass};
use array::ArrayTrait;
use core::traits::Into;
use starknet::{get_caller_address, ContractAddress, contract_address_const,};

// Local imports.
use satoru::tests_lib::{teardown};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::{data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait}, keys};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::swap::swap_utils::SwapParams;
use satoru::role::role;
use satoru::market::market::Market;
use satoru::market::market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait};
use satoru::price::price::{Price, PriceTrait};
use satoru::tests_lib::{deploy_oracle_store, deploy_oracle};
use satoru::market::market_factory::{IMarketFactoryDispatcher, IMarketFactoryDispatcherTrait};
use debug::PrintTrait;


//TODO Tests need to be added after implementation of swap_utils

fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'data_store'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'event_emitter'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![], deployed_contract_address).unwrap()
}

/// Utility function to deploy a `Bank` contract and return its dispatcher.
fn deploy_bank_address(
    data_store_address: ContractAddress, role_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('Bank');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'bank'>();
    start_prank(deployed_contract_address, caller_address);
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}


/// Utility function to deploy a `SwapHandler` contract and return its dispatcher.
fn deploy_swap_handler_address(
    role_store_address: ContractAddress, data_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('SwapHandler');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'swap_handler'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'role_store'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![caller_address.into()], deployed_contract_address).unwrap()
}

fn deploy_tokens() -> (ContractAddress, ContractAddress, ContractAddress) {
    let contract = declare('ERC20');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let constructor_calldata = array!['satoru_index', 'STU', 4000, 0, caller_address.into()];
    let constructor_calldata1 = array!['satoru_long', 'STU', 4000, 0, caller_address.into()];
    let constructor_calldata2 = array!['satoru_short', 'STU', 4000, 0, caller_address.into()];

    (
        contract.deploy(@constructor_calldata).unwrap(),
        contract.deploy(@constructor_calldata1).unwrap(),
        contract.deploy(@constructor_calldata2).unwrap()
    )
}

fn deploy_market_factory(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    market_token_class_hash: ContractClass,
) -> ContractAddress {
    let contract = declare('MarketFactory');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'market_factory'>();
    start_prank(deployed_contract_address, caller_address);
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    constructor_calldata.append(event_emitter_address.into());
    constructor_calldata.append(market_token_class_hash.class_hash.into());
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn declare_market_token() -> ContractClass {
    declare('MarketToken')
}


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IDataStoreDispatcher` - The data store dispatcher.
/// * `IEventEmitterDispatcher` - The event emitter dispatcher.
/// * `IOracleDispatcher` - The oracle dispatcher dispatcher.
/// * `IBankDispatcher` - The bank dispatcher.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `ISwapHandlerDispatcher` - The swap handler dispatcher.
fn setup() -> (
    ContractAddress,
    IDataStoreDispatcher,
    IEventEmitterDispatcher,
    IOracleDispatcher,
    IBankDispatcher,
    IRoleStoreDispatcher,
    ISwapHandlerDispatcher,
    IMarketFactoryDispatcher,
    IERC20Dispatcher,
    IERC20Dispatcher,
    IERC20Dispatcher
) {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();

    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    let oracle_store_address = deploy_oracle_store(role_store_address, event_emitter_address);

    let oracle_address = deploy_oracle(
        role_store_address, oracle_store_address, contract_address_const::<'pragma'>()
    );
    let oracle = IOracleDispatcher { contract_address: oracle_address };

    let bank_address = deploy_bank_address(data_store_address, role_store_address);
    let bank = IBankDispatcher { contract_address: bank_address };

    let swap_handler_address = deploy_swap_handler_address(role_store_address, data_store_address);
    let swap_handler = ISwapHandlerDispatcher { contract_address: swap_handler_address };

    let (index_token_address, long_token_address, short_token_address) = deploy_tokens();
    let index_token_handler = IERC20Dispatcher { contract_address: index_token_address };
    let long_token_handler = IERC20Dispatcher { contract_address: long_token_address };
    let short_token_handler = IERC20Dispatcher { contract_address: short_token_address };

    let market_token_class_hash = declare_market_token();

    let market_factory_address = deploy_market_factory(
        data_store_address, role_store_address, event_emitter_address, market_token_class_hash
    );
    let market_factory = IMarketFactoryDispatcher { contract_address: market_factory_address };

    start_prank(role_store_address, caller_address);
    start_prank(data_store_address, caller_address);
    start_prank(event_emitter_address, caller_address);
    start_prank(oracle_address, caller_address);
    start_prank(bank_address, caller_address);
    start_prank(swap_handler_address, caller_address);
    start_prank(index_token_address, caller_address);
    start_prank(long_token_address, caller_address);
    start_prank(short_token_address, caller_address);
    // start_prank(market_token_address, caller_address);
    start_prank(market_factory_address, caller_address);

    // Grant the caller the `CONTROLLER` role.
    role_store.grant_role(caller_address, role::CONTROLLER);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);

    index_token_handler.mint(caller_address, 2000000000000000000);
    long_token_handler.mint(caller_address, 2000000000000000000);
    short_token_handler.mint(caller_address, 2000000000000000000);

    (
        caller_address,
        data_store,
        event_emitter,
        oracle,
        bank,
        role_store,
        swap_handler,
        market_factory,
        index_token_handler,
        long_token_handler,
        short_token_handler
    )
}


#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn given_caller_not_controller_when_swap_then_fails() {
    let (
        caller_address,
        data_store,
        event_emitter,
        oracle,
        bank,
        role_store,
        swap_handler,
        market_factory,
        index_token_handler,
        long_token_handler,
        short_token_handler
    ) =
        setup();

    // Revoke the caller the `CONTROLLER` role.
    role_store.revoke_role(caller_address, role::CONTROLLER);

    let mut market = Market {
        market_token: contract_address_const::<'market_token'>(),
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };

    let mut swap = SwapParams {
        data_store: data_store,
        event_emitter: event_emitter,
        oracle: oracle,
        bank: bank,
        key: 1,
        token_in: contract_address_const::<'token_in'>(),
        amount_in: 1,
        swap_path_markets: ArrayTrait::new().span(),
        min_output_amount: 1,
        receiver: contract_address_const::<'receiver'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
    };

    swap_handler.swap(swap);
    teardown(data_store.contract_address);
}


#[test]
fn given_amount_in_is_zero_then_works() {
    //Change that when swap_handler has been implemented
    let (
        caller_address,
        data_store,
        event_emitter,
        oracle,
        bank,
        role_store,
        swap_handler,
        market_factory,
        index_token_handler,
        long_token_handler,
        short_token_handler
    ) =
        setup();

    let mut market = Market {
        market_token: contract_address_const::<'market_token'>(),
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };

    let mut swap = SwapParams {
        data_store: data_store,
        event_emitter: event_emitter,
        oracle: oracle,
        bank: bank,
        key: 1,
        token_in: contract_address_const::<'token_in'>(),
        amount_in: 0,
        swap_path_markets: ArrayTrait::new().span(),
        min_output_amount: 1,
        receiver: contract_address_const::<'receiver'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
    };

    let swap_result = swap_handler.swap(swap);

    assert(swap_result == (contract_address_const::<'token_in'>(), 0), 'Error');

    teardown(role_store.contract_address);
}


#[test]
#[should_panic(expected: ('insufficient output amount', 1, 2))]
fn given_insufficient_output_then_fails() {
    //Change that when swap_handler has been implemented
    let (
        caller_address,
        data_store,
        event_emitter,
        oracle,
        bank,
        role_store,
        swap_handler,
        market_factory,
        index_token_handler,
        long_token_handler,
        short_token_handler
    ) =
        setup();

    let mut market = Market {
        market_token: contract_address_const::<'market_token'>(),
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };

    let mut swap = SwapParams {
        data_store: data_store,
        event_emitter: event_emitter,
        oracle: oracle,
        bank: bank,
        key: 1,
        token_in: contract_address_const::<'token_in'>(),
        amount_in: 1,
        swap_path_markets: ArrayTrait::new().span(),
        min_output_amount: 2,
        receiver: contract_address_const::<'receiver'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
    };

    let swap_result = swap_handler.swap(swap);

    assert(swap_result == (contract_address_const::<'token_in'>(), 1), 'Error');

    teardown(role_store.contract_address);
}

#[test]
fn given_normal_conditions_swap_then_works() {
    //Change that when swap_handler has been implemented
    let (
        caller_address,
        data_store,
        event_emitter,
        oracle,
        bank,
        role_store,
        swap_handler,
        market_factory,
        index_token_handler,
        long_token_handler,
        short_token_handler
    ) =
        setup();

    let mut market = Market {
        market_token: contract_address_const::<'market_token'>(),
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };

    let mut swap = SwapParams {
        data_store: data_store,
        event_emitter: event_emitter,
        oracle: oracle,
        bank: bank,
        key: 1,
        token_in: long_token_handler.contract_address,
        amount_in: 2,
        swap_path_markets: ArrayTrait::new().span(),
        min_output_amount: 1,
        receiver: contract_address_const::<'receiver'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
    };

    let swap_result = swap_handler.swap(swap);

    assert(swap_result == (long_token_handler.contract_address, 2), 'Error');

    teardown(role_store.contract_address);
}


#[test]
fn given_swap_path_market_then_works() {
    let (
        caller_address,
        data_store,
        event_emitter,
        oracle,
        bank,
        role_store,
        swap_handler,
        market_factory,
        index_token_handler,
        long_token_handler,
        short_token_handler
    ) =
        setup();

    //create Market 
    let index_token = index_token_handler.contract_address;
    let long_token = long_token_handler.contract_address;
    let short_token = short_token_handler.contract_address;
    let market_type = 'market_type';

    let market_token_deployed_address = market_factory
        .create_market(index_token, long_token, short_token, market_type);

    let mut market = Market {
        market_token: market_token_deployed_address,
        index_token: index_token,
        long_token: long_token,
        short_token: short_token,
    };
    let price = Price { min: 10, max: 100 };
    let key1 = keys::pool_amount_key(market_token_deployed_address, long_token);
    let key2 = keys::pool_amount_key(market_token_deployed_address, short_token);

    let key3 = keys::max_pool_amount_key(market_token_deployed_address, long_token);
    let key4 = keys::max_pool_amount_key(market_token_deployed_address, short_token);

    oracle.set_primary_price(index_token, price);
    oracle.set_primary_price(long_token, price);
    oracle.set_primary_price(short_token, price);

    data_store.set_market(market_token_deployed_address, 1, market);
    data_store.set_u256(key1, 361850278866613121369732);
    data_store.set_u256(key2, 361850278866613121369732);

    data_store.set_u256(key3, 661850278866613121369732);
    data_store.set_u256(key4, 661850278866613121369732);

    let mut swap_path_markets = ArrayTrait::<Market>::new();
    swap_path_markets.append(market);

    let mut swap = SwapParams {
        data_store: data_store,
        event_emitter: event_emitter,
        oracle: oracle,
        bank: bank,
        key: 1,
        token_in: long_token,
        amount_in: 200000000000000000,
        swap_path_markets: swap_path_markets.span(),
        min_output_amount: 1,
        receiver: market_token_deployed_address,
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
    };

    let swap_result = swap_handler.swap(swap);
    assert(swap_result == (short_token, 20000000000000000), 'Error');

    teardown(role_store.contract_address);
}
//TODO add more tested when swap_handler has been implemented


