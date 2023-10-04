//! Key management for the values in the `DataStore` contract.

// IMPORTS
use satoru::utils::hash::hash_poseidon_single;
use satoru::order::order::OrderType;
use starknet::ContractAddress;

use poseidon::poseidon_hash_span;

// *************************************************************************
// *                        CONSTANT KEYS                                  *
// *************************************************************************

/// Key for the address of the fee token.
fn fee_token() -> felt252 {
    hash_poseidon_single('FEE_TOKEN')
}

/// Key for the nonce value used in NonceUtils.
fn nonce() -> felt252 {
    hash_poseidon_single('NONCE')
}

/// For sending received fees.
fn fee_receiver() -> felt252 {
    hash_poseidon_single('FEE_RECEIVER')
}

/// For holding tokens that could not be sent out.
fn holding_address() -> felt252 {
    hash_poseidon_single('HOLDING_ADDRESS')
}

/// Key for the minimum gas that should be forwarded for execution error handling.
fn min_handle_execution_error_gas() -> felt252 {
    hash_poseidon_single('MIN_HANDLE_EXECUTION_ERROR_GAS')
}

/// For a global reentrancy guard.
fn reentrancy_guard_status() -> felt252 {
    hash_poseidon_single('REENTRANCY_GUARD_STATUS')
}

/// Key for deposit fees.
fn deposit_fee_type() -> felt252 {
    hash_poseidon_single('DEPOSIT_FEE_TYPE')
}

/// Key for withdrawal fees.
fn withdrawal_fee_type() -> felt252 {
    hash_poseidon_single('WITHDRAWAL_FEE_TYPE')
}

/// Key for swap fees.
fn swap_fee_type() -> felt252 {
    hash_poseidon_single('SWAP_FEE_TYPE')
}

/// Key for position fees.
fn position_fee_type() -> felt252 {
    hash_poseidon_single('POSITION_FEE_TYPE')
}

/// Key for UI deposit fees.
fn ui_deposit_fee_type() -> felt252 {
    hash_poseidon_single('UI_DEPOSIT_FEE_TYPE')
}

/// Key for UI withdrawal fees.
fn ui_withdrawal_fee_type() -> felt252 {
    hash_poseidon_single('UI_WITHDRAWAL_FEE_TYPE')
}

/// Key for UI swap fees.
fn ui_swap_fee_type() -> felt252 {
    hash_poseidon_single('UI_SWAP_FEE_TYPE')
}

/// Key for UI position fees.
fn ui_position_fee_type() -> felt252 {
    hash_poseidon_single('UI_POSITION_FEE_TYPE')
}

/// Key for UI fee factor.
fn ui_fee_factor() -> felt252 {
    hash_poseidon_single('UI_FEE_FACTOR')
}

/// Key for max UI fee receiver factor.
fn max_ui_fee_factor() -> felt252 {
    hash_poseidon_single('MAX_UI_FEE_FACTOR')
}

/// Key for the claimable fee amount.
fn claimable_fee_amount() -> felt252 {
    hash_poseidon_single('CLAIMABLE_FEE_AMOUNT')
}

/// Key for the claimable UI fee amount.
fn claimable_ui_fee_amount() -> felt252 {
    hash_poseidon_single('CLAIMABLE_UI_FEE_AMOUNT')
}

/// Key for the market list.
fn market_list() -> felt252 {
    hash_poseidon_single('MARKET_LIST')
}

/// Key for the deposit list.
fn deposit_list() -> felt252 {
    hash_poseidon_single('DEPOSIT_LIST')
}

/// Key for the account deposit list.
fn account_deposit_list() -> felt252 {
    hash_poseidon_single('ACCOUNT_DEPOSIT_LIST')
}

/// Key for the withdrawal list.
fn withdrawal_list() -> felt252 {
    hash_poseidon_single('WITHDRAWAL_LIST')
}

/// Key for the account withdrawal list.
fn account_withdrawal_list() -> felt252 {
    hash_poseidon_single('ACCOUNT_WITHDRAWAL_LIST')
}

/// Key for the position list.
fn position_list() -> felt252 {
    hash_poseidon_single('POSITION_LIST')
}

/// Key for the account position list.
fn account_position_list() -> felt252 {
    hash_poseidon_single('ACCOUNT_POSITION_LIST')
}

/// Key for the order list.
fn order_list() -> felt252 {
    hash_poseidon_single('ORDER_LIST')
}

/// Key for the account order list.
fn account_order_list() -> felt252 {
    hash_poseidon_single('ACCOUNT_ORDER_LIST')
}

/// Key for is market disabled.
fn is_market_disabled() -> felt252 {
    hash_poseidon_single('IS_MARKET_DISABLED')
}

/// Key for the max swap path length allowed.
fn max_swap_path_length() -> felt252 {
    hash_poseidon_single('MAX_SWAP_PATH_LENGTH')
}

/// Key used to store markets observed in a swap path, to ensure that a swap path contains unique markets.
fn swap_path_market_flag() -> felt252 {
    hash_poseidon_single('SWAP_PATH_MARKET_FLAG')
}

/// Key for whether the create deposit feature is disabled.
fn create_deposit_feature_disabled() -> felt252 {
    hash_poseidon_single('CREATE_DEPOSIT_FEATURE_DISABLED')
}

/// Key for whether the cancel deposit feature is disabled.
fn cancel_deposit_feature_disabled() -> felt252 {
    hash_poseidon_single('CANCEL_DEPOSIT_FEATURE_DISABLED')
}

/// Key for whether the execute deposit feature is disabled.
fn execute_deposit_feature_disabled() -> felt252 {
    hash_poseidon_single('EXEC_DEPOSIT_FEATURE_DISABLED')
}

/// Key for whether the create withdrawal feature is disabled.
fn create_withdrawal_feature_disabled() -> felt252 {
    hash_poseidon_single('CREATE_WITHDR_FEATURE_DISABLED')
}

/// Key for whether the cancel withdrawal feature is disabled.
fn cancel_withdrawal_feature_disabled() -> felt252 {
    hash_poseidon_single('CANCEL_WITHDR_FEATURE_DISABLED')
}

