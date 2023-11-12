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
use satoru::position::{
    position::Position, position_utils::UpdatePositionParams,
    position_utils::WillPositionCollateralBeSufficientValues, position_utils
};
use satoru::tests_lib::{setup, setup_event_emitter, teardown};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::pricing::position_pricing_utils::{PositionFees, PositionReferralFees};
use satoru::order::{
    order::{Order, SecondaryOrderType, OrderType, DecreasePositionSwapType},
    order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait}
};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::order::base_order_utils::ExecuteOrderParamsContracts;
use satoru::utils::i128::{i128, i128_new};
#[test]
fn given_normal_conditions_when_get_position_key_then_works() {
    // 
    // Setup  
    //   
    let account: ContractAddress = contract_address_const::<'account'>();
    let market: ContractAddress = contract_address_const::<'market'>();
    let token: ContractAddress = contract_address_const::<'token'>();
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
fn given_empty_position_when_validate_non_empty_position_then_fails() {
    // 
    // Setup  
    //   
    let position: Position = Default::default();

    // Test
    position_utils::validate_non_empty_position(position);
}

#[test]
fn given_normal_conditions_when_validate_non_empty_position_then_works() {
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
fn given_invalid_position_size_when_validate_position_then_fails() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();

    let referral_storage = IReferralStorageDispatcher {
        contract_address: contract_address_const::<'12345'>()
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
fn given_empty_market_when_validate_position_then_fails() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();

    let referral_storage = IReferralStorageDispatcher {
        contract_address: contract_address_const::<'12345'>()
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
#[should_panic(expected: ('minimum_position_size',))]
fn given_minimum_position_size_when_validate_position_then_fails() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();

    let referral_storage = IReferralStorageDispatcher {
        contract_address: contract_address_const::<'12345'>()
    };
    let token: ContractAddress = contract_address_const::<'token'>();

    let mut position: Position = Default::default();
    let mut market: Market = Default::default();
    // Set valid pos size valeus
    position.size_in_usd = 100;
    position.size_in_tokens = 10;

    // Set valid market colleteral tokens  (positon.collateral_token == market.long_token || token == market.short_token;)
    position.collateral_token = token;
    market.long_token = token;
    market.market_token = contract_address_const::<'market_token'>();

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
fn given_normal_conditions_when_increment_claimable_funding_amount_then_works() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();
    let (event_emitter_address, event_emitter) = setup_event_emitter();

    let market_token: ContractAddress = contract_address_const::<'market_token'>();
    let long_token: ContractAddress = contract_address_const::<'long_token'>();
    let short_token: ContractAddress = contract_address_const::<'short_token'>();
    let account: ContractAddress = contract_address_const::<'account'>();
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


/// Utility function to deploy a `ReferralStorage` contract and return its dispatcher.
fn deploy_referral_storage(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('ReferralStorage');
    let constructor_calldata = array![event_emitter_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}


#[test]
fn given_negative_remaining_collateral_usd_when_checking_liquidatability_then_invalid_position() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();
    let (event_emitter_address, event_emitter) = setup_event_emitter();

    let referral_storage_address: ContractAddress = deploy_referral_storage(event_emitter_address);

    let referral_storage = IReferralStorageDispatcher {
        contract_address: referral_storage_address
    };

    let market_token: ContractAddress = contract_address_const::<'market_token'>();
    let long_token: ContractAddress = contract_address_const::<'long_token'>();
    let short_token: ContractAddress = contract_address_const::<'short_token'>();

    //Create a long position
    let mut position: Position = Default::default();
    position.size_in_usd = 10000;
    position.collateral_amount = 10;
    position.borrowing_factor = 2;
    position.size_in_tokens = 50;
    position.is_long = true;
    position.collateral_token = long_token;
    position.market = market_token;

    // Fill required data store keys.

    // setting long interest greater than te position size in USD...
    let open_interest_key = keys::open_interest_key(market_token, long_token, true);
    data_store.set_u128(open_interest_key, 15000);

    // setting cumulative borrowing factor greater than the borrowing factor...
    let cumulative_borrowing_factor_key = keys::cumulative_borrowing_factor_key(market_token, true);
    data_store.set_u128(cumulative_borrowing_factor_key, 1000);

    let market = Market { market_token, index_token: long_token, long_token, short_token, };

    let long_token_price = Price { min: 100, max: 110 };
    let index_token_price = Price { min: 100, max: 110 };
    let short_token_price = Price { min: 100, max: 110 };

    let prices: MarketPrices = MarketPrices {
        index_token_price: index_token_price,
        long_token_price: long_token_price,
        short_token_price: short_token_price
    };

    // Test

    let (is_liquiditable, reason) = position_utils::is_position_liquiditable(
        data_store, referral_storage, position, market, prices, false
    );

    assert(is_liquiditable, 'Invalid position liquidation');
    assert(reason == '0<', 'Invalid liquidation reason');
}


#[test]
fn given_below_minimum_collateral_when_checking_liquidatability_then_invalid_position() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();
    let (event_emitter_address, event_emitter) = setup_event_emitter();

    let referral_storage_address: ContractAddress = deploy_referral_storage(event_emitter_address);

    let referral_storage = IReferralStorageDispatcher {
        contract_address: referral_storage_address
    };

    let market_token: ContractAddress = contract_address_const::<'market_token'>();
    let long_token: ContractAddress = contract_address_const::<'long_token'>();
    let short_token: ContractAddress = contract_address_const::<'short_token'>();

    //Create a long position
    let mut position: Position = Default::default();
    position.size_in_usd = 10000;
    position.collateral_amount = 10;
    position.borrowing_factor = 2;
    position.size_in_tokens = 50;
    position.is_long = true;
    position.collateral_token = long_token;
    position.market = market_token;

    // Fill required data store keys.

    // setting long interest greater than te position size in USD...
    let open_interest_key = keys::open_interest_key(market_token, long_token, true);
    data_store.set_u128(open_interest_key, 15000);

    // setting cumulative borrowing factor greater than the borrowing factor...
    let cumulative_borrowing_factor_key = keys::cumulative_borrowing_factor_key(market_token, true);
    data_store.set_u128(cumulative_borrowing_factor_key, 1000);

    let market = Market { market_token, index_token: long_token, long_token, short_token, };

    let long_token_price = Price { min: 100, max: 110 };
    let index_token_price = Price { min: 100, max: 110 };
    let short_token_price = Price { min: 100, max: 110 };

    let prices: MarketPrices = MarketPrices {
        index_token_price: index_token_price,
        long_token_price: long_token_price,
        short_token_price: short_token_price
    };

    // Test

    let (is_liquiditable, reason) = position_utils::is_position_liquiditable(
        data_store, referral_storage, position, market, prices, true
    );

    assert(is_liquiditable, 'Invalid position liquidation');
    assert(reason == 'min collateral', 'Invalid liquidation reason');
}

#[test]
fn given_valid_position_when_checking_liquidatability_then_valid_position() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();
    let (event_emitter_address, event_emitter) = setup_event_emitter();

    let referral_storage_address: ContractAddress = deploy_referral_storage(event_emitter_address);

    let referral_storage = IReferralStorageDispatcher {
        contract_address: referral_storage_address
    };

    let market_token: ContractAddress = contract_address_const::<'market_token'>();
    let long_token: ContractAddress = contract_address_const::<'long_token'>();
    let short_token: ContractAddress = contract_address_const::<'short_token'>();

    //Create a long position
    let mut position: Position = Default::default();
    position.size_in_usd = 10000;
    position.collateral_amount = 1000;
    position.borrowing_factor = 2;
    position.size_in_tokens = 50;
    position.is_long = true;
    position.collateral_token = long_token;
    position.market = market_token;

    // Fill required data store keys.

    // setting long interest greater than te position size in USD...
    let open_interest_key = keys::open_interest_key(market_token, long_token, true);
    data_store.set_u128(open_interest_key, 15000);

    // setting cumulative borrowing factor greater than the borrowing factor...
    let cumulative_borrowing_factor_key = keys::cumulative_borrowing_factor_key(market_token, true);
    data_store.set_u128(cumulative_borrowing_factor_key, 1000);

    let market = Market { market_token, index_token: long_token, long_token, short_token, };

    let long_token_price = Price { min: 100, max: 110 };
    let index_token_price = Price { min: 100, max: 110 };
    let short_token_price = Price { min: 100, max: 110 };

    let prices: MarketPrices = MarketPrices {
        index_token_price: index_token_price,
        long_token_price: long_token_price,
        short_token_price: short_token_price
    };

    // Test

    let (is_liquiditable, reason) = position_utils::is_position_liquiditable(
        data_store, referral_storage, position, market, prices, true
    );

    assert(!is_liquiditable, 'Invalid position liquidation');
    assert(reason == '', 'Invalid liquidation reason');
}

#[test]
fn given_below_min_collateral_leverage_when_checking_liquidatability_then_invalid_position() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();
    let (event_emitter_address, event_emitter) = setup_event_emitter();

    let referral_storage_address: ContractAddress = deploy_referral_storage(event_emitter_address);

    let referral_storage = IReferralStorageDispatcher {
        contract_address: referral_storage_address
    };

    let market_token: ContractAddress = contract_address_const::<'market_token'>();
    let long_token: ContractAddress = contract_address_const::<'long_token'>();
    let short_token: ContractAddress = contract_address_const::<'short_token'>();

    //Create a long position
    let mut position: Position = Default::default();
    position.size_in_usd = 10000;
    position.collateral_amount = 60;
    position.borrowing_factor = 2;
    position.size_in_tokens = 50;
    position.is_long = true;
    position.collateral_token = long_token;
    position.market = market_token;

    // Fill required data store keys.

    // setting long interest greater than te position size in USD...
    let open_interest_key = keys::open_interest_key(market_token, long_token, true);
    data_store.set_u128(open_interest_key, 15000);

    // setting cumulative borrowing factor greater than the borrowing factor...
    let cumulative_borrowing_factor_key = keys::cumulative_borrowing_factor_key(market_token, true);
    data_store.set_u128(cumulative_borrowing_factor_key, 1000);

    // setting a min collateral factor for the market
    let min_collateral_factor_key = keys::min_collateral_factor_key(market_token);
    data_store.set_u128(min_collateral_factor_key, 10_000_000_000_000_000_000);

    let market = Market { market_token, index_token: long_token, long_token, short_token, };

    let long_token_price = Price { min: 100, max: 110 };
    let index_token_price = Price { min: 100, max: 110 };
    let short_token_price = Price { min: 100, max: 110 };

    let prices: MarketPrices = MarketPrices {
        index_token_price: index_token_price,
        long_token_price: long_token_price,
        short_token_price: short_token_price
    };

    // Test

    let (is_liquiditable, reason) = position_utils::is_position_liquiditable(
        data_store, referral_storage, position, market, prices, false
    );

    assert(is_liquiditable, 'Invalid position liquidation');
    assert(reason == 'min collateral for leverage', 'Invalid liquidation reason');
}


#[test]
fn given_initial_total_borrowing_when_updating_then_correct_total_borrowing() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();
    let (event_emitter_address, event_emitter) = setup_event_emitter();

    let market_token: ContractAddress = contract_address_const::<'market_token'>();
    let long_token: ContractAddress = contract_address_const::<'long_token'>();
    let short_token: ContractAddress = contract_address_const::<'short_token'>();

    // Fill required data store keys.
    let total_borrowing_key = keys::total_borrowing_key(market_token, false);
    data_store.set_u128(total_borrowing_key, 1000);

    let mut params: position_utils::UpdatePositionParams = UpdatePositionParams {
        contracts: ExecuteOrderParamsContracts {
            data_store,
            event_emitter,
            order_vault: IOrderVaultDispatcher { contract_address: Zeroable::zero() },
            oracle: IOracleDispatcher { contract_address: Zeroable::zero() },
            swap_handler: ISwapHandlerDispatcher { contract_address: Zeroable::zero() },
            referral_storage: IReferralStorageDispatcher { contract_address: Zeroable::zero() },
        },
        market: Market { market_token, index_token: long_token, long_token, short_token, },
        order: Default::default(),
        order_key: 0,
        position: Default::default(),
        position_key: 0,
        secondary_order_type: SecondaryOrderType::None,
    };

    //Test

    //Update total borrowing 
    let next_position_size_in_usd: u128 = 1000000000000000;
    let next_position_borrowing_factor: u128 = 20000000;

    position_utils::update_total_borrowing(
        params, next_position_size_in_usd, next_position_borrowing_factor
    );

    let total_borrowing_value: u128 = data_store.get_u128(total_borrowing_key);
    assert(total_borrowing_value == 1200, 'Invalid total borrowing')
}

