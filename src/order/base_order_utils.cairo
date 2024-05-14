// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use integer::BoundedInt;
use starknet::ContractAddress;
// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::order::{
    error::OrderError, order::{Order, SecondaryOrderType, OrderType, DecreasePositionSwapType},
    order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait}
};
use satoru::price::price::{Price, PriceTrait};
use satoru::market::market::Market;
use satoru::utils::precision;
use satoru::utils::store_arrays::{StoreMarketArray, StoreU64Array, StoreContractAddressArray};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::utils::span32::Span32;
use satoru::utils::calc;


use satoru::utils::i256::{i256, i256_neg};

#[derive(Drop, starknet::Store, Serde)]
struct ExecuteOrderParams {
    contracts: ExecuteOrderParamsContracts,
    /// The key of the order to execute.
    key: felt252,
    /// The order to execute.
    order: Order,
    /// The market values of the markets in the swap_path.
    swap_path_markets: Array<Market>,
    /// The min oracle block numbers.
    min_oracle_block_numbers: Array<u64>,
    /// The max oracle block numbers.
    max_oracle_block_numbers: Array<u64>,
    /// The market values of the trading market.
    market: Market,
    /// The keeper sending the transaction.
    keeper: ContractAddress,
    /// The starting gas.
    starting_gas: u256,
    /// The secondary order type.
    secondary_order_type: SecondaryOrderType
}


#[derive(Drop, Copy, starknet::Store, Serde)]
struct ExecuteOrderParamsContracts {
    /// The dispatcher to interact with the `DataStore` contract
    data_store: IDataStoreDispatcher,
    /// The dispatcher to interact with the `EventEmitter` contract
    event_emitter: IEventEmitterDispatcher,
    /// The dispatcher to interact with the `OrderVault` contract
    order_vault: IOrderVaultDispatcher,
    /// The dispatcher to interact with the `Oracle` contract
    oracle: IOracleDispatcher,
    /// The dispatcher to interact with the `SwapHandler` contract
    swap_handler: ISwapHandlerDispatcher,
    /// The dispatcher to interact with the `ReferralStorage` contract
    referral_storage: IReferralStorageDispatcher
}

/// CreateOrderParams struct used in create_order.
#[derive(Drop, Copy, starknet::Store, Serde)]
struct CreateOrderParams {
    /// Meant to allow the output of an order to be
    /// received by an address that is different from the position.account
    /// address.
    /// For funding fees, the funds are still credited to the owner
    /// of the position indicated by order.account.
    receiver: ContractAddress,
    /// The contract to call for callbacks.
    callback_contract: ContractAddress,
    /// The UI fee receiver.
    ui_fee_receiver: ContractAddress,
    /// The trading market.
    market: ContractAddress,
    /// The initial collateral token for increase orders.
    initial_collateral_token: ContractAddress,
    /// An Span32 of market addresses to swap through.
    swap_path: Span32<ContractAddress>,
    /// The requested change in position size.
    size_delta_usd: u256,
    /// For increase orders, this is the amount of the initialCollateralToken sent in by the user.
    /// For decrease orders, this is the amount of the position's collateralToken to withdraw.
    /// For swaps, this is the amount of initialCollateralToken sent in for the swap.
    initial_collateral_delta_amount: u256,
    /// The trigger price for non-market orders.
    trigger_price: u256,
    /// The acceptable execution price for increase / decrease orders.
    acceptable_price: u256,
    /// The execution fee for keepers.
    execution_fee: u256,
    /// The gas limit for the callbackContract.
    callback_gas_limit: u256,
    /// The minimum output amount for decrease orders and swaps.
    min_output_amount: u256,
    /// The order type.
    order_type: OrderType,
    /// The swap type on decrease position.
    decrease_position_swap_type: DecreasePositionSwapType,
    /// Whether the order is for a long or short.
    is_long: bool,
    /// The referral code linked to this order.
    referral_code: felt252
}

impl CreateOrderParamsClone of Clone<CreateOrderParams> {
    fn clone(self: @CreateOrderParams) -> CreateOrderParams {
        CreateOrderParams {
            receiver: *self.receiver,
            callback_contract: *self.callback_contract,
            ui_fee_receiver: *self.ui_fee_receiver,
            market: *self.market,
            initial_collateral_token: *self.initial_collateral_token,
            swap_path: self.swap_path.clone(),
            size_delta_usd: *self.size_delta_usd,
            initial_collateral_delta_amount: *self.initial_collateral_delta_amount,
            trigger_price: *self.trigger_price,
            acceptable_price: *self.acceptable_price,
            execution_fee: *self.execution_fee,
            callback_gas_limit: *self.callback_gas_limit,
            min_output_amount: *self.min_output_amount,
            order_type: *self.order_type,
            decrease_position_swap_type: *self.decrease_position_swap_type,
            is_long: *self.is_long,
            referral_code: *self.referral_code
        }
    }
}

