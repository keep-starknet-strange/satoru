// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use result::ResultTrait;
use core::traits::{Into, TryInto};
use core::integer::I128Neg;

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::market::{
    market::Market,
    market_utils::{
        MarketPrices, validate_swap_market, get_opposite_token, apply_swap_impact_with_cap,
        apply_delta_to_pool_amount, validate_max_pnl, validate_pool_amount, validata_reserve
    }
};
use satoru::fee::fee_utils::{increment_claimable_fee_amount, increment_claimable_ui_fee_amount};
use satoru::utils::{store_arrays::StoreMarketArray, traits::ContractAddressDefault};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::swap::error::SwapError;
use satoru::data::keys;
use satoru::pricing::swap_pricing_utils::{
    get_price_impact_usd, get_swap_fees, GetPriceImpactUsdParams
};
use satoru::price::price::{Price, PriceTrait, PriceDefault};

/// Parameters to execute a swap.
#[derive(Drop, starknet::Store, Serde)]
struct SwapParams {
    /// The contract that provides access to data stored on-chain.
    data_store: IDataStoreDispatcher,
    /// The contract that emits events.
    event_emitter: IEventEmitterDispatcher,
    /// The contract that provides access to price data from oracles.
    oracle: IOracleDispatcher,
    /// The contract providing the funds for the swap.
    bank: IBankDispatcher,
    /// An identifying key for the swap.
    key: felt252,
    /// The address of the token that is being swapped.
    token_in: ContractAddress,
    /// The amount of the token that is being swapped.
    amount_in: u128,
    /// An array of market properties, specifying the markets in which the swap should be executed.
    swap_path_markets: Array<Market>,
    /// The minimum amount of tokens that should be received as part of the swap.
    min_output_amount: u128,
    /// The minimum amount of tokens that should be received as part of the swap.
    receiver: ContractAddress,
    /// The address of the ui fee receiver.
    ui_fee_receiver: ContractAddress,
    /// A boolean indicating whether the received tokens should be unwrapped from
    /// the wrapped native token (WNT) if they are wrapped.
    should_unwrap_native_token: bool,
}

impl DefaultSwapParams of Default<SwapParams> {
    fn default() -> SwapParams {
        let contract_address = Zeroable::zero();
        SwapParams {
            data_store: IDataStoreDispatcher { contract_address },
            event_emitter: IEventEmitterDispatcher { contract_address },
            oracle: IOracleDispatcher { contract_address },
            bank: IBankDispatcher { contract_address },
            key: 0,
            token_in: contract_address,
            amount_in: 0,
            swap_path_markets: array![],
            min_output_amount: 0,
            receiver: contract_address,
            ui_fee_receiver: contract_address,
            should_unwrap_native_token: false,
        }
    }
}

#[derive(Drop, Copy, starknet::Store, Serde)]
struct _SwapParams {
    /// The market in which the swap should be executed.
    market: Market,
    /// The address of the token that is being swapped.
    token_in: ContractAddress,
    /// The amount of the token that is being swapped.
    amount_in: u128,
    /// The address to which the swapped tokens should be sent.
    receiver: ContractAddress,
    /// A boolean indicating whether the received tokens should be unwrapped from
    /// the wrapped native token (WNT) if they are wrapped.
    should_unwrap_native_token: bool,
}

#[derive(Default, Drop, Copy, starknet::Store, Serde)]
struct SwapCache {
    /// The address of the token that is being received as part of the swap.
    token_out: ContractAddress,
    /// The price of the token that is being swapped.
    token_in_price: Price,
    /// The price of the token that is being received as part of the swap.
    token_out_price: Price,
    /// The amount of the token that is being swapped.
    amount_in: u128,
    /// The amount of the token that is being received as part of the swap.
    amount_out: u128,
    /// The total amount of the token that is being received by all users in the swap pool.
    pool_amount_out: u128,
/// The price impact of the swap in USD.
/// TODO: to uncomment when i128 will be supported
// price_impact_usd: i128,
/// The price impact of the swap in tokens.
// price_impact_amount: i128,
}

/// Swaps a given amount of a given token for another token based on a
/// specified swap path.
/// # Arguments
/// * `params` - The parameters for the swap.
/// # Returns
/// A tuple containing the address of the token that was received as
/// part of the swap and the amount of the received token.
#[inline(always)]
fn swap(params: @SwapParams) -> (ContractAddress, u128) {
    // TODO
    (0.try_into().unwrap(), 0)
}

