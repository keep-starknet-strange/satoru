// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use core::integer::I128Neg;


// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::market::{market::Market, market_utils};
use satoru::fee::fee_utils;
use satoru::utils::{calc, store_arrays::StoreMarketSpan, traits::ContractAddressDefault};
use satoru::utils::i128::{I128Store, I128Serde, I128Div, I128Mul, I128Default};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::swap::error::SwapError;
use satoru::data::keys;
use satoru::pricing::swap_pricing_utils;
use satoru::price::price::{Price, PriceTrait, PriceDefault};

/// Parameters to execute a swap.
#[derive(Drop, Copy, starknet::Store, Serde)]
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
    swap_path_markets: Span<Market>,
    /// The minimum amount of tokens that should be received as part of the swap.
    min_output_amount: u128,
    /// The minimum amount of tokens that should be received as part of the swap.
    receiver: ContractAddress,
    /// The address of the ui fee receiver.
    ui_fee_receiver: ContractAddress,
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
            swap_path_markets: array![].span(),
            min_output_amount: 0,
            receiver: contract_address,
            ui_fee_receiver: contract_address,
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
    price_impact_usd: i128,
    /// The price impact of the swap in tokens.
    price_impact_amount: i128,
}

/// Swaps a given amount of a given token for another token based on a
/// specified swap path.
/// # Arguments
/// * `params` - The parameters for the swap.
/// # Returns
/// A tuple containing the address of the token that was received as
/// part of the swap and the amount of the received token.
fn swap(params: @SwapParams) -> (ContractAddress, u128) {
    if (*params.amount_in == 0) {
        return (*params.token_in, *params.amount_in);
    }
    let array_length = (*params.swap_path_markets).len();
    if (array_length == 0) {
        if (*params.amount_in < *params.min_output_amount) {
            SwapError::INSUFFICIENT_OUTPUT_AMOUNT(*params.amount_in, *params.min_output_amount);
        }
        if (params.bank.contract_address != params.receiver) {
            (*params.bank).transfer_out(*params.token_in, *params.receiver, *params.amount_in);
        }
        return (*params.token_in, *params.amount_in);
    }
    let first_path: Market = *params.swap_path_markets[0];
    if (params.bank.contract_address != @first_path.market_token) {
        (*params.bank).transfer_out(*params.token_in, first_path.market_token, *params.amount_in);
    }
    let mut token_out = *params.token_in;
    let mut output_amount = *params.amount_in;
    let mut i = 0;
    loop {
        if (i >= array_length) {
            break;
        }
        let market: Market = *params.swap_path_markets[i];
        let flag_exists = (*params.data_store)
            .get_bool(keys::swap_path_market_flag_key(market.market_token))
            .expect('get_bool failed');
        if (flag_exists) {
            SwapError::DUPLICATED_MARKET_IN_SWAP_PATH(market.market_token);
        }
        (*params.data_store).set_bool(keys::swap_path_market_flag_key(market.market_token), true);
        let next_index = i + 1;
        let path: Market = *params.swap_path_markets[next_index];
        let receiver = if (next_index < array_length) {
            path.market_token
        } else {
            *params.receiver
        };
        let _params = _SwapParams {
            market: market, token_in: token_out, amount_in: output_amount, receiver: receiver,
        };
        let (_token_out_res, _output_amount_res) = _swap(params, @_params);
        token_out = _token_out_res;
        output_amount = _output_amount_res;
        i += 1;
    };
    i = 0;
    loop {
        if (i >= array_length) {
            break;
        }
        let market: Market = *params.swap_path_markets[i];
        (*params.data_store).set_bool(keys::swap_path_market_flag_key(market.market_token), false);
        i += 1;
    };
    if (output_amount < *params.min_output_amount) {
        SwapError::INSUFFICIENT_OUTPUT_AMOUNT(output_amount, *params.min_output_amount);
    }

    (token_out, output_amount)
}

