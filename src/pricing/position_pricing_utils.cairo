//! Library for position pricing functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;
use zeroable::Zeroable;

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::market::market::Market;
use satoru::price::price::Price;
use satoru::position::position::Position;


use satoru::market::market_utils;
use satoru::utils::calc;
use satoru::pricing::pricing_utils;
use satoru::data::keys;
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::utils::i128::{StoreI128, I128Serde,};
use satoru::utils::i128::i128_to_u128;
use satoru::utils::precision;
use satoru::pricing::error::PricingError;
use satoru::referral::referral_utils;

/// Struct used in get_position_fees.
#[derive(Drop, starknet::Store, Serde)]
struct GetPositionFeesParams {
    /// The `DataStore` contract dispatcher.
    data_store: IDataStoreDispatcher,
    /// The `ReferralStorage` contract dispatcher.
    referral_storage: IReferralStorageDispatcher,
    /// The position struct.
    position: Position,
    /// The price of the collateral token.
    collateral_token_price: Price,
    /// Wether it is for a positive impact.
    for_positive_impact: bool,
    /// The long token contract address.
    long_token: ContractAddress,
    /// The short token contract address.
    short_token: ContractAddress,
    /// The size variation in USD.
    size_delta_usd: u128,
    /// The ui fee receiver contract address.
    ui_fee_receiver: ContractAddress,
}

/// Struct used in get_price_impact_usd.
#[derive(Drop, Copy, starknet::Store, Serde)]
struct GetPriceImpactUsdParams {
    /// The `DataStore` contract dispatcher.
    data_store: IDataStoreDispatcher,
    /// The market to check.
    market: Market,
    /// The change in position size in USD.
    usd_delta: i128,
    /// Whether the position is long or short.
    is_long: bool,
}

/// Struct used to store open interest.
#[derive(Drop, starknet::Store, Serde)]
struct OpenInterestParams {
    /// The amount of long open interest.
    long_open_interest: u128,
    /// The amount of short open interest.
    short_open_interest: u128,
    /// The updated amount of long open interest.
    next_long_open_interest: u128,
    /// The updated amount of short open interest.
    next_short_open_interest: u128,
}

impl DefaultContractAddress of Default<ContractAddress> {
    fn default() -> ContractAddress {
        Zeroable::zero()
    }
}
/// Struct to store position fees data.
#[derive(Default, Drop, starknet::Store, Serde)]
struct PositionFees {
    /// The referral fees.
    referral: PositionReferralFees,
    /// The funding fees.
    funding: PositionFundingFees,
    /// The borrowing fees.
    borrowing: PositionBorrowingFees,
    /// The ui fees.
    ui: PositionUiFees,
    /// The collateral_token_price.
    collateral_token_price: Price,
    /// The position fee factor.
    position_fee_factor: u128,
    /// The amount of fee to the protocol.
    protocol_fee_amount: u128,
    /// The factor of fee due to receiver.
    position_fee_receiver_factor: u128,
    /// The amount of fee due to receiver.
    fee_receiver_amount: u128,
    /// The amount of fee due to the pool.
    fee_amount_for_pool: u128,
    /// The position fee amount for the pool
    position_fee_amount_for_pool: u128,
    /// The fee amount for increasing / decreasing the position.
    position_fee_amount: u128,
    /// The total cost amount in tokens excluding funding.
    total_cost_amount_excluding_funding: u128,
    /// The total cost amount in tokens.
    total_cost_amount: u128,
}

/// Struct used to store referral parameters useful for fees computation.
#[derive(Default, Drop, starknet::Store, Serde)]
struct PositionReferralFees {
    /// The referral code used.
    referral_code: felt252,
    /// The referral affiliate of the trader.
    affiliate: ContractAddress,
    /// The trader address.
    trader: ContractAddress,
    /// The total rebate factor.
    total_rebate_factor: u128,
    /// The trader discount factor.
    trader_discount_factor: u128,
    /// The total rebate amount.
    total_rebate_amount: u128,
    /// The discount amount for the trader.
    trader_discount_amount: u128,
    /// The affiliate reward amount.
    affiliate_reward_amount: u128,
}

