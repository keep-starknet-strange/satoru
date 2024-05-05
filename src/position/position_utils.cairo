//! Library for position functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use poseidon::poseidon_hash_span;
// Local imports.
use satoru::data::{data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait}, keys};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::market::{market::Market, market_utils::MarketPrices, market_utils};
use satoru::position::{position::Position, error::PositionError};
use satoru::pricing::{
    position_pricing_utils, position_pricing_utils::PositionFees,
    position_pricing_utils::GetPriceImpactUsdParams, position_pricing_utils::GetPositionFeesParams
};
use satoru::order::{
    order::{Order, SecondaryOrderType}, base_order_utils::ExecuteOrderParamsContracts,
    order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait}
};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::price::price::{Price, PriceTrait};
use satoru::utils::{calc, precision, i256::i256, default::DefaultContractAddress, error_utils};
use satoru::referral::referral_utils;

/// Struct used in increasePosition and decreasePosition.
#[derive(Drop, Copy, starknet::Store, Serde)]
struct UpdatePositionParams {
    /// BaseOrderUtils.ExecuteOrderParamsContracts
    contracts: ExecuteOrderParamsContracts,
    /// The values of the trading market.
    market: Market,
    /// The decrease position order.
    order: Order,
    /// The key of the order.
    order_key: felt252,
    /// The order's position.
    position: Position,
    /// The key of the order's position.
    position_key: felt252,
    /// The secondary oder type.
    secondary_order_type: SecondaryOrderType,
}

impl DefaultUpdatePositionParams of Default<UpdatePositionParams> {
    fn default() -> UpdatePositionParams {
        let contract_address = contract_address_const::<0>();
        UpdatePositionParams {
            contracts: ExecuteOrderParamsContracts {
                data_store: IDataStoreDispatcher { contract_address },
                event_emitter: IEventEmitterDispatcher { contract_address },
                order_vault: IOrderVaultDispatcher { contract_address },
                oracle: IOracleDispatcher { contract_address },
                swap_handler: ISwapHandlerDispatcher { contract_address },
                referral_storage: IReferralStorageDispatcher { contract_address }
            },
            market: Default::default(),
            order: Default::default(),
            order_key: 0,
            position: Default::default(),
            position_key: 0,
            secondary_order_type: SecondaryOrderType::None,
        }
    }
}

/// Struct to determine wether position collateral will be sufficient.
#[derive(Drop, starknet::Store, Serde)]
struct WillPositionCollateralBeSufficientValues {
    position_size_in_usd: u256,
    position_collateral_amount: u256,
    realized_pnl_usd: i256,
    open_interest_delta: i256,
}

/// Struct used as decrease_position_collateral output.
#[derive(Drop, starknet::Store, Serde, Default, Copy)]
struct DecreasePositionCollateralValuesOutput {
    /// The output token address.
    output_token: ContractAddress,
    /// The output amount in tokens.
    output_amount: u256,
    /// The seconary output token address.
    secondary_output_token: ContractAddress,
    /// The secondary output amount in tokens.
    secondary_output_amount: u256,
}

/// Struct used to contain the values in process_collateral
#[derive(Drop, starknet::Store, Serde, Default, Copy)]
struct DecreasePositionCollateralValues {
    /// The order execution price.
    execution_price: u256,
    /// The remaining collateral amount of the position.
    remaining_collateral_amount: u256,
    /// The pnl of the position in USD.
    base_pnl_usd: i256,
    /// The uncapped pnl of the position in USD.
    uncapped_base_pnl_usd: i256,
    /// The change in position size in tokens.
    size_delta_in_tokens: u256,
    /// The price impact in usd.
    price_impact_usd: i256,
    /// The price impact difference in USD.
    price_impact_diff_usd: u256,
    /// The output struct.
    output: DecreasePositionCollateralValuesOutput
}