#[derive(Drop, starknet::Store, Serde)]
struct GetExecutionPriceCache {
    price: u256,
    execution_price: u256,
    adjusted_price_impact_usd: u256
}

/// Check if an order_type is a market order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is a market order
fn is_market_order(order_type: OrderType) -> bool {
    // a liquidation order is not considered as a market order
    order_type == OrderType::MarketSwap
        || order_type == OrderType::MarketIncrease
        || order_type == OrderType::MarketDecrease
}

/// Check if an order_type is a limit order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is a limit order
fn is_limit_order(order_type: OrderType) -> bool {
    order_type == OrderType::LimitSwap
        || order_type == OrderType::LimitIncrease
        || order_type == OrderType::LimitDecrease
}

/// Check if an order_type is a swap order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is a swap order
fn is_swap_order(order_type: OrderType) -> bool {
    order_type == OrderType::MarketSwap || order_type == OrderType::LimitSwap
}

/// Check if an order_type is a position order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is a position order
fn is_position_order(order_type: OrderType) -> bool {
    is_increase_order(order_type) || is_decrease_order(order_type)
}

/// Check if an order_type is an increase order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is an increase order
fn is_increase_order(order_type: OrderType) -> bool {
    order_type == OrderType::MarketIncrease || order_type == OrderType::LimitIncrease
}

/// Check if an order_type is a decrease order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is a decrease order
fn is_decrease_order(order_type: OrderType) -> bool {
    order_type == OrderType::MarketDecrease
        || order_type == OrderType::LimitDecrease
        || order_type == OrderType::StopLossDecrease
        || order_type == OrderType::Liquidation
}

/// Check if an order_type is a liquidation order.
/// # Arguments
/// * `order_type` - The order type.
/// # Return
/// Return whether an order_type is a liquidation order
fn is_liquidation_order(order_type: OrderType) -> bool {
    order_type == OrderType::Liquidation
}

/// Validate the price for increase / decrease orders based on the trigger_price
/// the acceptablePrice for increase / decrease orders is validated in get_execution_price
/// it is possible to update the oracle to support a primary_price and a secondary_price
/// which would allow for stop-loss orders to be executed at exactly the trigger_price.
/// # Arguments
/// * `oracle` - Oracle.
/// * `index_token` - The index token.
/// * `order_type` - The order type.
/// * `trigger_price` - the order's trigger_price.
/// * `is_long` - Whether the order is for a long or short.
fn validate_order_trigger_price(
    oracle: IOracleDispatcher,
    index_token: ContractAddress,
    order_type: OrderType,
    trigger_price: u256,
    is_long: bool
) {
    if is_swap_order(order_type)
        || is_market_order(order_type)
        || is_liquidation_order(order_type) {
        return;
    }

    let primary_price = oracle.get_primary_price(index_token);

    // for limit increase long positions:
    //      - the order should be executed when the oracle price is <= triggerPrice
    //      - primaryPrice.max should be used for the oracle price
    // for limit increase short positions:
    //      - the order should be executed when the oracle price is >= triggerPrice
    //      - primaryPrice.min should be used for the oracle price
    if order_type == OrderType::LimitIncrease {
        let ok = if is_long {
            primary_price.max <= trigger_price
        } else {
            primary_price.min >= trigger_price
        };

        if !ok {
            OrderError::INVALID_ORDER_PRICE(primary_price, trigger_price, order_type);
        }

        return;
    }

    // for limit decrease long positions:
    //      - the order should be executed when the oracle price is >= triggerPrice
    //      - primaryPrice.min should be used for the oracle price
    // for limit decrease short positions:
    //      - the order should be executed when the oracle price is <= triggerPrice
    //      - primaryPrice.max should be used for the oracle price
    if order_type == OrderType::LimitDecrease {
        let ok = if is_long {
            primary_price.min >= trigger_price
        } else {
            primary_price.max <= trigger_price
        };

        if !ok {
            OrderError::INVALID_ORDER_PRICE(primary_price, trigger_price, order_type);
        }

        return;
    }

    // for stop-loss decrease long positions:
    //      - the order should be executed when the oracle price is <= triggerPrice
    //      - primaryPrice.min should be used for the oracle price
    // for stop-loss decrease short positions:
    //      - the order should be executed when the oracle price is >= triggerPrice
    //      - primaryPrice.max should be used for the oracle price
    if order_type == OrderType::StopLossDecrease {
        let ok = if is_long {
            primary_price.min <= trigger_price
        } else {
            primary_price.max >= trigger_price
        };

        if !ok {
            OrderError::INVALID_ORDER_PRICE(primary_price, trigger_price, order_type);
        }

        return;
    }

    panic(array![OrderError::UNSUPPORTED_ORDER_TYPE]);
}

