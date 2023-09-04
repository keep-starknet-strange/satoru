// Declare modules.

// `adl` is a module to help with auto-deleveraging.
mod adl {
    mod adl_utils;
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
}

// `deposit` handles the depositing of funds into the system.
mod deposit {
    mod deposit;
    mod deposit_utils;
    mod deposit_vault;
    mod execute_deposit_utils;
}

// `feature` is used to validate if a feature is enabled or disabled.
mod feature {
    mod feature_utils;
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


// `role` is a module that contains the role store and role management functions.
mod role {
    // Custom errors.
    mod error;
    // The definition of the different roles in the system.
    mod role;
    // The contract handling the roles and store them.
    mod role_store;
}

// `price` contains utility functions for calculating prices.
mod price {
    mod price;
}

// `utils` contains utility functions.
mod utils {
    mod array;
    mod basic_multicall;
    mod bits;
    mod calc;
    mod enumerable_values;
    mod global_reentrancy_guard;
    mod precision;
    mod u128_mask;
    mod hash;
    mod store_arrays;
    mod validate_account;
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
}

// `oracle` contains functions related to oracles used by Satoru.
mod oracle {
    mod error;
    mod oracle_modules;
    mod oracle_store;
    mod oracle_utils;
    mod oracle;
}

// `order` contains order management functions.
mod order {
    mod order;
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
}
