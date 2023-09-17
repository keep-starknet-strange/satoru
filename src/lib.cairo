// Declare modules.

// `adl` is a module to help with auto-deleveraging.
mod adl {
    mod adl_utils;
    mod error;
}

// `bank` is a module handling storing and transferring of tokens.
mod bank {
    mod bank;
    mod strict_bank;
    mod error;
}

// `callback` is a module that allows for better composability with other contracts.
mod callback {
    mod callback_utils;
    mod error;
    mod mocks;
    mod deposit_callback_receiver {
        mod interface;
    }
    mod order_callback_receiver {
        mod interface;
    }
    mod withdrawal_callback_receiver {
        mod interface;
    }
}

// `chain` is a module that contains utility function for interacting with the chain and getting information.
mod chain {
    mod chain;
}

// `config` is a module that contains the configuration for the system.
mod config {
    mod config;
    mod error;
    mod timelock;
}

// `event` is a module event management functions.
mod event {
    mod event_utils;
    mod event_emitter;
}

// `data` is a module that contains the data store for the system.
mod data {
    mod data_store;
    mod keys;
    mod error;
}

// `deposit` handles the depositing of funds into the system.
mod deposit {
    mod deposit;
    mod deposit_utils;
    mod deposit_vault;
    mod error;
    mod execute_deposit_utils;
}

// `exchange` contains main satoru handlers to create and execute actions.
mod exchange {
    mod adl_handler;
    mod base_order_handler;
    mod deposit_handler;
    mod error;
    mod exchange_utils;
    mod liquidation_handler;
    mod order_handler;
    mod withdrawal_handler;
}

// `feature` is used to validate if a feature is enabled or disabled.
mod feature {
    mod feature_utils;
    mod error;
}

// `fee` is used for fees actions.
mod fee {
    mod fee_handler;
    mod fee_utils;
    mod error;
}

// `gas` is used for execution fee estimation and payments.
mod gas {
    mod gas_utils;
}

// `nonce` is a module that maintains a progressively increasing nonce value.
mod nonce {
    mod nonce_utils;
}

// 'reader' is a module that retrieves the financial market data and trading utility.
mod reader {
    mod reader_pricing_utils;
    mod reader_utils;
    mod reader;
}

// 'router' is a module where users utilize the router to initiate token transactions, exchanges, and transfers.
mod router {
    mod router;
    mod exchange_router;
    mod error;
}

// `role` is a module that contains the role store and role management functions.
mod role {
    // Custom errors.
    mod error;
    // The definition of the different roles in the system.
    mod role;
    // The contract handling the roles and store them.
    mod role_store;
    // The contract handling the role modifiers
    mod role_module;
}

// `price` contains utility functions for calculating prices.
mod price {
    mod price;
}

// `utils` contains utility functions.
mod utils {
    mod account_utils;
    mod arrays;
    mod basic_multicall;
    mod bits;
    mod calc;
    mod enumerable_set;
    mod enumerable_values;
    mod error;
    mod global_reentrancy_guard;
    mod precision;
    mod span32;
    mod u128_mask;
    mod hash;
    mod store_arrays;
    mod error_utils;
    mod starknet_utils;
}

// `liquidation` function to help with liquidations.
mod liquidation {
    mod liquidation_utils;
}

// `market` contains market management functions.
mod market {
    mod market_utils;
    mod error;
    mod market_token;
    mod market_factory;
    mod market;
    mod market_pool_value_info;
    mod market_event_utils;
}

// `oracle` contains functions related to oracles used by Satoru.
mod oracle {
    mod error;
    mod oracle_modules;
    mod oracle_store;
    mod oracle_utils;
    mod oracle;
    mod price_feed;
}

// `order` contains order management functions.
mod order {
    mod base_order_utils;
    mod order_utils;
    mod decrease_order_utils;
    mod increase_order_utils;
    mod order_vault;
    mod order;
    mod order_store_utils;
    mod order_event_utils;
    mod error;
}

// `position` contains positions management functions
mod position {
    mod decrease_position_collateral_utils;
    mod decrease_position_swap_utils;
    mod decrease_position_utils;
    mod increase_position_utils;
    mod position_event_utils;
    mod position_utils;
    mod position;
    mod error;
}

// `pricing` contains pricing utils
mod pricing {
    mod position_pricing_utils;
    mod pricing_utils;
    mod swap_pricing_utils;
}

// `referral` contains referral logic.
mod referral {
    mod referral_utils;
    mod referral_tier;
    mod referral_storage {
        mod interface;
    }
}

mod swap {
    mod swap_utils;
    mod swap_handler;
    mod error;
}

// Copied from `https://github.com/OpenZeppelin/cairo-contracts/blob/cairo-2/src/token`.
// TODO: Use openzeppelin as dependency when Scarb versions match.
mod token {
    mod erc20;
    mod token_utils;
}

// This is a temporary solution for tests until they resolve the issue (https://github.com/foundry-rs/starknet-foundry/issues/647)
mod tests {
    mod adl {
        mod test_adl_utils;
    }
    mod bank {
        mod test_bank;
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
    }
    mod exchange {
        mod test_withdrawal_handler;
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
        mod test_order;
    }
    mod position {
        mod test_decrease_position_swap_utils;
        mod test_position_utils;
    }
    mod price {
        mod test_price;
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
        mod test_reentrancy_guard;
        mod test_starknet_utils;
        mod test_u128_mask;
    }
}

mod tests_lib;

// `withdrawal` contains withdrawal management functions
mod withdrawal {
    mod error;
    mod withdrawal_utils;
    mod withdrawal_vault;
    mod withdrawal;
}
