//! Contract to emit the events of the system.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, ClassHash};

// Local imports.
use satoru::deposit::deposit::Deposit;
use satoru::withdrawal::withdrawal::Withdrawal;
use satoru::position::position::Position;
use satoru::market::market_pool_value_info::MarketPoolValueInfo;
use satoru::pricing::swap_pricing_utils::SwapFees;
use satoru::position::position_event_utils::PositionIncreaseParams;
use satoru::position::position_utils::DecreasePositionCollateralValues;
use satoru::order::order::OrderType;
use satoru::price::price::Price;
use satoru::pricing::position_pricing_utils::PositionFees;
use satoru::order::order::{Order, SecondaryOrderType};
use satoru::utils::span32::{Span32, DefaultSpan32};
use satoru::utils::i128::{I128Div, I128Mul, I128Store, I128Serde};


//TODO: OrderCollatDeltaAmountAutoUpdtd must be renamed back to OrderCollateralDeltaAmountAutoUpdated when string will be allowed as event argument
//TODO: AfterWithdrawalCancelError must be renamed back to AfterWithdrawalCancellationError when string will be allowed as event argument
//TODO: CumulativeBorrowingFactorUpdatd must be renamed back to CumulativeBorrowingFactorUpdated when string will be allowed as event argument
//TODO: ClaimableFundingPerSizeUpdatd must be renamed back to ClaimableFundingAmountPerSizeUpdated when string will be allowed as event argument

// *************************************************************************
//                  Interface of the `EventEmitter` contract.
// *************************************************************************
#[starknet::interface]
trait IEventEmitter<TContractState> {
    /// Emits the `ClaimableCollateralUpdated` event.
    fn emit_claimable_collateral_updated(
        ref self: TContractState,
        market: ContractAddress,
        token: ContractAddress,
        account: ContractAddress,
        time_key: u128,
        delta: u128,
        next_value: u128,
        next_pool_value: u128,
    );

    /// Emits the `ClaimableFundingUpdated` event.
    fn emit_claimable_funding_updated(
        ref self: TContractState,
        market: ContractAddress,
        token: ContractAddress,
        account: ContractAddress,
        delta: u128,
        next_value: u128,
        next_pool_value: u128,
    );

    /// Emits the `PositionImpactPoolAmountUpdated` event.
    fn emit_position_impact_pool_amount_updated(
        ref self: TContractState, market: ContractAddress, delta: u128, next_value: u128,
    );

    /// Emits the `SwapImpactPoolAmountUpdated` event.
    fn emit_swap_impact_pool_amount_updated(
        ref self: TContractState,
        market: ContractAddress,
        token: ContractAddress,
        delta: u128,
        next_value: u128,
    );

    /// Emits the `MarketCreated` event.
    fn emit_market_created(
        ref self: TContractState,
        creator: ContractAddress,
        market_token: ContractAddress,
        index_token: ContractAddress,
        long_token: ContractAddress,
        short_token: ContractAddress,
        market_type: felt252,
    );

    /// Emits the `MarketTokenClassHashUpdated` event.
    fn emit_market_token_class_hash_updated(
        ref self: TContractState,
        updated_by: ContractAddress,
        previous_value: ClassHash,
        new_value: ClassHash,
    );

    /// Emits the `ClaimableFeeAmountUpdated` event.
    fn emit_claimable_fee_amount_updated(
        ref self: TContractState,
        market: ContractAddress,
        token: ContractAddress,
        delta: u128,
        next_value: u128,
        fee_type: felt252
    );

    /// Emits the `ClaimableUiFeeAmountUpdated` event.
    fn emit_claimable_ui_fee_amount_updated(
        ref self: TContractState,
        ui_fee_receiver: ContractAddress,
        market: ContractAddress,
        token: ContractAddress,
        delta: u128,
        next_value: u128,
        next_pool_value: u128,
        fee_type: felt252
    );

    /// Emits the `FeesClaimed` event.
    fn emit_fees_claimed(
        ref self: TContractState,
        market: ContractAddress,
        receiver: ContractAddress,
        fee_amount: u128
    );

    /// Emits the `UiFeesClaimed` event.
    fn emit_ui_fees_claimed(
        ref self: TContractState,
        ui_fee_receiver: ContractAddress,
        market: ContractAddress,
        receiver: ContractAddress,
        fee_amount: u128,
        next_pool_value: u128
    );

    /// Emits the `DepositCreated` event.
    #[inline(always)]
    fn emit_deposit_created(ref self: TContractState, key: felt252, deposit: Deposit);

    /// Emits the `DepositExecuted` event.
    fn emit_deposit_executed(
        ref self: TContractState,
        key: felt252,
        long_token_amount: u128,
        short_token_amount: u128,
        received_market_tokens: u128,
    );

    /// Emits the `DepositCancelled` event.
    fn emit_deposit_cancelled(
        ref self: TContractState, key: felt252, reason: felt252, reason_bytes: Span<felt252>
    );

    /// Emits the `WithdrawalCreated` event.
    #[inline(always)]
    fn emit_withdrawal_created(ref self: TContractState, key: felt252, withdrawal: Withdrawal);

    /// Emits the `WithdrawalExecuted` event.
    fn emit_withdrawal_executed(ref self: TContractState, key: felt252);

    /// Emits the `WithdrawalCancelled` event.
    fn emit_withdrawal_cancelled(
        ref self: TContractState, key: felt252, reason: felt252, reason_bytes: Span<felt252>
    );

    /// Emits the `PositionIncrease` event.
    #[inline(always)]
    fn emit_position_increase(ref self: TContractState, params: PositionIncreaseParams);

    /// Emits the `PositionDecrease` event.
    #[inline(always)]
    fn emit_position_decrease(
        ref self: TContractState,
        order_key: felt252,
        position_key: felt252,
        position: Position,
        size_delta_usd: u128,
        collateral_delta_amount: u128,
        order_type: OrderType,
        values: DecreasePositionCollateralValues,
        index_token_price: Price,
        collateral_token_price: Price
    );

    /// Emits the `InsolventClose` event.
    fn emit_insolvent_close_info(
        ref self: TContractState,
        order_key: felt252,
        position_collateral_amount: u128,
        base_pnl_usd: u128,
        remaining_cost_usd: u128
    );

    /// Emits the `InsufficientFundingFeePayment` event.
    fn emit_insufficient_funding_fee_payment(
        ref self: TContractState,
        market: ContractAddress,
        token: ContractAddress,
        expected_amount: u128,
        amount_paid_in_collateral_token: u128,
        amount_paid_in_secondary_output_token: u128
    );

    /// Emits the `PositionFeesCollected` event.
    #[inline(always)]
    fn emit_position_fees_collected(
        ref self: TContractState,
        order_key: felt252,
        position_key: felt252,
        market: ContractAddress,
        collateral_token: ContractAddress,
        trade_size_usd: u128,
        is_increase: bool,
        fees: PositionFees
    );

    /// Emits the `PositionFeesInfo` event.
    #[inline(always)]
    fn emit_position_fees_info(
        ref self: TContractState,
        order_key: felt252,
        position_key: felt252,
        market: ContractAddress,
        collateral_token: ContractAddress,
        trade_size_usd: u128,
        is_increase: bool,
        fees: PositionFees
    );

    /// Emits the `OrderCreated` event.
    #[inline(always)]
    fn emit_order_created(ref self: TContractState, key: felt252, order: Order);

    /// Emits the `OrderExecuted` event.
    fn emit_order_executed(
        ref self: TContractState, key: felt252, secondary_order_type: SecondaryOrderType
    );

    /// Emits the `OrderUpdated` event.
    fn emit_order_updated(
        ref self: TContractState,
        key: felt252,
        size_delta_usd: u128,
        acceptable_price: u128,
        trigger_price: u128,
        min_output_amount: u128
    );

    /// Emits the `OrderSizeDeltaAutoUpdated` event.
    fn emit_order_size_delta_auto_updated(
        ref self: TContractState, key: felt252, size_delta_usd: u128, next_size_delta_usd: u128
    );

    /// Emits the `OrderCollatDeltaAmountAutoUpdtd` event.
    fn emit_order_collateral_delta_amount_auto_updated(
        ref self: TContractState,
        key: felt252,
        collateral_delta_amount: u128,
        next_collateral_delta_amount: u128
    );

    /// Emits the `OrderCancelled` event.
    fn emit_order_cancelled(
        ref self: TContractState, key: felt252, reason: felt252, reason_bytes: Span<felt252>
    );

    /// Emits the `OrderFrozen` event.
    fn emit_order_frozen(
        ref self: TContractState, key: felt252, reason: felt252, reason_bytes: Span<felt252>
    );

    /// Emits the `AffiliateRewardUpdated` event.
    fn emit_affiliate_reward_updated(
        ref self: TContractState,
        market: ContractAddress,
        token: ContractAddress,
        affiliate: ContractAddress,
        delta: u128,
        next_value: u128,
        next_pool_value: u128
    );

    /// Emits the `AffiliateRewardClaimed` event.
    fn emit_affiliate_reward_claimed(
        ref self: TContractState,
        market: ContractAddress,
        token: ContractAddress,
        affiliate: ContractAddress,
        receiver: ContractAddress,
        amount: u128,
        next_pool_value: u128
    );

    /// Emits the `AfterDepositExecutionError` event.
    fn emit_after_deposit_execution_error(ref self: TContractState, key: felt252, deposit: Deposit);

    /// Emits the `AfterDepositCancellationError` event.
    fn emit_after_deposit_cancellation_error(
        ref self: TContractState, key: felt252, deposit: Deposit
    );

    /// Emits the `AfterWithdrawalExecutionError` event.
    fn emit_after_withdrawal_execution_error(
        ref self: TContractState, key: felt252, withdrawal: Withdrawal
    );

    /// Emits the `AfterWithdrawalCancelError` event.
    fn emit_after_withdrawal_cancellation_error(
        ref self: TContractState, key: felt252, withdrawal: Withdrawal
    );

    /// Emits the `AfterOrderExecutionError` event.
    fn emit_after_order_execution_error(ref self: TContractState, key: felt252, order: Order);

    /// Emits the `AfterOrderCancellationError` event.
    fn emit_after_order_cancellation_error(ref self: TContractState, key: felt252, order: Order);

    /// Emits the `AfterOrderFrozenError` event.
    fn emit_after_order_frozen_error(ref self: TContractState, key: felt252, order: Order);

