// Declare modules.

// `bank` is a module handling storing and transferring of tokens.
mod bank {
    mod bank;
    mod strict_bank;
    mod error;
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
    mod hash;
    mod store_contract_address_array;
}

// `market` contains market management functions.
mod market {
    mod market_utils;
    mod error;
    mod market_token;
    mod market_factory;
    mod market;
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
