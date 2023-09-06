//! Contract to emit the events of the system.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, ClassHash};

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
}

#[starknet::contract]
mod EventEmitter {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::{ContractAddress, ClassHash};

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
        AffiliateRewardUpdated: AffiliateRewardUpdated,
        AffiliateRewardClaimed: AffiliateRewardClaimed,
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
    struct AffiliateRewardUpdated {
        market: ContractAddress,
        token: ContractAddress,
        affiliate: ContractAddress,
        delta: u128,
        next_value: u128,
        next_pool_value: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct AffiliateRewardClaimed {
        market: ContractAddress,
        token: ContractAddress,
        affiliate: ContractAddress,
        receiver: ContractAddress,
        amount: u128,
        next_pool_value: u128,
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
    }
}