    /// Emits the `AdlStateUpdated` event.
    fn emit_adl_state_updated(
        ref self: TContractState,
        market: ContractAddress,
        is_long: bool,
        pnl_to_pool_factor: felt252,
        max_pnl_factor: u128,
        should_enable_adl: bool,
    );

    /// Emits the `SetBool` event.
    fn emit_set_bool(
        ref self: TContractState, key: felt252, data_bytes: Span<felt252>, value: bool
    );

    /// Emits the `SetAddress` event.
    fn emit_set_address(
        ref self: TContractState, key: felt252, data_bytes: Span<felt252>, value: ContractAddress
    );

    /// Emits the `SetFelt252` event.
    fn emit_set_felt252(
        ref self: TContractState, key: felt252, data_bytes: Span<felt252>, value: felt252
    );

    /// Emits the `SetUint` event.
    fn emit_set_uint(
        ref self: TContractState, key: felt252, data_bytes: Span<felt252>, value: u128
    );

    /// Emits the `SetInt` event.
    fn emit_set_int(
        ref self: TContractState, key: felt252, data_bytes: Span<felt252>, value: felt252
    );

    /// Emits the `SignalAddOracleSigner` event.
    fn emit_signal_add_oracle_signer(
        ref self: TContractState, action_key: felt252, account: ContractAddress
    );

    /// Emits the `SignalAddOracleSigner` event.
    fn emit_add_oracle_signer(
        ref self: TContractState, action_key: felt252, account: ContractAddress
    );

    /// Emits the `SignalRemoveOracleSigner` event.
    fn emit_signal_remove_oracle_signer(
        ref self: TContractState, action_key: felt252, account: ContractAddress
    );

    /// Emits the `RemoveOracleSigner` event.
    fn emit_remove_oracle_signer(
        ref self: TContractState, action_key: felt252, account: ContractAddress
    );

    /// Emits the `SignalSetFeeReceiver` event.
    fn emit_signal_set_fee_receiver(
        ref self: TContractState, action_key: felt252, account: ContractAddress
    );

    /// Emits the `SetFeeReceiver` event.
    fn emit_set_fee_receiver(
        ref self: TContractState, action_key: felt252, account: ContractAddress
    );

    /// Emits the `SignalGrantRole` event.
    fn emit_signal_grant_role(
        ref self: TContractState, action_key: felt252, account: ContractAddress, role_key: felt252
    );

    /// Emits the `GrantRole` event.
    fn emit_grant_role(
        ref self: TContractState, action_key: felt252, account: ContractAddress, role_key: felt252
    );

    /// Emits the `SignalRevokeRole` event.
    fn emit_signal_revoke_role(
        ref self: TContractState, action_key: felt252, account: ContractAddress, role_key: felt252
    );

    /// Emits the `RevokeRole` event.
    fn emit_revoke_role(
        ref self: TContractState, action_key: felt252, account: ContractAddress, role_key: felt252
    );

    /// Emits the `SignalSetPriceFeed` event.
    fn emit_signal_set_price_feed(
        ref self: TContractState,
        action_key: felt252,
        token: ContractAddress,
        price_feed: ContractAddress,
        price_feed_multiplier: u128,
        price_feed_heartbeat_duration: u128,
        stable_price: u128
    );

    /// Emits the `SetPriceFeed` event.
    fn emit_set_price_feed(
        ref self: TContractState,
        action_key: felt252,
        token: ContractAddress,
        price_feed: ContractAddress,
        price_feed_multiplier: u128,
        price_feed_heartbeat_duration: u128,
        stable_price: u128
    );

    /// Emits the `SignalPendingAction` event.
    fn emit_signal_pending_action(
        ref self: TContractState, action_key: felt252, action_label: felt252
    );

    /// Emits the `ClearPendingAction` event.
    fn emit_clear_pending_action(
        ref self: TContractState, action_key: felt252, action_label: felt252
    );

    /// Emits the `KeeperExecutionFee` event.
    fn emit_keeper_execution_fee(
        ref self: TContractState, keeper: ContractAddress, execution_fee_amount: u128
    );

    /// Emits the `ExecutionFeeRefund` event.
    fn emit_execution_fee_refund(
        ref self: TContractState, receiver: ContractAddress, refund_fee_amount: u128
    );

    /// Emits the `MarketPoolValueInfo` event.
    #[inline(always)]
    fn emit_market_pool_value_info(
        ref self: TContractState,
        market: ContractAddress,
        market_pool_value_info: MarketPoolValueInfo,
        market_tokens_supply: u128
    );

    /// Emits the `PoolAmountUpdated` event.
    fn emit_pool_amount_updated(
        ref self: TContractState,
        market: ContractAddress,
        token: ContractAddress,
        delta: i128,
        next_value: u128
    );

    /// Emits the `OpenInterestInTokensUpdated` event.
    fn emit_open_interest_in_tokens_updated(
        ref self: TContractState,
        market: ContractAddress,
        collateral_token: ContractAddress,
        is_long: bool,
        delta: i128,
        next_value: u128
    );

    /// Emits the `OpenInterestUpdated` event.
    fn emit_open_interest_updated(
        ref self: TContractState,
        market: ContractAddress,
        collateral_token: ContractAddress,
        is_long: bool,
        delta: u128,
        next_value: u128
    );

    /// Emits the `VirtualSwapInventoryUpdated` event.
    fn emit_virtual_swap_inventory_updated(
        ref self: TContractState,
        market: ContractAddress,
        is_long_token: bool,
        virtual_market_id: felt252,
        delta: u128,
        next_value: u128
    );

    /// Emits the `VirtualPositionInventoryUpdated` event.
    fn emit_virtual_position_inventory_updated(
        ref self: TContractState,
        token: ContractAddress,
        virtual_token_id: felt252,
        delta: u128,
        next_value: u128
    );

    /// Emits the `CollateralSumUpdated` event.
    fn emit_collateral_sum_updated(
        ref self: TContractState,
        market: ContractAddress,
        collateral_token: ContractAddress,
        is_long: bool,
        delta: i128,
        next_value: u128
    );

    /// Emits the `CumulativeBorrowingFactorUpdatd` event.
    fn emit_cumulative_borrowing_factor_updated(
        ref self: TContractState,
        market: ContractAddress,
        is_long: bool,
        delta: u128,
        next_value: u128
    );

    /// Emits the `FundingFeeAmountPerSizeUpdated` event.
    fn emit_funding_fee_amount_per_size_updated(
        ref self: TContractState,
        market: ContractAddress,
        collateral_token: ContractAddress,
        is_long: bool,
        delta: u128,
        next_value: u128
    );

    /// Emits the `ClaimableFundingPerSizeUpdatd` event.
    fn emit_claimable_funding_amount_per_size_updated(
        ref self: TContractState,
        market: ContractAddress,
        collateral_token: ContractAddress,
        is_long: bool,
        delta: u128,
        next_value: u128
    );

    /// Emits the `FundingFeesClaimed` event.
    fn emit_funding_fees_claimed(
        ref self: TContractState,
        market: ContractAddress,
        token: ContractAddress,
        account: ContractAddress,
        receiver: ContractAddress,
        amount: u128,
        next_pool_value: u128
    );

    /// Emits the `CollateralClaimed` event.
    fn emit_collateral_claimed(
        ref self: TContractState,
        market: ContractAddress,
        token: ContractAddress,
        account: ContractAddress,
        receiver: ContractAddress,
        time_key: u128,
        amount: u128,
        next_pool_value: u128
    );

    /// Emits the `UiFeeFactorUpdated` event.
    fn emit_ui_fee_factor_updated(
        ref self: TContractState, account: ContractAddress, ui_fee_factor: u128
    );

    /// Emits the `OraclePriceUpdate` event.
    fn emit_oracle_price_update(
        ref self: TContractState,
        token: ContractAddress,
        min_price: u128,
        max_price: u128,
        is_price_feed: bool
    );

    /// Emits the `SignerAdded` event.
    fn emit_signer_added(ref self: TContractState, account: ContractAddress);

    /// Emits the `SignerRemoved` event.
    fn emit_signer_removed(ref self: TContractState, account: ContractAddress);

    /// Emits the `SwapReverted` event.
    fn emit_swap_reverted(ref self: TContractState, reason: felt252, reason_bytes: Span<felt252>);

    /// Emits the `SwapInfo` event.
    fn emit_swap_info(
        ref self: TContractState,
        order_key: felt252,
        market: ContractAddress,
        receiver: ContractAddress,
        token_in: ContractAddress,
        token_out: ContractAddress,
        token_in_price: u128,
        token_out_price: u128,
        amount_in: u128,
        amount_in_after_fees: u128,
        amount_out: u128,
        price_impact_usd: i128,
        price_impact_amount: i128
    );

    /// Emits the `SwapFeesCollected` event.
    #[inline(always)]
    fn emit_swap_fees_collected(
        ref self: TContractState,
        market: ContractAddress,
        token: ContractAddress,
        token_price: u128,
        action: felt252,
        fees: SwapFees
    );

    fn emit_oracle_price_updated(
        ref self: TContractState,
        token: ContractAddress,
        min_price: u128,
        max_price: u128,
        is_price_feed: bool
    );

    fn emit_set_handler(ref self: TContractState, handler: ContractAddress, is_active: bool);

    fn emit_set_trader_referral_code(
        ref self: TContractState, account: ContractAddress, code: felt252
    );

    fn emit_set_tier(
        ref self: TContractState, tier_id: u128, total_rebate: u128, discount_share: u128
    );

    fn emit_set_referrer_tier(ref self: TContractState, referrer: ContractAddress, tier_id: u128);

    fn emit_set_referrer_discount_share(
        ref self: TContractState, referrer: ContractAddress, discount_share: u128
    );

    fn emit_register_code(ref self: TContractState, account: ContractAddress, code: felt252);

    fn emit_set_code_owner(
        ref self: TContractState,
        account: ContractAddress,
        new_account: ContractAddress,
        code: felt252
    );

    fn emit_gov_set_code_owner(
        ref self: TContractState, code: felt252, new_account: ContractAddress
    );

    fn emit_set_gov(ref self: TContractState, prev_gov: ContractAddress, next_gov: ContractAddress);
}

#[starknet::contract]
mod EventEmitter {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::{ContractAddress, ClassHash, get_caller_address};

