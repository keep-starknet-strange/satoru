//! Library for deposit functions, to help with the depositing of liquidity
//! into a market in return for market tokens.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;

// Local imports.
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::callback::callback_utils::after_deposit_execution;
use satoru::data::{
    keys::{deposit_fee_type, ui_deposit_fee_type, max_pnl_factor_for_deposits},
    data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait}
};
use satoru::deposit::{
    deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait}, error::DepositError
};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::event::event_utils::{LogData, LogDataTrait, ContractAddressDictValue, I256252DictValue};
use satoru::utils::serializable_dict::{SerializableFelt252Dict, SerializableFelt252DictTrait};
use satoru::fee::fee_utils;
use satoru::gas::gas_utils::pay_execution_fee_deposit;
use satoru::market::{
    market::Market, market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait},
    market_utils
};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::oracle::{oracle::{IOracleDispatcher, IOracleDispatcherTrait}, oracle_utils};
use satoru::price::price::{Price, PriceTrait};
use satoru::pricing::swap_pricing_utils::{
    get_swap_fees, get_price_impact_usd, GetPriceImpactUsdParams
};
use satoru::swap::swap_utils;
use satoru::swap::error::SwapError;
use satoru::utils::{
    calc::{to_unsigned, to_signed}, i256::{i256, i256_new, i256_neg}, precision, span32::Span32,
    starknet_utils::{sn_gasleft, sn_gasprice}
};
use satoru::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};

/// Struct used in executeDeposit to avoid stack too deep errors
#[derive(Drop, Serde)]
struct ExecuteDepositParams {
    /// `data_store` contract dispatcher.
    data_store: IDataStoreDispatcher,
    /// `event_emitter` contract dispatcher.
    event_emitter: IEventEmitterDispatcher,
    /// `deposit_vault` contract dispatcher.
    deposit_vault: IDepositVaultDispatcher,
    /// `oracle` contract dispatcher.
    oracle: IOracleDispatcher,
    /// `key` the key of the deposit to execute.
    key: felt252,
    /// `min_oracle_block_numbers` the min oracle block numbers.
    min_oracle_block_numbers: Array<u64>,
    /// `max_oracle_block_numbers` the max oracle block numbers
    max_oracle_block_numbers: Array<u64>,
    /// `keeper` the address of the keeper executing the deposit.
    keeper: ContractAddress,
    /// `starting_gas` the starting amount of gas.
    starting_gas: u256
}

/// Struct used in executeDeposit to avoid stack too deep errors
#[derive(Drop, starknet::Store, Serde)]
struct _ExecuteDepositParams {
    /// `market` The market to deposit into.
    market: Market,
    /// `account` The depositing account.
    account: ContractAddress,
    /// `receiver` The account to send the market tokens to.
    receiver: ContractAddress,
    /// `ui_fee_receiver` The ui fee receiver account.
    ui_fee_receiver: ContractAddress,
    /// `token_in` The token to deposit.
    token_in: ContractAddress,
    /// `token_out` The other token.
    token_out: ContractAddress,
    /// `token_in_price` Price of token_in.
    token_in_price: Price,
    /// `token_out_price` Price of token_out.
    token_out_price: Price,
    /// `amount` Amount of token_in.
    amount: u256,
    /// `price_impact_usd` Price impact in USD.
    price_impact_usd: i256
}

#[derive(Drop, Default)]
struct ExecuteDepositCache {
    long_token_amount: u256,
    short_token_amount: u256,
    long_token_usd: u256,
    short_token_usd: u256,
    received_market_tokens: u256,
    price_impact_usd: i256
}