/// Key for whether the execute withdrawal feature is disabled.
fn execute_withdrawal_feature_disabled() -> felt252 {
    hash_poseidon_single('EXEC_WITHDR_FEATURE_DISABLED')
}

/// Key for whether the create order feature is disabled.
fn create_order_feature_disabled() -> felt252 {
    hash_poseidon_single('CREATE_ORDER_FEATURE_DISABLED')
}

/// Key for whether the execute order feature is disabled.
fn execute_order_feature_disabled() -> felt252 {
    hash_poseidon_single('EXECUTE_ORDER_FEATURE_DISABLED')
}

/// Key for whether the execute ADL feature is disabled.
fn execute_adl_feature_disabled() -> felt252 {
    hash_poseidon_single('EXECUTE_ADL_FEATURE_DISABLED')
}

/// Key for whether the update order feature is disabled.
fn update_order_feature_disabled() -> felt252 {
    hash_poseidon_single('UPDATE_ORDER_FEATURE_DISABLED')
}

/// Key for whether the cancel order feature is disabled.
fn cancel_order_feature_disabled() -> felt252 {
    hash_poseidon_single('CANCEL_ORDER_FEATURE_DISABLED')
}

/// Key for whether the claim funding fees feature is disabled.
fn claim_funding_fees_feature_disabled() -> felt252 {
    hash_poseidon_single('CLAIM_FND_FEES_FEATURE_DISABLED')
}

/// Key for whether the claim collateral feature is disabled.
fn claim_collateral_feature_disabled() -> felt252 {
    hash_poseidon_single('CLAIM_COLLAT_FEATURE_DISABLED')
}

/// Key for whether the claim affiliate rewards feature is disabled.
fn claim_affiliate_rewards_feature_disabled() -> felt252 {
    hash_poseidon_single('CLAIM_AFFIL_RWRD_FEATURE_DSBLED')
}

/// Key for whether the claim UI fees feature is disabled.
fn claim_ui_fees_feature_disabled() -> felt252 {
    hash_poseidon_single('CLAIM_UI_FEES_FEATURE_DISABLED')
}

/// Key for the minimum required oracle signers for an oracle observation.
fn min_oracle_signers() -> felt252 {
    hash_poseidon_single('MIN_ORACLE_SIGNERS')
}

/// Key for the minimum block confirmations before blockhash can be excluded for oracle signature validation.
fn min_oracle_block_confirmations() -> felt252 {
    hash_poseidon_single('MIN_ORACLE_BLOCK_CONFIRMATIONS')
}

/// Key for the maximum usable oracle price age in seconds.
fn max_oracle_price_age() -> felt252 {
    hash_poseidon_single('MAX_ORACLE_PRICE_AGE')
}

/// Key for the maximum oracle price deviation factor from the ref price.
fn max_oracle_ref_price_deviation_factor() -> felt252 {
    hash_poseidon_single('MAX_ORAC_REF_PRICE_DEV_FACTOR')
}

/// Key for the percentage amount of position fees to be received.
fn position_fee_receiver_factor() -> felt252 {
    hash_poseidon_single('POSITION_FEE_RECEIVER_FACTOR')
}

/// Key for the percentage amount of swap fees to be received.
fn swap_fee_receiver_factor() -> felt252 {
    hash_poseidon_single('SWAP_FEE_RECEIVER_FACTOR')
}

/// Key for the percentage amount of borrowing fees to be received.
fn borrowing_fee_receiver_factor() -> felt252 {
    hash_poseidon_single('BORROWING_FEE_RECEIVER_FACTOR')
}

/// Key for the base gas limit used when estimating execution fee.
fn estimated_gas_fee_base_amount() -> felt252 {
    hash_poseidon_single('EST_GAS_FEE_BASE_AMT')
}

/// Key for the multiplier used when estimating execution fee.
fn estimated_gas_fee_multiplier_factor() -> felt252 {
    hash_poseidon_single('EST_GAS_FEE_MULT_FACT')
}

/// Key for the base gas limit used when calculating execution fee.
fn execution_gas_fee_base_amount() -> felt252 {
    hash_poseidon_single('EXEC_GAS_FEE_BASE_AMT')
}

/// Key for the multiplier used when calculating execution fee.
fn execution_gas_fee_multiplier_factor() -> felt252 {
    hash_poseidon_single('EXEC_GAS_FEE_MULT_FACT')
}

/// Key for the estimated gas limit for deposits.
fn deposit_gas_limit() -> felt252 {
    hash_poseidon_single('DEPOSIT_GAS_LIMIT')
}

/// Key for the estimated gas limit for withdrawals.
fn withdrawal_gas_limit() -> felt252 {
    hash_poseidon_single('WITHDRAW_GAS_LIMIT')
}

/// Key for the estimated gas limit for single swaps.
fn single_swap_gas_limit() -> felt252 {
    hash_poseidon_single('SINGLE_SWAP_GAS_LIMIT')
}

/// Key for the estimated gas limit for increase orders.
fn increase_order_gas_limit() -> felt252 {
    hash_poseidon_single('INCR_ORD_GAS_LIMIT')
}

/// Key for the estimated gas limit for decrease orders.
fn decrease_order_gas_limit() -> felt252 {
    hash_poseidon_single('DECR_ORD_GAS_LIMIT')
}

/// Key for the estimated gas limit for swap orders.
fn swap_order_gas_limit() -> felt252 {
    hash_poseidon_single('SWAP_ORD_GAS_LIMIT')
}

/// Key for the amount of gas to forward for token transfers.
fn token_transfer_gas_limit() -> felt252 {
    hash_poseidon_single('TOKEN_TRANS_GAS_LIMIT')
}

/// Key for the amount of gas to forward for native token transfers.
fn native_token_transfer_gas_limit() -> felt252 {
    hash_poseidon_single('NATIVE_TKN_TRANS_GL')
}

/// Key for the maximum request block age, after which the request will be considered expired.
fn request_expiration_block_age() -> felt252 {
    hash_poseidon_single('REQ_EXPIR_BLOCK_AGE')
}

/// Key for the max callback gas limit.
fn max_callback_gas_limit() -> felt252 {
    hash_poseidon_single('MAX_CALLBACK_GAS_LIMIT')
}

/// Key for the saved callback contract.
fn saved_callback_contract() -> felt252 {
    hash_poseidon_single('SAVED_CALLBACK_CONTRACT')
}