#[derive(Copy, Drop, starknet::Store, Serde)]
struct DecreasePositionCache {
    /// The prices of the tokens in the market.
    prices: MarketPrices,
    /// The estimated position pnl in USD.
    estimated_position_pnl_usd: i256,
    /// The estimated realized position pnl in USD after decrease.
    estimated_realized_pnl_usd: i256,
    /// The estimated remaining position pnl in USD.
    estimated_remaining_pnl_usd: i256,
    /// The token that the pnl for the user is in, for long positions.
    /// This is the market.longToken, for short positions this is the market.short_token.
    pnl_token: ContractAddress,
    /// The price of the pnl_token.
    pnl_token_price: Price,
    /// The price of the collateral token.
    collateral_token_price: Price,
    /// The initial collateral amount.
    initial_collateral_amount: u256,
    /// The new position size in USD.
    next_position_size_in_usd: u256,
    /// The new position borrowing factor.
    next_position_borrowing_factor: u256,
}

/// Struct used as cache in get_position_pnl.
#[derive(Drop, starknet::Store, Serde)]
struct GetPositionPnlUsdCache {
    /// The position value.
    position_value: i256,
    /// The total position pnl.
    total_position_pnl: i256,
    /// The uncapped total position pnl.
    uncapped_total_position_pnl: i256,
    /// The pnl token address.
    pnl_token: ContractAddress,
    /// The amount of token in pool.
    pool_token_amount: u256,
    /// The price of pool token.
    pool_token_price: u256,
    /// The pool token value in usd.
    pool_token_usd: u256,
    /// The total pool pnl.
    pool_pnl: i256,
    /// The capped pool pnl.
    capped_pool_pnl: i256,
    /// The size variation in tokens.
    size_delta_in_tokens: u256,
    /// The positions pnl in usd.
    position_pnl_usd: i256,
    /// The uncapped positions pnl in usd.
    uncapped_position_pnl_usd: i256,
}

/// Struct used as cache in is_position_liquidatable.
#[derive(Drop, starknet::Store, Serde)]
struct IsPositionLiquidatableCache {
    /// The position's pnl in USD.
    position_pnl_usd: i256,
    /// The min collateral factor.
    min_collateral_factor: u256,
    /// The collateral token price.
    collateral_token_price: Price,
    /// The position's collateral in USD.
    collateral_usd: u256,
    /// The usd_delta value for the price impact calculation.
    usd_delta_for_price_impact: i256,
    /// The price impact of closing the position in USD.
    price_impact_usd: i256,
    has_positive_impact: bool,
    /// The minimum allowed collateral in USD.
    min_collateral_usd: i256,
    min_collateral_usd_for_leverage: i256,
    /// The remaining position collateral in USD.
    remaining_collateral_usd: i256,
}

impl DefaultGetPositionPnlUsdCache of Default<GetPositionPnlUsdCache> {
    fn default() -> GetPositionPnlUsdCache {
        GetPositionPnlUsdCache {
            position_value: Zeroable::zero(),
            total_position_pnl: Zeroable::zero(),
            uncapped_total_position_pnl: 0.into(),
            pnl_token: contract_address_const::<0>(),
            pool_token_amount: 0,
            pool_token_price: 0,
            pool_token_usd: 0,
            pool_pnl: Zeroable::zero(),
            capped_pool_pnl: Zeroable::zero(),
            size_delta_in_tokens: 0,
            position_pnl_usd: Zeroable::zero(),
            uncapped_position_pnl_usd: Zeroable::zero(),
        }
    }
}

impl DefaultIsPositionLiquidatableCache of Default<IsPositionLiquidatableCache> {
    fn default() -> IsPositionLiquidatableCache {
        IsPositionLiquidatableCache {
            position_pnl_usd: Zeroable::zero(),
            min_collateral_factor: 0,
            collateral_token_price: Price { min: 0, max: 0 },
            collateral_usd: 0,
            usd_delta_for_price_impact: Zeroable::zero(),
            price_impact_usd: Zeroable::zero(),
            has_positive_impact: false,
            min_collateral_usd: Zeroable::zero(),
            min_collateral_usd_for_leverage: Zeroable::zero(),
            remaining_collateral_usd: Zeroable::zero()
        }
    }
}