#[test]
fn given_initial_open_interest_when_updating_then_correct_open_interest() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();
    let (event_emitter_address, event_emitter) = setup_event_emitter();

    let market_token: ContractAddress = contract_address_const::<'market_token'>();
    let long_token: ContractAddress = contract_address_const::<'long_token'>();
    let short_token: ContractAddress = contract_address_const::<'short_token'>();

    // Fill required data store keys.
    let key_open_interest = keys::open_interest_key(
        market_token, contract_address_const::<0>(), false
    );
    data_store.set_u128(key_open_interest, 1000);

    let key_open_interest_in_tokens = keys::open_interest_in_tokens_key(
        market_token, contract_address_const::<0>(), false
    );
    data_store.set_u128(key_open_interest_in_tokens, 2000);

    let mut params: position_utils::UpdatePositionParams = UpdatePositionParams {
        contracts: ExecuteOrderParamsContracts {
            data_store,
            event_emitter,
            order_vault: IOrderVaultDispatcher { contract_address: Zeroable::zero() },
            oracle: IOracleDispatcher { contract_address: Zeroable::zero() },
            swap_handler: ISwapHandlerDispatcher { contract_address: Zeroable::zero() },
            referral_storage: IReferralStorageDispatcher { contract_address: Zeroable::zero() },
        },
        market: Market { market_token, index_token: long_token, long_token, short_token, },
        order: Default::default(),
        order_key: 0,
        position: Default::default(),
        position_key: 0,
        secondary_order_type: SecondaryOrderType::None,
    };

    //Update open interest 
    let size_delta_usd: i128 = 10.try_into().unwrap();
    let size_delta_in_tokens: i128 = 20.try_into().unwrap();

    //Test

    position_utils::update_open_interest(params, size_delta_usd, size_delta_in_tokens);

    let open_interest = data_store.get_u128(key_open_interest);

    let open_interest_in_tokens = data_store.get_u128(key_open_interest_in_tokens);

    assert(open_interest == 1010, 'Invalid open interest value');
    assert(open_interest_in_tokens == 2020, 'Invalid open interest value');
}

