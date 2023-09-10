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


// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::chain::chain::{IChainDispatcher, IChainDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::market::market_factory::{IMarketFactoryDispatcher, IMarketFactoryDispatcherTrait};
use satoru::market::market::{Market, UniqueIdMarket, IntoMarketToken};
use satoru::market::market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait};
use satoru::market::market_utils;
use satoru::data::keys;
use satoru::role::role;
use satoru::price::price::{Price, PriceTrait};

#[test]
fn given_normal_conditions_when_get_open_interest_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a market.
    let index_token = contract_address_const::<'index_token'>();
    let long_token = contract_address_const::<'long_token'>();
    let short_token = contract_address_const::<'short_token'>();
    let market_type = 'market_type';

    let (market_token_deployed_address, market_id) = market_factory
        .create_market(index_token, long_token, short_token, market_type);

    // Get the market from the data store.
    // This must not panic, because the market was created in the previous step.
    // Hence the market must exist in the data store and it's safe to unwrap.
    let market = data_store.get_market(market_id).unwrap();

    let collateral_token = contract_address_const::<'collateral_token'>();
    let is_long = true;
    let divisor = 3;

    let open_interest_data_store_key = keys::open_interest_key(
        market_token_deployed_address, collateral_token, is_long
    );
    data_store.set_u128(open_interest_data_store_key, 300);

    let open_interest = market_utils::get_open_interest(
        data_store, market_token_deployed_address, collateral_token, is_long, divisor
    );
    // Open interest is 300, so 300 / 3 = 100.
    assert(open_interest == 100, 'wrong open interest');

    let market_token = market.market_token();

    // Get the name of the market token.
    let market_token_name = market_token.name();
    assert(market_token_name == 'Satoru Market', 'wrong market token name');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}


#[test]
fn given_normal_conditions_when_get_open_interest_in_tokens_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let market_address = contract_address_const::<'market_address'>();
    let collateral_token = contract_address_const::<'collateral_token'>();
    let is_long = true;
    let divisor = 3;

    let open_interest_in_tokens_key = keys::open_interest_in_tokens_key(
        market_address, collateral_token, is_long
    );
    data_store.set_u128(open_interest_in_tokens_key, 300);

    let open_interest_in_tokens = market_utils::get_open_interest_in_tokens(
        data_store, market_address, collateral_token, is_long, divisor
    );
    // Open interest is 300, so 300 / 3 = 100.
    assert(open_interest_in_tokens == 100, 'wrong open interest');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn given_normal_conditions_when_get_open_interest_in_tokens_for_market_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test case.
    let market_token_address = contract_address_const::<'market_token'>();
    let market = Market {
        market_token: market_token_address,
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };
    let is_long = true;

    // Setup pre conditions.

    // Set open interest for long token.
    let open_interest_in_tokens_key_for_long = keys::open_interest_in_tokens_key(
        market_token_address, market.long_token, is_long
    );
    data_store.set_u128(open_interest_in_tokens_key_for_long, 100);

    // Set open interest for short token.
    let open_interest_in_tokens_key_for_short = keys::open_interest_in_tokens_key(
        market_token_address, market.short_token, is_long
    );
    data_store.set_u128(open_interest_in_tokens_key_for_short, 200);

    // Actual test case.
    let open_interest_in_tokens_for_market = market_utils::get_open_interest_in_tokens_for_market(
        data_store, @market, is_long
    );

    // Perform assertions.

    // Since long token != short token, then the divisor is 1 and the open interest is 100 + 200 = 300.
    assert(open_interest_in_tokens_for_market == 300, 'wrong open interest');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}