/// Perform a swap on a single market.
/// * `params` - The parameters for the swap.
/// * `_params` - The parameters for the swap on this specific market.
/// # Returns
/// The token and amount that was swapped.
fn _swap(params: @SwapParams, _params: @_SwapParams) -> (ContractAddress, u128) {
    if (_params.token_in != _params.market.long_token
        && _params.token_in != _params.market.short_token) {
        SwapError::INVALID_TOKEN_IN(*_params.token_in, *_params.market.long_token);
    }
    let mut cache: SwapCache = Default::default();

    market_utils::validate_swap_market(*params.data_store, *_params.market);

    cache.token_out = market_utils::get_opposite_token(*_params.token_in, _params.market);
    cache.token_in_price = (*params.oracle).get_primary_price(*_params.token_in);
    cache.token_out_price = (*params.oracle).get_primary_price(cache.token_out);

    let usd_delta_for_token_felt252: felt252 = (*_params.amount_in
        * cache.token_out_price.mid_price())
        .into();

    let usd_delta = *_params.amount_in * cache.token_out_price.mid_price();
    let price_impact_usd = swap_pricing_utils::get_price_impact_usd(
        swap_pricing_utils::GetPriceImpactUsdParams {
            data_store: *params.data_store,
            market: *_params.market,
            token_a: *_params.token_in,
            token_b: cache.token_out,
            price_for_token_a: cache.token_in_price.mid_price(),
            price_for_token_b: cache.token_out_price.mid_price(),
            usd_delta_for_token_a: calc::to_signed(usd_delta, true),
            usd_delta_for_token_b: calc::to_signed(usd_delta, false),
        }
    );

    let fees = swap_pricing_utils::get_swap_fees(
        *params.data_store,
        *_params.market.market_token,
        *_params.amount_in,
        price_impact_usd > 0,
        *params.ui_fee_receiver
    );

    fee_utils::increment_claimable_fee_amount(
        *params.data_store,
        *params.event_emitter,
        *_params.market.market_token,
        *_params.token_in,
        fees.fee_receiver_amount,
        keys::swap_fee_type(),
    );

    fee_utils::increment_claimable_ui_fee_amount(
        *params.data_store,
        *params.event_emitter,
        *params.ui_fee_receiver,
        *_params.market.market_token,
        *_params.token_in,
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
            market_utils::apply_swap_impact_with_cap(
                *params.data_store,
                *params.event_emitter,
                *_params.market.market_token,
                cache.token_out,
                cache.token_out_price,
                price_impact_usd
            );

        cache.amount_out += calc::to_unsigned(price_impact_amount);
    } else {
        // when there is a negative price impact factor,
        // less of the input amount is sent to the pool
        // for example, if 10 ETH is swapped in and there is a negative price impact
        // only 9.995 ETH may be swapped in
        // the remaining 0.005 ETH will be stored in the swap impact pool
        price_impact_amount =
            market_utils::apply_swap_impact_with_cap(
                *params.data_store,
                *params.event_emitter,
                *_params.market.market_token,
                *_params.token_in,
                cache.token_in_price,
                price_impact_usd
            );

        if fees.amount_after_fees <= calc::to_unsigned(-price_impact_amount) {
            SwapError::SWAP_PRICE_IMPACT_EXCEEDS_AMOUNT_IN(
                fees.amount_after_fees, price_impact_amount
            );
        }
        cache.amount_in = fees.amount_after_fees - calc::to_unsigned(-price_impact_amount);
        cache.amount_out = cache.amount_in * cache.token_in_price.min / cache.token_out_price.max;
        cache.pool_amount_out = cache.amount_out;
    }

    // the amountOut value includes the positive price impact amount
    if (_params.receiver != _params.market.market_token) {
        IBankDispatcher { contract_address: *_params.market.market_token }
            .transfer_out(cache.token_out, *_params.receiver, cache.amount_out);
    }

    let mut delta_felt252: felt252 = (cache.amount_in + fees.fee_amount_for_pool).into();
    market_utils::apply_delta_to_pool_amount(
        *params.data_store,
        *params.event_emitter,
        *_params.market,
        *_params.token_in,
        delta_felt252.try_into().expect('felt252 into u128 faild'),
    );

    // the poolAmountOut excludes the positive price impact amount
    // as that is deducted from the swap impact pool instead
    market_utils::apply_delta_to_pool_amount(
        *params.data_store,
        *params.event_emitter,
        *_params.market,
        cache.token_out,
        calc::to_signed(cache.pool_amount_out, false),
    );

    let prices = market_utils::MarketPrices {
        index_token_price: (*params.oracle).get_primary_price(*_params.market.index_token),
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

    market_utils::validate_pool_amount(params.data_store, _params.market, *_params.token_in);
    market_utils::validata_reserve(
        params.data_store, _params.market, @prices, cache.token_out == *_params.market.long_token
    );
    let (pnl_factor_type_for_longs, pnl_factor_type_for_shorts) = if (cache
        .token_out == *_params
        .market
        .long_token) {
        (keys::max_pnl_factor_for_deposits(), keys::max_pnl_factor_for_withdrawals())
    } else {
        (keys::max_pnl_factor_for_withdrawals(), keys::max_pnl_factor_for_deposits())
    };

    market_utils::validate_max_pnl(
        *params.data_store,
        *_params.market,
        @prices,
        if (*_params.token_in == *_params.market.long_token) {
            keys::max_pnl_factor_for_deposits()
        } else {
            keys::max_pnl_factor_for_withdrawals()
        },
        if (cache.token_out == *_params.market.short_token) {
            keys::max_pnl_factor_for_withdrawals()
        } else {
            keys::max_pnl_factor_for_deposits()
        }
    );

    (*params.event_emitter)
        .emit_swap_info(
            *params.key,
            *_params.market.market_token,
            *_params.receiver,
            *_params.token_in,
            cache.token_out,
            cache.token_in_price.min,
            cache.token_out_price.max,
            *_params.amount_in,
            cache.amount_in,
            cache.amount_out,
            price_impact_usd,
            price_impact_amount,
        );

    (*params.event_emitter)
        .emit_swap_fees_collected(
            *_params.market.market_token, *_params.token_in, cache.token_in_price.min, 'swap', fees
        );
    (cache.token_out, cache.amount_out)
}
