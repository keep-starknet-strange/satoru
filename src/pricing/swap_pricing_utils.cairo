//! Library for pricing functions

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::data::keys;
use satoru::market::market::Market;
use satoru::market::market_utils;
use satoru::pricing::error::PricingError;
use satoru::pricing::pricing_utils;
use satoru::utils::calc;
use satoru::utils::precision;
use satoru::utils::i128::{i128,i128_neg};


/// Struct used in get_price_impact_usd.
#[derive(Copy, Drop, starknet::Store, Serde)]
struct GetPriceImpactUsdParams {
    /// The `DataStore` contract dispatcher.
    data_store: IDataStoreDispatcher,
    /// The market to check.
    market: Market,
    /// The token to check balance for.
    token_a: ContractAddress,
    /// The token to check balance for.
    token_b: ContractAddress,
    price_for_token_a: u128,
    price_for_token_b: u128,
    // The USD change in amount of token_a.
    usd_delta_for_token_a: i128,
    // The USD change in amount of token_b.
    usd_delta_for_token_b: i128,
}

/// Struct to contain pool values.
#[derive(Drop, starknet::Store, Serde)]
struct PoolParams {
    /// The USD value of token_a in the pool.
    pool_usd_for_token_a: u128,
    /// The USD value of token_b in the pool.
    pool_usd_for_token_b: u128,
    /// The next USD value of token_a in the pool.
    next_pool_usd_for_token_a: u128,
    /// The next USD value of token_b in the pool.
    next_pool_usd_for_token_b: u128,
}

/// Struct to contain swap fee values.
#[derive(Copy, Drop, starknet::Store, Serde)]
struct SwapFees {
    /// The fee amount for the fee receiver.
    fee_receiver_amount: u128,
    /// The fee amount for the pool.
    fee_amount_for_pool: u128,
    /// The output amount after fees.
    amount_after_fees: u128,
    /// The ui fee receiver.
    ui_fee_receiver: ContractAddress,
    /// The factor for receiver.
    ui_fee_receiver_factor: u128,
    /// The ui fee amount.
    ui_fee_amount: u128,
}

impl DefaultSwapFees of Default<SwapFees> {
    fn default() -> SwapFees {
        SwapFees {
            fee_receiver_amount: 0,
            fee_amount_for_pool: 0,
            amount_after_fees: 0,
            ui_fee_receiver: Zeroable::zero(),
            ui_fee_receiver_factor: 0,
            ui_fee_amount: 0
        }
    }
}

/// Get the price impact in USD
///
/// Note that there will be some difference between the pool amounts used for
/// calculating the price impact and fees vs the actual pool amounts after the
/// swap is done, since the pool amounts will be increased / decreased by an amount
/// after factoring in the calculated price impact and fees.
///
/// Since the calculations are based on the real-time prices values of the tokens
/// if a token price increases, the pool will incentivise swapping out more of that token
/// this is useful if prices are ranging, if prices are strongly directional, the pool may
/// be selling tokens as the token price increases.
/// # Arguments
/// * `params` - The necessary params to compute next pool amount in USD.
/// # Returns
/// New pool amount.
fn get_price_impact_usd(params: GetPriceImpactUsdParams) -> i128 {
    let pool_params = get_next_pool_amount_usd(params);

    let price_impact_usd = get_price_impact_usd_(params.data_store, params.market, pool_params);

    // the virtual price impact calculation is skipped if the price impact
    // is positive since the action is helping to balance the pool
    //
    // in case two virtual pools are unbalanced in a different direction
    // e.g. pool0 has more WNT than USDC while pool1 has less WNT
    // than USDT
    // not skipping the virtual price impact calculation would lead to
    // a negative price impact for any trade on either pools and would
    // disincentivise the balancing of pools
    if price_impact_usd >= Zeroable::zero() {
        return price_impact_usd;
    }

    // note that the virtual pool for the long token / short token may be different across pools
    // e.g. ETH/USDC, ETH/USDT would have USDC and USDT as the short tokens
    // the short token amount is multiplied by the price of the token in the current pool, e.g. if the swap
    // is for the ETH/USDC pool, the combined USDC and USDT short token amounts is multiplied by the price of
    // USDC to calculate the price impact, this should be reasonable most of the time unless there is a
    // large depeg of one of the tokens, in which case it may be necessary to remove that market from being a virtual
    // market, removal of virtual markets may lead to incorrect virtual token accounting, the feature to correct for
    // this can be added if needed
    let (
        has_virtual_inventory,
        virtual_pool_amount_for_long_token,
        virtual_pool_amount_for_short_token
    ) =
        market_utils::get_virtual_inventory_for_swaps(
        params.data_store, params.market.market_token
    );

    if !has_virtual_inventory {
        return price_impact_usd;
    }

    let token_a_is_long = params.token_a == params.market.long_token;
    let (virtual_pool_amount_for_token_a, virtual_pool_amount_for_token_b) = if token_a_is_long {
        (virtual_pool_amount_for_long_token, virtual_pool_amount_for_short_token)
    } else {
        (virtual_pool_amount_for_short_token, virtual_pool_amount_for_long_token)
    };

    let pool_params_for_virtual_inventory = get_next_pool_amount_params(
        params, virtual_pool_amount_for_token_a, virtual_pool_amount_for_token_b
    );

    let price_impact_usd_for_virtual_inventory = get_price_impact_usd_(
        params.data_store, params.market, pool_params_for_virtual_inventory
    );

    if price_impact_usd_for_virtual_inventory < price_impact_usd {
        price_impact_usd_for_virtual_inventory
    } else {
        price_impact_usd
    }
}

