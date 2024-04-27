mod adl {
    mod test_adl_utils;
}
mod bank {
    mod test_bank;
    mod test_strict_bank;
}
mod callback {
    mod test_callback_utils;
}
mod config {
    mod test_config;
}
mod data {
    mod test_data_store;
    mod test_deposit_store;
    mod test_keys;
    mod test_market;
    mod test_order;
    mod test_position;
    mod test_withdrawal;
}
mod deposit {
    mod test_deposit_utils;
    mod test_deposit_vault;
    mod test_execute_deposit_utils;
}
mod event {
    mod test_adl_events_emitted;
    mod test_callback_events_emitted;
    mod test_config_events_emitted;
    mod test_gas_events_emitted;
    mod test_market_events_emitted;
    mod test_oracle_events_emitted;
    mod test_order_events_emitted;
    mod test_position_events_emitted;
    mod test_pricing_events_emitted;
    mod test_referral_events_emitted;
    mod test_swap_events_emitted;
    mod test_timelock_events_emitted;
    mod test_withdrawal_events_emitted;
    mod test_event_utils;
}
mod exchange {
    // mod test_liquidation_handler;
    mod test_withdrawal_handler;
    mod test_deposit_handler;
    mod test_exchange_utils;
// mod test_base_order_handler;
}
mod feature {
    mod test_feature_utils;
}
mod fee {
    mod test_fee_handler;
    mod test_fee_utils;
}
mod market {
    mod test_market_factory;
    mod test_market_token;
    mod test_market_utils;
}
mod nonce {
    mod test_nonce_utils;
}
mod oracle {
    mod test_oracle;
}
mod order {
    mod test_base_order_utils;
    // mod test_increase_order_utils;
    mod test_order;
}
mod position {
    mod test_decrease_position_utils;
    mod test_decrease_position_swap_utils;
    mod test_position_utils;
}
mod price {
    mod test_price;
}
mod pricing {
    mod test_position_pricing_utils;
    mod test_swap_pricing_utils;
}
mod reader {
    mod test_reader;
}
mod role {
    mod test_role_module;
    mod test_role_store;
}
mod router {
    mod test_router;
}
mod swap {
    mod test_swap_handler;
}
mod utils {
    mod test_account_utils;
    mod test_arrays;
    mod test_basic_multicall;
    mod test_calc;
    mod test_enumerable_set;
    mod test_precision;
    mod test_reentrancy_guard;
    mod test_starknet_utils;
    // mod test_u128_mask;
    // mod test_i128;
    mod test_serializable_dict;
}
mod withdrawal {
    mod test_withdrawal_vault;
}
mod mock {
    mod test_governable;
    mod test_referral_storage;
}
mod referral {
    mod test_referral_utils;
}

mod integration {
    mod test_deposit_withdrawal;
    mod test_long_integration;
    mod test_short_integration;
    // mod test_swap_integration;
    mod swap_test;
}