#[test]
fn given_normal_conditions_when_get_pool_amount_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // *************************************************************************
    //                     Case 1: long_token != short_token.
    // *************************************************************************
    let market_token_address = contract_address_const::<'market_token'>();
    let token_address = contract_address_const::<'token_address'>();
    let market = Market {
        market_token: market_token_address,
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };
    let pool_amount_key = keys::pool_amount_key(market_token_address, token_address);
    data_store.set_u128(pool_amount_key, 1000);

    let pool_amount = market_utils::get_pool_amount(data_store, @market, token_address);
    // long_token != short_token, so the pool amount is 1000 because the divisor is 1.
    assert(pool_amount == 1000, 'wrong pool amount');

    // *************************************************************************
    //                     Case 1: long_token == short_token.
    // *************************************************************************
    let market_token_address_2 = contract_address_const::<'market_token_2'>();
    let token_address_2 = contract_address_const::<'token_address_2'>();
    let market_2 = Market {
        market_token: market_token_address_2,
        index_token: contract_address_const::<'index_token_2'>(),
        long_token: contract_address_const::<'same_token'>(),
        short_token: contract_address_const::<'same_token'>(),
    };
    let pool_amount_key_2 = keys::pool_amount_key(market_token_address_2, token_address_2);
    data_store.set_u128(pool_amount_key_2, 1000);
    let pool_amount_2 = market_utils::get_pool_amount(data_store, @market_2, token_address_2);
    // long_token == short_token, so the pool amount is 500 because the divisor is 2.
    assert(pool_amount_2 == 500, 'wrong pool amount');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn given_normal_conditions_when_get_max_pool_amount_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test case.
    let market_token_address = contract_address_const::<'market_token_address'>();
    let token_address = contract_address_const::<'token_address'>();

    // Setup pre conditions.
    let max_pool_amount_key = keys::max_pool_amount_key(market_token_address, token_address);
    data_store.set_u128(max_pool_amount_key, 1000);

    // Actual test case.

    // Get the max pool amount.
    let max_pool_amount = market_utils::get_max_pool_amount(
        data_store, market_token_address, token_address
    );

    // Perform assertions.

    assert(max_pool_amount == 1000, 'wrong pool amount');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn given_normal_conditions_when_get_max_open_interest_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test case.
    let market_token_address = contract_address_const::<'market_token_address'>();
    let is_long = false;

    // Setup pre conditions.

    let max_open_interest_key = keys::max_open_interest_key(market_token_address, is_long);
    data_store.set_u128(max_open_interest_key, 1000);

    // Actual test case.

    // Get the max open interest.

    let max_open_interest = market_utils::get_max_open_interest(
        data_store, market_token_address, is_long
    );

    // Perform assertions.

    assert(max_open_interest == 1000, 'wrong pool amount');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn given_normal_conditions_when_increment_claimable_collateral_amount_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test case.
    let current_timestamp = 1000;
    let market_address = contract_address_const::<'market_address'>();
    let token = contract_address_const::<'token'>();
    let account = contract_address_const::<'account'>();
    let delta = 50;
    // The key for the claimable collateral amount for the account.
    // This is the key that will be used to assert the result.
    let claimable_collatoral_amount_for_account_key =
        0x11df62b70ad974a354ae7d38b9e985489300785772473d224995d4dd6ac2d81;
    // The key for the claimable collateral amount for the market.
    // This is the key that will be used to assert the result.
    let claimable_collateral_amount_key =
        0x7af284cf9ac7ef4a7bb96ad1004a1fb2b9d3c545ea9600edca47d4b033f9b85;

    // Setup pre conditions.

    // Mock the timestamp.
    start_warp(chain.contract_address, current_timestamp);

    // Fill required data store keys.
    data_store.set_u128(keys::claimable_collateral_time_divisor(), 1);

    // Actual test case.
    market_utils::increment_claimable_collateral_amount(
        data_store, chain, event_emitter, market_address, token, account, delta
    );

    // Perform assertions.

    // The value of the claimable collateral amount for the account should now be 50.
    // Read the value from the data store using the hardcoded key and assert it.
    assert(data_store.get_u128(claimable_collatoral_amount_for_account_key) == 50, 'wrong value');
    // The value of the claimable collateral amount for the market should now be 50.
    // Read the value from the data store using the hardcoded key and assert it.
    assert(data_store.get_u128(claimable_collateral_amount_key) == 50, 'wrong value');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn given_normal_conditions_when_increment_claimable_funding_amount_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test case.
    let market_address = contract_address_const::<'market_address'>();
    let token = contract_address_const::<'token'>();
    let account = contract_address_const::<'account'>();
    let delta = 50;
    // The key for the claimable funding amount for the account.
    // This is the key that will be used to assert the result.
    let claimable_funding_amount_for_account_key =
        0x1321919246b443e98ce5d62b2f6b23526c7f1c0d03db2dc2ec82d763a3a3446;
    // The key for the claimable funding amount for the market.
    // This is the key that will be used to assert the result.
    let claimable_funding_amount_key =
        0x3ae3e6b61acb60cab724b0b9a1fc05e4f520a578ddbcd0ca40d05885207249;

    // Actual test case.
    market_utils::increment_claimable_funding_amount(
        data_store, event_emitter, market_address, token, account, delta
    );

    // Perform assertions.

    // The value of the claimable funding amount for the account should now be 50.
    // Read the value from the data store using the hardcoded key and assert it.
    assert(data_store.get_u128(claimable_funding_amount_for_account_key) == 50, 'wrong value');
    // The value of the claimable funding amount for the market should now be 50.
    // Read the value from the data store using the hardcoded key and assert it.
    assert(data_store.get_u128(claimable_funding_amount_key) == 50, 'wrong value');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn given_normal_conditions_when_get_pool_divisor_then_works() {
    // long token == short token, should return 2.
    assert(
        market_utils::get_pool_divisor(
            contract_address_const::<1>(), contract_address_const::<1>()
        ) == 2,
        'wrong pool divisor'
    );
    // long token != short token, should return 1.
    assert(
        market_utils::get_pool_divisor(
            contract_address_const::<1>(), contract_address_const::<2>()
        ) == 1,
        'wrong pool divisor'
    );
}