/// Called by get_price_impact_usd().
/// # Arguments
/// * `data_store` - DataStore
/// * `market` - the trading market
/// * `pool_params` - PoolParams
/// # Returns
/// The price impact in USD.
fn get_price_impact_usd_(
    data_store: IDataStoreDispatcher, market: Market, pool_params: PoolParams,
) -> i128 {
    let initial_diff_usd = calc::diff(
        pool_params.pool_usd_for_token_a, pool_params.pool_usd_for_token_b
    );
    let next_diff_usd = calc::diff(
        pool_params.next_pool_usd_for_token_a, pool_params.next_pool_usd_for_token_b
    );

    // check whether an improvement in balance comes from causing the balance to switch sides
    // for example, if there is $2000 of ETH and $1000 of USDC in the pool
    // adding $1999 USDC into the pool will reduce absolute balance from $1000 to $999 but it does not
    // help rebalance the pool much, the isSameSideRebalance value helps avoid gaming using this case

    let a_lte_b = pool_params.pool_usd_for_token_a <= pool_params.pool_usd_for_token_b;
    let next_a_lte_b = pool_params
        .next_pool_usd_for_token_a <= pool_params
        .next_pool_usd_for_token_b;
    let is_same_side_rebalance = a_lte_b == next_a_lte_b;
    let impact_exponent_factor = data_store
        .get_u128(keys::swap_impact_exponent_factor_key(market.market_token));

    if is_same_side_rebalance {
        let has_positive_impact = next_diff_usd < initial_diff_usd;
        let impact_factor = market_utils::get_adjusted_swap_impact_factor(
            data_store, market.market_token, has_positive_impact
        );

        pricing_utils::get_price_impact_usd_for_same_side_rebalance(
            initial_diff_usd, next_diff_usd, impact_factor, impact_exponent_factor
        )
    } else {
        let (positive_impact_factor, negative_impact_factor) =
            market_utils::get_adjusted_swap_impact_factors(
            data_store, market.market_token
        );

        pricing_utils::get_price_impact_usd_for_crossover_rebalance(
            initial_diff_usd,
            next_diff_usd,
            positive_impact_factor,
            negative_impact_factor,
            impact_exponent_factor
        )
    }
}