/// Perform a swap on a single market.
/// * `params` - The parameters for the swap.
/// * `_params` - The parameters for the swap on this specific market.
/// # Returns
/// The token and amount that was swapped.
#[inline(always)]
fn _swap(params: SwapParams, _params: _SwapParams) -> (ContractAddress, u128) {
    if (_params.token_in != _params.market.long_token
        && _params.token_in != _params.market.short_token) {
        SwapError::INVALID_TOKEN_IN(_params.token_in, _params.market.long_token);
    }
    let mut cache: SwapCache = Default::default();

    validate_swap_market(params.data_store, @_params.market);

    cache.token_out = get_opposite_token(@_params.market, _params.token_in);
    cache.token_in_price = params.oracle.get_primary_price(_params.token_in);
    cache.token_out_price = params.oracle.get_primary_price(cache.token_out);

    let usd_delta_for_token_felt252: felt252 = (_params.amount_in
        * cache.token_out_price.mid_price())
        .into();

    let price_impact_usd = get_price_impact_usd(
        params.data_store,
        _params.market,
        _params.token_in,
        cache.token_out,
        cache.token_in_price.mid_price(),
        cache.token_out_price.mid_price(),
        usd_delta_for_token_felt252.try_into().unwrap(),
        -usd_delta_for_token_felt252.try_into().unwrap(),
    );

    let fees = get_swap_fees(
        params.data_store,
        _params.market.market_token,
        _params.amount_in,
        price_impact_usd > 0,
        params.ui_fee_receiver
    );

    increment_claimable_fee_amount(
        params.data_store,
        params.event_emitter,
        _params.market.market_token,
        _params.token_in,
        fees.fee_receiver_amount,
        keys::swap_fee_type(),
    );

    increment_claimable_ui_fee_amount(
        params.data_store,
        params.event_emitter,
        params.ui_fee_receiver,
        _params.market.market_token,
        _params.token_in,
        fees.ui_fee_amount,
        keys::swap_fee_type(),
    );
    let mut price_impact_amount: i128 = 0;
    if (price_impact_usd > 0) {
        // when there is a positive price impact factor, additional tokens from the swap impact pool
        // are withdrawn for the user
        // for example, if 50,000 USDC is swapped out and there is a positive price impact
        // an additional 100 USDC may be sent to the user
        // the swap impact pool is decreased by the used amount

        cache.amount_in = fees.amount_after_fees;
        cache.amount_out = cache.amount_in * cache.token_in_price.min / cache.token_out_price.max;
        cache.pool_amount_out = cache.amount_out;

        price_impact_amount =
            apply_swap_impact_with_cap(
                params.data_store,
                params.event_emitter,
                _params.market.market_token,
                cache.token_out,
                cache.token_out_price,
                price_impact_usd
            );
        let price_impact_amount_felt252: felt252 = price_impact_amount.into();
        cache.amount_out += price_impact_amount_felt252.try_into().unwrap();
    } else {
        // when there is a negative price impact factor,
        // less of the input amount is sent to the pool
        // for example, if 10 ETH is swapped in and there is a negative price impact
        // only 9.995 ETH may be swapped in
        // the remaining 0.005 ETH will be stored in the swap impact pool
        price_impact_amount =
            apply_swap_impact_with_cap(
                params.data_store,
                params.event_emitter,
                _params.market.market_token,
                _params.token_in,
                cache.token_in_price,
                price_impact_usd
            );
        let price_impact_amount_felt252: felt252 = (-price_impact_amount).into();
        if (fees.amount_after_fees <= price_impact_amount_felt252.try_into().unwrap()) {
            SwapError::SWAP_PRICE_IMPACT_EXCEEDS_AMOUNT_IN(
                fees.amount_after_fees, price_impact_amount
            );
        }
        cache.amount_in = fees.amount_after_fees - price_impact_amount_felt252.try_into().unwrap();
        cache.amount_out = cache.amount_in * cache.token_in_price.min / cache.token_out_price.max;
        cache.pool_amount_out = cache.amount_out;
    }

    // the amountOut value includes the positive price impact amount
    if (_params.receiver != _params.market.market_token) {
        IBankDispatcher { contract_address: _params.market.market_token }
            .transfer_out(cache.token_out, _params.receiver, cache.amount_out);
    }

    let mut delta_felt252: felt252 = (cache.amount_in + fees.fee_amount_for_pool).into();
    apply_delta_to_pool_amount(
        params.data_store,
        params.event_emitter,
        @_params.market,
        _params.token_in,
        delta_felt252.try_into().unwrap(),
    );

    // the poolAmountOut excludes the positive price impact amount
    // as that is deducted from the swap impact pool instead
    delta_felt252 = cache.pool_amount_out.into();
    apply_delta_to_pool_amount(
        params.data_store,
        params.event_emitter,
        @_params.market,
        cache.token_out,
        -delta_felt252.try_into().unwrap(),
    );

    let prices = MarketPrices {
        index_token_price: params.oracle.get_primary_price(_params.market.short_token),
        long_token_price: if (_params.token_in == _params.market.long_token) {
            cache.token_in_price
        } else {
            cache.token_out_price
        },
        short_token_price: if (_params.token_in == _params.market.short_token) {
            cache.token_in_price
        } else {
            cache.token_out_price
        },
    };

    validate_pool_amount(params.data_store, @_params.market, _params.token_in);
    validata_reserve(
        params.data_store, @_params.market, @prices, cache.token_out == _params.market.long_token
    );
    let (pnl_factor_type_for_longs, pnl_factor_type_for_shorts) = if (cache
        .token_out == _params
        .market
        .long_token) {
        (keys::max_pnl_factor_for_deposits(), keys::max_pnl_factor_for_withdrawals())
    } else {
        (keys::max_pnl_factor_for_withdrawals(), keys::max_pnl_factor_for_deposits())
    };

    validate_max_pnl(
        params.data_store,
        @_params.market,
        @prices,
        pnl_factor_type_for_longs,
        pnl_factor_type_for_shorts
    );

    let price_impact_usd_felt252: felt252 = price_impact_usd.into();
    let price_impact_amount_felt252: felt252 = price_impact_amount.into();
    params
        .event_emitter
        .emit_swap_info(
            params.key,
            _params.market.market_token,
            _params.receiver,
            _params.token_in,
            cache.token_out,
            cache.token_in_price.min,
            cache.token_out_price.max,
            _params.amount_in,
            cache.amount_in,
            cache.amount_out,
            price_impact_usd_felt252.try_into().unwrap(), //TODO: should accept i128
            price_impact_amount_felt252.try_into().unwrap() //TODO: should accept i128
        );

    params
        .event_emitter
        .emit_swap_fees_collected(
            _params.market.market_token, _params.token_in, cache.token_in_price.min, 'swap', fees
        );
    (cache.token_out, cache.amount_out)
}