/// Key for the min collateral factor.
fn min_collateral_factor() -> felt252 {
    hash_poseidon_single('MIN_COLLATERAL_FACTOR')
}

/// Key for the min collateral factor for open interest multiplier.
fn min_collateral_factor_for_open_interest_multiplier() -> felt252 {
    hash_poseidon_single('MIN_COLL_FACT_FOR_OI_MULT')
}

/// Key for the min allowed collateral in USD.
fn min_collateral_usd() -> felt252 {
    hash_poseidon_single('MIN_COLLATERAL_USD')
}

/// Key for the min allowed position size in USD.
fn min_position_size_usd() -> felt252 {
    hash_poseidon_single('MIN_POSITION_SIZE_USD')
}

/// Key for the virtual id of tokens.
fn virtual_token_id() -> felt252 {
    hash_poseidon_single('VIRTUAL_TOKEN_ID')
}

/// Key for the virtual id of markets.
fn virtual_market_id() -> felt252 {
    hash_poseidon_single('VIRTUAL_MARKET_ID')
}

/// Key for the virtual inventory for swaps.
fn virtual_inventory_for_swaps() -> felt252 {
    hash_poseidon_single('VIRT_INV_FOR_SWAPS')
}

/// Key for the virtual inventory for positions.
fn virtual_inventory_for_positions() -> felt252 {
    hash_poseidon_single('VIRT_INV_FOR_POSITIONS')
}

/// Key for the position impact factor.
fn position_impact_factor() -> felt252 {
    hash_poseidon_single('POSITION_IMPACT_FACTOR')
}

/// Key for the position impact exponent factor.
fn position_impact_exponent_factor() -> felt252 {
    hash_poseidon_single('POS_IMPACT_EXP_FACTOR')
}

/// Key for the max decrease position impact factor.
fn max_position_impact_factor() -> felt252 {
    hash_poseidon_single('MAX_POS_IMPACT_FACTOR')
}

/// Key for the max position impact factor for liquidations.
fn max_position_impact_factor_for_liquidations() -> felt252 {
    hash_poseidon_single('MAX_POS_IMP_FACT_FOR_LIQ')
}

/// Key for the position fee factor.
fn position_fee_factor() -> felt252 {
    hash_poseidon_single('POSITION_FEE_FACTOR')
}

/// Key for the swap impact factor.
fn swap_impact_factor() -> felt252 {
    hash_poseidon_single('SWAP_IMPACT_FACTOR')
}

/// Key for the swap impact exponent factor.
fn swap_impact_exponent_factor() -> felt252 {
    hash_poseidon_single('SWAP_IMPACT_EXP_FACTOR')
}

/// Key for the swap fee factor.
fn swap_fee_factor() -> felt252 {
    hash_poseidon_single('SWAP_FEE_FACTOR')
}

/// Key for the oracle type.
fn oracle_type() -> felt252 {
    hash_poseidon_single('ORACLE_TYPE')
}

/// Key for open interest.
fn open_interest() -> felt252 {
    hash_poseidon_single('OPEN_INTEREST')
}

/// Key for open interest in tokens.
fn open_interest_in_tokens() -> felt252 {
    hash_poseidon_single('OPEN_INTEREST_IN_TOKENS')
}

/// Key for collateral sum for a market.
fn collateral_sum() -> felt252 {
    hash_poseidon_single('COLLATERAL_SUM')
}

/// Key for pool amount.
fn pool_amount() -> felt252 {
    hash_poseidon_single('POOL_AMOUNT')
}

/// Key for max pool amount.
fn max_pool_amount() -> felt252 {
    hash_poseidon_single('MAX_POOL_AMOUNT')
}

/// Key for max open interest.
fn max_open_interest() -> felt252 {
    hash_poseidon_single('MAX_OPEN_INTEREST')
}

/// Key for position impact pool amount.
fn position_impact_pool_amount() -> felt252 {
    hash_poseidon_single('POS_IMPACT_POOL_AMT')
}

/// Key for swap impact pool amount.
fn swap_impact_pool_amount() -> felt252 {
    hash_poseidon_single('SWAP_IMPACT_POOL_AMT')
}

/// Key for price feed.
fn price_feed() -> felt252 {
    hash_poseidon_single('PRICE_FEED')
}

/// Key for price feed multiplier.
fn price_feed_multiplier() -> felt252 {
    hash_poseidon_single('PRICE_FEED_MULTIPLIER')
}

/// Key for price feed heartbeat.
fn price_feed_heartbeat_duration() -> felt252 {
    hash_poseidon_single('PRICE_FEED_HB_DURATION')
}

/// Key for stable price.
fn stable_price() -> felt252 {
    hash_poseidon_single('STABLE_PRICE')
}

/// Key for reserve factor.
fn reserve_factor() -> felt252 {
    hash_poseidon_single('RESERVE_FACTOR')
}

/// Key for open interest reserve factor.
fn open_interest_reserve_factor() -> felt252 {
    hash_poseidon_single('OI_RESERVE_FACTOR')
}

/// Key for max pnl factor.
fn max_pnl_factor() -> felt252 {
    hash_poseidon_single('MAX_PNL_FACTOR')
}

/// Key for max pnl factor for traders.
fn max_pnl_factor_for_traders() -> felt252 {
    hash_poseidon_single('MAX_PNL_FACT_FOR_TRADERS')
}

/// Key for max pnl factor for adl.
fn max_pnl_factor_for_adl() -> felt252 {
    hash_poseidon_single('MAX_PNL_FACTOR_FOR_ADL')
}

/// Key for min pnl factor after adl.
fn min_pnl_factor_after_adl() -> felt252 {
    hash_poseidon_single('MIN_PNL_FACTOR_AFTER_ADL')
}

/// Key for max pnl factor for deposits.
fn max_pnl_factor_for_deposits() -> felt252 {
    hash_poseidon_single('MAX_PNL_FACTOR_FOR_DEPOSITS')
}

/// Key for max pnl factor for withdrawals.
fn max_pnl_factor_for_withdrawals() -> felt252 {
    hash_poseidon_single('MAX_PNL_FACT_FOR_WITHDRAWALS')
}

