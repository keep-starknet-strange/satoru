// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.

use result::ResultTrait;
use traits::{TryInto, Into};
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
    ClassHash,
};
use debug::PrintTrait;
use snforge_std::{declare, start_prank, stop_prank, start_warp, ContractClassTrait, ContractClass};
use poseidon::poseidon_hash_span;
use zeroable::Zeroable;
// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::chain::chain::{IChainDispatcher, IChainDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::market::market_factory::{IMarketFactoryDispatcher, IMarketFactoryDispatcherTrait};
use satoru::market::market::{Market, UniqueIdMarket, IntoMarketToken};
use satoru::market::{market_utils::MarketPrices};
use satoru::market::market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait};
use satoru::data::keys;
use satoru::role::role;
use satoru::price::price::{Price, PriceTrait};
use satoru::position::{position::Position, position_utils::UpdatePositionParams, position_utils};
use satoru::tests_lib::{setup, setup_event_emitter, teardown};
use satoru::referral::referral_storage::interface::{
    IReferralStorageDispatcher, IReferralStorageDispatcherTrait
};
use satoru::pricing::{position_pricing_utils::PositionFees};
use satoru::order::{
    order::{Order, SecondaryOrderType, OrderType, DecreasePositionSwapType},
    order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait}
};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::order::base_order_utils::ExecuteOrderParamsContracts;
#[test]
fn test_get_position_key() {
    // 
    // Setup  
    //   
    let account: ContractAddress = 'account'.try_into().unwrap();
    let market: ContractAddress = 'market'.try_into().unwrap();
    let token: ContractAddress = 'token'.try_into().unwrap();
    let mut data = array![account.into(), market.into(), token.into(), false.into()];
    let mut data2 = array![account.into(), market.into(), token.into(), true.into()];
    let key_1 = poseidon_hash_span(data.span());
    let key_2 = poseidon_hash_span(data2.span());

    // Test
    let retrieved_key1 = position_utils::get_position_key(account, market, token, false);
    let retrieved_key2 = position_utils::get_position_key(account, market, token, true);
    assert(key_1 == retrieved_key1, 'invalid key1');
    assert(key_2 == retrieved_key2, 'invalid key2');
}


#[test]
#[should_panic(expected: ('empty_position',))]
fn test_validate_non_empty_fail() {
    // 
    // Setup  
    //   
    let position: Position = Default::default();

    // Test
    position_utils::validate_non_empty_position(position);
}

#[test]
fn test_validate_non_empty() {
    // 
    // Setup  
    //   

    let mut position: Position = Default::default();
    position.size_in_tokens = 123;

    // Test

    position_utils::validate_non_empty_position(position);

    position.size_in_tokens = 0;
    position.collateral_amount = 123;

    position_utils::validate_non_empty_position(position);
}

#[test]
#[should_panic(expected: ('invalid_position_size_values',))]
fn test_invalid_pos_size() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();

    let referral_storage = IReferralStorageDispatcher {
        contract_address: '12345'.try_into().unwrap()
    };

    let position: Position = Default::default();
    let market: Market = Default::default();
    let price = Price { min: 0, max: 0 };
    let prices: MarketPrices = MarketPrices {
        index_token_price: price, long_token_price: price, short_token_price: price
    };
    // Test
    position_utils::validate_position(
        data_store, referral_storage, position, market, prices, false, false
    );
    teardown(data_store.contract_address);
}

#[test]
#[should_panic(expected: ('empty_market',))]
fn test_validate_pos_empty_market() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();

    let referral_storage = IReferralStorageDispatcher {
        contract_address: '12345'.try_into().unwrap()
    };

    let mut position: Position = Default::default();
    // Set valid pos size valeus
    position.size_in_usd = 100;
    position.size_in_tokens = 10;

    let market: Market = Default::default();
    let price = Price { min: 0, max: 0 };
    let prices: MarketPrices = MarketPrices {
        index_token_price: price, long_token_price: price, short_token_price: price
    };

    // Test
    // Should fail at 'validate_enabled_market'
    position_utils::validate_position(
        data_store, referral_storage, position, market, prices, false, false
    );
    teardown(data_store.contract_address);
}


