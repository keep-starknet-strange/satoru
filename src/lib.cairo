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
    mod error;
}

// `nonce` is a module that maintains a progressively increasing nonce value.
mod nonce {
    mod nonce_utils;
}

// 'reader' is a module that retrieves the financial market data and trading utility.
mod reader {
    mod error;
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
    mod i128;
    mod i128_test_storage_contract;
    mod store_arrays;
    mod error_utils;
    mod starknet_utils;
    mod traits;
}

// `liquidation` function to help with liquidations.
mod liquidation {
    mod liquidation_utils;
}

// `market` contains market management functions.
mod market {
    mod error;
    mod market;
    mod market_factory;
    mod market_pool_value_info;
    mod market_store_utils;
    mod market_token;
    mod market_utils;
}

mod mock {
    mod error;
    mod governable;
    mod referral_storage;
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
    mod error;
    mod position_pricing_utils;
    mod pricing_utils;
    mod swap_pricing_utils;
}

// `referral` contains referral logic.
mod referral {
    mod referral_utils;
    mod referral_tier;
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

mod tests_lib;

// `withdrawal` contains withdrawal management functions
mod withdrawal {
    mod error;
    mod withdrawal_utils;
    mod withdrawal_vault;
    mod withdrawal;
}