fn get_execution_price_for_increase(
    size_delta_usd: u256, size_delta_in_tokens: u256, acceptable_price: u256, is_long: bool
) -> u256 {
    assert(size_delta_in_tokens != 0, OrderError::EMPTY_SIZE_DELTA_IN_TOKENS);

    let execution_price = size_delta_usd / size_delta_in_tokens;

    // increase order:
    //     - long: executionPrice should be smaller than acceptablePrice
    //     - short: executionPrice should be larger than acceptablePrice
    if (is_long && execution_price <= acceptable_price)
        || (!is_long && execution_price >= acceptable_price) {
        return execution_price;
    }

    // the validateOrderTriggerPrice function should have validated if the price fulfills
    // the order's trigger price
    //
    // for increase orders, the negative price impact is not capped
    //
    // for both increase and decrease orders, if it is due to price impact that the
    // order cannot be fulfilled then the order should be frozen
    //
    // this is to prevent gaming by manipulation of the price impact value
    //
    // usually it should be costly to game the price impact value
    // however, for certain cases, e.g. a user already has a large position opened
    // the user may create limit orders that would only trigger after they close
    // their position, this gives the user the option to cancel the pending order if
    // prices do not move in their favour or to close their position and let the order
    // execute if prices move in their favour
    //
    // it may also be possible for users to prevent the execution of orders from other users
    // by manipulating the price impact, though this should be costly

    OrderError::ORDER_NOT_FULFILLABLE_AT_ACCEPTABLE_PRICE(execution_price, acceptable_price);
    0 // doesn't compile otherwise
}