#[test]
fn given_valid_referral_when_handling_then_referral_successfully_processed() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();
    let (event_emitter_address, event_emitter) = setup_event_emitter();

    let market_token: ContractAddress = contract_address_const::<'market_token'>();
    let long_token: ContractAddress = contract_address_const::<'long_token'>();
    let short_token: ContractAddress = contract_address_const::<'short_token'>();

    let mut fees: PositionFees = Default::default();
    let mut referral: PositionReferralFees = Default::default();

    referral.affiliate = contract_address_const::<'1'>();
    referral.affiliate_reward_amount = 20;
    fees.referral = referral;

    // Fill required data store keys.
    let affiliate_reward_for_account_key = keys::affiliate_reward_for_account_key(
        market_token, contract_address_const::<0>(), referral.affiliate
    );
    data_store.set_u128(affiliate_reward_for_account_key, 10);

    let mut params: position_utils::UpdatePositionParams = UpdatePositionParams {
        contracts: ExecuteOrderParamsContracts {
            data_store,
            event_emitter,
            order_vault: IOrderVaultDispatcher { contract_address: Zeroable::zero() },
            oracle: IOracleDispatcher { contract_address: Zeroable::zero() },
            swap_handler: ISwapHandlerDispatcher { contract_address: Zeroable::zero() },
            referral_storage: IReferralStorageDispatcher { contract_address: Zeroable::zero() },
        },
        market: Market { market_token, index_token: long_token, long_token, short_token, },
        order: Default::default(),
        order_key: 0,
        position: Default::default(),
        position_key: 0,
        secondary_order_type: SecondaryOrderType::None,
    };

    //Attribute position.market to the market instance define above

    params.position.market = params.market.market_token;

    //Test 

    position_utils::handle_referral(params, fees);
    let affiliate_reward_value = data_store.get_u128(affiliate_reward_for_account_key);

    assert(affiliate_reward_value == 30, 'Invalide affiliate reward value')
}