#[test]
fn given_normal_conditions_when_get_pnl_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test case.
    let market_token_address = contract_address_const::<'market_token'>();
    let market = Market {
        market_token: market_token_address,
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };
    let is_long = true;
    let maximize = true;
    let price = Price { min: 10, max: 50 };

    // Setup pre conditions.

    // Set open interest for long token.
    let open_interest_key_for_long = keys::open_interest_key(
        market_token_address, market.long_token, is_long
    );
    data_store.set_u128(open_interest_key_for_long, 100);
    // Set open interest for short token.
    let open_interest_key_for_short = keys::open_interest_key(
        market_token_address, market.short_token, is_long
    );
    data_store.set_u128(open_interest_key_for_short, 150);

    // Set open interest in tokens for long token.
    let open_interest_in_tokens_key_for_long = keys::open_interest_in_tokens_key(
        market_token_address, market.long_token, is_long
    );
    data_store.set_u128(open_interest_in_tokens_key_for_long, 200);

    // Set open interest in tokens for short token.
    let open_interest_in_tokens_key_for_short = keys::open_interest_in_tokens_key(
        market_token_address, market.short_token, is_long
    );
    data_store.set_u128(open_interest_in_tokens_key_for_short, 250);

    // Actual test case.
    let pnl = market_utils::get_pnl(data_store, @market, @price, is_long, maximize);

    // Perform assertions.
    assert(pnl == 22250, 'wrong pnl');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn given_zero_open_interest_when_get_pnl_then_returns_zero_pnl() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test case.
    let market_token_address = contract_address_const::<'market_token'>();
    let market = Market {
        market_token: market_token_address,
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };
    let is_long = true;
    let maximize = true;
    let price = Price { min: 10, max: 50 };

    // Setup pre conditions.

    // Set open interest for long token.
    let open_interest_key_for_long = keys::open_interest_key(
        market_token_address, market.long_token, is_long
    );
    data_store.set_u128(open_interest_key_for_long, 0);
    // Set open interest for short token.
    let open_interest_key_for_short = keys::open_interest_key(
        market_token_address, market.short_token, is_long
    );
    data_store.set_u128(open_interest_key_for_short, 0);

    // Set open interest in tokens for long token.
    let open_interest_in_tokens_key_for_long = keys::open_interest_in_tokens_key(
        market_token_address, market.long_token, is_long
    );
    data_store.set_u128(open_interest_in_tokens_key_for_long, 200);

    // Set open interest in tokens for short token.
    let open_interest_in_tokens_key_for_short = keys::open_interest_in_tokens_key(
        market_token_address, market.short_token, is_long
    );
    data_store.set_u128(open_interest_in_tokens_key_for_short, 250);

    // Actual test case.
    let pnl = market_utils::get_pnl(data_store, @market, @price, is_long, maximize);

    // Perform assertions.
    assert(pnl == 0, 'wrong pnl');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn given_zero_open_interest_in_tokens_when_get_pnl_then_returns_zero_pnl() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test case.
    let market_token_address = contract_address_const::<'market_token'>();
    let market = Market {
        market_token: market_token_address,
        index_token: contract_address_const::<'index_token'>(),
        long_token: contract_address_const::<'long_token'>(),
        short_token: contract_address_const::<'short_token'>(),
    };
    let is_long = true;
    let maximize = true;
    let price = Price { min: 10, max: 50 };

    // Setup pre conditions.

    // Set open interest for long token.
    let open_interest_key_for_long = keys::open_interest_key(
        market_token_address, market.long_token, is_long
    );
    data_store.set_u128(open_interest_key_for_long, 100);
    // Set open interest for short token.
    let open_interest_key_for_short = keys::open_interest_key(
        market_token_address, market.short_token, is_long
    );
    data_store.set_u128(open_interest_key_for_short, 200);

    // Set open interest in tokens for long token.
    let open_interest_in_tokens_key_for_long = keys::open_interest_in_tokens_key(
        market_token_address, market.long_token, is_long
    );
    data_store.set_u128(open_interest_in_tokens_key_for_long, 0);

    // Set open interest in tokens for short token.
    let open_interest_in_tokens_key_for_short = keys::open_interest_in_tokens_key(
        market_token_address, market.short_token, is_long
    );
    data_store.set_u128(open_interest_in_tokens_key_for_short, 0);

    // Actual test case.
    let pnl = market_utils::get_pnl(data_store, @market, @price, is_long, maximize);

    // Perform assertions.
    assert(pnl == 0, 'wrong pnl');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn given_normal_conditions_when_get_position_impact_pool_amount_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test case.
    let market_token_address = contract_address_const::<'market_token'>();

    // Setup pre conditions.

    // Fill required data store keys.
    let position_impact_pool_amount_key = keys::position_impact_pool_amount_key(
        market_token_address
    );
    data_store.set_u128(position_impact_pool_amount_key, 1000);

    // Actual test case.
    let position_impact_pool_amount = market_utils::get_position_impact_pool_amount(
        data_store, market_token_address
    );

    // Perform assertions.

    assert(position_impact_pool_amount == 1000, 'wrong pool amount');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn given_normal_conditions_when_get_swap_impact_pool_amount_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test case.
    let market_token_address = contract_address_const::<'market_token'>();
    let token = contract_address_const::<'token'>();

    // Setup pre conditions.

    // Fill required data store keys.
    let swap_impact_pool_amount_key = keys::swap_impact_pool_amount_key(
        market_token_address, token
    );
    data_store.set_u128(swap_impact_pool_amount_key, 1000);

    // Actual test case.
    let swap_impact_pool_amount = market_utils::get_swap_impact_pool_amount(
        data_store, market_token_address, token,
    );

    // Perform assertions.

    assert(swap_impact_pool_amount == 1000, 'wrong pool amount');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn given_normal_conditions_when_apply_delta_to_position_impact_pool_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test case.
    let market_token_address = contract_address_const::<'market_token'>();
    let delta = 50;

    // Setup pre conditions.

    // Fill required data store keys.
    let key = keys::position_impact_pool_amount_key(market_token_address);
    data_store.set_u128(key, 1000);

    // Actual test case.
    let next_value = market_utils::apply_delta_to_position_impact_pool(
        data_store, event_emitter, market_token_address, delta
    );

    // Perform assertions.

    assert(next_value == 1050, 'wrong value');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn given_normal_conditions_when_apply_delta_to_swap_impact_pool_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Define variables for the test case.
    let market_token_address = contract_address_const::<'market_token'>();
    let token = contract_address_const::<'token'>();
    let delta = 50;

    // Setup pre conditions.

    // Fill required data store keys.
    let key = keys::swap_impact_pool_amount_key(market_token_address, token);
    data_store.set_u128(key, 1000);

    // Actual test case.
    let next_value = market_utils::apply_delta_to_swap_impact_pool(
        data_store, event_emitter, market_token_address, token, delta
    );

    // Perform assertions.

    assert(next_value == 1050, 'wrong value');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}


