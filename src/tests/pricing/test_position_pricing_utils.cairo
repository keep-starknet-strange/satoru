use starknet::{ContractAddress, contract_address_const};
use satoru::pricing::position_pricing_utils;

#[test]
fn given_normal_conditions_when_get_price_impact_usd() {
    let (caller_address, data_store) = setup();

    let get_price_impact_params = create_get_price_impact_usd_params(data_store);
    position_pricing_utils::get_price_impact_usd(get_price_impact_params);
}

#[test]
fn given_normal_conditions_when_get_next_open_interest() {
    let (caller_address, data_store) = setup();

    let get_price_impact_params = create_get_price_impact_usd_params(data_store);
    position_pricing_utils::get_next_open_interest(get_price_impact_params);
}

#[test]
fn given_normal_conditions_when_get_next_open_interest_for_virtual_inventory() {
    let (caller_address, data_store) = setup();

    let get_price_impact_params = create_get_price_impact_usd_params(data_store);
    position_pricing_utils::get_next_open_interest_for_virtual_inventory(get_price_impact_params, 50);
}

#[test]
fn given_normal_conditions_when_get_next_open_interest_params() {
    let (caller_address, data_store) = setup();

    let get_price_impact_params = create_get_price_impact_usd_params(data_store);
    position_pricing_utils::get_next_open_interest_params(get_price_impact_params, 100, 20);
}

#[test]
fn given_normal_conditions_when_get_position_fees() {
    let (caller_address, data_store) = setup();

    let get_price_impact_params = create_get_price_impact_usd_params(data_store);
    position_pricing_utils::get_position_fees(get_price_impact_params);
}

#[test]
fn given_normal_conditions_when_get_borrowing_fees() {
    let (caller_address, data_store) = setup();
    let price = Price {
        min: 5,
        max: 10,
    }

    let get_price_impact_params = create_get_price_impact_usd_params(data_store);
    position_pricing_utils::get_position_fees(data_store, price, 3);
}

// #[test]
// #[should_panic(expected: ('null_account',))]
// fn given_account_null_when_validate_account_then_fails() {
//     let account = contract_address_const::<0>();
//     validate_account(account);
// }

fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@array![]).unwrap()
}

fn setup() -> (ContractAddress, IDataStoreDispatcher) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    (caller_address, data_store)
}


fn create_get_price_impact_usd_params(data_store: IDataStoreDispatcher) -> GetPriceImpactUsdParams {
    let market = Market {
        market_token: contract_address_const::<'market_token'>(),
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>()
    };
    
    GetPriceImpactUsdParams {
        data_store,
        market,
        usd_delta: 50,
        is_long: true
    }
}