    // Local imports.
    use satoru::deposit::deposit::Deposit;
    use satoru::withdrawal::withdrawal::Withdrawal;
    use satoru::position::position::Position;
    use satoru::market::market_pool_value_info::MarketPoolValueInfo;
    use satoru::pricing::swap_pricing_utils::SwapFees;
    use satoru::position::position_event_utils::PositionIncreaseParams;
    use satoru::position::position_utils::DecreasePositionCollateralValues;
    use satoru::order::order::OrderType;
    use satoru::price::price::Price;
    use satoru::pricing::position_pricing_utils::PositionFees;
    use satoru::order::order::{Order, SecondaryOrderType};
    use satoru::utils::span32::{Span32, DefaultSpan32};
    use satoru::utils::i128::{I128Div, I128Mul, I128Store, I128Serde};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {}

    // *************************************************************************
    // EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ClaimableCollateralUpdated: ClaimableCollateralUpdated,
        ClaimableFundingUpdated: ClaimableFundingUpdated,
        PositionImpactPoolAmountUpdated: PositionImpactPoolAmountUpdated,
        SwapImpactPoolAmountUpdated: SwapImpactPoolAmountUpdated,
        MarketCreated: MarketCreated,
        MarketTokenClassHashUpdated: MarketTokenClassHashUpdated,
        ClaimableFeeAmountUpdated: ClaimableFeeAmountUpdated,
        ClaimableUiFeeAmountUpdated: ClaimableUiFeeAmountUpdated,
        FeesClaimed: FeesClaimed,
        UiFeesClaimed: UiFeesClaimed,
        DepositCreated: DepositCreated,
        DepositExecuted: DepositExecuted,
        DepositCancelled: DepositCancelled,
        WithdrawalCreated: WithdrawalCreated,
        WithdrawalExecuted: WithdrawalExecuted,
        WithdrawalCancelled: WithdrawalCancelled,
        OrderCreated: OrderCreated,
        OrderExecuted: OrderExecuted,
        OrderUpdated: OrderUpdated,
        OrderSizeDeltaAutoUpdated: OrderSizeDeltaAutoUpdated,
        OrderCollatDeltaAmountAutoUpdtd: OrderCollatDeltaAmountAutoUpdtd,
        OrderCancelled: OrderCancelled,
        OrderFrozen: OrderFrozen,
        PositionIncrease: PositionIncrease,
        PositionDecrease: PositionDecrease,
        InsolventClose: InsolventClose,
        InsufficientFundingFeePayment: InsufficientFundingFeePayment,
        PositionFeesCollected: PositionFeesCollected,
        PositionFeesInfo: PositionFeesInfo,
        AffiliateRewardUpdated: AffiliateRewardUpdated,
        AffiliateRewardClaimed: AffiliateRewardClaimed,
        AfterDepositExecutionError: AfterDepositExecutionError,
        AfterDepositCancellationError: AfterDepositCancellationError,
        AfterWithdrawalExecutionError: AfterWithdrawalExecutionError,
        AfterWithdrawalCancelError: AfterWithdrawalCancelError,
        AfterOrderExecutionError: AfterOrderExecutionError,
        AfterOrderCancellationError: AfterOrderCancellationError,
        AfterOrderFrozenError: AfterOrderFrozenError,
        AdlStateUpdated: AdlStateUpdated,
        SetBool: SetBool,
        SetAddress: SetAddress,
        SetFelt252: SetFelt252,
        SetUint: SetUint,
        SetInt: SetInt,
        SignalAddOracleSigner: SignalAddOracleSigner,
        AddOracleSigner: AddOracleSigner,
        SignalRemoveOracleSigner: SignalRemoveOracleSigner,
        RemoveOracleSigner: RemoveOracleSigner,
        SignalSetFeeReceiver: SignalSetFeeReceiver,
        SetFeeReceiver: SetFeeReceiver,
        SignalGrantRole: SignalGrantRole,
        GrantRole: GrantRole,
        SignalRevokeRole: SignalRevokeRole,
        RevokeRole: RevokeRole,
        SignalSetPriceFeed: SignalSetPriceFeed,
        SetPriceFeed: SetPriceFeed,
        SignalPendingAction: SignalPendingAction,
        ClearPendingAction: ClearPendingAction,
        KeeperExecutionFee: KeeperExecutionFee,
        ExecutionFeeRefund: ExecutionFeeRefund,
        MarketPoolValueInfoEvent: MarketPoolValueInfoEvent,
        PoolAmountUpdated: PoolAmountUpdated,
        OpenInterestInTokensUpdated: OpenInterestInTokensUpdated,
        OpenInterestUpdated: OpenInterestUpdated,
        VirtualSwapInventoryUpdated: VirtualSwapInventoryUpdated,
        VirtualPositionInventoryUpdated: VirtualPositionInventoryUpdated,
        CollateralSumUpdated: CollateralSumUpdated,
        CumulativeBorrowingFactorUpdatd: CumulativeBorrowingFactorUpdatd,
        FundingFeeAmountPerSizeUpdated: FundingFeeAmountPerSizeUpdated,
        ClaimableFundingPerSizeUpdatd: ClaimableFundingPerSizeUpdatd,
        FundingFeesClaimed: FundingFeesClaimed,
        CollateralClaimed: CollateralClaimed,
        UiFeeFactorUpdated: UiFeeFactorUpdated,
        OraclePriceUpdate: OraclePriceUpdate,
        SignerAdded: SignerAdded,
        SignerRemoved: SignerRemoved,
        SwapReverted: SwapReverted,
        SwapInfo: SwapInfo,
        SwapFeesCollected: SwapFeesCollected,
        SetHandler: SetHandler,
        SetTraderReferralCode: SetTraderReferralCode,
        SetTier: SetTier,
        SetReferrerTier: SetReferrerTier,
        SetReferrerDiscountShare: SetReferrerDiscountShare,
        SetRegisterCode: SetRegisterCode,
        SetCodeOwner: SetCodeOwner,
        GovSetCodeOwner: GovSetCodeOwner,
        SetGov: SetGov,
    }

    #[derive(Drop, starknet::Event)]
    struct ClaimableCollateralUpdated {
        market: ContractAddress,
        token: ContractAddress,
        account: ContractAddress,
        time_key: u128,
        delta: u128,
        next_value: u128,
        next_pool_value: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct ClaimableFundingUpdated {
        market: ContractAddress,
        token: ContractAddress,
        account: ContractAddress,
        delta: u128,
        next_value: u128,
        next_pool_value: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct PositionImpactPoolAmountUpdated {
        market: ContractAddress,
        delta: u128,
        next_value: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct SwapImpactPoolAmountUpdated {
        market: ContractAddress,
        token: ContractAddress,
        delta: u128,
        next_value: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct MarketCreated {
        creator: ContractAddress,
        market_token: ContractAddress,
        index_token: ContractAddress,
        long_token: ContractAddress,
        short_token: ContractAddress,
        market_type: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct MarketTokenClassHashUpdated {
        updated_by: ContractAddress,
        previous_value: ClassHash,
        new_value: ClassHash,
    }

    #[derive(Drop, starknet::Event)]
    struct ClaimableFeeAmountUpdated {
        market: ContractAddress,
        token: ContractAddress,
        delta: u128,
        next_value: u128,
        fee_type: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct ClaimableUiFeeAmountUpdated {
        ui_fee_receiver: ContractAddress,
        market: ContractAddress,
        token: ContractAddress,
        delta: u128,
        next_value: u128,
        next_pool_value: u128,
        fee_type: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct FeesClaimed {
        market: ContractAddress,
        receiver: ContractAddress,
        fee_amount: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct UiFeesClaimed {
        ui_fee_receiver: ContractAddress,
        market: ContractAddress,
        receiver: ContractAddress,
        fee_amount: u128,
        next_pool_value: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct DepositCreated {
        key: felt252,
        account: ContractAddress,
        receiver: ContractAddress,
        callback_contract: ContractAddress,
        market: ContractAddress,
        initial_long_token: ContractAddress,
        initial_short_token: ContractAddress,
        long_token_swap_path: Span32<ContractAddress>,
        short_token_swap_path: Span32<ContractAddress>,
        initial_long_token_amount: u128,
        initial_short_token_amount: u128,
        min_market_tokens: u128,
        updated_at_block: u64,
        execution_fee: u128,
        callback_gas_limit: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct DepositExecuted {
        key: felt252,
        long_token_amount: u128,
        short_token_amount: u128,
        received_market_tokens: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct DepositCancelled {
        key: felt252,
        reason: felt252,
        reason_bytes: Span<felt252>,
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalCreated {
        key: felt252,
        account: ContractAddress,
        receiver: ContractAddress,
        callback_contract: ContractAddress,
        market: ContractAddress,
        market_token_amount: u128,
        min_long_token_amount: u128,
        min_short_token_amount: u128,
        updated_at_block: u64,
        execution_fee: u128,
        callback_gas_limit: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalExecuted {
        key: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalCancelled {
        key: felt252,
        reason: felt252,
        reason_bytes: Span<felt252>
    }

    #[derive(Drop, starknet::Event)]
    struct PositionIncrease {
        account: ContractAddress,
        market: ContractAddress,
        collateral_token: ContractAddress,
        size_in_usd: u128,
        size_in_tokens: u128,
        collateral_amount: u128,
        borrowing_factor: u128,
        funding_fee_amount_per_pize: u128,
        long_token_claimable_funding_amount_per_size: u128,
        short_token_claimable_funding_amount_per_size: u128,
        execution_price: u128,
        index_token_price_max: u128,
        index_token_price_min: u128,
        collateral_token_price_max: u128,
        collateral_token_price_min: u128,
        size_delta_usd: u128,
        size_delta_in_tokens: u128,
        order_type: OrderType,
        collateral_delta_amount: u128,
        price_impact_usd: u128,
        price_impact_amount: u128,
        is_long: bool,
        order_key: felt252,
        position_key: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct PositionDecrease {
        account: ContractAddress,
        market: ContractAddress,
        collateral_token: ContractAddress,
        size_in_usd: u128,
        size_in_tokens: u128,
        collateral_amount: u128,
        borrowing_factor: u128,
        funding_fee_amount_per_pize: u128,
        long_token_claimable_funding_amount_per_size: u128,
        short_token_claimable_funding_amount_per_size: u128,
        execution_price: u128,
        index_token_price_max: u128,
        index_token_price_min: u128,
        collateral_token_price_max: u128,
        collateral_token_price_min: u128,
        size_delta_usd: u128,
        size_delta_in_tokens: u128,
        collateral_delta_amount: u128,
        price_impact_diff_usd: u128,
        order_type: OrderType,
        price_impact_usd: i128,
        base_pnl_usd: i128,
        uncapped_base_pnl_usd: i128,
        is_long: bool,
        order_key: felt252,
        position_key: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct InsolventClose {
        order_key: felt252,
        position_collateral_amount: u128,
        base_pnl_usd: u128,
        remaining_cost_usd: u128
    }

    #[derive(Drop, starknet::Event)]
    struct InsufficientFundingFeePayment {
        market: ContractAddress,
        token: ContractAddress,
        expected_amount: u128,
        amount_paid_in_collateral_token: u128,
        amount_paid_in_secondary_output_token: u128
    }

    #[derive(Drop, starknet::Event)]
    struct PositionFeesCollected {
        order_key: felt252,
        position_key: felt252,
        referral_code: felt252,
        market: ContractAddress,
        collateral_token: ContractAddress,
        affiliate: ContractAddress,
        trader: ContractAddress,
        ui_fee_receiver: ContractAddress,
        collateral_token_price_min: u128,
        collateral_token_price_max: u128,
        trade_size_usd: u128,
        total_rebate_factor: u128,
        trader_discount_factor: u128,
        total_rebate_amount: u128,
        trader_discount_amount: u128,
        affiliate_reward_amount: u128,
        funding_fee_amount: u128,
        claimable_long_token_amount: u128,
        claimable_short_token_amount: u128,
        latest_funding_fee_amount_per_size: u128,
        latest_long_token_claimable_funding_amount_per_size: u128,
        latest_short_token_claimable_funding_amount_per_size: u128,
        borrowing_fee_usd: u128,
        borrowing_fee_amount: u128,
        borrowing_fee_receiver_factor: u128,
        borrowing_fee_amount_for_fee_receiver: u128,
        position_fee_factor: u128,
        protocol_fee_amount: u128,
        position_fee_receiver_factor: u128,
        fee_receiver_amount: u128,
        fee_amount_for_pool: u128,
        position_fee_amount_for_pool: u128,
        position_fee_amount: u128,
        total_cost_amount: u128,
        ui_fee_receiver_factor: u128,
        ui_fee_amount: u128,
        is_increase: bool
    }

    #[derive(Drop, starknet::Event)]
    struct PositionFeesInfo {
        order_key: felt252,
        position_key: felt252,
        referral_code: felt252,
        market: ContractAddress,
        collateral_token: ContractAddress,
        affiliate: ContractAddress,
        trader: ContractAddress,
        ui_fee_receiver: ContractAddress,
        collateral_token_price_min: u128,
        collateral_token_price_max: u128,
        trade_size_usd: u128,
        total_rebate_factor: u128,
        trader_discount_factor: u128,
        total_rebate_amount: u128,
        trader_discount_amount: u128,
        affiliate_reward_amount: u128,
        funding_fee_amount: u128,
        claimable_long_token_amount: u128,
        claimable_short_token_amount: u128,
        latest_funding_fee_amount_per_size: u128,
        latest_long_token_claimable_funding_amount_per_size: u128,
        latest_short_token_claimable_funding_amount_per_size: u128,
        borrowing_fee_usd: u128,
        borrowing_fee_amount: u128,
        borrowing_fee_receiver_factor: u128,
        borrowing_fee_amount_for_fee_receiver: u128,
        position_fee_factor: u128,
        protocol_fee_amount: u128,
        position_fee_receiver_factor: u128,
        fee_receiver_amount: u128,
        fee_amount_for_pool: u128,
        position_fee_amount_for_pool: u128,
        position_fee_amount: u128,
        total_cost_amount: u128,
        ui_fee_receiver_factor: u128,
        ui_fee_amount: u128,
        is_increase: bool
    }

    #[derive(Drop, starknet::Event)]
    struct OrderCreated {
        key: felt252,
        order: Order
    }

    #[derive(Drop, starknet::Event)]
    struct OrderExecuted {
        key: felt252,
        secondary_order_type: SecondaryOrderType
    }

    #[derive(Drop, starknet::Event)]
    struct OrderUpdated {
        key: felt252,
        size_delta_usd: u128,
        acceptable_price: u128,
        trigger_price: u128,
        min_output_amount: u128
    }

    #[derive(Drop, starknet::Event)]
    struct OrderSizeDeltaAutoUpdated {
        key: felt252,
        size_delta_usd: u128,
        next_size_delta_usd: u128
    }

    #[derive(Drop, starknet::Event)]
    struct OrderCollatDeltaAmountAutoUpdtd {
        key: felt252,
        collateral_delta_amount: u128,
        next_collateral_delta_amount: u128
    }

    #[derive(Drop, starknet::Event)]
    struct OrderCancelled {
        key: felt252,
        reason: felt252,
        reason_bytes: Span<felt252>
    }

    #[derive(Drop, starknet::Event)]
    struct OrderFrozen {
        key: felt252,
        reason: felt252,
        reason_bytes: Span<felt252>
    }

    #[derive(Drop, starknet::Event)]
    struct AffiliateRewardUpdated {
        market: ContractAddress,
        token: ContractAddress,
        affiliate: ContractAddress,
        delta: u128,
        next_value: u128,
        next_pool_value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct AffiliateRewardClaimed {
        market: ContractAddress,
        token: ContractAddress,
        affiliate: ContractAddress,
        receiver: ContractAddress,
        amount: u128,
        next_pool_value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct AfterDepositExecutionError {
        key: felt252,
        deposit: Deposit,
    }

    #[derive(Drop, starknet::Event)]
    struct AfterDepositCancellationError {
        key: felt252,
        deposit: Deposit,
    }

    #[derive(Drop, starknet::Event)]
    struct AfterWithdrawalExecutionError {
        key: felt252,
        withdrawal: Withdrawal,
    }

    #[derive(Drop, starknet::Event)]
    struct AfterWithdrawalCancelError {
        key: felt252,
        withdrawal: Withdrawal,
    }

    #[derive(Drop, starknet::Event)]
    struct AfterOrderExecutionError {
        key: felt252,
        order: Order,
    }

    #[derive(Drop, starknet::Event)]
    struct AfterOrderCancellationError {
        key: felt252,
        order: Order,
    }

    #[derive(Drop, starknet::Event)]
    struct AfterOrderFrozenError {
        key: felt252,
        order: Order,
    }

    #[derive(Drop, starknet::Event)]
    struct AdlStateUpdated {
        market: ContractAddress,
        is_long: bool,
        pnl_to_pool_factor: felt252,
        max_pnl_factor: u128,
        should_enable_adl: bool,
    }

    #[derive(Drop, starknet::Event)]
    struct SetBool {
        key: felt252,
        data_bytes: Span<felt252>,
        value: bool,
    }

    #[derive(Drop, starknet::Event)]
    struct SetAddress {
        key: felt252,
        data_bytes: Span<felt252>,
        value: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct SetFelt252 {
        key: felt252,
        data_bytes: Span<felt252>,
        value: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct SetUint {
        key: felt252,
        data_bytes: Span<felt252>,
        value: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct SetInt {
        key: felt252,
        data_bytes: Span<felt252>,
        value: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct SignalAddOracleSigner {
        action_key: felt252,
        account: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct AddOracleSigner {
        action_key: felt252,
        account: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct SignalRemoveOracleSigner {
        action_key: felt252,
        account: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct RemoveOracleSigner {
        action_key: felt252,
        account: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct SignalSetFeeReceiver {
        action_key: felt252,
        account: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct SetFeeReceiver {
        action_key: felt252,
        account: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct SignalGrantRole {
        action_key: felt252,
        account: ContractAddress,
        role_key: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct GrantRole {
        action_key: felt252,
        account: ContractAddress,
        role_key: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct SignalRevokeRole {
        action_key: felt252,
        account: ContractAddress,
        role_key: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct RevokeRole {
        action_key: felt252,
        account: ContractAddress,
        role_key: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct SignalSetPriceFeed {
        action_key: felt252,
        token: ContractAddress,
        price_feed: ContractAddress,
        price_feed_multiplier: u128,
        price_feed_heartbeat_duration: u128,
        stable_price: u128
    }

    #[derive(Drop, starknet::Event)]
    struct SetPriceFeed {
        action_key: felt252,
        token: ContractAddress,
        price_feed: ContractAddress,
        price_feed_multiplier: u128,
        price_feed_heartbeat_duration: u128,
        stable_price: u128
    }

    #[derive(Drop, starknet::Event)]
    struct SignalPendingAction {
        action_key: felt252,
        action_label: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct ClearPendingAction {
        action_key: felt252,
        action_label: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct KeeperExecutionFee {
        keeper: ContractAddress,
        execution_fee_amount: u128
    }

    #[derive(Drop, starknet::Event)]
    struct ExecutionFeeRefund {
        receiver: ContractAddress,
        refund_fee_amount: u128
    }

    #[derive(Drop, starknet::Event)]
    struct MarketPoolValueInfoEvent {
        market: ContractAddress,
        market_pool_value_info: MarketPoolValueInfo,
        market_tokens_supply: u128
    }

    #[derive(Drop, starknet::Event)]
    struct PoolAmountUpdated {
        market: ContractAddress,
        token: ContractAddress,
        delta: i128,
        next_value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct OpenInterestInTokensUpdated {
        market: ContractAddress,
        collateral_token: ContractAddress,
        is_long: bool,
        delta: i128,
        next_value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct OpenInterestUpdated {
        market: ContractAddress,
        collateral_token: ContractAddress,
        is_long: bool,
        delta: u128,
        next_value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct VirtualSwapInventoryUpdated {
        market: ContractAddress,
        is_long_token: bool,
        virtual_market_id: felt252,
        delta: u128,
        next_value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct VirtualPositionInventoryUpdated {
        token: ContractAddress,
        virtual_token_id: felt252,
        delta: u128,
        next_value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct CollateralSumUpdated {
        market: ContractAddress,
        collateral_token: ContractAddress,
        is_long: bool,
        delta: i128,
        next_value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct CumulativeBorrowingFactorUpdatd {
        market: ContractAddress,
        is_long: bool,
        delta: u128,
        next_value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct FundingFeeAmountPerSizeUpdated {
        market: ContractAddress,
        collateral_token: ContractAddress,
        is_long: bool,
        delta: u128,
        next_value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct ClaimableFundingPerSizeUpdatd {
        market: ContractAddress,
        collateral_token: ContractAddress,
        is_long: bool,
        delta: u128,
        next_value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct FundingFeesClaimed {
        market: ContractAddress,
        token: ContractAddress,
        account: ContractAddress,
        receiver: ContractAddress,
        amount: u128,
        next_pool_value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct CollateralClaimed {
        market: ContractAddress,
        token: ContractAddress,
        account: ContractAddress,
        receiver: ContractAddress,
        time_key: u128,
        amount: u128,
        next_pool_value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct UiFeeFactorUpdated {
        account: ContractAddress,
        ui_fee_factor: u128
    }

    #[derive(Drop, starknet::Event)]
    struct OraclePriceUpdate {
        token: ContractAddress,
        min_price: u128,
        max_price: u128,
        is_price_feed: bool
    }

    #[derive(Drop, starknet::Event)]
    struct SignerAdded {
        account: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct SignerRemoved {
        account: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct SwapReverted {
        reason: felt252,
        reason_bytes: Span<felt252>
    }

    #[derive(Drop, starknet::Event)]
    struct SwapInfo {
        order_key: felt252,
        market: ContractAddress,
        receiver: ContractAddress,
        token_in: ContractAddress,
        token_out: ContractAddress,
        token_in_price: u128,
        token_out_price: u128,
        amount_in: u128,
        amount_in_after_fees: u128,
        amount_out: u128,
        price_impact_usd: i128,
        price_impact_amount: i128
    }

    #[derive(Drop, starknet::Event)]
    struct SwapFeesCollected {
        market: ContractAddress,
        token: ContractAddress,
        token_price: u128,
        action: felt252,
        fees: SwapFees
    }

    #[derive(Drop, starknet::Event)]
    struct SetHandler {
        handler: ContractAddress,
        is_active: bool
    }

    #[derive(Drop, starknet::Event)]
    struct SetTraderReferralCode {
        account: ContractAddress,
        code: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct SetTier {
        tier_id: u128,
        total_rebate: u128,
        discount_share: u128
    }

    #[derive(Drop, starknet::Event)]
    struct SetReferrerTier {
        referrer: ContractAddress,
        tier_id: u128
    }

    #[derive(Drop, starknet::Event)]
    struct SetReferrerDiscountShare {
        referrer: ContractAddress,
        discount_share: u128
    }

    #[derive(Drop, starknet::Event)]
    struct SetRegisterCode {
        account: ContractAddress,
        code: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct SetCodeOwner {
        account: ContractAddress,
        new_account: ContractAddress,
        code: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct GovSetCodeOwner {
        code: felt252,
        new_account: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct SetGov {
        prev_gov: ContractAddress,
        next_gov: ContractAddress
    }

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl EventEmitterImpl of super::IEventEmitter<ContractState> {
        /// Emits the `ClaimableCollateralUpdated` event.
        fn emit_claimable_collateral_updated(
            ref self: ContractState,
            market: ContractAddress,
            token: ContractAddress,
            account: ContractAddress,
            time_key: u128,
            delta: u128,
            next_value: u128,
            next_pool_value: u128,
        ) {
            self
                .emit(
                    ClaimableCollateralUpdated {
                        market, token, account, time_key, delta, next_value, next_pool_value,
                    }
                );
        }

        /// Emits the `ClaimableFundingUpdated` event.
        fn emit_claimable_funding_updated(
            ref self: ContractState,
            market: ContractAddress,
            token: ContractAddress,
            account: ContractAddress,
            delta: u128,
            next_value: u128,
            next_pool_value: u128,
        ) {
            self
                .emit(
                    ClaimableFundingUpdated {
                        market, token, account, delta, next_value, next_pool_value,
                    }
                );
        }

        /// Emits the `PositionImpactPoolAmountUpdated` event.
        fn emit_position_impact_pool_amount_updated(
            ref self: ContractState, market: ContractAddress, delta: u128, next_value: u128,
        ) {
            self.emit(PositionImpactPoolAmountUpdated { market, delta, next_value, });
        }

        /// Emits the `SwapImpactPoolAmountUpdated` event.
        fn emit_swap_impact_pool_amount_updated(
            ref self: ContractState,
            market: ContractAddress,
            token: ContractAddress,
            delta: u128,
            next_value: u128,
        ) {
            self.emit(SwapImpactPoolAmountUpdated { market, token, delta, next_value, });
        }

        /// Emits the `MarketCreated` event.
        fn emit_market_created(
            ref self: ContractState,
            creator: ContractAddress,
            market_token: ContractAddress,
            index_token: ContractAddress,
            long_token: ContractAddress,
            short_token: ContractAddress,
            market_type: felt252,
        ) {
            self
                .emit(
                    MarketCreated {
                        creator, market_token, index_token, long_token, short_token, market_type,
                    }
                );
        }

        /// Emits the `MarketTokenClassHashUpdated` event.
        fn emit_market_token_class_hash_updated(
            ref self: ContractState,
            updated_by: ContractAddress,
            previous_value: ClassHash,
            new_value: ClassHash,
        ) {
            self.emit(MarketTokenClassHashUpdated { updated_by, previous_value, new_value, });
        }

        /// Emits the `ClaimableFeeAmountUpdated` event.
        fn emit_claimable_fee_amount_updated(
            ref self: ContractState,
            market: ContractAddress,
            token: ContractAddress,
            delta: u128,
            next_value: u128,
            fee_type: felt252
        ) {
            self.emit(ClaimableFeeAmountUpdated { market, token, delta, next_value, fee_type });
        }

        /// Emits the `ClaimableUiFeeAmountUpdated` event.
        fn emit_claimable_ui_fee_amount_updated(
            ref self: ContractState,
            ui_fee_receiver: ContractAddress,
            market: ContractAddress,
            token: ContractAddress,
            delta: u128,
            next_value: u128,
            next_pool_value: u128,
            fee_type: felt252
        ) {
            self
                .emit(
                    ClaimableUiFeeAmountUpdated {
                        ui_fee_receiver, market, token, delta, next_value, next_pool_value, fee_type
                    }
                );
        }

        /// Emits the `FeesClaimed` event.
        fn emit_fees_claimed(
            ref self: ContractState,
            market: ContractAddress,
            receiver: ContractAddress,
            fee_amount: u128
        ) {
            self.emit(FeesClaimed { market, receiver, fee_amount });
        }

        /// Emits the `UiFeesClaimed` event.
        fn emit_ui_fees_claimed(
            ref self: ContractState,
            ui_fee_receiver: ContractAddress,
            market: ContractAddress,
            receiver: ContractAddress,
            fee_amount: u128,
            next_pool_value: u128
        ) {
            self
                .emit(
                    UiFeesClaimed { ui_fee_receiver, market, receiver, fee_amount, next_pool_value }
                );
        }

        /// Emits the `DepositCreated` event.
        #[inline(always)]
        fn emit_deposit_created(ref self: ContractState, key: felt252, deposit: Deposit) {
            self
                .emit(
                    DepositCreated {
                        key,
                        account: deposit.account,
                        receiver: deposit.receiver,
                        callback_contract: deposit.callback_contract,
                        market: deposit.market,
                        initial_long_token: deposit.initial_long_token,
                        initial_short_token: deposit.initial_short_token,
                        long_token_swap_path: deposit.long_token_swap_path,
                        short_token_swap_path: deposit.short_token_swap_path,
                        initial_long_token_amount: deposit.initial_long_token_amount,
                        initial_short_token_amount: deposit.initial_short_token_amount,
                        min_market_tokens: deposit.min_market_tokens,
                        updated_at_block: deposit.updated_at_block,
                        execution_fee: deposit.execution_fee,
                        callback_gas_limit: deposit.callback_gas_limit
                    }
                );
        }

        /// Emits the `DepositExecuted` event.
        fn emit_deposit_executed(
            ref self: ContractState,
            key: felt252,
            long_token_amount: u128,
            short_token_amount: u128,
            received_market_tokens: u128
        ) {
            self
                .emit(
                    DepositExecuted {
                        key, long_token_amount, short_token_amount, received_market_tokens
                    }
                );
        }

        /// Emits the `DepositCancelled` event.
        fn emit_deposit_cancelled(
            ref self: ContractState, key: felt252, reason: felt252, reason_bytes: Span<felt252>
        ) {
            self.emit(DepositCancelled { key, reason, reason_bytes });
        }

        /// Emits the `WithdrawalCreated` event.
        fn emit_withdrawal_created(ref self: ContractState, key: felt252, withdrawal: Withdrawal) {
            self
                .emit(
                    WithdrawalCreated {
                        key,
                        account: withdrawal.account,
                        receiver: withdrawal.receiver,
                        callback_contract: withdrawal.callback_contract,
                        market: withdrawal.market,
                        market_token_amount: withdrawal.market_token_amount,
                        min_long_token_amount: withdrawal.min_long_token_amount,
                        min_short_token_amount: withdrawal.min_short_token_amount,
                        updated_at_block: withdrawal.updated_at_block,
                        execution_fee: withdrawal.execution_fee,
                        callback_gas_limit: withdrawal.callback_gas_limit,
                    }
                );
        }

        /// Emits the `WithdrawalExecuted` event.
        fn emit_withdrawal_executed(ref self: ContractState, key: felt252) {
            self.emit(WithdrawalExecuted { key });
        }

        /// Emits the `WithdrawalCancelled` event.
        fn emit_withdrawal_cancelled(
            ref self: ContractState, key: felt252, reason: felt252, reason_bytes: Span<felt252>
        ) {
            self.emit(WithdrawalCancelled { key, reason, reason_bytes });
        }

        /// Emits the `PositionIncrease` event.
        /// # Arguments
        /// * `params` - The position increase parameters.
        #[inline(always)]
        fn emit_position_increase(ref self: ContractState, params: PositionIncreaseParams) {
            self
                .emit(
                    PositionIncrease {
                        account: params.position.account,
                        market: params.position.market,
                        collateral_token: params.position.collateral_token,
                        size_in_usd: params.position.size_in_usd,
                        size_in_tokens: params.position.size_in_tokens,
                        collateral_amount: params.position.collateral_amount,
                        borrowing_factor: params.position.borrowing_factor,
                        funding_fee_amount_per_pize: params.position.funding_fee_amount_per_size,
                        long_token_claimable_funding_amount_per_size: params
                            .position
                            .long_token_claimable_funding_amount_per_size,
                        short_token_claimable_funding_amount_per_size: params
                            .position
                            .short_token_claimable_funding_amount_per_size,
                        execution_price: params.execution_price,
                        index_token_price_max: params.index_token_price.max,
                        index_token_price_min: params.index_token_price.min,
                        collateral_token_price_max: params.collateral_token_price.max,
                        collateral_token_price_min: params.collateral_token_price.min,
                        size_delta_usd: params.size_delta_usd,
                        size_delta_in_tokens: params.size_delta_in_tokens,
                        order_type: params.order_type,
                        collateral_delta_amount: params.collateral_delta_amount,
                        price_impact_usd: params.price_impact_usd,
                        price_impact_amount: params.price_impact_amount,
                        is_long: params.position.is_long,
                        order_key: params.order_key,
                        position_key: params.position_key
                    }
                );
        }

        /// Emits the `PositionDecrease` event.
        /// # Arguments
        /// * `order_key` - The key linked to the position decrease order.
        /// * `position_key` - The key linked to the position.
        /// * `position` - The position struct.
        /// * `size_delta_usd` - The position decrease amount in usd.
        /// * `collateral_delta_amount` - The collateral variation amount in usd.
        /// * `order_type` - The type of the order.
        /// * `values` - The parameters linked to the decrease of collateral.
        /// * `index_token_price` - The price of the index token.
        /// * `collateral_token_price` - The price of the collateral token.
        #[inline(always)]
        fn emit_position_decrease(
            ref self: ContractState,
            order_key: felt252,
            position_key: felt252,
            position: Position,
            size_delta_usd: u128,
            collateral_delta_amount: u128,
            order_type: OrderType,
            values: DecreasePositionCollateralValues,
            index_token_price: Price,
            collateral_token_price: Price
        ) {
            self
                .emit(
                    PositionDecrease {
                        account: position.account,
                        market: position.market,
                        collateral_token: position.collateral_token,
                        size_in_usd: position.size_in_usd,
                        size_in_tokens: position.size_in_tokens,
                        collateral_amount: position.collateral_amount,
                        borrowing_factor: position.borrowing_factor,
                        funding_fee_amount_per_pize: position.funding_fee_amount_per_size,
                        long_token_claimable_funding_amount_per_size: position
                            .long_token_claimable_funding_amount_per_size,
                        short_token_claimable_funding_amount_per_size: position
                            .short_token_claimable_funding_amount_per_size,
                        execution_price: values.execution_price,
                        index_token_price_max: index_token_price.max,
                        index_token_price_min: index_token_price.min,
                        collateral_token_price_max: collateral_token_price.max,
                        collateral_token_price_min: collateral_token_price.min,
                        size_delta_usd: size_delta_usd,
                        size_delta_in_tokens: values.size_delta_in_tokens,
                        collateral_delta_amount: collateral_delta_amount,
                        price_impact_diff_usd: values.price_impact_diff_usd,
                        order_type: order_type,
                        price_impact_usd: values.price_impact_usd,
                        base_pnl_usd: values.base_pnl_usd,
                        uncapped_base_pnl_usd: values.uncapped_base_pnl_usd,
                        is_long: position.is_long,
                        order_key: order_key,
                        position_key: position_key
                    }
                );
        }

        /// Emits the `OrderCreated` event.
        fn emit_order_created(ref self: ContractState, key: felt252, order: Order) {
            self.emit(OrderCreated { key, order });
        }

        /// Emits the `OrderExecuted` event.
        fn emit_order_executed(
            ref self: ContractState, key: felt252, secondary_order_type: SecondaryOrderType
        ) {
            self.emit(OrderExecuted { key, secondary_order_type });
        }

        /// Emits the `OrderUpdated` event.
        fn emit_order_updated(
            ref self: ContractState,
            key: felt252,
            size_delta_usd: u128,
            acceptable_price: u128,
            trigger_price: u128,
            min_output_amount: u128
        ) {
            self
                .emit(
                    OrderUpdated {
                        key, size_delta_usd, acceptable_price, trigger_price, min_output_amount
                    }
                );
        }

        /// Emits the `OrderSizeDeltaAutoUpdated` event.
        fn emit_order_size_delta_auto_updated(
            ref self: ContractState, key: felt252, size_delta_usd: u128, next_size_delta_usd: u128
        ) {
            self.emit(OrderSizeDeltaAutoUpdated { key, size_delta_usd, next_size_delta_usd });
        }

        /// Emits the `OrderCollatDeltaAmountAutoUpdtd` event.
        fn emit_order_collateral_delta_amount_auto_updated(
            ref self: ContractState,
            key: felt252,
            collateral_delta_amount: u128,
            next_collateral_delta_amount: u128
        ) {
            self
                .emit(
                    OrderCollatDeltaAmountAutoUpdtd {
                        key, collateral_delta_amount, next_collateral_delta_amount
                    }
                );
        }

        /// Emits the `InsolventClose` event.
        /// # Arguments
        /// * `order_key` - The key linked to the position decrease order.
        /// * `position_collateral_amount` - The amount of collateral tokens of the position.
        /// * `base_pnl_usd` - The base pnl amount in usd.
        /// * `remaining_cost_usd` - The remaining costs.
        fn emit_insolvent_close_info(
            ref self: ContractState,
            order_key: felt252,
            position_collateral_amount: u128,
            base_pnl_usd: u128,
            remaining_cost_usd: u128
        ) {
            self
                .emit(
                    InsolventClose {
                        order_key, position_collateral_amount, base_pnl_usd, remaining_cost_usd
                    }
                );
        }

        /// Emits the `InsufficientFundingFeePayment` event.
        /// # Arguments
        /// * `market` - The market concerned.
        /// * `token` - The token used for payment.
        /// * `expected_amount` - The expected paid amount.
        /// * `amount_paid_in_collateral_token` - The amount paid in collateral token.
        /// * `amount_paid_in_secondary_output_token` - The amount paid in secondary output token.
        fn emit_insufficient_funding_fee_payment(
            ref self: ContractState,
            market: ContractAddress,
            token: ContractAddress,
            expected_amount: u128,
            amount_paid_in_collateral_token: u128,
            amount_paid_in_secondary_output_token: u128
        ) {
            self
                .emit(
                    InsufficientFundingFeePayment {
                        market,
                        token,
                        expected_amount,
                        amount_paid_in_collateral_token,
                        amount_paid_in_secondary_output_token
                    }
                );
        }

        /// Emits the `PositionFeesCollected` event.
        /// # Arguments
        /// * `order_key` - The key linked to the position decrease order.
        /// * `position_key` - The key linked to the position.
        /// * `market` - The market where fees were collected.
        /// * `collateral_token` - The collateral token.
        /// * `trade_size_usd` - The trade size in usd.
        /// * `is_increase` - Wether it is an increase.
        /// * `fees` - The struct storing position fees.
        fn emit_position_fees_collected(
            ref self: ContractState,
            order_key: felt252,
            position_key: felt252,
            market: ContractAddress,
            collateral_token: ContractAddress,
            trade_size_usd: u128,
            is_increase: bool,
            fees: PositionFees
        ) {
            self
                .emit(
                    PositionFeesCollected {
                        order_key: order_key,
                        position_key: position_key,
                        referral_code: fees.referral.referral_code,
                        market: market,
                        collateral_token: collateral_token,
                        affiliate: fees.referral.affiliate,
                        trader: fees.referral.trader,
                        ui_fee_receiver: fees.ui.ui_fee_receiver,
                        collateral_token_price_min: fees.collateral_token_price.min,
                        collateral_token_price_max: fees.collateral_token_price.max,
                        trade_size_usd: trade_size_usd,
                        total_rebate_factor: fees.referral.total_rebate_factor,
                        trader_discount_factor: fees.referral.trader_discount_factor,
                        total_rebate_amount: fees.referral.total_rebate_amount,
                        trader_discount_amount: fees.referral.trader_discount_amount,
                        affiliate_reward_amount: fees.referral.affiliate_reward_amount,
                        funding_fee_amount: fees.funding.funding_fee_amount,
                        claimable_long_token_amount: fees.funding.claimable_long_token_amount,
                        claimable_short_token_amount: fees.funding.claimable_short_token_amount,
                        latest_funding_fee_amount_per_size: fees
                            .funding
                            .latest_funding_fee_amount_per_size,
                        latest_long_token_claimable_funding_amount_per_size: fees
                            .funding
                            .latest_long_token_claimable_funding_amount_per_size,
                        latest_short_token_claimable_funding_amount_per_size: fees
                            .funding
                            .latest_short_token_claimable_funding_amount_per_size,
                        borrowing_fee_usd: fees.borrowing.borrowing_fee_usd,
                        borrowing_fee_amount: fees.borrowing.borrowing_fee_amount,
                        borrowing_fee_receiver_factor: fees.borrowing.borrowing_fee_receiver_factor,
                        borrowing_fee_amount_for_fee_receiver: fees
                            .borrowing
                            .borrowing_fee_amount_for_fee_receiver,
                        position_fee_factor: fees.position_fee_factor,
                        protocol_fee_amount: fees.protocol_fee_amount,
                        position_fee_receiver_factor: fees.position_fee_receiver_factor,
                        fee_receiver_amount: fees.fee_receiver_amount,
                        fee_amount_for_pool: fees.fee_amount_for_pool,
                        position_fee_amount_for_pool: fees.position_fee_amount_for_pool,
                        position_fee_amount: fees.position_fee_amount,
                        total_cost_amount: fees.total_cost_amount,
                        ui_fee_receiver_factor: fees.ui.ui_fee_receiver_factor,
                        ui_fee_amount: fees.ui.ui_fee_amount,
                        is_increase: is_increase
                    }
                );
        }

        /// Emits the `PositionFeesInfo` event.
        /// # Arguments
        /// * `order_key` - The key linked to the position decrease order.
        /// * `position_key` - The key linked to the position.
        /// * `market` - The market where fees were collected.
        /// * `collateral_token` - The collateral token.
        /// * `trade_size_usd` - The trade size in usd.
        /// * `is_increase` - Wether it is an increase.
        /// * `fees` - The struct storing position fees.
        fn emit_position_fees_info(
            ref self: ContractState,
            order_key: felt252,
            position_key: felt252,
            market: ContractAddress,
            collateral_token: ContractAddress,
            trade_size_usd: u128,
            is_increase: bool,
            fees: PositionFees
        ) {
            self
                .emit(
                    PositionFeesInfo {
                        order_key: order_key,
                        position_key: position_key,
                        referral_code: fees.referral.referral_code,
                        market: market,
                        collateral_token: collateral_token,
                        affiliate: fees.referral.affiliate,
                        trader: fees.referral.trader,
                        ui_fee_receiver: fees.ui.ui_fee_receiver,
                        collateral_token_price_min: fees.collateral_token_price.min,
                        collateral_token_price_max: fees.collateral_token_price.max,
                        trade_size_usd: trade_size_usd,
                        total_rebate_factor: fees.referral.total_rebate_factor,
                        trader_discount_factor: fees.referral.trader_discount_factor,
                        total_rebate_amount: fees.referral.total_rebate_amount,
                        trader_discount_amount: fees.referral.trader_discount_amount,
                        affiliate_reward_amount: fees.referral.affiliate_reward_amount,
                        funding_fee_amount: fees.funding.funding_fee_amount,
                        claimable_long_token_amount: fees.funding.claimable_long_token_amount,
                        claimable_short_token_amount: fees.funding.claimable_short_token_amount,
                        latest_funding_fee_amount_per_size: fees
                            .funding
                            .latest_funding_fee_amount_per_size,
                        latest_long_token_claimable_funding_amount_per_size: fees
                            .funding
                            .latest_long_token_claimable_funding_amount_per_size,
                        latest_short_token_claimable_funding_amount_per_size: fees
                            .funding
                            .latest_short_token_claimable_funding_amount_per_size,
                        borrowing_fee_usd: fees.borrowing.borrowing_fee_usd,
                        borrowing_fee_amount: fees.borrowing.borrowing_fee_amount,
                        borrowing_fee_receiver_factor: fees.borrowing.borrowing_fee_receiver_factor,
                        borrowing_fee_amount_for_fee_receiver: fees
                            .borrowing
                            .borrowing_fee_amount_for_fee_receiver,
                        position_fee_factor: fees.position_fee_factor,
                        protocol_fee_amount: fees.protocol_fee_amount,
                        position_fee_receiver_factor: fees.position_fee_receiver_factor,
                        fee_receiver_amount: fees.fee_receiver_amount,
                        fee_amount_for_pool: fees.fee_amount_for_pool,
                        position_fee_amount_for_pool: fees.position_fee_amount_for_pool,
                        position_fee_amount: fees.position_fee_amount,
                        total_cost_amount: fees.total_cost_amount,
                        ui_fee_receiver_factor: fees.ui.ui_fee_receiver_factor,
                        ui_fee_amount: fees.ui.ui_fee_amount,
                        is_increase: is_increase
                    }
                );
        }

        /// Emits the `OrderCancelled` event.
        fn emit_order_cancelled(
            ref self: ContractState, key: felt252, reason: felt252, reason_bytes: Span<felt252>
        ) {
            self.emit(OrderCancelled { key, reason, reason_bytes });
        }

        /// Emits the `OrderFrozen` event.
        fn emit_order_frozen(
            ref self: ContractState, key: felt252, reason: felt252, reason_bytes: Span<felt252>
        ) {
            self.emit(OrderFrozen { key, reason, reason_bytes });
        }

        /// Emits the `AffiliateRewardUpdated` event.
        fn emit_affiliate_reward_updated(
            ref self: ContractState,
            market: ContractAddress,
            token: ContractAddress,
            affiliate: ContractAddress,
            delta: u128,
            next_value: u128,
            next_pool_value: u128
        ) {
            self
                .emit(
                    AffiliateRewardUpdated {
                        market, token, affiliate, delta, next_value, next_pool_value
                    }
                );
        }

        /// Emits the `AffiliateRewardClaimed` event.
        fn emit_affiliate_reward_claimed(
            ref self: ContractState,
            market: ContractAddress,
            token: ContractAddress,
            affiliate: ContractAddress,
            receiver: ContractAddress,
            amount: u128,
            next_pool_value: u128
        ) {
            self
                .emit(
                    AffiliateRewardClaimed {
                        market, token, affiliate, receiver, amount, next_pool_value
                    }
                );
        }

        /// Emits the `AfterDepositExecutionError` event.
        fn emit_after_deposit_execution_error(
            ref self: ContractState, key: felt252, deposit: Deposit
        ) {
            self.emit(AfterDepositExecutionError { key, deposit });
        }

        /// Emits the `AfterDepositCancellationError` event.
        fn emit_after_deposit_cancellation_error(
            ref self: ContractState, key: felt252, deposit: Deposit
        ) {
            self.emit(AfterDepositCancellationError { key, deposit });
        }

        /// Emits the `AfterWithdrawalExecutionError` event.
        fn emit_after_withdrawal_execution_error(
            ref self: ContractState, key: felt252, withdrawal: Withdrawal
        ) {
            self.emit(AfterWithdrawalExecutionError { key, withdrawal });
        }

        /// Emits the `AfterWithdrawalCancellationError` event.
        fn emit_after_withdrawal_cancellation_error(
            ref self: ContractState, key: felt252, withdrawal: Withdrawal
        ) {
            self.emit(AfterWithdrawalCancelError { key, withdrawal });
        }

        /// Emits the `AfterOrderExecutionError` event.
        fn emit_after_order_execution_error(ref self: ContractState, key: felt252, order: Order) {
            self.emit(AfterOrderExecutionError { key, order });
        }

        /// Emits the `AfterOrderCancellationError` event.
        fn emit_after_order_cancellation_error(
            ref self: ContractState, key: felt252, order: Order
        ) {
            self.emit(AfterOrderCancellationError { key, order });
        }

        /// Emits the `AfterOrderFrozenError` event.
        fn emit_after_order_frozen_error(ref self: ContractState, key: felt252, order: Order) {
            self.emit(AfterOrderFrozenError { key, order });
        }
        /// Emits the `AdlStateUpdated` event.
        /// # Arguments
        // * `market`- Address of the market for the ADL state update
        // * `is_long`- Indicates the ADL state update is for the long or short side of the market
        // * `pnl_to_pool_factor`- The the ratio of PnL to pool value
        // * `max_pnl_factor`- The max PnL factor
        // * `should_enable_adl`- Whether ADL was enabled or disabled
        fn emit_adl_state_updated(
            ref self: ContractState,
            market: ContractAddress,
            is_long: bool,
            pnl_to_pool_factor: felt252,
            max_pnl_factor: u128,
            should_enable_adl: bool,
        ) {
            self
                .emit(
                    AdlStateUpdated {
                        market, is_long, pnl_to_pool_factor, max_pnl_factor, should_enable_adl
                    }
                );
        }

        /// Emits the `SetBool` event.
        fn emit_set_bool(
            ref self: ContractState, key: felt252, data_bytes: Span<felt252>, value: bool
        ) {
            self.emit(SetBool { key, data_bytes, value });
        }

        /// Emits the `SetAddress` event.
        fn emit_set_address(
            ref self: ContractState, key: felt252, data_bytes: Span<felt252>, value: ContractAddress
        ) {
            self.emit(SetAddress { key, data_bytes, value });
        }

        fn emit_set_felt252(
            ref self: ContractState, key: felt252, data_bytes: Span<felt252>, value: felt252
        ) {
            self.emit(SetFelt252 { key, data_bytes, value });
        }

        /// Emits the `SetFelt252` event.
        fn emit_set_uint(
            ref self: ContractState, key: felt252, data_bytes: Span<felt252>, value: u128
        ) {
            self.emit(SetUint { key, data_bytes, value });
        }

        /// Emits the `SetInt` event.
        fn emit_set_int(
            ref self: ContractState, key: felt252, data_bytes: Span<felt252>, value: felt252
        ) {
            self.emit(SetInt { key, data_bytes, value });
        }

        /// Emits the `SignalAddOracleSigner` event.
        fn emit_signal_add_oracle_signer(
            ref self: ContractState, action_key: felt252, account: ContractAddress
        ) {
            self.emit(SignalAddOracleSigner { action_key, account });
        }

        /// Emits the `AddOracleSigner` event.
        fn emit_add_oracle_signer(
            ref self: ContractState, action_key: felt252, account: ContractAddress
        ) {
            self.emit(AddOracleSigner { action_key, account });
        }

        /// Emits the `SignalRemoveOracleSigner` event.
        fn emit_signal_remove_oracle_signer(
            ref self: ContractState, action_key: felt252, account: ContractAddress
        ) {
            self.emit(SignalRemoveOracleSigner { action_key, account });
        }

        /// Emits the `RemoveOracleSigner` event.
        fn emit_remove_oracle_signer(
            ref self: ContractState, action_key: felt252, account: ContractAddress
        ) {
            self.emit(RemoveOracleSigner { action_key, account });
        }

        /// Emits the `SignalSetFeeReceiver` event.
        fn emit_signal_set_fee_receiver(
            ref self: ContractState, action_key: felt252, account: ContractAddress
        ) {
            self.emit(SignalSetFeeReceiver { action_key, account });
        }

        /// Emits the `SetFeeReceiver` event.
        fn emit_set_fee_receiver(
            ref self: ContractState, action_key: felt252, account: ContractAddress
        ) {
            self.emit(SetFeeReceiver { action_key, account });
        }

        /// Emits the `SignalGrantRole` event.
        fn emit_signal_grant_role(
            ref self: ContractState,
            action_key: felt252,
            account: ContractAddress,
            role_key: felt252
        ) {
            self.emit(SignalGrantRole { action_key, account, role_key });
        }

        /// Emits the `GrantRole` event.
        fn emit_grant_role(
            ref self: ContractState,
            action_key: felt252,
            account: ContractAddress,
            role_key: felt252
        ) {
            self.emit(GrantRole { action_key, account, role_key });
        }

        /// Emits the `SignalRevokeRole` event.
        fn emit_signal_revoke_role(
            ref self: ContractState,
            action_key: felt252,
            account: ContractAddress,
            role_key: felt252
        ) {
            self.emit(SignalRevokeRole { action_key, account, role_key });
        }

        /// Emits the `RevokeRole` event.
        fn emit_revoke_role(
            ref self: ContractState,
            action_key: felt252,
            account: ContractAddress,
            role_key: felt252
        ) {
            self.emit(RevokeRole { action_key, account, role_key });
        }

        /// Emits the `SignalSetPriceFeed` event.
        fn emit_signal_set_price_feed(
            ref self: ContractState,
            action_key: felt252,
            token: ContractAddress,
            price_feed: ContractAddress,
            price_feed_multiplier: u128,
            price_feed_heartbeat_duration: u128,
            stable_price: u128
        ) {
            self
                .emit(
                    SignalSetPriceFeed {
                        action_key,
                        token,
                        price_feed,
                        price_feed_multiplier,
                        price_feed_heartbeat_duration,
                        stable_price
                    }
                );
        }

        /// Emits the `SetPriceFeed` event.
        fn emit_set_price_feed(
            ref self: ContractState,
            action_key: felt252,
            token: ContractAddress,
            price_feed: ContractAddress,
            price_feed_multiplier: u128,
            price_feed_heartbeat_duration: u128,
            stable_price: u128
        ) {
            self
                .emit(
                    SetPriceFeed {
                        action_key,
                        token,
                        price_feed,
                        price_feed_multiplier,
                        price_feed_heartbeat_duration,
                        stable_price
                    }
                );
        }

        /// Emits the `SignalPendingAction` event.
        fn emit_signal_pending_action(
            ref self: ContractState, action_key: felt252, action_label: felt252,
        ) {
            self.emit(SignalPendingAction { action_key, action_label });
        }

        /// Emits the `ClearPendingAction` event.
        fn emit_clear_pending_action(
            ref self: ContractState, action_key: felt252, action_label: felt252,
        ) {
            self.emit(ClearPendingAction { action_key, action_label });
        }

        /// Emits the `KeeperExecutionFee` event.
        fn emit_keeper_execution_fee(
            ref self: ContractState, keeper: ContractAddress, execution_fee_amount: u128
        ) {
            self.emit(KeeperExecutionFee { keeper, execution_fee_amount });
        }

        /// Emits the `ExecutionFeeRefund` event.
        fn emit_execution_fee_refund(
            ref self: ContractState, receiver: ContractAddress, refund_fee_amount: u128
        ) {
            self.emit(ExecutionFeeRefund { receiver, refund_fee_amount });
        }

        /// Emits the `MarketPoolValueInfo` event.
        #[inline(always)]
        fn emit_market_pool_value_info(
            ref self: ContractState,
            market: ContractAddress,
            market_pool_value_info: MarketPoolValueInfo,
            market_tokens_supply: u128
        ) {
            self
                .emit(
                    MarketPoolValueInfoEvent {
                        market, market_pool_value_info, market_tokens_supply
                    }
                );
        }

        /// Emits the `PoolAmountUpdated` event.
        fn emit_pool_amount_updated(
            ref self: ContractState,
            market: ContractAddress,
            token: ContractAddress,
            delta: i128,
            next_value: u128
        ) {
            self.emit(PoolAmountUpdated { market, token, delta, next_value });
        }

        /// Emits the `OpenInterestInTokensUpdated` event.
        fn emit_open_interest_in_tokens_updated(
            ref self: ContractState,
            market: ContractAddress,
            collateral_token: ContractAddress,
            is_long: bool,
            delta: i128,
            next_value: u128
        ) {
            self
                .emit(
                    OpenInterestInTokensUpdated {
                        market, collateral_token, is_long, delta, next_value
                    }
                );
        }

        /// Emits the `OpenInterestUpdated` event.
        fn emit_open_interest_updated(
            ref self: ContractState,
            market: ContractAddress,
            collateral_token: ContractAddress,
            is_long: bool,
            delta: u128,
            next_value: u128
        ) {
            self.emit(OpenInterestUpdated { market, collateral_token, is_long, delta, next_value });
        }

        /// Emits the `VirtualSwapInventoryUpdated` event.
        fn emit_virtual_swap_inventory_updated(
            ref self: ContractState,
            market: ContractAddress,
            is_long_token: bool,
            virtual_market_id: felt252,
            delta: u128,
            next_value: u128
        ) {
            self
                .emit(
                    VirtualSwapInventoryUpdated {
                        market, is_long_token, virtual_market_id, delta, next_value
                    }
                );
        }

        /// Emits the `VirtualPositionInventoryUpdated` event.
        fn emit_virtual_position_inventory_updated(
            ref self: ContractState,
            token: ContractAddress,
            virtual_token_id: felt252,
            delta: u128,
            next_value: u128
        ) {
            self
                .emit(
                    VirtualPositionInventoryUpdated { token, virtual_token_id, delta, next_value }
                );
        }

        /// Emits the `CollateralSumUpdated` event.
        fn emit_collateral_sum_updated(
            ref self: ContractState,
            market: ContractAddress,
            collateral_token: ContractAddress,
            is_long: bool,
            delta: i128,
            next_value: u128
        ) {
            self
                .emit(
                    CollateralSumUpdated { market, collateral_token, is_long, delta, next_value }
                );
        }

        /// Emits the `CumulativeBorrowingFactorUpdatd` event.
        fn emit_cumulative_borrowing_factor_updated(
            ref self: ContractState,
            market: ContractAddress,
            is_long: bool,
            delta: u128,
            next_value: u128
        ) {
            self.emit(CumulativeBorrowingFactorUpdatd { market, is_long, delta, next_value });
        }

        /// Emits the `FundingFeeAmountPerSizeUpdated` event.
        fn emit_funding_fee_amount_per_size_updated(
            ref self: ContractState,
            market: ContractAddress,
            collateral_token: ContractAddress,
            is_long: bool,
            delta: u128,
            next_value: u128
        ) {
            self
                .emit(
                    FundingFeeAmountPerSizeUpdated {
                        market, collateral_token, is_long, delta, next_value
                    }
                );
        }

        /// Emits the `ClaimableFundingPerSizeUpdatd` event.
        fn emit_claimable_funding_amount_per_size_updated(
            ref self: ContractState,
            market: ContractAddress,
            collateral_token: ContractAddress,
            is_long: bool,
            delta: u128,
            next_value: u128
        ) {
            self
                .emit(
                    ClaimableFundingPerSizeUpdatd {
                        market, collateral_token, is_long, delta, next_value
                    }
                );
        }

        /// Emits the `FundingFeesClaimed` event.
        fn emit_funding_fees_claimed(
            ref self: ContractState,
            market: ContractAddress,
            token: ContractAddress,
            account: ContractAddress,
            receiver: ContractAddress,
            amount: u128,
            next_pool_value: u128
        ) {
            self
                .emit(
                    FundingFeesClaimed { market, token, account, receiver, amount, next_pool_value }
                );
        }

        /// Emits the `CollateralClaimed` event.
        fn emit_collateral_claimed(
            ref self: ContractState,
            market: ContractAddress,
            token: ContractAddress,
            account: ContractAddress,
            receiver: ContractAddress,
            time_key: u128,
            amount: u128,
            next_pool_value: u128
        ) {
            self
                .emit(
                    CollateralClaimed {
                        market, token, account, receiver, time_key, amount, next_pool_value
                    }
                );
        }

        /// Emits the `UiFeeFactorUpdated` event.
        fn emit_ui_fee_factor_updated(
            ref self: ContractState, account: ContractAddress, ui_fee_factor: u128
        ) {
            self.emit(UiFeeFactorUpdated { account, ui_fee_factor });
        }

        /// Emits the `OraclePriceUpdate` event.
        fn emit_oracle_price_update(
            ref self: ContractState,
            token: ContractAddress,
            min_price: u128,
            max_price: u128,
            is_price_feed: bool
        ) {
            self.emit(OraclePriceUpdate { token, min_price, max_price, is_price_feed });
        }

        /// Emits the `SignerAdded` event.
        fn emit_signer_added(ref self: ContractState, account: ContractAddress) {
            self.emit(SignerAdded { account });
        }

        /// Emits the `SignerRemoved` event.
        fn emit_signer_removed(ref self: ContractState, account: ContractAddress) {
            self.emit(SignerRemoved { account });
        }

        /// Emits the `SwapReverted` event.
        fn emit_swap_reverted(
            ref self: ContractState, reason: felt252, reason_bytes: Span<felt252>
        ) {
            self.emit(SwapReverted { reason, reason_bytes });
        }

        /// Emits the `SwapInfo` event.

        fn emit_swap_info(
            ref self: ContractState,
            order_key: felt252,
            market: ContractAddress,
            receiver: ContractAddress,
            token_in: ContractAddress,
            token_out: ContractAddress,
            token_in_price: u128,
            token_out_price: u128,
            amount_in: u128,
            amount_in_after_fees: u128,
            amount_out: u128,
            price_impact_usd: i128,
            price_impact_amount: i128
        ) {
            self
                .emit(
                    SwapInfo {
                        order_key,
                        market,
                        receiver,
                        token_in,
                        token_out,
                        token_in_price,
                        token_out_price,
                        amount_in,
                        amount_in_after_fees,
                        amount_out,
                        price_impact_usd,
                        price_impact_amount
                    }
                );
        }

        /// Emits the `SwapFeesCollected` event.
        #[inline(always)]
        fn emit_swap_fees_collected(
            ref self: ContractState,
            market: ContractAddress,
            token: ContractAddress,
            token_price: u128,
            action: felt252,
            fees: SwapFees
        ) {
            self.emit(SwapFeesCollected { market, token, token_price, action, fees });
        }

        fn emit_oracle_price_updated(
            ref self: ContractState,
            token: ContractAddress,
            min_price: u128,
            max_price: u128,
            is_price_feed: bool
        ) {
            self.emit(OraclePriceUpdate { token, min_price, max_price, is_price_feed });
        }

        fn emit_set_handler(ref self: ContractState, handler: ContractAddress, is_active: bool) {
            self.emit(SetHandler { handler, is_active });
        }

        fn emit_set_tier(
            ref self: ContractState, tier_id: u128, total_rebate: u128, discount_share: u128
        ) {
            self.emit(SetTier { tier_id, total_rebate, discount_share });
        }

        fn emit_set_referrer_tier(
            ref self: ContractState, referrer: ContractAddress, tier_id: u128
        ) {
            self.emit(SetReferrerTier { referrer, tier_id });
        }

        fn emit_set_referrer_discount_share(
            ref self: ContractState, referrer: ContractAddress, discount_share: u128
        ) {
            self.emit(SetReferrerDiscountShare { referrer, discount_share });
        }

        fn emit_set_trader_referral_code(
            ref self: ContractState, account: ContractAddress, code: felt252
        ) {
            self.emit(SetTraderReferralCode { account, code });
        }


        fn emit_register_code(ref self: ContractState, account: ContractAddress, code: felt252) {
            self.emit(SetRegisterCode { account, code });
        }

        fn emit_set_code_owner(
            ref self: ContractState,
            account: ContractAddress,
            new_account: ContractAddress,
            code: felt252
        ) {
            self.emit(SetCodeOwner { account, new_account, code });
        }

        fn emit_gov_set_code_owner(
            ref self: ContractState, code: felt252, new_account: ContractAddress
        ) {
            self.emit(GovSetCodeOwner { code, new_account });
        }

        fn emit_set_gov(
            ref self: ContractState, prev_gov: ContractAddress, next_gov: ContractAddress
        ) {
            self.emit(SetGov { prev_gov, next_gov });
        }
    }
}
