use starknet::{ContractAddress, contract_address_const};

use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait, PrintTrait};

use satoru::data::data_store::{DataStore, IDataStoreDispatcher};
use satoru::event::event_emitter::{EventEmitter, IEventEmitterDispatcher};
use satoru::oracle::oracle::{Oracle, IOracleDispatcher, IOracleDispatcherTrait, SetPricesParams};
use satoru::oracle::oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait};
use satoru::price::price::Price;
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;

// Panics due to the mocked IPriceFeed not returning data, triggering an error.
#[test]
#[should_panic()]
fn given_normal_conditions_when_set_prices_then_works() {
    let (controller, data_store, event_emitter, oracle) = setup();
    let params = mock_set_prices_params();

    start_prank(oracle.contract_address, controller);
    oracle.set_prices(data_store, event_emitter, params);
}

#[test]
fn given_normal_conditions_when_set_primary_price_then_works() {
    let (controller, data_store, event_emitter, oracle) = setup();

    let token = contract_address_const::<111>();
    let price = Price { min: 10, max: 11 };

    start_prank(oracle.contract_address, controller);
    oracle.set_primary_price(token, price);

    let price_from_view = oracle.get_primary_price(token);
    assert(
        price_from_view.min == price.min && price_from_view.max == price.max, 'wrong primary price'
    );
}

#[test]
fn given_normal_conditions_when_clear_all_prices_then_works() {
    let (controller, data_store, event_emitter, oracle) = setup();

    let token1 = contract_address_const::<111>();
    let price1 = Price { min: 10, max: 11 };
    let token2 = contract_address_const::<222>();
    let price2 = Price { min: 20, max: 22 };

    start_prank(oracle.contract_address, controller);
    oracle.set_primary_price(token1, price1);
    oracle.set_primary_price(token2, price2);
    assert(oracle.get_tokens_with_prices_count() == 2, 'wrong tokens count');

    oracle.clear_all_prices();
    assert(oracle.get_tokens_with_prices_count() == 0, 'wrong tokens count');
}

#[test]
fn given_normal_conditions_when_tokens_with_prices_count_then_works() {
    let (controller, data_store, event_emitter, oracle) = setup();
    let token1 = contract_address_const::<111>();
    let price1 = Price { min: 10, max: 11 };
    let token2 = contract_address_const::<222>();
    let price2 = Price { min: 20, max: 22 };
    let token3 = contract_address_const::<333>();
    let price3 = Price { min: 30, max: 33 };

    assert(oracle.get_tokens_with_prices_count() == 0, 'wrong tokens count');

    start_prank(oracle.contract_address, controller);
    oracle.set_primary_price(token1, price1);
    oracle.set_primary_price(token2, price2);
    oracle.set_primary_price(token3, price3);

    assert(oracle.get_tokens_with_prices_count() == 3, 'wrong tokens count');
}

#[test]
fn given_normal_conditions_when_get_tokens_with_prices_then_works() {
    let (controller, data_store, event_emitter, oracle) = setup();

    let prices = oracle.get_tokens_with_prices(0, 5);
    assert(prices == array![], 'wrong prices array');

    let token1 = contract_address_const::<111>();
    let price1 = Price { min: 10, max: 11 };
    let token2 = contract_address_const::<222>();
    let price2 = Price { min: 20, max: 22 };
    let token3 = contract_address_const::<333>();
    let price3 = Price { min: 30, max: 33 };

    start_prank(oracle.contract_address, controller);
    oracle.set_primary_price(token1, price1);
    oracle.set_primary_price(token2, price2);
    oracle.set_primary_price(token3, price3);

    let prices = oracle.get_tokens_with_prices(0, 0);
    assert(prices == array![], 'wrong prices array 0-0');
    let prices = oracle.get_tokens_with_prices(0, 1);
    assert(prices == array![token1], 'wrong prices array 0-1');
    let prices = oracle.get_tokens_with_prices(0, 2);
    assert(prices == array![token1, token2], 'wrong prices array 0-2');
    let prices = oracle.get_tokens_with_prices(0, 3);
    assert(prices == array![token1, token2, token3], 'wrong prices array 0-3');
    let prices = oracle.get_tokens_with_prices(0, 5);
    assert(prices == array![token1, token2, token3], 'wrong prices array 0-5');
    let prices = oracle.get_tokens_with_prices(1, 3);
    assert(prices == array![token2, token3], 'wrong prices array 1-3');
    let prices = oracle.get_tokens_with_prices(1, 5);
    assert(prices == array![token2, token3], 'wrong prices array 1-5');
    let prices = oracle.get_tokens_with_prices(2, 3);
    assert(prices == array![token3], 'wrong prices array 2-3');
    let prices = oracle.get_tokens_with_prices(2, 5);
    assert(prices == array![token3], 'wrong prices array 2-5');
}