/// Struct used to store position borrowing fees.
#[derive(Default, Drop, starknet::Store, Serde)]
struct PositionBorrowingFees {
    /// The borrowing fees amount in USD.
    borrowing_fee_usd: u128,
    /// The borrowing fees amount in tokens.
    borrowing_fee_amount: u128,
    /// The borrowing fees factor for receiver.
    borrowing_fee_receiver_factor: u128,
    /// The borrowing fees amount in tokens for fee receiver.
    borrowing_fee_amount_for_fee_receiver: u128,
}

/// Struct used to store position funding fees.
#[derive(Default, Copy, Drop, starknet::Store, Serde)]
struct PositionFundingFees {
    /// The amount of funding fees in tokens.
    funding_fee_amount: u128,
    /// The negative funding fee in long token that is claimable.
    claimable_long_token_amount: u128,
    /// The negative funding fee in short token that is claimable.
    claimable_short_token_amount: u128,
    /// The latest long token funding fee amount per size for the market.
    latest_funding_fee_amount_per_size: u128,
    /// The latest long token funding amount per size for the market.
    latest_long_token_claimable_funding_amount_per_size: u128,
    /// The latest short token funding amount per size for the market.
    latest_short_token_claimable_funding_amount_per_size: u128,
}

/// Struct used to store position ui fees
#[derive(Default, Drop, starknet::Store, Serde)]
struct PositionUiFees {
    /// The ui fee receiver address
    ui_fee_receiver: ContractAddress,
    /// The factor for fee receiver.
    ui_fee_receiver_factor: u128,
    /// The ui fee amount in tokens.
    ui_fee_amount: u128,
}

/// Get the price impact in USD for a position increase / decrease.
fn get_price_impact_usd(params: GetPriceImpactUsdParams) -> i128 {
    let open_interest_params: OpenInterestParams = get_next_open_interest(params);
    let price_impact_usd = _get_price_impact_usd(
        params.data_store, params.market.market_token, open_interest_params
    );

    if (price_impact_usd >= 0) {
        return price_impact_usd;
    }

    let (has_virtual_inventory, virtual_inventory) =
        market_utils::get_virtual_inventory_for_positions(
        params.data_store, params.market.index_token
    );

    if (!has_virtual_inventory) {
        return price_impact_usd;
    }

    let open_interest_params_for_virtual_inventory: OpenInterestParams =
        get_next_open_interest_for_virtual_inventory(
        params, virtual_inventory
    );
    let price_impact_usd_for_virtual_inventory = _get_price_impact_usd(
        params.data_store, params.market.market_token, open_interest_params_for_virtual_inventory
    );

    if (price_impact_usd_for_virtual_inventory < price_impact_usd) {
        return price_impact_usd_for_virtual_inventory;
    }

    price_impact_usd
}