/// Key for latest ADL block.
fn latest_adl_block() -> felt252 {
    hash_poseidon_single('LATEST_ADL_BLOCK')
}

/// Key for whether ADL is enabled.
fn is_adl_enabled() -> felt252 {
    hash_poseidon_single('IS_ADL_ENABLED')
}

/// Key for funding factor.
fn funding_factor() -> felt252 {
    hash_poseidon_single('FUNDING_FACTOR')
}

/// Key for stable funding factor.
fn stable_funding_factor() -> felt252 {
    hash_poseidon_single('STABLE_FUNDING_FACTOR')
}

/// Key for funding exponent factor.
fn funding_exponent_factor() -> felt252 {
    hash_poseidon_single('FUNDING_EXPONENT_FACTOR')
}

/// Key for funding fee amount per size.
fn funding_fee_amount_per_size() -> felt252 {
    hash_poseidon_single('FUNDING_FEE_AMT_PER_SIZE')
}

/// Key for claimable funding amount per size.
fn claimable_funding_amount_per_size() -> felt252 {
    hash_poseidon_single('CLAIMABLE_FUND_AMT_PER_SIZE')
}

/// Key for when funding was last updated at.
fn funding_updated_at() -> felt252 {
    hash_poseidon_single('FUNDING_UPDATED_AT')
}

/// Key for claimable funding amount.
fn claimable_funding_amount() -> felt252 {
    hash_poseidon_single('CLAIMABLE_FUNDING_AMOUNT')
}

/// Key for claimable collateral amount.
fn claimable_collateral_amount() -> felt252 {
    hash_poseidon_single('CLAIMABLE_COLLATERAL_AMT')
}

/// Key for claimable collateral factor.
fn claimable_collateral_factor() -> felt252 {
    hash_poseidon_single('CLAIMABLE_COLL_FACTOR')
}

/// Key for claimable collateral time divisor.
fn claimable_collateral_time_divisor() -> felt252 {
    hash_poseidon_single('CLAIMABLE_COLL_TIME_DIV')
}

/// Key for claimed collateral amount.
fn claimed_collateral_amount() -> felt252 {
    hash_poseidon_single('CLAIMED_COLLATERAL_AMOUNT')
}

/// Key for borrowing factor.
fn borrowing_factor() -> felt252 {
    hash_poseidon_single('BORROWING_FACTOR')
}

/// Key for borrowing exponent factor.
fn borrowing_exponent_factor() -> felt252 {
    hash_poseidon_single('BORROWING_EXPONENT_FACTOR')
}

/// Key for skipping the borrowing fee for the smaller side.
fn skip_borrowing_fee_for_smaller_side() -> felt252 {
    hash_poseidon_single('SKIP_BORROW_FEE_SMALLER_SIDE')
}

/// Key for cumulative borrowing factor.
fn cumulative_borrowing_factor() -> felt252 {
    hash_poseidon_single('CUMULATIVE_BORROWING_FACTOR')
}

/// Key for when the cumulative borrowing factor was last updated at.
fn cumulative_borrowing_factor_updated_at() -> felt252 {
    hash_poseidon_single('CUMUL_BORROW_FACT_UPDATED_AT')
}

/// Key for total borrowing amount.
fn total_borrowing() -> felt252 {
    hash_poseidon_single('TOTAL_BORROWING')
}

/// Key for affiliate reward.
fn affiliate_reward() -> felt252 {
    hash_poseidon_single('AFFILIATE_REWARD')
}

/// Constant for user initiated cancel reason.
fn user_initiated_cancel() -> felt252 {
    hash_poseidon_single('USER_INITIATED_CANCEL')
}

// *************************************************************************
// *                    NON CONSTANT KEYS                                  *
// *************************************************************************

/// Key for the account deposit list.
/// # Arguments
/// * `account` - The account address.
/// # Returns
/// * The key for the account deposit list.
fn account_deposit_list_key(account: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(account_deposit_list());
    data.append(account.into());
    poseidon_hash_span(data.span())
}

/// Key for the account withdrawal list.
/// # Arguments
/// * `account` - The account address.
/// # Returns
/// * The key for the account withdrawal list.
fn account_withdrawal_list_key(account: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(account_withdrawal_list());
    data.append(account.into());
    poseidon_hash_span(data.span())
}

/// Key for the account position list.
/// # Arguments
/// * `account` - The account address.
/// # Returns
/// * The key for the account position list.
fn account_position_list_key(account: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(account_position_list());
    data.append(account.into());
    poseidon_hash_span(data.span())
}

/// Key for the account order list.
/// # Arguments
/// * `account` - The account address.
/// # Returns
/// * The key for the account order list.
fn account_order_list_key(account: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(account_order_list());
    data.append(account.into());
    poseidon_hash_span(data.span())
}

