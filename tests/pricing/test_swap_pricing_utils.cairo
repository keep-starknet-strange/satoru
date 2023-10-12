use debug::PrintTrait;
use satoru::data::data_store::IDataStoreDispatcherTrait;
use satoru::data::keys;
use satoru::pricing::swap_pricing_utils::{
    GetPriceImpactUsdParams, get_price_impact_usd_, get_price_impact_usd, get_next_pool_amount_usd,
    get_swap_fees, PoolParams
};
use satoru::market::market::Market;
use satoru::utils::calc;
use satoru::tests_lib::{setup, teardown};
use satoru::utils::precision;
use satoru::utils::precision::{FLOAT_PRECISION};

#[test]
fn given_normal_conditions_when_get_price_impact_usd_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (_, _, data_store) = setup();

    let market_token = 'market_token'.try_into().unwrap();
    let index_token = 'index_token'.try_into().unwrap();
    let long_token = 'long_token'.try_into().unwrap();
    let short_token = 'short_token'.try_into().unwrap();

    data_store.set_u128(keys::pool_amount_key(market_token, long_token), 1000);
    data_store.set_u128(keys::pool_amount_key(market_token, short_token), 1000);

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let params = GetPriceImpactUsdParams {
        data_store,
        market: Market { market_token, index_token, long_token, short_token },
        token_a: long_token,
        token_b: short_token,
        price_for_token_a: 101,
        price_for_token_b: 99,
        usd_delta_for_token_a: 5,
        usd_delta_for_token_b: 4,
    };

    let impact = get_price_impact_usd(params);
    // TODO change to real value when precision::apply_exponent_factor is implemented
    assert(impact == 0, 'foo');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_get_price_impact_usd_inner_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (_, _, data_store) = setup();

    let market_token = 'market_token'.try_into().unwrap();
    let index_token = 'index_token'.try_into().unwrap();
    let long_token = 'long_token'.try_into().unwrap();
    let short_token = 'short_token'.try_into().unwrap();

    data_store.set_u128(keys::pool_amount_key(market_token, long_token), 1000);
    data_store.set_u128(keys::pool_amount_key(market_token, short_token), 1000);

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let market = Market { market_token, index_token, long_token, short_token };

    let params = PoolParams {
        pool_usd_for_token_a: 1000,
        pool_usd_for_token_b: 1000,
        next_pool_usd_for_token_a: 1001,
        next_pool_usd_for_token_b: 999,
    };

    let impact = get_price_impact_usd_(data_store, market, params);
    'impact'.print();
    calc::to_signed(impact, true).print();

    assert(impact == 0, 'foo');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_get_next_pool_amount_usd_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (_, _, data_store) = setup();

    let market_token = 'market_token'.try_into().unwrap();
    let index_token = 'index_token'.try_into().unwrap();
    let long_token = 'long_token'.try_into().unwrap();
    let short_token = 'short_token'.try_into().unwrap();

    data_store.set_u128(keys::pool_amount_key(market_token, long_token), 1000);
    data_store.set_u128(keys::pool_amount_key(market_token, short_token), 1000);
    data_store.set_u128(keys::swap_impact_factor_key(market_token, false), 10);
    data_store.set_u128(keys::swap_impact_factor_key(market_token, true), 10);
    data_store.set_u128(keys::swap_impact_exponent_factor_key(market_token), 10);

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let params = GetPriceImpactUsdParams {
        data_store,
        market: Market { market_token, index_token, long_token, short_token },
        token_a: long_token,
        token_b: short_token,
        price_for_token_a: 101,
        price_for_token_b: 99,
        usd_delta_for_token_a: 5,
        usd_delta_for_token_b: 4,
    };

    let pool_params = get_next_pool_amount_usd(params);
    assert(pool_params.pool_usd_for_token_a == 101000, 'invalid');
    assert(pool_params.pool_usd_for_token_b == 99000, 'invalid');
    assert(pool_params.next_pool_usd_for_token_a == 101005, 'invalid');
    assert(pool_params.next_pool_usd_for_token_b == 99004, 'invalid');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}

#[test]
fn given_normal_conditions_when_get_swap_fees_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (_, _, data_store) = setup();

    let market_token = 'market_token'.try_into().unwrap();
    let ui_fee_receiver = 'ui_fee_receiver'.try_into().unwrap();
    let for_positive_impact = true;

    data_store.set_u128(keys::swap_fee_factor_key(market_token, for_positive_impact), 5);
    data_store.set_u128(keys::swap_fee_receiver_factor(), 10);
    data_store.set_u128(keys::max_ui_fee_factor(), 9);
    data_store.set_u128(keys::ui_fee_factor_key(ui_fee_receiver), 9);

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let amount = 1000 * FLOAT_PRECISION;
    let fees = get_swap_fees(
        data_store, market_token, amount, for_positive_impact, ui_fee_receiver
    );

    assert(fees.fee_receiver_amount == 0, 'invalid 1');
    assert(fees.fee_amount_for_pool == 5000, 'invalid 2');
    assert(fees.amount_after_fees == 1000 * FLOAT_PRECISION - 14000, 'invalid 3');
    assert(fees.ui_fee_receiver_factor == 9, 'invalid 4');
    assert(fees.ui_fee_amount == 9000, 'invalid 5');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}