#[test]
fn test_will_position_collateral_be_sufficient() {
    // Setup
    let (caller_address, role_store, data_store) = setup();

    let market_token: ContractAddress = contract_address_const::<'market_token'>();
    let long_token: ContractAddress = contract_address_const::<'long_token'>();
    let short_token: ContractAddress = contract_address_const::<'short_token'>();
    let market: Market = Market { market_token, index_token: long_token, long_token, short_token };

    let long_token_price = Price { min: 100, max: 110 };
    let index_token_price = Price { min: 100, max: 110 };
    let short_token_price = Price { min: 100, max: 110 };

    // setting long interest greater than te position size in USD...
    let open_interest_key = keys::open_interest_key(market_token, long_token, true);
    data_store.set_u128(open_interest_key, 15000);

    // setting a min collateral factor for the market
    let min_collateral_factor_key = keys::min_collateral_factor_key(market_token);
    data_store.set_u128(min_collateral_factor_key, 10_000_000_000_000_000_000);

    let prices: MarketPrices = MarketPrices {
        index_token_price: index_token_price,
        long_token_price: long_token_price,
        short_token_price: short_token_price
    };

    let values: WillPositionCollateralBeSufficientValues =
        WillPositionCollateralBeSufficientValues {
        position_size_in_usd: 1000,
        position_collateral_amount: 50,
        realized_pnl_usd: i128_new(10, true),
        open_interest_delta: i128_new(5, true),
    };

    // invoke the function with scenario where collateral will be sufficient
    let (will_be_sufficient, remaining_collateral_usd) =
        position_utils::will_position_collateral_be_sufficient(
        data_store, market, prices, long_token, true, values
    );
    assert(will_be_sufficient, 'collateral supposed sufficient');
    assert(remaining_collateral_usd == i128_new(4990, false), 'eq 4990');

    let values: WillPositionCollateralBeSufficientValues =
        WillPositionCollateralBeSufficientValues {
        position_size_in_usd: 1000,
        position_collateral_amount: 5,
        realized_pnl_usd: i128_new(410, true),
        open_interest_delta: i128_new(5, true),
    };

    // invoke the function with scenario where collateral will be insufficient
    let (will_be_sufficient, remaining_collateral_usd) =
        position_utils::will_position_collateral_be_sufficient(
        data_store, market, prices, long_token, true, values
    );
    // assert that the function returns that the collateral is not sufficient
    assert(!will_be_sufficient, 'collateral should insufficient');
    assert(remaining_collateral_usd == i128_new(90, false), 'eq 90');
}
//TODO
// #[test]
// fn test_update_funding_and_borrowing_state() {
// }