/// Executes a deposit.
/// # Arguments
/// * `params` - ExecuteDepositParams.
fn execute_deposit(params: ExecuteDepositParams) {
    // 63/64 gas is forwarded to external calls, reduce the startingGas to account for this
    let starting_gas = params.starting_gas - sn_gasleft(array![]) / 63;

    let deposit = params.data_store.get_deposit(params.key);
    params.data_store.remove_deposit(params.key, deposit.account);

    let mut cache: ExecuteDepositCache = Default::default();

    assert(deposit.account.is_non_zero(), DepositError::EMPTY_DEPOSIT);

    oracle_utils::validate_block_number_within_range(
        params.min_oracle_block_numbers.span(),
        params.max_oracle_block_numbers.span(),
        deposit.updated_at_block,
    );

    let market = market_utils::get_enabled_market(params.data_store, deposit.market);
    let prices = market_utils::get_market_prices(params.oracle, market);

    // deposits should improve the pool state but it should be checked if
    // the max pnl factor for deposits is exceeded as this would lead to the
    // price of the market token decreasing below a target minimum percentage
    // due to pnl
    // note that this is just a validation for deposits, there is no actual
    // minimum price for a market token
    market_utils::validate_max_pnl(
        params.data_store,
        market,
        prices,
        max_pnl_factor_for_deposits(),
        max_pnl_factor_for_deposits(),
    );

    cache
        .long_token_amount =
            swap(
                @params,
                deposit.long_token_swap_path,
                deposit.initial_long_token,
                deposit.initial_long_token_amount,
                market.market_token,
                market.long_token,
                deposit.ui_fee_receiver,
            );

    cache
        .short_token_amount =
            swap(
                @params,
                deposit.short_token_swap_path,
                deposit.initial_short_token,
                deposit.initial_short_token_amount,
                market.market_token,
                market.short_token,
                deposit.ui_fee_receiver,
            );

    if cache.long_token_amount == 0 && cache.short_token_amount == 0 {
        panic_with_felt252(DepositError::EMPTY_DEPOSIT_AMOUNTS_AFTER_SWAP)
    }

    cache.long_token_usd = cache.long_token_amount * prices.long_token_price.mid_price();
    cache.short_token_usd = cache.short_token_amount * prices.short_token_price.mid_price();

    cache
        .price_impact_usd =
            get_price_impact_usd(
                GetPriceImpactUsdParams {
                    data_store: params.data_store,
                    market: market,
                    token_a: market.long_token,
                    token_b: market.short_token,
                    price_for_token_a: prices.long_token_price.mid_price(),
                    price_for_token_b: prices.short_token_price.mid_price(),
                    usd_delta_for_token_a: to_signed(cache.long_token_usd, true),
                    usd_delta_for_token_b: to_signed(cache.short_token_usd, true),
                }
            );

    if cache.long_token_amount > 0 {
        let mut _params = _ExecuteDepositParams {
            market: market,
            account: deposit.account,
            receiver: deposit.receiver,
            ui_fee_receiver: deposit.ui_fee_receiver,
            token_in: market.long_token,
            token_out: market.short_token,
            token_in_price: prices.long_token_price,
            token_out_price: prices.short_token_price,
            amount: cache.long_token_amount,
            price_impact_usd: precision::mul_div_ival(
                cache.price_impact_usd,
                cache.long_token_usd,
                cache.long_token_usd + cache.short_token_usd
            )
        };

        cache.received_market_tokens += execute_deposit_helper(@params, ref _params);
    }

    if cache.short_token_amount > 0 {
        let mut _params = _ExecuteDepositParams {
            market: market,
            account: deposit.account,
            receiver: deposit.receiver,
            ui_fee_receiver: deposit.ui_fee_receiver,
            token_in: market.short_token,
            token_out: market.long_token,
            token_in_price: prices.short_token_price,
            token_out_price: prices.long_token_price,
            amount: cache.short_token_amount,
            price_impact_usd: precision::mul_div_ival(
                cache.price_impact_usd,
                cache.short_token_usd,
                cache.long_token_usd + cache.short_token_usd
            )
        };

        cache.received_market_tokens += execute_deposit_helper(@params, ref _params);
    }

    if cache.received_market_tokens < deposit.min_market_tokens {
        DepositError::MIN_MARKET_TOKENS(cache.received_market_tokens, deposit.min_market_tokens);
    }

    market_utils::validate_market_token_balance_check(params.data_store, market);

    (params.event_emitter)
        .emit_deposit_executed(
            params.key,
            cache.long_token_amount,
            cache.short_token_amount,
            cache.received_market_tokens,
        );
    // let mut event_data: LogData = Default::default();
    // event_data.uint_dict.insert_single('received_market_tokens', cache.received_market_tokens);
    // after_deposit_execution(params.key, deposit, event_data);

    pay_execution_fee_deposit(
        params.data_store,
        params.event_emitter,
        params.deposit_vault,
        deposit.execution_fee,
        params.starting_gas,
        params.keeper,
        deposit.account,
    );
}

