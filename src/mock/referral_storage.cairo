//! Referral storage for testing and testnets.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::referral::referral_tier::ReferralTier;

// *************************************************************************
//                  Interface of the `ReferralStorage` contract.
// *************************************************************************
#[starknet::interface]
trait IReferralStorage<TContractState> {
    fn initialize(ref self: TContractState, event_emitter_address: ContractAddress);

    fn only_handler(ref self: TContractState);

    /// Set an address as a handler.
    /// # Arguments
    /// * `handler` - Address of the handler.
    /// * `is_active` - Whether to set the handler as active or inactive.
    fn set_handler(ref self: TContractState, handler: ContractAddress, is_active: bool);

    /// Set the trader discount share for an affiliate.
    /// # Arguments
    /// * `account` - The address of the affiliate.
    fn set_referrer_discount_share(ref self: TContractState, discount_share: u256);

    /// Set the referral code for a trader.
    /// # Arguments
    /// * `code` - The referral code to set to.
    fn set_trader_referral_code_by_user(ref self: TContractState, code: felt252);

    /// Register a referral code.
    /// # Arguments
    /// * `code` - the referral code to register.
    fn register_code(ref self: TContractState, code: felt252);

    /// Set the owner of a referral code.
    /// # Arguments
    /// * `code` - The referral code.
    fn set_code_owner(ref self: TContractState, code: felt252, new_account: ContractAddress);

    /// Get the owner of a referral code.
    /// # Arguments
    /// * `code` - The referral code.
    /// # Returns
    /// The owner of the referral code.
    fn code_owners(self: @TContractState, code: felt252) -> ContractAddress;

    /// Get the referral code of a trader.
    /// # Arguments
    /// * `account` - The address of the trader.
    /// # Returns
    /// The referral code.
    fn trader_referral_codes(self: @TContractState, account: ContractAddress) -> felt252;

    /// Get the trader discount share for an affiliate.
    /// # Arguments
    /// * `account` - The address of the affiliate.
    /// # Returns
    /// The trader discount share.
    fn referrer_discount_shares(self: @TContractState, account: ContractAddress) -> u256;

    /// Get the tier level of an affiliate.
    /// # Arguments
    /// * `account` - The address of the affiliate.
    /// # Returns
    /// The tier level of the affiliate.
    fn referrer_tiers(self: @TContractState, account: ContractAddress) -> u256;

    /// Get the referral info for a trader.
    /// # Arguments
    /// * `account` - The address of the trader.
    /// # Returns
    /// (referral code, affiliate).
    fn get_trader_referral_info(
        self: @TContractState, account: ContractAddress
    ) -> (felt252, ContractAddress);

    /// Set the referral code for a trader.
    /// # Arguments
    /// * `account` - The address of the trader.
    /// * `code` - The referral code of the trader.
    fn set_trader_referral_code(ref self: TContractState, account: ContractAddress, code: felt252);

    /// Set the values for a tier.
    /// # Arguments
    /// * `tier_id` - The tier level.
    /// * `total_rebate` - The total rebate for the tier (affiliate reward + trader discount).
    /// * `discount_share` - The share of the total_rebate for traders.
    fn set_tier(ref self: TContractState, tier_id: u256, total_rebate: u256, discount_share: u256);

    /// Set the tier for an affiliate.
    /// # Arguments
    /// * `referrer` - The referrer.
    /// * `tier_id` - The tier level.
    fn set_referrer_tier(ref self: TContractState, referrer: ContractAddress, tier_id: u256);

    /// Set the owner for a referral code.
    /// # Arguments
    /// * `code` - The referral code.
    /// * `new_account` - The new owner.
    fn gov_set_code_owner(ref self: TContractState, code: felt252, new_account: ContractAddress);

    /// Get the tier values for a tier level.
    /// # Arguments
    /// * `tier_level` - The tier level.
    /// # Returns
    /// (total_rebate, discount_share).
    fn tiers(self: @TContractState, tier_level: u256) -> ReferralTier;
}

#[starknet::contract]
mod ReferralStorage {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::{get_caller_address, ContractAddress, contract_address_const};
    use result::ResultTrait;