#[test]
#[should_panic(expected: ('minumum position size',))]
fn test_validate_position_min_pos() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();

    let referral_storage = IReferralStorageDispatcher {
        contract_address: '12345'.try_into().unwrap()
    };
    let token: ContractAddress = 'token'.try_into().unwrap();

    let mut position: Position = Default::default();
    let mut market: Market = Default::default();
    // Set valid pos size valeus
    position.size_in_usd = 100;
    position.size_in_tokens = 10;

    // Set valid market colleteral tokens  (positon.collateral_token == market.long_token || token == market.short_token;)
    position.collateral_token = token;
    market.long_token = token;
    market.market_token = 'market_token'.try_into().unwrap();

    let price = Price { min: 0, max: 0 };
    let prices: MarketPrices = MarketPrices {
        index_token_price: price, long_token_price: price, short_token_price: price
    };
    let should_validate_min_position_size = true;

    // Test

    let min_size: u128 = 1000000;
    data_store.set_u128(keys::min_position_size_usd(), min_size);
    data_store.set_bool(keys::is_market_disabled_key(market.market_token), false);
    // Check key assigned
    let retrieved_size = data_store.get_u128(keys::min_position_size_usd());
    assert(retrieved_size == min_size, 'invalid key assignment');

    // Fail 
    position_utils::validate_position(
        data_store,
        referral_storage,
        position,
        market,
        prices,
        should_validate_min_position_size,
        false
    );
    teardown(data_store.contract_address);
}

#[test]
fn test_increment_claimable_funding_amount() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();
    let (event_emitter_address, event_emitter) = setup_event_emitter();

    let market_token: ContractAddress = 'market_token'.try_into().unwrap();
    let long_token: ContractAddress = 'long_token'.try_into().unwrap();
    let short_token: ContractAddress = 'short_token'.try_into().unwrap();
    let account: ContractAddress = 'account'.try_into().unwrap();
    let long_token_amount: u128 = 10000;
    let short_token_amount: u128 = 20000;

    let mut fees: PositionFees = Default::default();

    let mut params: position_utils::UpdatePositionParams = UpdatePositionParams {
        contracts: ExecuteOrderParamsContracts {
            data_store,
            event_emitter,
            order_vault: IOrderVaultDispatcher { contract_address: Zeroable::zero() },
            oracle: IOracleDispatcher { contract_address: Zeroable::zero() },
            swap_handler: ISwapHandlerDispatcher { contract_address: Zeroable::zero() },
            referral_storage: IReferralStorageDispatcher { contract_address: Zeroable::zero() },
        },
        market: Market { market_token, index_token: Zeroable::zero(), long_token, short_token, },
        order: Default::default(),
        order_key: 0,
        position: Default::default(),
        position_key: 0,
        secondary_order_type: SecondaryOrderType::None,
    };

    params.order.account = account;
    fees.funding.claimable_long_token_amount = long_token_amount;
    fees.funding.claimable_short_token_amount = short_token_amount;

    // Test

    position_utils::increment_claimable_funding_amount(params, fees,);

    let claimable_fund_long_key = keys::claimable_funding_amount_by_account_key(
        market_token, long_token, account
    );
    let claimable_fund_short_key = keys::claimable_funding_amount_by_account_key(
        market_token, short_token, account
    );

    // Check funding amounts increased for long and short tokens 
    let retrieved_claimable_long = data_store.get_u128(claimable_fund_long_key);
    let retrieved_claimable_short = data_store.get_u128(claimable_fund_short_key);
    assert(retrieved_claimable_long == long_token_amount, 'Invalid claimable for long');
    assert(retrieved_claimable_short == short_token_amount, 'Invalid claimable for short');

    let mut fees2: PositionFees = Default::default();
    fees2.funding.claimable_long_token_amount = 0;
    fees2.funding.claimable_short_token_amount = 0;
    position_utils::increment_claimable_funding_amount(params, fees2);

    // Check funding amounts doesnt change
    let retrieved_claimable_long = data_store.get_u128(claimable_fund_long_key);
    let retrieved_claimable_short = data_store.get_u128(claimable_fund_short_key);
    assert(retrieved_claimable_long == long_token_amount, 'Invalid claimable for long');
    assert(retrieved_claimable_short == short_token_amount, 'Invalid claimable for short');

    teardown(data_store.contract_address);
}
// TODO 
// Missing libraries
//fn test_is_position_liquiditable() {
// 

// TODO 
// Missing libraries
//fn test_will_position_collateral_be_sufficient() {
// 

// TODO 
// Missing libraries
//fn test_update_funding_and_borrowing_state() {
// 

// TODO 
// Missing libraries
//fn test_update_total_borrowing() {
// 

// TODO 
// Missing libraries
//fn test_update_open_interest() {
// 

// TODO 
// Missing libraries
//fn test_handle_referral() {
// 