fn get_execution_price_for_decrease(
    index_token_price: Price,
    position_size_in_usd: u256,
    position_size_in_tokens: u256,
    size_delta_usd: u256,
    price_impact_usd: i256,
    acceptable_price: u256,
    is_long: bool
) -> u256 {
    // decrease order:
    //     - long: use the smaller price
    //     - short: use the larger price
    let price = index_token_price.pick_price(!is_long);
    let mut execution_price = price;

    // using closing of long positions as an example
    // realized pnl is calculated as totalPositionPnl * sizeDeltaInTokens / position.sizeInTokens
    // totalPositionPnl: position.sizeInTokens * executionPrice - position.sizeInUsd
    // sizeDeltaInTokens: position.sizeInTokens * sizeDeltaUsd / position.sizeInUsd
    // realized pnl: (position.sizeInTokens * executionPrice - position.sizeInUsd) * (position.sizeInTokens * sizeDeltaUsd / position.sizeInUsd) / position.sizeInTokens
    // realized pnl: (position.sizeInTokens * executionPrice - position.sizeInUsd) * (sizeDeltaUsd / position.sizeInUsd)
    // priceImpactUsd should adjust the execution price such that:
    // [(position.sizeInTokens * executionPrice - position.sizeInUsd) * (sizeDeltaUsd / position.sizeInUsd)] -
    // [(position.sizeInTokens * price - position.sizeInUsd) * (sizeDeltaUsd / position.sizeInUsd)] = priceImpactUsd
    //
    // (position.sizeInTokens * executionPrice - position.sizeInUsd) - (position.sizeInTokens * price - position.sizeInUsd)
    // = priceImpactUsd / (sizeDeltaUsd / position.sizeInUsd)
    // = priceImpactUsd * position.sizeInUsd / sizeDeltaUsd
    //
    // position.sizeInTokens * executionPrice - position.sizeInTokens * price = priceImpactUsd * position.sizeInUsd / sizeDeltaUsd
    // position.sizeInTokens * (executionPrice - price) = priceImpactUsd * position.sizeInUsd / sizeDeltaUsd
    // executionPrice - price = (priceImpactUsd * position.sizeInUsd) / (sizeDeltaUsd * position.sizeInTokens)
    // executionPrice = price + (priceImpactUsd * position.sizeInUsd) / (sizeDeltaUsd * position.sizeInTokens)
    // executionPrice = price + (priceImpactUsd / sizeDeltaUsd) * (position.sizeInUsd / position.sizeInTokens)
    // executionPrice = price + (priceImpactUsd * position.sizeInUsd / position.sizeInTokens) / sizeDeltaUsd
    //
    // e.g. if price is $2000, sizeDeltaUsd is $5000, priceImpactUsd is -$1000, position.sizeInUsd is $10,000, position.sizeInTokens is 5
    // executionPrice = 2000 + (-1000 * 10,000 / 5) / 5000 = 1600
    // realizedPnl based on price, without price impact: 0
    // realizedPnl based on executionPrice, with price impact: (5 * 1600 - 10,000) * (5 * 5000 / 10,000) / 5 => -1000

    // a positive adjustedPriceImpactUsd would decrease the executionPrice
    // a negative adjustedPriceImpactUsd would increase the executionPrice

    // for increase orders, the adjustedPriceImpactUsd is added to the divisor
    // a positive adjustedPriceImpactUsd would increase the divisor and decrease the executionPrice
    // increase long order:
    //      - if price impact is positive, adjustedPriceImpactUsd should be positive, to decrease the executionPrice
    //      - if price impact is negative, adjustedPriceImpactUsd should be negative, to increase the executionPrice
    // increase short order:
    //      - if price impact is positive, adjustedPriceImpactUsd should be negative, to increase the executionPrice
    //      - if price impact is negative, adjustedPriceImpactUsd should be positive, to decrease the executionPrice

    // for decrease orders, the adjustedPriceImpactUsd adjusts the numerator
    // a positive adjustedPriceImpactUsd would increase the divisor and increase the executionPrice
    // decrease long order:
    //      - if price impact is positive, adjustedPriceImpactUsd should be positive, to increase the executionPrice
    //      - if price impact is negative, adjustedPriceImpactUsd should be negative, to decrease the executionPrice
    // decrease short order:
    //      - if price impact is positive, adjustedPriceImpactUsd should be negative, to decrease the executionPrice
    //      - if price impact is negative, adjustedPriceImpactUsd should be positive, to increase the executionPrice
    // adjust price by price impact
    if size_delta_usd > 0 && position_size_in_tokens > 0 {
        let adjusted_price_impact_usd = if is_long {
            price_impact_usd
        } else {
            i256_neg(price_impact_usd)
        };

        if adjusted_price_impact_usd < Zeroable::zero()
            && calc::to_unsigned(i256_neg(adjusted_price_impact_usd)) > size_delta_usd {
            OrderError::PRICE_IMPACT_LARGER_THAN_ORDER_SIZE(
                adjusted_price_impact_usd, size_delta_usd
            );
        }

        let numerator = precision::mul_div_inum(
            position_size_in_usd, adjusted_price_impact_usd, position_size_in_tokens
        );
        let adjustment = numerator / calc::to_signed(size_delta_usd, true);

        let _execution_price: i256 = calc::to_signed(price, true) + adjustment;

        if _execution_price < Zeroable::zero() {
            OrderError::NEGATIVE_EXECUTION_PRICE(
                _execution_price,
                price,
                position_size_in_usd,
                adjusted_price_impact_usd,
                size_delta_usd
            );
        }

        execution_price = calc::to_unsigned(_execution_price);
    }

    // decrease order:
    //     - long: executionPrice should be larger than acceptablePrice
    //     - short: executionPrice should be smaller than acceptablePrice
    if (is_long && execution_price >= acceptable_price)
        || (!is_long && execution_price <= acceptable_price) {
        return execution_price;
    }

    // the validateOrderTriggerPrice function should have validated if the price fulfills
    // the order's trigger price
    //
    // for decrease orders, the price impact should already be capped, so if the user
    // had set an acceptable price within the range of the capped price impact, then
    // the order should be fulfillable at the acceptable price
    //
    // for increase orders, the negative price impact is not capped
    //
    // for both increase and decrease orders, if it is due to price impact that the
    // order cannot be fulfilled then the order should be frozen
    //
    // this is to prevent gaming by manipulation of the price impact value
    //
    // usually it should be costly to game the price impact value
    // however, for certain cases, e.g. a user already has a large position opened
    // the user may create limit orders that would only trigger after they close
    // their position, this gives the user the option to cancel the pending order if
    // prices do not move in their favour or to close their position and let the order
    // execute if prices move in their favour
    //
    // it may also be possible for users to prevent the execution of orders from other users
    // by manipulating the price impact, though this should be costly
    OrderError::ORDER_NOT_FULFILLABLE_AT_ACCEPTABLE_PRICE(execution_price, acceptable_price);
    0
}

/// Validates that an order exists.
/// # Arguments
/// * `order` - The order to check.
fn validate_non_empty_order(order: @Order) {
    assert((*order.account).is_non_zero(), OrderError::EMPTY_ORDER);
    assert(
        *order.size_delta_usd != 0 || *order.initial_collateral_delta_amount != 0,
        OrderError::EMPTY_ORDER
    );
}
