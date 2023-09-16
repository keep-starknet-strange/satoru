//! Referral storage for testing and testnets.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;

// *************************************************************************
//                  Interface of the `OracleStore` contract.
// *************************************************************************
#[starknet::interface]
trait IReferralStorage<TContractState> {
    fn only_handler(ref self: TContractState);
    fn set_handler(ref self: TContractState, handler: ContractAddress, is_active: bool);
    fn set_referrer_discount_share(ref self: TContractState, discount_share: u128);
    fn set_trader_referral_code_by_user(ref self: TContractState, code: felt252);
    fn register_code(ref self: TContractState, code: felt252);
    fn set_code_owner(ref self: TContractState, code: felt252, new_account: ContractAddress);
    fn _set_trader_referral_code(ref self: TContractState, account: ContractAddress, code: felt252);
    //////////////////////////////////////////////////////
    /// Get the owner of a referral code.
    /// # Arguments
    /// * `code` - The referral code.
    /// # Returns
    /// The owner of the referral code.
    // fn code_owners(self: @TContractState, code: felt252) -> ContractAddress;

    /// Get the referral code of a trader.
    /// # Arguments
    /// * `account` - The address of the trader.
    /// # Returns
    /// The referral code.
    // fn trader_referral_codes(self: @TContractState, account: ContractAddress) -> felt252;

    /// Get the trader discount share for an affiliate.
    /// # Arguments
    /// * `account` - The address of the affiliate.
    /// # Returns
    /// The trader discount share.
    // fn referrer_discount_share(self: @TContractState, account: ContractAddress) -> u128;

    /// Get the tier level of an affiliate.
    /// # Arguments
    /// * `account` - The address of the affiliate.
    /// # Returns
    /// The tier level of the affiliate.
    // fn referrer_tiers(self: @TContractState, account: ContractAddress) -> u128;

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
    fn set_tier(ref self: TContractState, tier_id: u128, total_rebate: u128, discount_share: u128);

    /// Set the tier for an affiliate.
    /// # Arguments
    /// * `referrer` - The referrer.
    /// * `tier_id` - The tier level.
    fn set_referrer_tier(ref self: TContractState, referrer: ContractAddress, tier_id: u128);

    /// Set the owner for a referral code.
    /// # Arguments
    /// * `code` - The referral code.
    /// * `new_account` - The new owner.
    fn gov_set_code_owner(ref self: TContractState, code: felt252, new_account: ContractAddress);

    /// Get the tier values for a tier level.
    /// # Arguments
    /// * `tier_level` - The tier level.
    /// # Returns
    /// (totalRebate, discountShare).
    // fn tiers(self: @TContractState, tier_level: u128) -> (u128, u128);

}

#[starknet::contract]
mod ReferralStorage {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;
    use starknet::{get_caller_address, ContractAddress};
    use result::ResultTrait;

    // Local imports.
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::event::event_emitter::{IEventEmitterDispatcher};
    use satoru::oracle::error::OracleError;
    use satoru::referral::referral_tier::ReferralTier;
    use satoru::mock::error::MockError;
    use satoru::mock::governable::{IGovernableDispatcher, IGovernableDispatcherTrait};


    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        referrer_discount_share: LegacyMap<ContractAddress, u128>,
        referrer_tiers: LegacyMap<ContractAddress, u128>,
        tiers: LegacyMap<u128, ReferralTier>,
        is_handler: LegacyMap<ContractAddress, bool>,
        code_owners: LegacyMap<felt252, ContractAddress>,
        trader_referral_codes: LegacyMap<ContractAddress, felt252>,
        event_emitter: IEventEmitterDispatcher,
        governable: IGovernableDispatcher,
    }

    const BASIS_POINTS: u128 = 10000;

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl ReferralStorageImpl of super::IReferralStorage<ContractState> {
        fn only_handler(ref self: ContractState){
            assert(self.is_handler.read(get_caller_address()), MockError::FORBIDDEN);
        }

        fn set_handler(ref self: ContractState, handler: ContractAddress, is_active: bool){
            self.governable.only_gov();
            self.is_handler.write(handler, is_active);
            event_emitter.emit_set_handler(handler, is_active);
        }

        fn set_tier(ref self: ContractState, tier_id: u128, total_rebate: u128, discount_share: u128){
            self.governable::only_gov();
            assert(total_rebate <= BASIS_POINTS, MockError::INVALID_TOTAL_REBATE);
            assert(discount_share <= BASIS_POINTS, MockError::INVALID_DISCOUNT_SHARE);

            let mut tier: ReferralTier = self.tiers.read(tier_id);
            tier.total_rebate = total_rebate;
            tier.discount_share = discount_share;
            self.tiers.write(tier_id, tier);
            event_emitter.emit_set_tier(tier_id, total_rebate, discount_share);
        }

        fn set_referrer_tier(ref self: ContractState, referrer: ContractAddress, tier_id: u128) {
            self.governable::only_gov();
            self.referrer_tiers.write(referrer, tier_id);
            event_emitter.set_referrer_tier(referral, tier_id);
        }

        fn set_referrer_discount_share(ref self: ContractState, discount_share: u128){
            assert(discount_share <= BASIS_POINTS, MockError::INVALID_DISCOUNT_SHARE);

            self.referrer_discount_share.write(get_caller_address(), discount_share);
            event_emitter.emit_set_referrer_discount_share(get_caller_address(), discount_share);
        }

        fn set_trader_referral_code(ref self: ContractState, account: ContractAddress, code: felt252){
            only_handler();
            _set_trader_referral_code(account, code);
        }

        fn set_trader_referral_code_by_user(ref self: ContractState, code: felt252){
            _set_trader_referral_code(get_caller_address(), code);
        }

        fn register_code(ref self: ContractState, code: felt252){
            assert(code != 0, MockError::INVALID_CODE);
            assert(self.code_owners.read(code) == 0.try_into().unwrap(), MockError::CODE_ALREADY_EXISTS);

            self.code_owners.write(code, get_caller_address());
            event_emitter.emit_register_code(get_caller_address(), code);
        }

        fn set_code_owner(ref self: ContractState, code: felt252, new_account: ContractAddress){
            assert(code != 0, MockError::INVALID_CODE);

            let account: ContractAddress = self.code_owners.read(code);
            assert(get_caller_address() == account, MockError::FORBIDDEN);

            self.code_owners.write(code, new_account);
            event_emitter.emit_set_code_owner(get_caller_address(), new_account, code)
        }

        fn gov_set_code_owner(ref self: ContractState, code: felt252, new_account: ContractAddress){
            governable.only_gov();
            assert(code != 0, MockError::INVALID_CODE);

            self.code_owners.write(code, new_account);
            event_emitter.emit_gov_set_code_owner(code, new_account);
        }

        fn get_trader_referral_info(self: @ContractState, account: ContractAddress) -> (felt252, ContractAddress) {
            let mut code: felt252 = self.trader_referral_codes.read(account);
            let mut referrer: ContractAddress = 0.try_into().unwrap();

            if (code != 0){
                referrer = self.code_owners.read(code);
            }
            (code, referral)
        }

        //THIS IS PRIVATE FUNCTION
        fn _set_trader_referral_code(ref self: ContractState, account: ContractAddress, code: felt252){
            self.trader_referral_codes.write(account, code);
            event_emitter.emit_set_trader_referral_code(account, code);
        }
    }
}