/// Called internally by get_price_impact_params().
fn _get_price_impact_usd(
    data_store: IDataStoreDispatcher,
    market: ContractAddress,
    open_interest_params: OpenInterestParams,
) -> i128 {
    let initial_diff_usd = calc::diff(
        open_interest_params.long_open_interest, open_interest_params.short_open_interest
    );
    let next_diff_usd = calc::diff(
        open_interest_params.next_long_open_interest, open_interest_params.next_short_open_interest
    );

    let is_same_side_rebalance_first = open_interest_params
        .long_open_interest <= open_interest_params
        .short_open_interest;
    let is_same_side_rebalance_second = open_interest_params
        .short_open_interest <= open_interest_params
        .next_long_open_interest;
    let is_same_side_rebalance_third = open_interest_params
        .next_long_open_interest <= open_interest_params
        .next_short_open_interest;
    let is_same_side_rebalance = is_same_side_rebalance_first
        && is_same_side_rebalance_second
        && is_same_side_rebalance_third;

    let impact_exponent_factor = data_store
        .get_u128(keys::position_impact_exponent_factor_key(market));

    if (is_same_side_rebalance) {
        let has_positive_impact = next_diff_usd < initial_diff_usd;
        let impact_factor = market_utils::get_adjusted_position_impact_factor(
            data_store, market, has_positive_impact
        );

        return pricing_utils::get_price_impact_usd_for_same_side_rebalance(
            initial_diff_usd, next_diff_usd, impact_factor, impact_exponent_factor
        );
    } else {
        let (positive_impact_factor, negative_impact_factor) =
            market_utils::get_adjusted_position_impact_factors(
            data_store, market
        );

        return pricing_utils::get_price_impact_usd_for_crossover_rebalance(
            initial_diff_usd,
            next_diff_usd,
            positive_impact_factor,
            negative_impact_factor,
            impact_exponent_factor
        );
    }
}

/// Compute new open interest.
/// # Arguments
/// * `params` - Price impact in usd.
/// # Returns
/// New open interest.
fn get_next_open_interest(params: GetPriceImpactUsdParams) -> OpenInterestParams {
    let long_open_interest = market_utils::get_open_interest_for_market_is_long(
        params.data_store, @params.market, true
    );

    let short_open_interest = market_utils::get_open_interest_for_market_is_long(
        params.data_store, @params.market, false
    );

    return get_next_open_interest_params(params, long_open_interest, short_open_interest);
}

/// Compute new open interest for virtual inventory.
/// # Arguments
/// * `params` - Price impact in usd.
/// * `virtual_inventory` - Price impact in usd.
/// # Returns
/// New open interest for virtual inventory.
fn get_next_open_interest_for_virtual_inventory(
    params: GetPriceImpactUsdParams, virtual_inventory: i128,
) -> OpenInterestParams {
    let mut long_open_interest = 0;
    let mut short_open_interest = 0;

    if (virtual_inventory > 0) {
        short_open_interest = i128_to_u128(virtual_inventory);
    } else {
        long_open_interest = i128_to_u128(-virtual_inventory);
    }

    if (params.usd_delta < 0) {
        let offset = i128_to_u128(-params.usd_delta);
        long_open_interest += offset;
        short_open_interest += offset;
    }

    return get_next_open_interest_params(params, long_open_interest, short_open_interest);
}

/// Compute new open interest.
/// # Arguments
/// * `params` - Price impact in usd.
/// * `long_open_interest` - Long positions open interest.
/// * `long_open_interest` - Short positions open interest.
/// # Returns
/// New open interest.
fn get_next_open_interest_params(
    params: GetPriceImpactUsdParams, long_open_interest: u128, short_open_interest: u128
) -> OpenInterestParams {
    let mut next_long_open_interest = long_open_interest;
    let mut next_short_open_interest = short_open_interest;

    if (params.is_long) {
        if (params.usd_delta < 0 && i128_to_u128(-params.usd_delta) > long_open_interest) {
            PricingError::USD_DELTA_EXCEEDS_LONG_OPEN_INTEREST(params.usd_delta, long_open_interest)
        }

        next_long_open_interest = calc::sum_return_uint_128(long_open_interest, params.usd_delta);
    } else {
        if (params.usd_delta < 0 && i128_to_u128(-params.usd_delta) > short_open_interest) {
            PricingError::USD_DELTA_EXCEEDS_SHORT_OPEN_INTEREST(
                params.usd_delta, short_open_interest
            )
        }

        next_short_open_interest = calc::sum_return_uint_128(short_open_interest, params.usd_delta);
    }

    let open_interest_params = OpenInterestParams {
        long_open_interest, short_open_interest, next_long_open_interest, next_short_open_interest
    };

    open_interest_params
}