#[test]
fn given_normal_conditions_when_get_primary_price_then_works() {
    let (controller, data_store, event_emitter, oracle) = setup();

    let token1 = contract_address_const::<111>();
    let price1 = Price { min: 10, max: 11 };
    let token2 = contract_address_const::<222>();
    let price2 = Price { min: 20, max: 22 };
    let token3 = contract_address_const::<333>();
    let price3 = Price { min: 30, max: 33 };

    start_prank(oracle.contract_address, controller);
    oracle.set_primary_price(token1, price1);
    oracle.set_primary_price(token2, price2);
    oracle.set_primary_price(token3, price3);
    assert(is_price_eq(oracle.get_primary_price(token1), price1), 'wrong price token-1');
    assert(is_price_eq(oracle.get_primary_price(token2), price2), 'wrong price token-2');
    assert(is_price_eq(oracle.get_primary_price(token3), price3), 'wrong price token-3');
}

#[test]
#[should_panic()]
fn given_normal_conditions_when_price_feed_multiplier_then_works() {
    let (controller, data_store, event_emitter, oracle) = setup();

    let token = contract_address_const::<111>();

    oracle.get_price_feed_multiplier(data_store, token);
}

#[test]
fn given_normal_conditions_when_validate_prices_then_works() {
    let (controller, data_store, event_emitter, oracle) = setup();
    let params: SetPricesParams = mock_set_prices_params();
    let token1 = contract_address_const::<111>();
    let price1 = Price { min: 10, max: 11 };
    let token2 = contract_address_const::<222>();
    let price2 = Price { min: 20, max: 22 };
    let token3 = contract_address_const::<333>();
    let price3 = Price { min: 30, max: 33 };

    start_prank(oracle.contract_address, controller);
    oracle.set_primary_price(token1, price1);
    oracle.set_primary_price(token2, price2);
    oracle.set_primary_price(token3, price3);

    let validated_prices = oracle.validate_prices(data_store, params);
}

fn setup() -> (ContractAddress, IDataStoreDispatcher, IEventEmitterDispatcher, IOracleDispatcher) {
    let caller_address = contract_address_const::<0x101>();
    let order_keeper = contract_address_const::<0x2233>();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };
    let oracle_store_address = deploy_oracle_store(role_store_address, event_emitter_address);
    let oracle_store = IOracleStoreDispatcher { contract_address: oracle_store_address };
    let oracle_address = deploy_oracle(oracle_store_address, role_store_address);
    let oracle = IOracleDispatcher { contract_address: oracle_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    role_store.grant_role(order_keeper, role::ORDER_KEEPER);
    oracle_store.add_signer(contract_address_const::<'signer'>());
    start_prank(data_store_address, caller_address);
    (caller_address, data_store, event_emitter, oracle)
}

fn deploy_oracle(
    oracle_address: ContractAddress, role_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('Oracle');
    let constructor_calldata = array![role_store_address.into(), oracle_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_oracle_store(
    role_store_address: ContractAddress, event_emitter_address: ContractAddress
) -> ContractAddress {
    let contract = declare('OracleStore');
    let constructor_calldata = array![role_store_address.into(), event_emitter_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
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

fn mock_set_prices_params() -> SetPricesParams {
    SetPricesParams {
        signer_info: 1,
        tokens: array![
            contract_address_const::<1>(),
            contract_address_const::<2>(),
            contract_address_const::<3>()
        ],
        compacted_min_oracle_block_numbers: array![0, 0, 0],
        compacted_max_oracle_block_numbers: array![6400, 6400, 6400],
        compacted_oracle_timestamps: array![0, 0, 0],
        compacted_decimals: array![18, 18, 18],
        compacted_min_prices: array![100, 200, 300],
        compacted_min_prices_indexes: array![1, 2, 3],
        compacted_max_prices: array![101, 201, 301],
        compacted_max_prices_indexes: array![1, 2, 3],
        signatures: array![1, 2, 3],
        price_feed_tokens: array![
            contract_address_const::<1>(),
            contract_address_const::<2>(),
            contract_address_const::<3>()
        ]
    }
}

fn is_price_eq(lhs: Price, rhs: Price) -> bool {
    lhs.min == rhs.min && lhs.max == rhs.max
}