impl DefaultDecreasePositionCache of Default<DecreasePositionCache> {
    fn default() -> DecreasePositionCache {
        DecreasePositionCache {
            prices: Default::default(),
            estimated_position_pnl_usd: Zeroable::zero(),
            estimated_realized_pnl_usd: Zeroable::zero(),
            estimated_remaining_pnl_usd: Zeroable::zero(),
            pnl_token: Default::default(),
            pnl_token_price: Default::default(),
            collateral_token_price: Default::default(),
            initial_collateral_amount: Default::default(),
            next_position_size_in_usd: Default::default(),
            next_position_borrowing_factor: Default::default(),
        }
    }
}


/// Get the position pnl in USD.
///
/// For long positions, pnl is calculated as:
/// (position.sizeInTokens * indexTokenPrice) - position.sizeInUsd
/// If position.sizeInTokens is larger for long positions, the position will have
/// larger profits and smaller losses for the same changes in token price.
///
/// For short positions, pnl is calculated as:
/// position.sizeInUsd -  (position.sizeInTokens * indexTokenPrice)
/// If position.sizeInTokens is smaller for long positions, the position will have
/// larger profits and smaller losses for the same changes in token price.
/// # Arguments
/// *`data_store` - The data store dispatcher
/// *`market` - The market
/// *`position` - The position values
/// *`size_delta_usd` - The change in position size
/// # Returns
/// (position_pnl_usd, uncapped_position_pnl_usd, size_delta_in_tokens)
fn get_position_pnl_usd(
    data_store: IDataStoreDispatcher,
    market: Market,
    prices: MarketPrices,
    position: Position,
    size_delta_usd: u256,
) -> (i256, i256, u256) {
    let mut cache: GetPositionPnlUsdCache = Default::default();
    let execution_price = prices.index_token_price.pick_price_for_pnl(position.is_long, false);
    // position.sizeInUsd is the cost of the tokens, positionValue is the current worth of the tokens
    cache.position_value = calc::to_signed(position.size_in_tokens * execution_price, true);
    cache
        .total_position_pnl =
            if position.is_long {
                cache.position_value - calc::to_signed(position.size_in_usd, true)
            } else {
                calc::to_signed(position.size_in_usd, true) - cache.position_value
            };
    cache.uncapped_total_position_pnl = cache.total_position_pnl;

    if (cache.total_position_pnl > Zeroable::zero()) {
        cache.pnl_token = if position.is_long {
            market.long_token
        } else {
            market.short_token
        };
        cache
            .pool_token_amount =
                market_utils::get_pool_amount(data_store, @market, cache.pnl_token);
        cache
            .pool_token_price =
                if position.is_long {
                    prices.long_token_price.min
                } else {
                    prices.short_token_price.min
                };
        cache.pool_token_usd = cache.pool_token_amount * cache.pool_token_price;
        cache
            .pool_pnl =
                market_utils::get_pnl(
                    data_store, @market, @prices.index_token_price, position.is_long, true
                );
        cache
            .capped_pool_pnl =
                market_utils::get_capped_pnl(
                    data_store,
                    market.market_token,
                    position.is_long,
                    cache.pool_pnl,
                    cache.pool_token_usd,
                    keys::max_pnl_factor_for_traders()
                );
        if (cache.capped_pool_pnl != cache.pool_pnl
            && cache.capped_pool_pnl > Zeroable::zero()
            && cache.pool_pnl > Zeroable::zero()) {
            cache
                .total_position_pnl =
                    precision::mul_div_inum(
                        calc::to_unsigned(cache.total_position_pnl),
                        cache.capped_pool_pnl,
                        calc::to_unsigned(cache.pool_pnl)
                    );
        }
    }
    if position.size_in_usd == size_delta_usd {
        cache.size_delta_in_tokens = position.size_in_tokens;
    } else {
        if position.is_long {
            cache
                .size_delta_in_tokens =
                    calc::roundup_division(
                        position.size_in_tokens * size_delta_usd, position.size_in_usd
                    );
        } else {
            error_utils::check_division_by_zero(position.size_in_usd, 'position.size_in_usd');
            cache.size_delta_in_tokens = position.size_in_tokens
                * size_delta_usd
                / position.size_in_usd;
        }
    }
    cache
        .position_pnl_usd =
            precision::mul_div_ival(
                cache.total_position_pnl, cache.size_delta_in_tokens, position.size_in_tokens
            );
    cache
        .uncapped_position_pnl_usd =
            precision::mul_div_ival(
                cache.uncapped_total_position_pnl,
                cache.size_delta_in_tokens,
                position.size_in_tokens
            );

    (cache.position_pnl_usd, cache.uncapped_position_pnl_usd, cache.size_delta_in_tokens)
}

