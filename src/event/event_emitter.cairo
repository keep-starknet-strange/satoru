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
use satoru::position::position_event_utils::PositionIncreaseParams;
use satoru::position::position_utils::DecreasePositionCollateralValues;
use satoru::order::order::OrderType;
use satoru::price::price::Price;
use satoru::pricing::position_pricing_utils::PositionFees;
use satoru::order::order::{Order, SecondaryOrderType};

//TODO: OrderCollatDeltaAmountAutoUpdtd must be renamed back to OrderCollateralDeltaAmountAutoUpdated when string will be allowed as event argument

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
        ref self: TContractState, key: felt252, reason: felt252, reasonBytes: Array<felt252>
    );

    /// Emits the `WithdrawalCreated` event.
    #[inline(always)]
    fn emit_withdrawal_created(ref self: TContractState, key: felt252, withdrawal: Withdrawal);

    /// Emits the `WithdrawalExecuted` event.
    fn emit_withdrawal_executed(ref self: TContractState, key: felt252);

    /// Emits the `WithdrawalCancelled` event.
    fn emit_withdrawal_cancelled(
        ref self: TContractState, key: felt252, reason: felt252, reason_bytes: Array<felt252>
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
        ref self: TContractState, key: felt252, reason: felt252, reason_bytes: Array<felt252>
    );

    /// Emits the `OrderFrozen` event.
    fn emit_order_frozen(
        ref self: TContractState, key: felt252, reason: felt252, reason_bytes: Array<felt252>
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

    /// Emits the `AfterWithdrawalCancellationError` event.
    fn emit_after_withdrawal_cancellation_error(
        ref self: TContractState, key: felt252, withdrawal: Withdrawal
    );

    /// Emits the `AfterOrderExecutionError` event.
    fn emit_after_order_execution_error(ref self: TContractState, key: felt252, order: Order);

    /// Emits the `AfterOrderCancellationError` event.
    fn emit_after_order_cancellation_error(ref self: TContractState, key: felt252, order: Order);

    /// Emits the `AfterOrderFrozenError` event.
    fn emit_after_order_frozen_error(ref self: TContractState, key: felt252, order: Order);
}

#[starknet::contract]
mod EventEmitter {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::{ContractAddress, ClassHash};

    // Local imports.
    use satoru::deposit::deposit::Deposit;
    use satoru::withdrawal::withdrawal::Withdrawal;
    use satoru::position::position::Position;
    use satoru::position::position_event_utils::PositionIncreaseParams;
    use satoru::position::position_utils::DecreasePositionCollateralValues;
    use satoru::order::order::OrderType;
    use satoru::price::price::Price;
    use satoru::pricing::position_pricing_utils::PositionFees;
    use satoru::order::order::{Order, SecondaryOrderType};

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
        AfterWithdrawalCancellationError: AfterWithdrawalCancellationError,
        AfterOrderExecutionError: AfterOrderExecutionError,
        AfterOrderCancellationError: AfterOrderCancellationError,
        AfterOrderFrozenError: AfterOrderFrozenError,
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
        long_token_swap_path: Array<ContractAddress>,
        short_token_swap_path: Array<ContractAddress>,
        initial_long_token_amount: u256,
        initial_short_token_amount: u256,
        min_market_tokens: u256,
        updated_at_block: u256,
        execution_fee: u256,
        callback_gas_limit: u256,
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
        reasonBytes: Array<felt252>,
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
        updated_at_block: u128,
        execution_fee: u256,
        callback_gas_limit: u128,
        should_unwrap_native_token: bool
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalExecuted {
        key: felt252
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalCancelled {
        key: felt252,
        reason: felt252,
        reason_bytes: Array<felt252>
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
        price_impact_usd: u128,
        base_pnl_usd: u128,
        uncapped_base_pnl_usd: u128,
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
        reason_bytes: Array<felt252>
    }

    #[derive(Drop, starknet::Event)]
    struct OrderFrozen {
        key: felt252,
        reason: felt252,
        reason_bytes: Array<felt252>
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
    struct AfterWithdrawalCancellationError {
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
            ref self: ContractState, key: felt252, reason: felt252, reasonBytes: Array<felt252>
        ) {
            self.emit(DepositCancelled { key, reason, reasonBytes });
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
                        should_unwrap_native_token: withdrawal.should_unwrap_native_token
                    }
                );
        }

        /// Emits the `WithdrawalExecuted` event.
        fn emit_withdrawal_executed(ref self: ContractState, key: felt252) {
            self.emit(WithdrawalExecuted { key });
        }

        /// Emits the `WithdrawalCancelled` event.
        fn emit_withdrawal_cancelled(
            ref self: ContractState, key: felt252, reason: felt252, reason_bytes: Array<felt252>
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
            ref self: ContractState, key: felt252, reason: felt252, reason_bytes: Array<felt252>
        ) {
            self.emit(OrderCancelled { key, reason, reason_bytes });
        }

        /// Emits the `OrderFrozen` event.
        fn emit_order_frozen(
            ref self: ContractState, key: felt252, reason: felt252, reason_bytes: Array<felt252>
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
            self.emit(AfterWithdrawalCancellationError { key, withdrawal });
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
    }
}
