//! Contract to emit the events of the system.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, ClassHash};

// Local imports.
use satoru::withdrawal::withdrawal::Withdrawal;

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

    fn emit_withdrawal_created(ref self: TContractState, key: felt252, withdrawal: Withdrawal);

    fn emit_withdrawal_executed(ref self: TContractState, key: felt252);

    fn emit_withdrawal_cancelled(
        ref self: TContractState, key: felt252, reason: felt252, reason_bytes: Array<felt252>
    );
}

#[starknet::contract]
mod EventEmitter {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::{ContractAddress, ClassHash};

    // Local imports.
    use satoru::withdrawal::withdrawal::Withdrawal;

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
        WithdrawalCreated: WithdrawalCreated,
        WithdrawalExecuted: WithdrawalExecuted,
        WithdrawalCancelled: WithdrawalCancelled,
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
        execution_fee: u128,
        callback_gas_limit: u128,
        should_unwrap_native_token: bool,
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalExecuted {
        key: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalCancelled {
        key: felt252,
        reason: felt252,
        reason_bytes: Array<felt252>
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

        /// Emits the `WithdrawalCreated` event.
        fn emit_withdrawal_created(ref self: ContractState, key: felt252, withdrawal: Withdrawal) {
            let account = withdrawal.account;
            let receiver = withdrawal.account;
            let callback_contract = withdrawal.callback_contract;
            let market = withdrawal.market;
            let market_token_amount = withdrawal.market_token_amount;
            let min_long_token_amount = withdrawal.min_long_token_amount;
            let min_short_token_amount = withdrawal.min_short_token_amount;
            let updated_at_block = withdrawal.updated_at_block;
            let execution_fee = withdrawal.execution_fee;
            let callback_gas_limit = withdrawal.callback_gas_limit;
            let should_unwrap_native_token = withdrawal.should_unwrap_native_token;

            self
                .emit(
                    WithdrawalCreated {
                        key,
                        account,
                        receiver,
                        callback_contract,
                        market,
                        market_token_amount,
                        min_long_token_amount,
                        min_short_token_amount,
                        updated_at_block,
                        execution_fee,
                        callback_gas_limit,
                        should_unwrap_native_token
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
    }
}
