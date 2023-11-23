//! Configuration of the system.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
use starknet::ContractAddress;


// *************************************************************************
//                  Interface of the `Config` contract.
// *************************************************************************
#[starknet::interface]
trait IConfig<TContractState> {
    /// Set a bool value.
    /// # Arguments
    /// * `base_key` - The base key of the value to set.
    /// * `data` - The additional data to be combined with the base key.
    /// * `value` - The value to set.
    fn set_bool(ref self: TContractState, base_key: felt252, data: Array<felt252>, value: bool);

    /// Set an address value.
    /// # Arguments
    /// * `base_key` - The base key of the value to set.
    /// * `data` - The additional data to be combined with the base key.
    /// * `value` - The value to set.
    fn set_address(
        ref self: TContractState, base_key: felt252, data: Array<felt252>, value: ContractAddress,
    );

    /// Set a felt252 value.
    /// # Arguments
    /// * `base_key` - The base key of the value to set.
    /// * `data` - The additional data to be combined with the base key.
    /// * `value` - The value to set.
    fn set_felt252(
        ref self: TContractState, base_key: felt252, data: Array<felt252>, value: felt252,
    );
}

#[starknet::contract]
mod Config {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::clone::Clone;
    use starknet::{get_caller_address, ContractAddress, contract_address_const,};
    use poseidon::poseidon_hash_span;


    // Local imports.
    use satoru::role::role;
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
    use satoru::data::keys;
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use satoru::config::error::ConfigError;

    // External imports.
    use alexandria_data_structures::array_ext::ArrayTraitExt;

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// An interface to interact with the `RoleStore` contract.
        role_store: IRoleStoreDispatcher,
        /// An interface to interact with the `DataStore` contract.
        data_store: IDataStoreDispatcher,
        /// An interface to interact with the `EventEmitter` contract.
        event_emitter: IEventEmitterDispatcher,
        /// The base keys that can be set.
        allowed_based_keys: LegacyMap<felt252, bool>,
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(
        ref self: ContractState,
        role_store_address: ContractAddress,
        data_store_address: ContractAddress,
        event_emitter_address: ContractAddress,
    ) {
        self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
        self.data_store.write(IDataStoreDispatcher { contract_address: data_store_address });
        self
            .event_emitter
            .write(IEventEmitterDispatcher { contract_address: event_emitter_address });
        // Initialize the allowed base keys.
        self.init_allowed_base_keys();
    }

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl ConfigImpl of super::IConfig<ContractState> {
        fn set_bool(
            ref self: ContractState, base_key: felt252, data: Array<felt252>, value: bool,
        ) {
            // Check that the caller has the `CONFIG_KEEPER` role.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONFIG_KEEPER);
            // Validate the base key.
            self.validate_key(base_key);
            // Get the full key.
            let full_key = self.get_full_key(base_key, data);
            // Set the value.
            self.data_store.read().set_bool(full_key, value);
        }

        fn set_address(
            ref self: ContractState,
            base_key: felt252,
            data: Array<felt252>,
            value: ContractAddress,
        ) {
            // Check that the caller has the `CONFIG_KEEPER` role.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONFIG_KEEPER);
            // Validate the base key.
            self.validate_key(base_key);
            // Get the full key.
            let full_key = self.get_full_key(base_key, data);
            // Set the value.
            self.data_store.read().set_address(full_key, value);
        }

        fn set_felt252(
            ref self: ContractState, base_key: felt252, data: Array<felt252>, value: felt252,
        ) {
            // Check that the caller has the `CONFIG_KEEPER` role.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONFIG_KEEPER);
            // Validate the base key.
            self.validate_key(base_key);
            // Get the full key.
            let full_key = self.get_full_key(base_key, data);
            // Set the value.
            self.data_store.read().set_felt252(full_key, value);
        }
    }