/// Get the key for a position.
/// # Arguments
/// *`account` - The position's account.
/// *`market` - The market to get the position from.
/// *`collateral_token` - The position's collateralToken.
/// *`is_long` - The position is long or short.
/// # Returns
/// The position key.
fn get_position_key(
    account: ContractAddress,
    market: ContractAddress,
    collateral_token: ContractAddress,
    is_long: bool,
) -> felt252 {
    let mut data = array![];
    data.append(account.into());
    data.append(market.into());
    data.append(collateral_token.into());
    data.append(is_long.into());
    poseidon_hash_span(data.span())
}

/// Validate that a position is not empty.
/// # Arguments
/// *`position` - The position to validate.
fn validate_non_empty_position(position: Position,) {
    if (position.size_in_usd == 0
        && position.size_in_tokens == 0
        && position.collateral_amount == 0) {
        panic_with_felt252(PositionError::EMPTY_POSITION);
    }
}

/// Check if a position is valid.
/// # Arguments
/// *`data_store` - The data store dispatcher.
/// *`referral_storage` - The Referral Storage dispatcher.
/// *`position` - The position values.
/// *`market` - The market values.
/// *`prices` - The prices of the tokens in the market.
/// *`should_validate_min_collateral_usd` - Whether min collateral usd needs to be validated.
/// Validation is skipped for decrease position to prevent reverts in case the order size
/// is just slightly smaller than the position size.
/// In decrease position, the remaining collateral is estimated at the start, and the order
/// size is updated to match the position size if the remaining collateral will be less than
/// the min collateral usd.
/// Since this is an estimate, there may be edge cases where there is a small remaining position size
/// and small amount of collateral remaining.
/// Validation is skipped for this case as it is preferred for the order to be executed
/// since the small amount of collateral remaining only impacts the potential payment of liquidation
/// keepers.
fn validate_position(
    data_store: IDataStoreDispatcher,
    referral_storage: IReferralStorageDispatcher,
    position: Position,
    market: Market,
    prices: MarketPrices,
    should_validate_min_position_size: bool,
    should_validate_min_collateral_usd: bool,
) {
    assert(
        position.size_in_usd != 0 && position.size_in_tokens != 0,
        PositionError::INVALID_POSITION_SIZE_VALUES
    );
    market_utils::validate_enabled_market(data_store, market);
    market_utils::validate_market_collateral_token(market, position.collateral_token);
    if should_validate_min_position_size {
        let min_position_size_usd = data_store.get_u256(keys::min_position_size_usd());
        assert(position.size_in_usd >= min_position_size_usd, PositionError::MIN_POSITION_SIZE);
    }
    let (is_liquiditable, reason) = is_position_liquiditable(
        data_store, referral_storage, position, market, prices, should_validate_min_collateral_usd
    );
    assert(!is_liquiditable, PositionError::LIQUIDATABLE_POSITION);
}