    // Local imports.
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use satoru::referral::referral_tier::ReferralTier;
    use satoru::mock::error::MockError;
    use satoru::mock::governable::{IGovernableDispatcher, IGovernableDispatcherTrait};
    use satoru::mock::governable::{Governable, IGovernable};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        referrer_discount_shares: LegacyMap<ContractAddress, u256>,
        referrer_tiers: LegacyMap<ContractAddress, u256>,
        tiers: LegacyMap<u256, ReferralTier>,
        is_handler: LegacyMap<ContractAddress, bool>,
        code_owners: LegacyMap<felt252, ContractAddress>,
        trader_referral_codes: LegacyMap<ContractAddress, felt252>,
        event_emitter: IEventEmitterDispatcher
    }

    #[constructor]
    fn constructor(ref self: ContractState, event_emitter_address: ContractAddress) {
        self.initialize(event_emitter_address);
    }

    const BASIS_POINTS: u256 = 10000;

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl ReferralStorageImpl of super::IReferralStorage<ContractState> {
        fn initialize(ref self: ContractState, event_emitter_address: ContractAddress) {
            let mut gov_state = Governable::unsafe_new_contract_state();
            gov_state.initialize(event_emitter_address);
        }

        fn code_owners(self: @ContractState, code: felt252) -> ContractAddress {
            self.code_owners.read(code)
        }

        fn trader_referral_codes(self: @ContractState, account: ContractAddress) -> felt252 {
            self.trader_referral_codes.read(account)
        }

        fn referrer_discount_shares(self: @ContractState, account: ContractAddress) -> u256 {
            self.referrer_discount_shares.read(account)
        }

        fn referrer_tiers(self: @ContractState, account: ContractAddress) -> u256 {
            self.referrer_tiers.read(account)
        }

        fn tiers(self: @ContractState, tier_level: u256) -> ReferralTier {
            self.tiers.read(tier_level)
        }

        fn only_handler(ref self: ContractState) {
            assert(self.is_handler.read(get_caller_address()), MockError::FORBIDDEN);
        }

        fn set_handler(ref self: ContractState, handler: ContractAddress, is_active: bool) {
            let gov_state = Governable::unsafe_new_contract_state();
            gov_state.only_gov();
            self.is_handler.write(handler, is_active);
            self.event_emitter.read().emit_set_handler(handler, is_active);
        }

        fn set_tier(
            ref self: ContractState, tier_id: u256, total_rebate: u256, discount_share: u256
        ) {
            let gov_state = Governable::unsafe_new_contract_state();
            gov_state.only_gov();
            assert(total_rebate <= BASIS_POINTS, MockError::INVALID_TOTAL_REBATE);
            assert(discount_share <= BASIS_POINTS, MockError::INVALID_DISCOUNT_SHARE);

            let mut tier: ReferralTier = self.tiers.read(tier_id);
            tier.total_rebate = total_rebate;
            tier.discount_share = discount_share;
            self.tiers.write(tier_id, tier);
            self.event_emitter.read().emit_set_tier(tier_id, total_rebate, discount_share);
        }

        fn set_referrer_tier(ref self: ContractState, referrer: ContractAddress, tier_id: u256) {
            let gov_state = Governable::unsafe_new_contract_state();
            gov_state.only_gov();
            self.referrer_tiers.write(referrer, tier_id);
            self.event_emitter.read().emit_set_referrer_tier(referrer, tier_id);
        }

        fn set_referrer_discount_share(ref self: ContractState, discount_share: u256) {
            assert(discount_share <= BASIS_POINTS, MockError::INVALID_DISCOUNT_SHARE);

            self.referrer_discount_shares.write(get_caller_address(), discount_share);
            self
                .event_emitter
                .read()
                .emit_set_referrer_discount_share(get_caller_address(), discount_share);
        }

        fn set_trader_referral_code(
            ref self: ContractState, account: ContractAddress, code: felt252
        ) {
            self.only_handler();
            self._set_trader_referral_code(account, code);
        }

        fn set_trader_referral_code_by_user(ref self: ContractState, code: felt252) {
            self._set_trader_referral_code(get_caller_address(), code);
        }

        fn register_code(ref self: ContractState, code: felt252) {
            assert(code != 0, MockError::INVALID_CODE);
            assert(
                self.code_owners.read(code) == contract_address_const::<0>(),
                MockError::CODE_ALREADY_EXISTS
            );

            self.code_owners.write(code, get_caller_address());
            self.event_emitter.read().emit_register_code(get_caller_address(), code);
        }

        fn set_code_owner(ref self: ContractState, code: felt252, new_account: ContractAddress) {
            assert(code != 0, MockError::INVALID_CODE);
            let account: ContractAddress = self.code_owners.read(code);
            assert(get_caller_address() == account, MockError::FORBIDDEN);

            self.code_owners.write(code, new_account);
            self.event_emitter.read().emit_set_code_owner(get_caller_address(), new_account, code)
        }

        fn gov_set_code_owner(
            ref self: ContractState, code: felt252, new_account: ContractAddress
        ) {
            let gov_state = Governable::unsafe_new_contract_state();
            gov_state.only_gov();
            assert(code != 0, MockError::INVALID_CODE);

            self.code_owners.write(code, new_account);
            self.event_emitter.read().emit_gov_set_code_owner(code, new_account);
        }

        fn get_trader_referral_info(
            self: @ContractState, account: ContractAddress
        ) -> (felt252, ContractAddress) {
            let mut code: felt252 = self.trader_referral_codes(account);
            let mut referrer = contract_address_const::<0>();

            if (code != 0) {
                referrer = self.code_owners.read(code);
            }
            (code, referrer)
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _set_trader_referral_code(
            ref self: ContractState, account: ContractAddress, code: felt252
        ) {
            self.trader_referral_codes.write(account, code);
            self.event_emitter.read().emit_set_trader_referral_code(account, code);
        }
    }
}