    // *************************************************************************
    //                          INTERNAL FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Initialize the allowed base keys.
        fn init_allowed_base_keys(ref self: ContractState) -> () {
            self.allowed_based_keys.write(keys::holding_address(), true);
            self.allowed_based_keys.write(keys::min_handle_execution_error_gas(), true);
            self.allowed_based_keys.write(keys::is_market_disabled(), true);
            self.allowed_based_keys.write(keys::max_swap_path_length(), true);
            self.allowed_based_keys.write(keys::max_callback_gas_limit(), true);

            self.allowed_based_keys.write(keys::min_position_size_usd(), true);
            self
                .allowed_based_keys
                .write(keys::max_position_impact_factor_for_liquidations(), true);

            self.allowed_based_keys.write(keys::max_pool_amount(), true);
            self.allowed_based_keys.write(keys::max_open_interest(), true);

            self.allowed_based_keys.write(keys::create_deposit_feature_disabled(), true);
            self.allowed_based_keys.write(keys::cancel_deposit_feature_disabled(), true);
            self.allowed_based_keys.write(keys::execute_deposit_feature_disabled(), true);

            self.allowed_based_keys.write(keys::create_withdrawal_feature_disabled(), true);
            self.allowed_based_keys.write(keys::cancel_withdrawal_feature_disabled(), true);
            self.allowed_based_keys.write(keys::execute_withdrawal_feature_disabled(), true);

            self.allowed_based_keys.write(keys::create_order_feature_disabled(), true);
            self.allowed_based_keys.write(keys::execute_order_feature_disabled(), true);
            self.allowed_based_keys.write(keys::execute_adl_feature_disabled(), true);
            self.allowed_based_keys.write(keys::update_order_feature_disabled(), true);
            self.allowed_based_keys.write(keys::cancel_order_feature_disabled(), true);

            self.allowed_based_keys.write(keys::claim_funding_fees_feature_disabled(), true);
            self.allowed_based_keys.write(keys::claim_collateral_feature_disabled(), true);
            self.allowed_based_keys.write(keys::claim_affiliate_rewards_feature_disabled(), true);
            self.allowed_based_keys.write(keys::claim_ui_fees_feature_disabled(), true);

            self.allowed_based_keys.write(keys::min_oracle_block_confirmations(), true);
            self.allowed_based_keys.write(keys::max_oracle_price_age(), true);
            self.allowed_based_keys.write(keys::max_oracle_ref_price_deviation_factor(), true);
            self.allowed_based_keys.write(keys::position_fee_receiver_factor(), true);
            self.allowed_based_keys.write(keys::swap_fee_receiver_factor(), true);
            self.allowed_based_keys.write(keys::borrowing_fee_receiver_factor(), true);

            self.allowed_based_keys.write(keys::estimated_gas_fee_base_amount(), true);
            self.allowed_based_keys.write(keys::estimated_gas_fee_multiplier_factor(), true);

            self.allowed_based_keys.write(keys::execution_gas_fee_base_amount(), true);
            self.allowed_based_keys.write(keys::execution_gas_fee_multiplier_factor(), true);

            self.allowed_based_keys.write(keys::deposit_gas_limit(), true);
            self.allowed_based_keys.write(keys::withdrawal_gas_limit_key(), true);
            self.allowed_based_keys.write(keys::single_swap_gas_limit(), true);
            self.allowed_based_keys.write(keys::increase_order_gas_limit(), true);
            self.allowed_based_keys.write(keys::decrease_order_gas_limit(), true);
            self.allowed_based_keys.write(keys::swap_order_gas_limit(), true);
            self.allowed_based_keys.write(keys::token_transfer_gas_limit(), true);
            self.allowed_based_keys.write(keys::native_token_transfer_gas_limit(), true);

            self.allowed_based_keys.write(keys::request_expiration_block_age(), true);
            self.allowed_based_keys.write(keys::min_collateral_factor(), true);
            self
                .allowed_based_keys
                .write(keys::min_collateral_factor_for_open_interest_multiplier(), true);
            self.allowed_based_keys.write(keys::min_collateral_usd(), true);

            self.allowed_based_keys.write(keys::virtual_token_id(), true);
            self.allowed_based_keys.write(keys::virtual_market_id(), true);
            self.allowed_based_keys.write(keys::virtual_inventory_for_swaps(), true);
            self.allowed_based_keys.write(keys::virtual_inventory_for_positions(), true);

            self.allowed_based_keys.write(keys::position_impact_factor(), true);
            self.allowed_based_keys.write(keys::position_impact_exponent_factor(), true);
            self.allowed_based_keys.write(keys::max_position_impact_factor(), true);
            self.allowed_based_keys.write(keys::position_fee_factor(), true);

            self.allowed_based_keys.write(keys::swap_impact_factor(), true);
            self.allowed_based_keys.write(keys::swap_impact_exponent_factor(), true);
            self.allowed_based_keys.write(keys::swap_fee_factor(), true);

            self.allowed_based_keys.write(keys::max_ui_fee_factor(), true);

            self.allowed_based_keys.write(keys::oracle_type(), true);

            self.allowed_based_keys.write(keys::reserve_factor(), true);
            self.allowed_based_keys.write(keys::open_interest_reserve_factor(), true);

            self.allowed_based_keys.write(keys::max_pnl_factor(), true);
            self.allowed_based_keys.write(keys::min_pnl_factor_after_adl(), true);

            self.allowed_based_keys.write(keys::funding_factor(), true);
            self.allowed_based_keys.write(keys::stable_funding_factor(), true);
            self.allowed_based_keys.write(keys::funding_exponent_factor(), true);

            self.allowed_based_keys.write(keys::borrowing_factor(), true);
            self.allowed_based_keys.write(keys::borrowing_exponent_factor(), true);
            self.allowed_based_keys.write(keys::skip_borrowing_fee_for_smaller_side(), true);

            self.allowed_based_keys.write(keys::claimable_collateral_factor(), true);

            self.allowed_based_keys.write(keys::price_feed_heartbeat_duration(), true);
        }

        /// Validate a base key.
        /// # Arguments
        /// * `base_key` - The base key to validate.
        fn validate_key(self: @ContractState, base_key: felt252) -> () {
            // Check that the base key is allowed.
            assert(self.allowed_based_keys.read(base_key), ConfigError::INVALID_BASE_KEY);
        }

        /// Get the full key.
        /// # Arguments
        /// * `base_key` - The base key.
        /// * `data` - The additional data to be combined with the base key.
        /// # Returns
        /// * `full_key` - The full key.
        fn get_full_key(self: @ContractState, base_key: felt252, data: Array<felt252>) -> felt252 {
            if data.len() == 0 {
                return base_key;
            }
            // TODO: Remove this clone and find a more efficient way to do this.
            let mut copied_data = data.clone();
            let mut full_key = array![];
            full_key.append(base_key);
            full_key.append_all(ref copied_data);
            poseidon_hash_span(full_key.span())
        }
    }
}