/// Utility function to setup the test environment.
fn setup() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress,
    // Address of the `MarketFactory` contract.
    ContractAddress,
    // Address of the `RoleStore` contract.
    ContractAddress,
    // Address of the `DataStore` contract.
    ContractAddress,
    // The `MarketToken` class hash for the factory.
    ContractClass,
    // Interface to interact with the `MarketFactory` contract.
    IMarketFactoryDispatcher,
    // Interface to interact with the `RoleStore` contract.
    IRoleStoreDispatcher,
    // Interface to interact with the `DataStore` contract.
    IDataStoreDispatcher,
    // Interface to interact with the `Chain` library contract.
    IChainDispatcher,
    // Interface to interact with the `EventEmitter` contract.
    IEventEmitterDispatcher,
) {
    // Setup required contracts.
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    ) =
        setup_contracts();

    // Grant roles and prank the caller address.
    grant_roles_and_prank(caller_address, role_store, data_store, market_factory);

    // Return the setup variables.
    (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    )
}

// Utility function to grant roles and prank the caller address.
/// Grants roles and pranks the caller address.
///
/// # Arguments
///
/// * `caller_address` - The address of the caller.
/// * `role_store` - The interface to interact with the `RoleStore` contract.
/// * `data_store` - The interface to interact with the `DataStore` contract.
/// * `market_factory` - The interface to interact with the `MarketFactory` contract.
fn grant_roles_and_prank(
    caller_address: ContractAddress,
    role_store: IRoleStoreDispatcher,
    data_store: IDataStoreDispatcher,
    market_factory: IMarketFactoryDispatcher,
) {
    start_prank(role_store.contract_address, caller_address);

    // Grant the caller the `CONTROLLER` role.
    // We use the same account to deploy data_store and role_store, so we can grant the role
    // because the caller is the owner of role_store contract.
    role_store.grant_role(caller_address, role::CONTROLLER);

    // Grant the call the `MARKET_KEEPER` role.
    // This role is required to create a market.
    role_store.grant_role(caller_address, role::MARKET_KEEPER);

    // Prank the caller address for calls to data_store contract.
    // We need this so that the caller has the CONTROLLER role.
    start_prank(data_store.contract_address, caller_address);

    // Prank the caller address for calls to market_factory contract.
    // We need this so that the caller has the MARKET_KEEPER role.
    start_prank(market_factory.contract_address, caller_address);
}

