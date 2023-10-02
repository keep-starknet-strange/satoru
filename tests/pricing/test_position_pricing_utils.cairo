use starknet::{ContractAddress, contract_address_const};
use satoru::price::price::Price;
use satoru::position::position::Position;
use satoru::pricing::position_pricing_utils;
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::mock::governable::{IGovernableDispatcher, IGovernableDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::market::market::Market;
use satoru::pricing::position_pricing_utils::{
    GetPositionFeesParams, PositionFundingFees, GetPriceImpactUsdParams
};
use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait};

// TODO add asserts for each test when possible

#[test]
fn given_normal_conditions_when_get_price_impact_usd_then_works() {
    let (caller_address, data_store, referral_storage) = setup();

    let get_price_impact_params = create_get_price_impact_usd_params(data_store);
    position_pricing_utils::get_price_impact_usd(get_price_impact_params);
}

#[test]
fn given_normal_conditions_when_get_next_open_interest_then_works() {
    let (caller_address, data_store, referral_storage) = setup();

    let get_price_impact_params = create_get_price_impact_usd_params(data_store);
    position_pricing_utils::get_next_open_interest(get_price_impact_params);
}

#[test]
fn given_normal_conditions_when_get_next_open_interest_for_virtual_inventory_then_works() {
    let (caller_address, data_store, referral_storage) = setup();

    let get_price_impact_params = create_get_price_impact_usd_params(data_store);
    position_pricing_utils::get_next_open_interest_for_virtual_inventory(
        get_price_impact_params, 50
    );
}

#[test]
fn given_normal_conditions_when_get_next_open_interest_params_then_works() {
    let (caller_address, data_store, referral_storage) = setup();

    let get_price_impact_params = create_get_price_impact_usd_params(data_store);
    position_pricing_utils::get_next_open_interest_params(get_price_impact_params, 100, 20);
}

#[test]
fn given_normal_conditions_when_get_position_fees_then_works() {
    let (caller_address, data_store, referral_storage) = setup();

    let position = Position {
        key: 1,
        account: contract_address_const::<'account'>(),
        market: contract_address_const::<'market'>(),
        collateral_token: contract_address_const::<'collateral_token'>(),
        size_in_usd: 100,
        size_in_tokens: 1,
        collateral_amount: 2,
        borrowing_factor: 3,
        funding_fee_amount_per_size: 4,
        long_token_claimable_funding_amount_per_size: 5,
        short_token_claimable_funding_amount_per_size: 6,
        increased_at_block: 15000,
        decreased_at_block: 15001,
        is_long: false
    };

    let collateral_token_price = Price { min: 5, max: 10, };

    GetPositionFeesParams {
        data_store,
        referral_storage,
        position,
        collateral_token_price,
        for_positive_impact: true,
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
        size_delta_usd: 10,
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>()
    };
}

#[test]
fn given_normal_conditions_when_get_borrowing_fees_then_works() {
    let (caller_address, data_store, referral_storage) = setup();
    let price = Price { min: 5, max: 10 };

    position_pricing_utils::get_borrowing_fees(data_store, price, 3);
}

#[test]
fn given_normal_conditions_when_get_funding_fees_then_works() {
    let (caller_address, data_store, referral_storage) = setup();
    let position_funding_fees = PositionFundingFees {
        funding_fee_amount: 10,
        claimable_long_token_amount: 100,
        claimable_short_token_amount: 50,
        latest_funding_fee_amount_per_size: 15,
        latest_long_token_claimable_funding_amount_per_size: 15,
        latest_short_token_claimable_funding_amount_per_size: 15,
    };

    let position = Position {
        key: 1,
        account: contract_address_const::<'account'>(),
        market: contract_address_const::<'market'>(),
        collateral_token: contract_address_const::<'collateral_token'>(),
        size_in_usd: 100,
        size_in_tokens: 1,
        collateral_amount: 2,
        borrowing_factor: 3,
        funding_fee_amount_per_size: 4,
        long_token_claimable_funding_amount_per_size: 5,
        short_token_claimable_funding_amount_per_size: 6,
        increased_at_block: 15000,
        decreased_at_block: 15001,
        is_long: false
    };

    position_pricing_utils::get_funding_fees(position_funding_fees, position);
}

#[test]
fn given_normal_conditions_when_get_ui_fees_then_works() {
    let (caller_address, data_store, referral_storage) = setup();
    let price = Price { min: 5, max: 10 };
    let ui_fee_receiver = contract_address_const::<'ui_fee_receiver'>();
    position_pricing_utils::get_ui_fees(data_store, price, 10, ui_fee_receiver);
}

#[test]
fn given_normal_conditions_when_get_position_fees_after_referral_then_works() {
    let (caller_address, data_store, referral_storage) = setup();
    let price = Price { min: 5, max: 10 };
    let account = contract_address_const::<'account'>();
    let market = contract_address_const::<'market'>();
    position_pricing_utils::get_position_fees_after_referral(
        data_store, referral_storage, price, true, account, market, 10
    );
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

fn deploy_referral_storage(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('ReferralStorage');
    let constructor_calldata = array![event_emitter_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_governable(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('Governable');
    let constructor_calldata = array![event_emitter_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    contract.deploy(@array![]).unwrap()
}

fn setup() -> (ContractAddress, IDataStoreDispatcher, IReferralStorageDispatcher) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();

    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    let event_emitter_address = deploy_event_emitter();
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    let referral_storage_address = deploy_referral_storage(event_emitter_address);
    let referral_storage = IReferralStorageDispatcher {
        contract_address: referral_storage_address
    };
    let governable_address = deploy_governable(event_emitter_address);
    let governable = IGovernableDispatcher { contract_address: governable_address };

    start_prank(event_emitter_address, caller_address);
    start_prank(data_store_address, caller_address);
    start_prank(referral_storage_address, caller_address);
    start_prank(governable_address, caller_address);

    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    (caller_address, data_store, referral_storage)
}


fn create_get_price_impact_usd_params(data_store: IDataStoreDispatcher) -> GetPriceImpactUsdParams {
    let market = Market {
        market_token: contract_address_const::<'market_token'>(),
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>()
    };

    GetPriceImpactUsdParams { data_store, market, usd_delta: 50, is_long: true }
}