/// Key for the claim fee amount.
/// # Arguments
/// * `market` - The market for the fee.
/// * `token` - The token for the fee.
/// # Returns
/// * The key for the claimable fee amount.
fn claimable_fee_amount_key(market: ContractAddress, token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(claimable_fee_amount());
    data.append(market.into());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// Key for the claimable ui fee amount for account.
/// # Arguments
/// * `market` - The market for the fee.
/// * `token` - The token for the fee.
/// * `account` - The account that can claim the ui fee.
/// # Returns
/// * The key for the claimable ui fee amount.
fn claimable_ui_fee_amount_key(market: ContractAddress, token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(claimable_ui_fee_amount());
    data.append(market.into());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// Key for the claimable ui fee amount for account.
/// # Arguments
/// * `market` - The market for the fee.
/// * `token` - The token for the fee.
/// * `account` - The account that can claim the ui fee.
/// # Returns
/// * The key for the claimable ui fee amount.
fn claimable_ui_fee_amount_for_account_key(
    market: ContractAddress, token: ContractAddress, account: ContractAddress
) -> felt252 {
    let mut data = array![];
    data.append(claimable_ui_fee_amount());
    data.append(market.into());
    data.append(token.into());
    data.append(account.into());
    poseidon_hash_span(data.span())
}

/// Key for deposit gas limit.
/// # Arguments
/// * `single_token` - Whether a single token or pair tokens are being deposited.
/// # Returns
/// * The key for the deposit gas limit.
fn deposit_gas_limit_key(single_token: bool) -> felt252 {
    let mut data = array![];
    data.append(deposit_gas_limit());
    // TODO: Replace by `single_token.into()` once upgrading to next version of Cairo.
    data.append(bool_to_felt252(single_token));
    poseidon_hash_span(data.span())
}

/// Key for withdrawal gas limit.
fn withdrawal_gas_limit_key() -> felt252 {
    let mut data = array![];
    data.append(withdrawal_gas_limit());
    poseidon_hash_span(data.span())
}

/// Key for single swap gas limit.
fn single_swap_gas_limit_key() -> felt252 {
    single_swap_gas_limit()
}

/// Key for increase order gas limit.
fn increase_order_gas_limit_key() -> felt252 {
    increase_order_gas_limit()
}

/// Key for decrease order gas limit.
fn decrease_order_gas_limit_key() -> felt252 {
    decrease_order_gas_limit()
}

/// Key for swap order gas limit.
fn swap_order_gas_limit_key() -> felt252 {
    swap_order_gas_limit()
}

/// Key for swap path market flag.
/// # Arguments
/// * `market` - The market for the swap path.
/// # Returns
/// * The key for the swap path market flag.
fn swap_path_market_flag_key(market: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(swap_path_market_flag());
    data.append(market.into());
    poseidon_hash_span(data.span())
}

/// Key for whether create deposit is disabled.
/// # Arguments
/// * `module` - The create deposit module.
fn create_deposit_feature_disabled_key(module: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(create_deposit_feature_disabled());
    data.append(module.into());
    poseidon_hash_span(data.span())
}

/// Key for whether cancel deposit is disabled.
/// # Arguments
/// * `module` - The cancel deposit module.
fn cancel_deposit_feature_disabled_key(module: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(cancel_deposit_feature_disabled());
    data.append(module.into());
    poseidon_hash_span(data.span())
}

/// Key for whether execute deposit is disabled.
/// # Arguments
/// * `module` - The execute deposit module.
fn execute_deposit_feature_disabled_key(module: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(execute_deposit_feature_disabled());
    data.append(module.into());
    poseidon_hash_span(data.span())
}

/// Key for whether create withdrawal is disabled.
/// # Arguments
/// * `module` - The create withdrawal module.
fn create_withdrawal_feature_disabled_key(module: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(create_withdrawal_feature_disabled());
    data.append(module.into());
    poseidon_hash_span(data.span())
}

/// Key for whether cancel withdrawal is disabled.
/// # Arguments
/// * `module` - The cancel withdrawal module.
fn cancel_withdrawal_feature_disabled_key(module: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(cancel_withdrawal_feature_disabled());
    data.append(module.into());
    poseidon_hash_span(data.span())
}

/// Key for whether execute withdrawal is disabled.
/// # Arguments
/// * `module` - The execute withdrawal module.
fn execute_withdrawal_feature_disabled_key(module: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(execute_withdrawal_feature_disabled());
    data.append(module.into());
    poseidon_hash_span(data.span())
}

/// Key for whether create order is disabled.
/// # Arguments
/// * `module` - The create order module.
/// * `order_type` - The order type.
fn create_order_feature_disabled_key(module: ContractAddress, order_type: OrderType) -> felt252 {
    let mut data = array![];
    data.append(create_order_feature_disabled());
    data.append(module.into());
    order_type.serialize(ref data);
    poseidon_hash_span(data.span())
}

/// Key for whether execute order is disabled.
/// # Arguments
/// * `module` - The execute order module.
/// * `order_type` - The order type.
fn execute_order_feature_disabled_key(module: ContractAddress, order_type: OrderType) -> felt252 {
    let mut data = array![];
    data.append(execute_order_feature_disabled());
    data.append(module.into());
    order_type.serialize(ref data);
    poseidon_hash_span(data.span())
}

/// Key for whether execute adl is disabled.
/// # Arguments
/// * `module` - The execute adl module.
/// * `order_type` - The order type.
fn execute_adl_feature_disabled_key(module: ContractAddress, order_type: felt252) -> felt252 {
    let mut data = array![];
    data.append(execute_adl_feature_disabled());
    data.append(module.into());
    data.append(order_type);
    poseidon_hash_span(data.span())
}

/// Key for whether update order is disabled.
/// # Arguments
/// * `module` - The update order module.
/// * `order_type` - The order type.
fn update_order_feature_disabled_key(module: ContractAddress, order_type: OrderType) -> felt252 {
    let mut data = array![];
    data.append(update_order_feature_disabled());
    data.append(module.into());
    order_type.serialize(ref data);
    poseidon_hash_span(data.span())
}

/// Key for whether cancel order is disabled.
/// # Arguments
/// * `module` - The cancel order module.
/// * `order_type` - The order type.
fn cancel_order_feature_disabled_key(module: ContractAddress, order_type: OrderType) -> felt252 {
    let mut data = array![];
    data.append(cancel_order_feature_disabled());
    data.append(module.into());
    order_type.serialize(ref data);
    poseidon_hash_span(data.span())
}

/// Key for whether claim funding fees is disabled.
/// # Arguments
/// * `module` - The claim funding fees module.
fn claim_funding_fees_feature_disabled_key(module: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(claim_funding_fees_feature_disabled());
    data.append(module.into());
    poseidon_hash_span(data.span())
}

/// Key for whether claim collateral is disabled.
/// # Arguments
/// * `module` - The claim funding fees module.
fn claim_collateral_feature_disabled_key(module: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(claim_collateral_feature_disabled());
    data.append(module.into());
    poseidon_hash_span(data.span())
}

/// Key for whether claim affiliate rewards is disabled.
/// # Arguments
/// * `module` - The claim affiliate rewards module.
fn claim_affiliate_rewards_feature_disabled_key(module: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(claim_affiliate_rewards_feature_disabled());
    data.append(module.into());
    poseidon_hash_span(data.span())
}

/// Key for whether claim ui fees is disabled.
/// # Arguments
/// * `module` - The claim ui fees module.
fn claim_ui_fees_feature_disabled_key(module: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(claim_ui_fees_feature_disabled());
    data.append(module.into());
    poseidon_hash_span(data.span())
}

/// Key for ui fee factor.
/// # Arguments
/// * `account` - The fee receiver account.
fn ui_fee_factor_key(account: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(ui_fee_factor());
    data.append(account.into());
    poseidon_hash_span(data.span())
}

/// Key for gas to forward for token transfer.
/// # Arguments
/// * `token` - The token to check.
fn token_transfer_gas_limit_key(token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(token_transfer_gas_limit());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// The default callback contract.
/// # Arguments
/// * `account` - The user account.
/// * `market` - The address of the market.
fn saved_callback_contract_key(account: ContractAddress, market: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(saved_callback_contract());
    data.append(account.into());
    data.append(market.into());
    poseidon_hash_span(data.span())
}

/// Key for the min collateral factor.
/// # Arguments
/// * `market` - The market address.
fn min_collateral_factor_key(market: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(min_collateral_factor());
    data.append(market.into());
    poseidon_hash_span(data.span())
}

/// Key for the min collateral factor for open interest multiplier.
/// # Arguments
/// * `market` - The market address.
/// * `is_long` - Whether the position is long.
fn min_collateral_factor_for_open_interest_multiplier_key(
    market: ContractAddress, is_long: bool
) -> felt252 {
    let mut data = array![];
    data.append(min_collateral_factor_for_open_interest_multiplier());
    data.append(market.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for the virtual token id.
/// # Arguments
/// * `token` - The token address.
fn virtual_token_id_key(token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(virtual_token_id());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// Key for the virtual market id.
/// # Arguments
/// * `market` - The market address.
fn virtual_market_id_key(market: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(virtual_market_id());
    data.append(market.into());
    poseidon_hash_span(data.span())
}

/// Key for the virtual inventory for positions.
/// # Arguments
/// * `virtual_token_id` - The virtual token id.
fn virtual_inventory_for_positions_key(virtual_token_id: felt252) -> felt252 {
    let mut data = array![];
    data.append(virtual_inventory_for_positions());
    data.append(virtual_token_id);
    poseidon_hash_span(data.span())
}

/// Key for the virtual inventory for swaps.
/// # Arguments
/// * `virtual_market_id` - The virtual market id.
/// * `is_long_token` - Whether the token is long.
fn virtual_inventory_for_swaps_key(virtual_market_id: felt252, is_long_token: bool) -> felt252 {
    let mut data = array![];
    data.append(virtual_inventory_for_swaps());
    data.append(virtual_market_id);
    data.append(bool_to_felt252(is_long_token));
    poseidon_hash_span(data.span())
}

/// Key for the position impact factor.
/// # Arguments
/// * `market` - The market address.
/// * `is_positive` - Whether the impact is positive or negative.
fn position_impact_factor_key(market: ContractAddress, is_positive: bool) -> felt252 {
    let mut data = array![];
    data.append(position_impact_factor());
    data.append(market.into());
    data.append(bool_to_felt252(is_positive));
    poseidon_hash_span(data.span())
}

/// Key for the position impact exponent factor.
/// # Arguments
/// * `market` - The market address.
fn position_impact_exponent_factor_key(market: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(position_impact_exponent_factor());
    data.append(market.into());
    poseidon_hash_span(data.span())
}

/// Key for the max position impact factor.
/// # Arguments
/// * `market` - The market address.
/// * `is_positive` - Whether the impact is positive or negative.
fn max_position_impact_factor_key(market: ContractAddress, is_positive: bool) -> felt252 {
    let mut data = array![];
    data.append(max_position_impact_factor());
    data.append(market.into());
    data.append(bool_to_felt252(is_positive));
    poseidon_hash_span(data.span())
}

/// Key for the max position impact factor for liquidations.
/// # Arguments
/// * `market` - The market address.
fn max_position_impact_factor_for_liquidations_key(market: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(max_position_impact_factor_for_liquidations());
    data.append(market.into());
    poseidon_hash_span(data.span())
}

/// Key for the position fee factor.
/// # Arguments
/// * `market` - The market address.
/// * `for_positive_impact` - Whether the fee is for an action that has a positive price impact.
fn position_fee_factor_key(market: ContractAddress, for_positive_impact: bool) -> felt252 {
    let mut data = array![];
    data.append(position_fee_factor());
    data.append(market.into());
    data.append(bool_to_felt252(for_positive_impact));
    poseidon_hash_span(data.span())
}

/// Key for the swap impact factor.
/// # Arguments
/// * `market` - The market address.
/// * `is_positive` - Whether the impact is positive or negative.
fn swap_impact_factor_key(market: ContractAddress, is_positive: bool) -> felt252 {
    let mut data = array![];
    data.append(swap_impact_factor());
    data.append(market.into());
    data.append(bool_to_felt252(is_positive));
    poseidon_hash_span(data.span())
}

/// Key for the swap impact exponent factor.
/// # Arguments
/// * `market` - The market address.
fn swap_impact_exponent_factor_key(market: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(swap_impact_exponent_factor());
    data.append(market.into());
    poseidon_hash_span(data.span())
}

/// Key for the swap fee factor.
/// # Arguments
/// * `market` - The market address.
/// * `for_positive_impact` - Whether the fee is for an action that has a positive price impact.
fn swap_fee_factor_key(market: ContractAddress, for_positive_impact: bool) -> felt252 {
    let mut data = array![];
    data.append(swap_fee_factor());
    data.append(market.into());
    data.append(bool_to_felt252(for_positive_impact));
    poseidon_hash_span(data.span())
}

/// Key for the oracle type.
/// # Arguments
/// * `token` - The token to check.
fn oracle_type_key(token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(oracle_type());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// Key for open interest.
/// # Arguments
/// * `market` - The market address.
/// * `collateral_token` - The collateral token.
/// * `is_long` - Whether to check the long or short open interest.
fn open_interest_key(
    market: ContractAddress, collateral_token: ContractAddress, is_long: bool
) -> felt252 {
    let mut data = array![];
    data.append(open_interest());
    data.append(market.into());
    data.append(collateral_token.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for open interest in tokens.
/// # Arguments
/// * `market` - The market address.
/// * `collateral_token` - The collateral token.
/// * `is_long` - Whether to check the long or short open interest.
fn open_interest_in_tokens_key(
    market: ContractAddress, collateral_token: ContractAddress, is_long: bool
) -> felt252 {
    let mut data = array![];
    data.append(open_interest_in_tokens());
    data.append(market.into());
    data.append(collateral_token.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for collateral sum for a market.
/// # Arguments
/// * `market` - The market address.
/// * `collateral_token` - The collateral token.
/// * `is_long` - Whether to check the long or short collateral sum.
fn collateral_sum_key(
    market: ContractAddress, collateral_token: ContractAddress, is_long: bool
) -> felt252 {
    let mut data = array![];
    data.append(collateral_sum());
    data.append(market.into());
    data.append(collateral_token.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for amount of tokens in a market's pool.
/// # Arguments
/// * `market` - The market address.
/// * `token` - The token to check.
fn pool_amount_key(market: ContractAddress, token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(pool_amount());
    data.append(market.into());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// Key for the max amount of pool tokens.
/// # Arguments
/// * `market` - The market address.
/// * `token` - The token for the pool.
fn max_pool_amount_key(market: ContractAddress, token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(max_pool_amount());
    data.append(market.into());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// Key for the max open interest.
/// # Arguments
/// * `market` - The market address.
/// * `is_long` - Whether the key is for the long or short side.
fn max_open_interest_key(market: ContractAddress, is_long: bool) -> felt252 {
    let mut data = array![];
    data.append(max_open_interest());
    data.append(market.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for amount of tokens in a market's position impact pool.
/// # Arguments
/// * `market` - The market address.
fn position_impact_pool_amount_key(market: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(position_impact_pool_amount());
    data.append(market.into());
    poseidon_hash_span(data.span())
}

/// Key for amount of tokens in a market's swap impact pool.
/// # Arguments
/// * `market` - The market address.
/// * `token` - The token to check.
fn swap_impact_pool_amount_key(market: ContractAddress, token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(swap_impact_pool_amount());
    data.append(market.into());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// Key for reserve factor.
/// # Arguments
/// * `market` - The market address.
/// * `is_long` - Whether the key is for the long or short side.
fn reserve_factor_key(market: ContractAddress, is_long: bool) -> felt252 {
    let mut data = array![];
    data.append(reserve_factor());
    data.append(market.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for open interest reserve favtor.
/// # Arguments
/// * `market` - The market address.
/// * `is_long` - Whether the key is for the long or short side.
fn open_interest_reserve_factor_key(market: ContractAddress, is_long: bool) -> felt252 {
    let mut data = array![];
    data.append(open_interest_reserve_factor());
    data.append(market.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for max pnl factor.
/// # Arguments
/// * `pnl_factor_type` - The pnl factor type.
/// * `market` - The market address.
/// * `is_long` - Whether the key is for the long or short side.
/// # Notes
/// `pnl_factor_type` is a felt252 because it is a hash of a string.
/// In GMX syntethics it's represented as a `bytes32` Solidity type, but we can simply use a felt252.
fn max_pnl_factor_key(pnl_factor_type: felt252, market: ContractAddress, is_long: bool) -> felt252 {
    let mut data = array![];
    data.append(max_pnl_factor());
    data.append(pnl_factor_type);
    data.append(market.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for min pnl factor after ADL.
/// # Arguments
/// * `market` - The market address.
/// * `is_long` - Whether the key is for the long or short side.
fn min_pnl_factor_after_adl_key(market: ContractAddress, is_long: bool) -> felt252 {
    let mut data = array![];
    data.append(min_pnl_factor_after_adl());
    data.append(market.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for latest adl block.
/// # Arguments
/// * `market` - The market address.
/// * `is_long` - Whether the key is for the long or short side.
fn latest_adl_block_key(market: ContractAddress, is_long: bool) -> felt252 {
    let mut data = array![];
    data.append(latest_adl_block());
    data.append(market.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for whether adl is enabled.
/// # Arguments
/// * `market` - The market address.
/// * `is_long` - Whether the key is for the long or short side.
fn is_adl_enabled_key(market: ContractAddress, is_long: bool) -> felt252 {
    let mut data = array![];
    data.append(is_adl_enabled());
    data.append(market.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for funding factor.
/// # Arguments
/// * `market` - The market address.
fn funding_factor_key(market: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(funding_factor());
    data.append(market.into());
    poseidon_hash_span(data.span())
}

/// Key for stable funding factor.
/// # Arguments
/// * `market` - The market address.
fn stable_funding_factor_key(market: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(stable_funding_factor());
    data.append(market.into());
    poseidon_hash_span(data.span())
}

/// Key for the funding exponent.
/// # Arguments
/// * `market` - The market address.
fn funding_exponent_factor_key(market: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(funding_exponent_factor());
    data.append(market.into());
    poseidon_hash_span(data.span())
}

/// Key for funding fee amount per size.
/// # Arguments
/// * `market` - The market address.
/// * `collateral_token` - The collateral token address.
/// * `is_long` - Whether the key is for the long or short side.
fn funding_fee_amount_per_size_key(
    market: ContractAddress, collateral_token: ContractAddress, is_long: bool
) -> felt252 {
    let mut data = array![];
    data.append(funding_fee_amount_per_size());
    data.append(market.into());
    data.append(collateral_token.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for claimable funding amount per size.
/// # Arguments
/// * `market` - The market address.
/// * `collateral_token` - The collateral token address.
/// * `is_long` - Whether the key is for the long or short side.
fn claimable_funding_amount_per_size_key(
    market: ContractAddress, collateral_token: ContractAddress, is_long: bool
) -> felt252 {
    let mut data = array![];
    data.append(claimable_funding_amount_per_size());
    data.append(market.into());
    data.append(collateral_token.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for when funding was last updated.
/// # Arguments
/// * `market` - The market address.
fn funding_updated_at_key(market: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(funding_updated_at());
    data.append(market.into());
    poseidon_hash_span(data.span())
}

/// Key for claimable funding amount.
/// # Arguments
/// * `market` - The market address.
/// * `token` - The token address.
fn claimable_funding_amount_key(market: ContractAddress, token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(claimable_funding_amount());
    data.append(market.into());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// Key for claimable funding amount by account.
/// # Arguments
/// * `market` - The market address.
/// * `token` - The token address.
/// * `account` - The account address.
fn claimable_funding_amount_by_account_key(
    market: ContractAddress, token: ContractAddress, account: ContractAddress
) -> felt252 {
    let mut data = array![];
    data.append(claimable_funding_amount());
    data.append(market.into());
    data.append(token.into());
    data.append(account.into());
    poseidon_hash_span(data.span())
}

/// Key for claimable collateral amount.
/// # Arguments
/// * `market` - The market address.
/// * `token` - The token address.
fn claimable_collateral_amount_key(market: ContractAddress, token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(claimable_collateral_amount());
    data.append(market.into());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// Key for claimable collateral amount for a timeKey for an account.
/// # Arguments
/// * `market` - The market address.
/// * `token` - The token address.
/// * `time_key` - The time key for the claimable amount.
/// * `account` - The account address.
fn claimable_collateral_amount_for_account_key(
    market: ContractAddress, token: ContractAddress, time_key: u128, account: ContractAddress
) -> felt252 {
    let mut data = array![];
    data.append(claimable_collateral_amount());
    data.append(market.into());
    data.append(token.into());
    data.append(time_key.into());
    data.append(account.into());
    poseidon_hash_span(data.span())
}

/// Key for claimable collateral factor for a timeKey.
/// # Arguments
/// * `market` - The market address.
/// * `token` - The token address.
/// * `time_key` - The time key for the claimable amount.
fn claimable_collateral_factor_key(
    market: ContractAddress, token: ContractAddress, time_key: u128
) -> felt252 {
    let mut data = array![];
    data.append(claimable_collateral_factor());
    data.append(market.into());
    data.append(token.into());
    data.append(time_key.into());
    poseidon_hash_span(data.span())
}

/// Key for claimable collateral factor for a timeKey for an account.
/// # Arguments
/// * `market` - The market address.
/// * `token` - The token address.
/// * `time_key` - The time key for the claimable amount.
/// * `account` - The account address.
fn claimable_collateral_factor_for_account_key(
    market: ContractAddress, token: ContractAddress, time_key: u128, account: ContractAddress
) -> felt252 {
    let mut data = array![];
    data.append(claimable_collateral_factor());
    data.append(market.into());
    data.append(token.into());
    data.append(time_key.into());
    data.append(account.into());
    poseidon_hash_span(data.span())
}

/// Key for claimed collateral amount.
/// # Arguments
/// * `market` - The market address.
/// * `token` - The token address.
/// * `time_key` - The time key for the claimable amount.
/// * `account` - The account address.
fn claimed_collateral_amount_key(
    market: ContractAddress, token: ContractAddress, time_key: u128, account: ContractAddress
) -> felt252 {
    let mut data = array![];
    data.append(claimed_collateral_amount());
    data.append(market.into());
    data.append(token.into());
    data.append(time_key.into());
    data.append(account.into());
    poseidon_hash_span(data.span())
}

/// Key for borrowing factor.
/// # Arguments
/// * `market` - The market address.
/// * `is_long` - Whether the key is for the long or short side.
fn borrowing_factor_key(market: ContractAddress, is_long: bool) -> felt252 {
    let mut data = array![];
    data.append(borrowing_factor());
    data.append(market.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for borrowing exponent factor.
/// # Arguments
/// * `market` - The market address.
/// * `is_long` - Whether the key is for the long or short side.
fn borrowing_exponent_factor_key(market: ContractAddress, is_long: bool) -> felt252 {
    let mut data = array![];
    data.append(borrowing_exponent_factor());
    data.append(market.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for cumulative borrowing factor.
/// # Arguments
/// * `market` - The market address.
/// * `is_long` - Whether the key is for the long or short side.
fn cumulative_borrowing_factor_key(market: ContractAddress, is_long: bool) -> felt252 {
    let mut data = array![];
    data.append(cumulative_borrowing_factor());
    data.append(market.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for cumulative borrowing factor updated at.
/// # Arguments
/// * `market` - The market address.
/// * `is_long` - Whether the key is for the long or short side.
fn cumulative_borrowing_factor_updated_at_key(market: ContractAddress, is_long: bool) -> felt252 {
    let mut data = array![];
    data.append(cumulative_borrowing_factor_updated_at());
    data.append(market.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for total borrowing amount.
/// # Arguments
/// * `market` - The market address.
/// * `is_long` - Whether the key is for the long or short side.
fn total_borrowing_key(market: ContractAddress, is_long: bool) -> felt252 {
    let mut data = array![];
    data.append(total_borrowing());
    data.append(market.into());
    data.append(bool_to_felt252(is_long));
    poseidon_hash_span(data.span())
}

/// Key for affiliate reward amount.
/// # Arguments
/// * `market` - The market address.
/// * `token` - The token address.
fn affiliate_reward_key(market: ContractAddress, token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(affiliate_reward());
    data.append(market.into());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// Key for affiliate reward amount for an account.
/// # Arguments
/// * `market` - The market address.
/// * `token` - The token address.
/// * `account` - The account address.
fn affiliate_reward_for_account_key(
    market: ContractAddress, token: ContractAddress, account: ContractAddress
) -> felt252 {
    let mut data = array![];
    data.append(affiliate_reward());
    data.append(market.into());
    data.append(token.into());
    data.append(account.into());
    poseidon_hash_span(data.span())
}

/// Key for is market disabled.
/// # Arguments
/// * `market` - The market address.
fn is_market_disabled_key(market: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(is_market_disabled());
    data.append(market.into());
    poseidon_hash_span(data.span())
}

/// Key for price feed address.
/// # Arguments
/// * `token` - The token address.
fn price_feed_key(token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(price_feed());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// Key for price feed multiplier.
/// # Arguments
/// * `token` - The token address.
fn price_feed_multiplier_key(token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(price_feed_multiplier());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// Key for price feed heartbeat duration.
/// # Arguments
/// * `token` - The token address.
fn price_feed_heartbeat_duration_key(token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(price_feed_heartbeat_duration());
    data.append(token.into());
    poseidon_hash_span(data.span())
}

/// Key for stable price value.
/// # Arguments
/// * `token` - The token address.
fn stable_price_key(token: ContractAddress) -> felt252 {
    let mut data = array![];
    data.append(stable_price());
    data.append(token.into());
    poseidon_hash_span(data.span())
}