/// Compute position fees.
/// # Arguments
/// * `params` - parameters to compute position fees.
/// # Returns
/// Position fees.
fn get_position_fees(params: GetPositionFeesParams) -> PositionFees {
    let mut fees = get_position_fees_after_referral(
        params.data_store,
        params.referral_storage,
        params.collateral_token_price,
        params.for_positive_impact,
        params.position.account,
        params.position.market,
        params.size_delta_usd
    );

    let borrowing_fee_usd = market_utils::get_borrowing_fees(params.data_store, params.position);

    fees
        .borrowing =
            get_borrowing_fees(params.data_store, params.collateral_token_price, borrowing_fee_usd);

    fees.fee_amount_for_pool = fees.position_fee_amount_for_pool
        + fees.borrowing.borrowing_fee_amount
        - fees.borrowing.borrowing_fee_amount_for_fee_receiver;
    fees.fee_receiver_amount += fees.borrowing.borrowing_fee_amount_for_fee_receiver;

    fees
        .funding
        .latest_funding_fee_amount_per_size =
            market_utils::get_funding_fee_amount_per_size(
                params.data_store,
                params.position.market,
                params.position.collateral_token,
                params.position.is_long
            );

    fees
        .funding
        .latest_long_token_claimable_funding_amount_per_size =
            market_utils::get_claimable_funding_amount_per_size(
                params.data_store,
                params.position.market,
                params.long_token,
                params.position.is_long
            );

    fees
        .funding
        .latest_short_token_claimable_funding_amount_per_size =
            market_utils::get_claimable_funding_amount_per_size(
                params.data_store,
                params.position.market,
                params.short_token,
                params.position.is_long
            );

    fees.funding = get_funding_fees(fees.funding, params.position);

    fees
        .ui =
            get_ui_fees(
                params.data_store,
                params.collateral_token_price,
                params.size_delta_usd,
                params.ui_fee_receiver
            );

    fees.total_cost_amount_excluding_funding = fees.position_fee_amount
        + fees.borrowing.borrowing_fee_amount
        + fees.ui.ui_fee_amount
        - fees.referral.trader_discount_amount;

    fees.total_cost_amount = fees.total_cost_amount_excluding_funding
        + fees.funding.funding_fee_amount;

    fees
}

/// Compute borrowing fees data.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `collateral_token_price` - The price of the collateral token.
/// * `borrowing_fee_usd` - Borrowing fee amount in USD.
/// # Returns
/// Borrowing fees.
fn get_borrowing_fees(
    data_store: IDataStoreDispatcher, collateral_token_price: Price, borrowing_fee_usd: u128,
) -> PositionBorrowingFees {
    PositionBorrowingFees {
        borrowing_fee_usd,
        borrowing_fee_amount: borrowing_fee_usd / collateral_token_price.min,
        borrowing_fee_receiver_factor: data_store.get_u128(keys::borrowing_fee_receiver_factor()),
        borrowing_fee_amount_for_fee_receiver: precision::apply_factor_u128(
            borrowing_fee_usd / collateral_token_price.min,
            data_store.get_u128(keys::borrowing_fee_receiver_factor())
        )
    }
}

/// Compute funding fees.
/// # Arguments
/// * `funding_fees` - The position funding fees struct to store fees.
/// * `position` - The position to compute funding fees for.
/// # Returns
/// Borrowing fees.
fn get_funding_fees(
    mut funding_fees: PositionFundingFees, position: Position
) -> PositionFundingFees {
    funding_fees
        .funding_fee_amount =
            market_utils::get_funding_amount(
                funding_fees.latest_funding_fee_amount_per_size,
                position.funding_fee_amount_per_size,
                position.size_in_usd,
                true // roundUpMagnitude
            );

    funding_fees
        .claimable_long_token_amount =
            market_utils::get_funding_amount(
                funding_fees.latest_long_token_claimable_funding_amount_per_size,
                position.long_token_claimable_funding_amount_per_size,
                position.size_in_usd,
                false // roundUpMagnitude
            );

    funding_fees
        .claimable_short_token_amount =
            market_utils::get_funding_amount(
                funding_fees.latest_short_token_claimable_funding_amount_per_size,
                position.short_token_claimable_funding_amount_per_size,
                position.size_in_usd,
                false // roundUpMagnitude
            );

    funding_fees
}