/// Get the next pool amounts in USD
/// # Arguments
/// `params` - GetPriceImpactUsdParams
/// # Returns
/// PoolParams
fn get_next_pool_amount_usd(params: GetPriceImpactUsdParams) -> PoolParams {
    let pool_amount_for_token_a = market_utils::get_pool_amount(
        params.data_store, @params.market, params.token_a
    );
    let pool_amount_for_token_b = market_utils::get_pool_amount(
        params.data_store, @params.market, params.token_b
    );

    get_next_pool_amount_params(params, pool_amount_for_token_a, pool_amount_for_token_b)
}

/// Get the new pool values.
/// # Arguments
/// * `params` - The necessary params to compute price impact.
/// * `pool_amount_for_token_a` - The pool amount of token a.
/// * `pool_amount_for_token_b` - The pool amount of token b.
/// # Returns
/// New pool values.
fn get_next_pool_amount_params(
    params: GetPriceImpactUsdParams, pool_amount_for_token_a: u128, pool_amount_for_token_b: u128
) -> PoolParams {
    let pool_usd_for_token_a = pool_amount_for_token_a * params.price_for_token_a;
    let pool_usd_for_token_b = pool_amount_for_token_b * params.price_for_token_b;
    if params.usd_delta_for_token_a < Zeroable::zero()
        && calc::to_unsigned(i128_neg(params.usd_delta_for_token_a)) > pool_usd_for_token_a {
        panic(
            array![
                PricingError::USD_DELTA_EXCEEDS_POOL_VALUE,
                params.usd_delta_for_token_a.into(),
                pool_usd_for_token_a.into()
            ]
        );
    }
    if params.usd_delta_for_token_b < Zeroable::zero()
        && calc::to_unsigned(i128_neg(params.usd_delta_for_token_b)) > pool_usd_for_token_b {
        panic(
            array![
                PricingError::USD_DELTA_EXCEEDS_POOL_VALUE,
                params.usd_delta_for_token_b.into(),
                pool_usd_for_token_b.into()
            ]
        );
    }
    let next_pool_usd_for_token_a = calc::sum_return_uint_128(
        pool_usd_for_token_a, params.usd_delta_for_token_a
    );
    let next_pool_usd_for_token_b = calc::sum_return_uint_128(
        pool_usd_for_token_b, params.usd_delta_for_token_b
    );

    PoolParams {
        pool_usd_for_token_a,
        pool_usd_for_token_b,
        next_pool_usd_for_token_a,
        next_pool_usd_for_token_b,
    }
}

/// Get the swap fees.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `market_token` - The address of market token.
/// * `amount` - The total swap fee amount.
/// * `for_positive_impact` - Wether it is for a positive impact.
/// * `ui_fee_receiver` - The ui fee receiver.
/// # Returns
/// New swap fees.
fn get_swap_fees(
    data_store: IDataStoreDispatcher,
    market_token: ContractAddress,
    amount: u128,
    for_positive_impact: bool,
    ui_fee_receiver: ContractAddress,
) -> SwapFees {
    // note that since it is possible to incur both positive and negative price impact values
    // and the negative price impact factor may be larger than the positive impact factor
    // it is possible for the balance to be improved overall but for the price impact to still be negative
    // in this case the fee factor for the negative price impact would be charged
    // a user could split the order into two, to incur a smaller fee, reducing the fee through this should not be a large issue

    let fee_factor = data_store
        .get_u128(keys::swap_fee_factor_key(market_token, for_positive_impact));
    let swap_fee_receiver_factor = data_store.get_u128(keys::swap_fee_receiver_factor());

    let fee_amount = precision::apply_factor_u128(amount, fee_factor);

    let fee_receiver_amount = precision::apply_factor_u128(fee_amount, swap_fee_receiver_factor);
    let fee_amount_for_pool = fee_amount - fee_receiver_amount;

    let ui_fee_receiver_factor = market_utils::get_ui_fee_factor(data_store, ui_fee_receiver);
    let ui_fee_amount = precision::apply_factor_u128(amount, ui_fee_receiver_factor);

    let amount_after_fees = amount - fee_amount - ui_fee_amount;

    SwapFees {
        fee_receiver_amount,
        fee_amount_for_pool,
        amount_after_fees,
        ui_fee_receiver,
        ui_fee_receiver_factor,
        ui_fee_amount,
    }
}