/// Check if a position is liquiditable.
/// # Arguments
/// *`data_store` - The data store dispatcher.
/// *`referral_storage` - The Referral Storage dispatcher.
/// *`position` - The position values.
/// *`market` - The market values.
/// *`prices` - The prices of the tokens in the market.
/// # Returns
/// True if liquiditable and reason of liquiditability, false else.
fn is_position_liquiditable(
    data_store: IDataStoreDispatcher,
    referral_storage: IReferralStorageDispatcher,
    position: Position,
    market: Market,
    prices: MarketPrices,
    should_validate_min_collateral_usd: bool
) -> (bool, felt252) {
    let mut cache: IsPositionLiquidatableCache = Default::default();
    let (pos_pnl_usd, _, _) = get_position_pnl_usd(
        data_store, market, prices, position, position.size_in_usd
    );
    cache.position_pnl_usd = pos_pnl_usd;

    cache
        .collateral_token_price =
            market_utils::get_cached_token_price(position.collateral_token, market, prices);

    cache.collateral_usd = position.collateral_amount * cache.collateral_token_price.min;

    // calculate the usdDeltaForPriceImpact for fully closing the position
    cache.usd_delta_for_price_impact = calc::to_signed(position.size_in_usd, false);
    cache
        .price_impact_usd =
            position_pricing_utils::get_price_impact_usd(
                GetPriceImpactUsdParams {
                    data_store,
                    market,
                    usd_delta: cache.usd_delta_for_price_impact,
                    is_long: position.is_long
                }
            );
    cache.has_positive_impact = cache.price_impact_usd > Zeroable::zero();
    // even if there is a large positive price impact, positions that would be liquidated
    // if the positive price impact is reduced should not be allowed to be created
    // as they would be easily liquidated if the price impact changes
    // cap the priceImpactUsd to zero to prevent these positions from being created
    if cache.price_impact_usd >= Zeroable::zero() {
        cache.price_impact_usd = Zeroable::zero();
    } else {
        let max_price_impact_factor = market_utils::get_max_position_impact_factor_for_liquidations(
            data_store, market.market_token
        );
        // if there is a large build up of open interest and a sudden large price movement
        // it may result in a large imbalance between longs and shorts
        // this could result in very large price impact temporarily
        // cap the max negative price impact to prevent cascading liquidations

        let max_negatice_price_impact = calc::to_signed(
            precision::apply_factor_u256(position.size_in_usd, max_price_impact_factor), true
        );
        if cache.price_impact_usd < max_negatice_price_impact {
            cache.price_impact_usd = max_negatice_price_impact;
        }
    }
    let mut pos_fees_params: GetPositionFeesParams = GetPositionFeesParams {
        data_store,
        referral_storage,
        position,
        collateral_token_price: cache.collateral_token_price,
        for_positive_impact: cache.has_positive_impact,
        long_token: market.long_token,
        short_token: market.short_token,
        size_delta_usd: position.size_in_usd,
        ui_fee_receiver: contract_address_const::<0>(),
    };
    let fees = position_pricing_utils::get_position_fees(pos_fees_params);
    // the totalCostAmount is in tokens, use collateralTokenPrice.min to calculate the cost in USD
    // since in PositionPricingUtils.getPositionFees the totalCostAmount in tokens was calculated
    // using collateralTokenPrice.min
    let collateral_cost_usd = fees.total_cost_amount * cache.collateral_token_price.min;

    // the position's pnl is counted as collateral for the liquidation check
    // as a position in profit should not be liquidated if the pnl is sufficient
    // to cover the position's fees
    cache.remaining_collateral_usd = calc::to_signed(cache.collateral_usd, true)
        + cache.position_pnl_usd
        + cache.price_impact_usd
        - calc::to_signed(collateral_cost_usd, true);

    if should_validate_min_collateral_usd {
        cache
            .min_collateral_usd =
                calc::to_signed(data_store.get_u256(keys::min_collateral_usd()), true);
        if (cache.remaining_collateral_usd < cache.min_collateral_usd) {
            return (true, 'min collateral');
        }
    }
    if cache.remaining_collateral_usd <= Zeroable::zero() {
        return (true, '0<');
    }
    cache
        .min_collateral_factor =
            market_utils::get_min_collateral_factor(data_store, market.market_token);
    // validate if (remaining collateral) / position.size is less than the min collateral factor (max leverage exceeded)
    // this validation includes the position fee to be paid when closing the position
    // i.e. if the position does not have sufficient collateral after closing fees it is considered a liquidatable position
    cache
        .min_collateral_usd_for_leverage =
            calc::to_signed(
                precision::apply_factor_u256(position.size_in_usd, cache.min_collateral_factor),
                true
            );

    if cache.remaining_collateral_usd <= cache.min_collateral_usd_for_leverage {
        return (true, 'min collateral for leverage');
    }

    (false, '')
}