/// Compute ui fees.
/// # Arguments
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `collateral_token_price` - The price of the collateral token.
/// * `ui_fee receiver` - The ui fee receiver address.
/// # Returns
/// Borrowing fees.
fn get_ui_fees(
    data_store: IDataStoreDispatcher,
    collateral_token_price: Price,
    size_delta_usd: u128,
    ui_fee_receiver: ContractAddress
) -> PositionUiFees {
    let mut ui_fees: PositionUiFees = Default::default();

    if (ui_fee_receiver == 0.try_into().unwrap()) {
        return ui_fees;
    }

    ui_fees.ui_fee_receiver = ui_fee_receiver;
    ui_fees.ui_fee_receiver_factor = market_utils::get_ui_fee_factor(data_store, ui_fee_receiver);
    ui_fees
        .ui_fee_amount =
            precision::apply_factor_u128(size_delta_usd, ui_fees.ui_fee_receiver_factor)
        / collateral_token_price.min;

    ui_fees
}

/// Get position fees after applying referral rebates / discounts.
/// * `data_store` - The `DataStore` contract dispatcher.
/// * `referral_storage` - The `ReferralStorage` contract dispatcher.
/// * `collateral_token_price` - The price of the collateral token.
/// * `for_positive_impact` - Wether it is for a positive impact.
/// * `account` - The user account address.
/// * `market` - The concerned market.
/// * `size_delta_usd` - The size variation in usd.
/// # Returns
/// Updated position fees.
fn get_position_fees_after_referral(
    data_store: IDataStoreDispatcher,
    referral_storage: IReferralStorageDispatcher,
    collateral_token_price: Price,
    for_positive_impact: bool,
    account: ContractAddress,
    market: ContractAddress,
    size_delta_usd: u128,
) -> PositionFees {
    let mut fees: PositionFees = Default::default();

    fees.collateral_token_price = collateral_token_price;

    fees.referral.trader = account;

    let (referral_code, affiliate, total_rebate_factor, trader_discount_factor) =
        referral_utils::get_referral_info(
        referral_storage, account
    );

    fees.referral.referral_code = referral_code;
    fees.referral.affiliate = affiliate;
    fees.referral.total_rebate_factor = total_rebate_factor;
    fees.referral.trader_discount_factor = trader_discount_factor;

    fees
        .position_fee_factor = data_store
        .get_u128(keys::position_fee_factor_key(market, for_positive_impact));
    fees
        .position_fee_amount =
            precision::apply_factor_u128(size_delta_usd, fees.position_fee_factor)
        / collateral_token_price.min;

    fees
        .referral
        .total_rebate_amount =
            precision::apply_factor_u128(
                fees.position_fee_amount, fees.referral.total_rebate_factor
            );
    fees
        .referral
        .trader_discount_amount =
            precision::apply_factor_u128(
                fees.referral.total_rebate_amount, fees.referral.trader_discount_factor
            );
    fees.referral.affiliate_reward_amount = fees.referral.total_rebate_amount
        - fees.referral.trader_discount_amount;

    fees.protocol_fee_amount = fees.position_fee_amount - fees.referral.total_rebate_amount;

    fees.position_fee_receiver_factor = data_store.get_u128(keys::position_fee_receiver_factor());
    fees
        .fee_receiver_amount =
            precision::apply_factor_u128(
                fees.protocol_fee_amount, fees.position_fee_receiver_factor
            );
    fees.position_fee_amount_for_pool = fees.protocol_fee_amount - fees.fee_receiver_amount;

    fees
}
