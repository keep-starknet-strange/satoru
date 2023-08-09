// Declare modules.

// `chain` is a module that contains utility function for interacting with the chain and getting information.
mod chain;

// `event` is a module event management functions.
mod event;

// `data` is a module that contains the data store for the system.
mod data;

// `deposit` handles the depositing of funds into the system.
mod deposit;

// `role` is a module that contains the role store and role management functions.
mod role;

// `price` contains utility functions for calculating prices.
mod price;

// `utils` contains utility functions.
mod utils;
// `market` contains market management functions.
mod market;

// Copied from `https://github.com/OpenZeppelin/cairo-contracts/blob/cairo-2/src/token`.
// TODO: Use openzeppelin as dependency when Scarb versions match.
mod token;