/// Utility function to teardown the test environment.
fn teardown(data_store: IDataStoreDispatcher, market_factory: IMarketFactoryDispatcher) {
    // Stop pranking the caller address.
    stop_prank(data_store.contract_address);
    stop_prank(market_factory.contract_address);
}

/// Setup required contracts.
fn setup_contracts() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress,
    // Address of the `MarketFactory` contract.
    ContractAddress,
    // Address of the `RoleStore` contract.
    ContractAddress,
    // Address of the `DataStore` contract.
    ContractAddress,
    // The `MarketToken` class hash for the factory.
    ContractClass,
    // Interface to interact with the `MarketFactory` contract.
    IMarketFactoryDispatcher,
    // Interface to interact with the `RoleStore` contract.
    IRoleStoreDispatcher,
    // Interface to interact with the `DataStore` contract.
    IDataStoreDispatcher,
    // Interface to interact with the `Chain` library contract.
    IChainDispatcher,
    // Interface to interact with the `EventEmitter` contract.
    IEventEmitterDispatcher,
) {
    // Deploy the role store contract.
    let role_store_address = deploy_role_store();

    // Create a role store dispatcher.
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let data_store_address = deploy_data_store(role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    // Declare the `MarketToken` contract.
    let market_token_class_hash = declare('MarketToken');

    // Declare the `Chain` library contract.
    let chain_address = deploy_chain();
    // Create a safe dispatcher to interact with the contract.
    let chain = IChainDispatcher { contract_address: chain_address };

    // Deploy the `EventEmitter` contract.
    let event_emitter_address = deploy_event_emitter();
    // Create a safe dispatcher to interact with the contract.
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    // Deploy the market factory.
    let market_factory_address = deploy_market_factory(
        data_store_address,
        role_store_address,
        event_emitter_address,
        market_token_class_hash.clone()
    );
    // Create a safe dispatcher to interact with the contract.
    let market_factory = IMarketFactoryDispatcher { contract_address: market_factory_address };

    (
        0x101.try_into().unwrap(),
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        chain,
        event_emitter,
    )
}

/// Utility function to deploy a market factory contract and return its address.
fn deploy_market_factory(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    market_token_class_hash: ContractClass,
) -> ContractAddress {
    let contract = declare('MarketFactory');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    constructor_calldata.append(event_emitter_address.into());
    constructor_calldata.append(market_token_class_hash.class_hash.into());
    contract.deploy(@constructor_calldata).unwrap()
}


/// Utility function to deploy a data store contract and return its address.
fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let mut constructor_calldata = array![];
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

/// Utility function to deploy a `Chain` contract and return its address.
fn deploy_chain() -> ContractAddress {
    let contract = declare('Chain');
    let constructor_arguments: @Array::<felt252> = @ArrayTrait::new();
    contract.deploy(constructor_arguments).unwrap()
}

/// Utility function to deploy a `EventEmitter` contract and return its address.
fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    let constructor_arguments: @Array::<felt252> = @ArrayTrait::new();
    contract.deploy(constructor_arguments).unwrap()
}
