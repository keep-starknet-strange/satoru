//! Stuct for positions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

/// Main struct used to store positions.
#[derive(Copy, Drop, starknet::Store, Serde, PartialEq)]
struct Position {
    /// The unique identifier of the position.
    key: felt252,
    /// The account linked to the position.
    account: ContractAddress,
    /// The market where is the position.
    market: ContractAddress,
    /// The collateral token of the position.
    collateral_token: ContractAddress,
    /// The size of the position in USD.
    size_in_usd: u128,
    /// The size of the position in tokens.
    size_in_tokens: u128,
    /// The amount of collateralToken for collateral.
    collateral_amount: u128,
    /// The borrowing factor of the position.
    borrowing_factor: u128,
    /// The position funding fee per size..
    funding_fee_amount_per_size: u128,
    /// the position's claimable funding amount per size for the market.long_token
    long_token_claimable_funding_amount_per_size: u128,
    /// the position's claimable funding amount per size for the market.short_token
    short_token_claimable_funding_amount_per_size: u128,
    /// The block at which the position was last increased.
    increased_at_block: u64,
    /// The block at which the position was last decreased.
    decreased_at_block: u64,
    /// Whether the position is a long or short.
    is_long: bool,
}
