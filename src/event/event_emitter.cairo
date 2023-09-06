//! Contract to emit the events of the system.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, ClassHash};

// Local imports.
use satoru::deposit::deposit::Deposit;

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
    fn emit_deposit_created(
        ref self: TContractState,
        key: felt252,
        deposit: Deposit,
    );

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
        ref self: TContractState,
        key: felt252,
        reason: felt252,
        reasonBytes: Array<felt252>,
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
    use satoru::deposit::deposit::Deposit;   

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
        fn emit_deposit_created(
            ref self: ContractState,
            key: felt252,
            deposit: Deposit,
        ) {
            let account = deposit.account;
            let receiver = deposit.receiver;
            let callback_contract = deposit.callback_contract;
            let market = deposit.market;
            let initial_long_token = deposit.initial_long_token;
            let initial_short_token = deposit.initial_short_token;
            let long_token_swap_path = deposit.long_token_swap_path;
            let short_token_swap_path = deposit.short_token_swap_path;
            let initial_long_token_amount = deposit.initial_long_token_amount;
            let initial_short_token_amount = deposit.initial_short_token_amount;
            let min_market_tokens = deposit.min_market_tokens;
            let updated_at_block = deposit.updated_at_block;
            let execution_fee = deposit.execution_fee;
            let callback_gas_limit = deposit.callback_gas_limit;
            self
                .emit(
                    DepositCreated { 
                        key,
                        account,
                        receiver,
                        callback_contract,
                        market,
                        initial_long_token,
                        initial_short_token,
                        long_token_swap_path,
                        short_token_swap_path,
                        initial_long_token_amount,
                        initial_short_token_amount,
                        min_market_tokens,
                        updated_at_block,
                        execution_fee,
                        callback_gas_limit,
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
                    DepositExecuted { key, long_token_amount, short_token_amount, received_market_tokens }
                );
        }

        /// Emits the `DepositCancelled` event.
        fn emit_deposit_cancelled(
            ref self: ContractState,
            key: felt252,
            reason: felt252,
            reasonBytes: Array<felt252>
        ) {
            self
                .emit(
                    DepositCancelled { key, reason, reasonBytes }
                );
        }
    }
}