/// Executes a deposit.
/// # Arguments
/// * `params` - @ExecuteDepositParams.
/// * `_params` - @_ExecuteDepositParams.
fn execute_deposit_helper(
    params: @ExecuteDepositParams, ref _params: _ExecuteDepositParams
) -> u256 {
    // for markets where longToken == shortToken, the price impact factor should be set to zero
    // in which case, the priceImpactUsd would always equal zero
    let mut fees = get_swap_fees(
        *params.data_store,
        _params.market.market_token,
        _params.amount,
        _params.price_impact_usd > Zeroable::zero(),
        _params.ui_fee_receiver,
    );

    fee_utils::increment_claimable_fee_amount(
        *params.data_store,
        *params.event_emitter,
        _params.market.market_token,
        _params.token_in,
        fees.fee_receiver_amount,
        deposit_fee_type(),
    );

    fee_utils::increment_claimable_ui_fee_amount(
        *params.data_store,
        *params.event_emitter,
        _params.ui_fee_receiver,
        _params.market.market_token,
        _params.token_in,
        fees.ui_fee_amount,
        ui_deposit_fee_type(),
    );

    (*params.event_emitter)
        .emit_swap_fees_collected(
            _params.market.market_token,
            _params.token_in,
            _params.token_in_price.min,
            'deposit',
            fees.clone(),
        );

    let pool_value_info = market_utils::get_pool_value_info(
        *params.data_store,
        _params.market,
        (*params.oracle).get_primary_price(_params.market.index_token),
        if _params.token_in == _params.market.long_token {
            _params.token_in_price
        } else {
            _params.token_out_price
        },
        if _params.token_in == _params.market.short_token {
            _params.token_in_price
        } else {
            _params.token_out_price
        },
        max_pnl_factor_for_deposits(),
        true,
    );

    //TODO add the pool_value_info.pool in the error message
    if pool_value_info.pool_value < Zeroable::zero() {
    panic_with_felt252(DepositError::INVALID_POOL_VALUE_FOR_DEPOSIT(pool_value_info.pool_value));
}

    let mut mint_amount = 0;
    let pool_value = to_unsigned(pool_value_info.pool_value);
    let market_tokens_supply = market_utils::get_market_token_supply(
        IMarketTokenDispatcher { contract_address: _params.market.market_token }
    );

    if pool_value == Zeroable::zero() && market_tokens_supply > 0 {
        panic_with_felt252(DepositError::INVALID_POOL_VALUE_FOR_DEPOSIT)
    }

    (*params.event_emitter)
        .emit_market_pool_value_info(
            _params.market.market_token, pool_value_info, market_tokens_supply,
        );

    // the pool_value and market_tokens_supply is cached for the mint_amount calculation below
    // so the effect of any positive price impact on the pool_value and market_tokens_supply
    // would not be accounted for
    //
    // for most cases, this should not be an issue, since the pool_value and market_tokens_supply
    // should have been proportionately increased
    //
    // e.g. if the pool_value is $100 and market_tokens_supply is 100, and there is a positive price impact
    // of $10, the pool_value should have increased by $10 and the market_tokens_supply should have been increased by 10
    //
    // there is a case where this may be an issue which is when all tokens are withdrawn from an existing market
    // and the market_tokens_supply is reset to zero, but the pool_value is not entirely zero
    // the case where this happens should be very rare and during withdrawal the pool_value should be close to zero
    //
    // however, in case this occurs, the usdToMarketTokenAmount will mint an additional number of market tokens
    // proportional to the existing pool_value
    //
    // since the pool_value and market_tokens_supply is cached, this could occur once during positive price impact
    // and again when calculating the mint_amount
    //
    // to avoid this, set the price_impact_usd to be zero for this case

    if _params.price_impact_usd > Zeroable::zero() && market_tokens_supply == Zeroable::zero() {
        _params.price_impact_usd = i256_new(0, false);
    }

    if _params.price_impact_usd > Zeroable::zero() {
        // when there is a positive price impact factor,
        // tokens from the swap impact pool are used to mint additional market tokens for the user
        // for example, if 50,000 USDC is deposited and there is a positive price impact
        // an additional 0.005 ETH may be used to mint market tokens
        // the swap impact pool is decreased by the used amount
        //
        // price_impact_usd is calculated based on pricing assuming only depositAmount of tokenIn
        // was added to the pool
        // since impactAmount of tokenOut is added to the pool here, the calculation of
        // the price impact would not be entirely accurate
        //
        // it is possible that the addition of the positive impact amount of tokens into the pool
        // could increase the imbalance of the pool, for most cases this should not be a significant
        // change compared to the improvement of balance from the actual deposit

        let positive_impact_amount = market_utils::apply_swap_impact_with_cap(
            *params.data_store,
            *params.event_emitter,
            _params.market.market_token,
            _params.token_out,
            _params.token_out_price,
            _params.price_impact_usd,
        );

        // calculate the usd amount using positiveImpactAmount since it may
        // be capped by the max available amount in the impact pool
        // use tokenOutPrice.max to get the USD value since the positiveImpactAmount
        // was calculated using a USD value divided by tokenOutPrice.max
        //
        // for the initial deposit, the pool value and token supply would be zero
        // so the market token price is treated as 1 USD
        //
        // it is possible for the pool value to be more than zero and the token supply
        // to be zero, in that case, the market token price is also treated as 1 USD
        mint_amount +=
            market_utils::usd_to_market_token_amount(
                to_unsigned(positive_impact_amount) * _params.token_out_price.max,
                pool_value,
                market_tokens_supply,
            );

        market_utils::apply_delta_to_pool_amount(
            *params.data_store,
            *params.event_emitter,
            _params.market,
            _params.token_out,
            positive_impact_amount
        );

        market_utils::validate_pool_amount(params.data_store, @_params.market, _params.token_out);
    }

    if (_params.price_impact_usd < Zeroable::zero()) {
        // when there is a negative price impact factor,
        // less of the deposit amount is used to mint market tokens
        // for example, if 10 ETH is deposited and there is a negative price impact
        // only 9.995 ETH may be used to mint market tokens
        // the remaining 0.005 ETH will be stored in the swap impact pool
        let negative_impact_amount = market_utils::apply_swap_impact_with_cap(
            *params.data_store,
            *params.event_emitter,
            _params.market.market_token,
            _params.token_in,
            _params.token_in_price,
            _params.price_impact_usd,
        );

        fees.amount_after_fees -= to_unsigned(i256_neg(negative_impact_amount));
    }

    mint_amount +=
        market_utils::usd_to_market_token_amount(
            fees.amount_after_fees * _params.token_in_price.min, pool_value, market_tokens_supply,
        );

    market_utils::apply_delta_to_pool_amount(
        *params.data_store,
        *params.event_emitter,
        _params.market,
        _params.token_in,
        to_signed(fees.amount_after_fees + fees.fee_amount_for_pool, true),
    );

    market_utils::validate_pool_amount(params.data_store, @_params.market, _params.token_in);

    IMarketTokenDispatcher { contract_address: _params.market.market_token }
        .mint(_params.receiver, mint_amount);

    mint_amount
}

fn swap(
    params: @ExecuteDepositParams,
    swap_path: Span32<ContractAddress>,
    initial_token: ContractAddress,
    input_amount: u256,
    market: ContractAddress,
    expected_output_token: ContractAddress,
    ui_fee_receiver: ContractAddress
) -> u256 {
    let swap_path_markets = market_utils::get_swap_path_markets(*params.data_store, swap_path);

    let (output_token, output_amount) = swap_utils::swap(
        @swap_utils::SwapParams {
            data_store: *params.data_store,
            event_emitter: *params.event_emitter,
            oracle: *params.oracle,
            bank: IBankDispatcher { contract_address: market },
            key: *params.key,
            token_in: initial_token,
            amount_in: input_amount,
            swap_path_markets: swap_path_markets.span(),
            min_output_amount: 0,
            receiver: market,
            ui_fee_receiver: ui_fee_receiver,
        }
    );

    if output_token != expected_output_token {
        SwapError::INVALID_SWAP_OUTPUT_TOKEN(output_token, expected_output_token)
    }

    market_utils::validate_market_token_balance_array(*params.data_store, swap_path_markets);

    output_amount
}