/// Fees and price impact are not included for the willPositionCollateralBeSufficient validation
/// this is because this validation is meant to guard against a specific scenario of price impact
/// gaming.
///
/// Price impact could be gamed by opening high leverage positions, if the price impact
/// that should be charged is higher than the amount of collateral in the position
/// then a user could pay less price impact than what is required, and there is a risk that
/// price manipulation could be profitable if the price impact cost is less than it should be.
///
/// This check should be sufficient even without factoring in fees as fees should have a minimal impact
/// it may be possible that funding or borrowing fees are accumulated and need to be deducted which could
/// lead to a user paying less price impact than they should, however gaming of this form should be difficult
/// since the funding and borrowing fees would still add up for the user's cost.
///
/// Another possibility would be if a user opens a large amount of both long and short positions, and
/// funding fees are paid from one side to the other, but since most of the open interest is owned by the
/// user the user earns most of the paid cost, in this scenario the borrowing fees should still be significant
/// since some time would be required for the funding fees to accumulate.
///
/// Fees and price impact are validated in the validatePosition check.
/// # Arguments
/// *`data_store` - The data store dispatcher.
/// *`market` - The market values.
/// *`prices` - The prices of the tokens in the market.
/// *`collateral_token` - The collateral token of the position.
/// *`is_long` - Whether it is for the long or short side.
/// *`values` - The prices of the tokens in the market.
/// # Returns
/// True if position collateral will be sufficient and remaining collateral in usd, false else.
fn will_position_collateral_be_sufficient(
    data_store: IDataStoreDispatcher,
    market: Market,
    prices: MarketPrices,
    collateral_token: ContractAddress,
    is_long: bool,
    values: WillPositionCollateralBeSufficientValues,
) -> (bool, i256) {
    let collateral_token_price = market_utils::get_cached_token_price(
        collateral_token, market, prices
    );
    let mut remaining_collateral_usd = calc::to_signed(values.position_collateral_amount, true)
        * calc::to_signed(collateral_token_price.min, true);
    // deduct realized pnl if it is negative since this would be paid from
    // the position's collateral
    if values.realized_pnl_usd < Zeroable::zero() {
        remaining_collateral_usd = remaining_collateral_usd + values.realized_pnl_usd;
    }

    if (remaining_collateral_usd < Zeroable::zero()) {
        return (false, remaining_collateral_usd);
    }
    // the min collateral factor will increase as the open interest for a market increases
    // this may lead to previously created limit increase orders not being executable
    //
    // the position's pnl is not factored into the remainingCollateralUsd value, since
    // factoring in a positive pnl may allow the user to manipulate price and bypass this check
    // it may be useful to factor in a negative pnl for this check, this can be added if required
    let mut min_collateral_factor = market_utils::get_min_collateral_factor_for_open_interest(
        data_store, market, values.open_interest_delta, is_long
    );

    let min_collateral_factor_for_market = market_utils::get_min_collateral_factor(
        data_store, market.market_token
    );
    // use the minCollateralFactor for the market if it is larger
    if (min_collateral_factor_for_market > min_collateral_factor) {
        min_collateral_factor = min_collateral_factor_for_market;
    }
    let min_collateral_usd_for_leverage = calc::to_signed(
        precision::apply_factor_u256(values.position_size_in_usd, min_collateral_factor), true
    );
    let will_be_sufficient: bool = remaining_collateral_usd >= min_collateral_usd_for_leverage;

    (will_be_sufficient, remaining_collateral_usd)
}


/// Update funding and borrowing states
/// # Arguments
/// *`data_store` - The data store dispatcher.
/// *`params` - The position parameters.
/// *`prices` - The prices of the tokens.

fn update_funding_and_borrowing_state(params: UpdatePositionParams, prices: MarketPrices,) {
    // update the funding amount per size for the market
    market_utils::update_funding_state(
        params.contracts.data_store, params.contracts.event_emitter, params.market, prices
    );
    // update the cumulative borrowing factor for longs
    market_utils::update_cumulative_borrowing_factor(
        params.contracts.data_store,
        params.contracts.event_emitter,
        params.market,
        prices,
        true // isLong
    );

    // update the cumulative borrowing factor for shorts
    market_utils::update_cumulative_borrowing_factor(
        params.contracts.data_store,
        params.contracts.event_emitter,
        params.market,
        prices,
        false // isLong
    );
}

/// # Arguments
/// *`params` - The position parameters.
/// *`next_position_size_in_usd` - The next posiiton USD size
/// *`next_position_borrowing_factor` - Thenext position borrowing factor
fn update_total_borrowing(
    params: UpdatePositionParams,
    next_position_size_in_usd: u256,
    next_position_borrowing_factor: u256,
) {
    market_utils::update_total_borrowing(
        params.contracts.data_store, // dataStore
        params.market.market_token, // market
        params.position.is_long, // isLong
        params.position.size_in_usd, // prevPositionSizeInUsd
        params.position.borrowing_factor, // prevPositionBorrowingFactor
        next_position_size_in_usd, // nextPositionSizeInUsd
        next_position_borrowing_factor // nextPositionBorrowingFactor
    );
}

/// The order.receiver is meant to allow the output of an order to be
/// received by an address that is different from the position.account
/// address.
/// For funding fees, the funds are still credited to the owner
/// of the position indicated by order.account.
/// # Arguments
/// *`params` - The position parameters.
/// *`fees` - The position fees.
fn increment_claimable_funding_amount(params: UpdatePositionParams, fees: PositionFees,) {
    // if the position has negative funding fees, distribute it to allow it to be claimable
    if (fees.funding.claimable_long_token_amount > 0) {
        market_utils::increment_claimable_funding_amount(
            params.contracts.data_store,
            params.contracts.event_emitter,
            params.market.market_token,
            params.market.long_token,
            params.order.account,
            fees.funding.claimable_long_token_amount
        );
    }

    if (fees.funding.claimable_short_token_amount > 0) {
        market_utils::increment_claimable_funding_amount(
            params.contracts.data_store,
            params.contracts.event_emitter,
            params.market.market_token,
            params.market.short_token,
            params.order.account,
            fees.funding.claimable_short_token_amount
        );
    }
}

/// # Arguments
/// *`params` - The position parameters.
/// *`size_delta_usd` - The USD change in position size.
/// *`size_delta_in_tokens` - The change in position size.
fn update_open_interest(
    params: UpdatePositionParams, size_delta_usd: i256, size_delta_in_tokens: i256,
) {
    if (size_delta_usd != Zeroable::zero()) {
        market_utils::apply_delta_to_open_interest(
            params.contracts.data_store,
            params.contracts.event_emitter,
            @params.market,
            params.position.collateral_token,
            params.position.is_long,
            size_delta_usd
        );
        market_utils::apply_delta_to_open_interest_in_tokens(
            params.contracts.data_store,
            params.contracts.event_emitter,
            params.market,
            params.position.collateral_token,
            params.position.is_long,
            size_delta_in_tokens
        );
    }
}

/// # Arguments
/// *`params` - The position parameters.
/// *`fees` - The position fees.
fn handle_referral(params: UpdatePositionParams, fees: PositionFees,) {
    referral_utils::increment_affiliate_reward(
        params.contracts.data_store,
        params.contracts.event_emitter,
        params.position.market,
        params.position.collateral_token,
        fees.referral.affiliate,
        fees.referral.affiliate_reward_amount
    );
}
