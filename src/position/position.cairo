//! Stuct for positions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

/// Main struct used to store positions.
#[derive(Copy, Drop, starknet::Store, Serde, PartialEq)]
struct Position {
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

impl DefaultPosition of Default<Position> {
    fn default() -> Position {
        Position {
            account: 0.try_into().unwrap(),
            market: 0.try_into().unwrap(),
            collateral_token: 0.try_into().unwrap(),
            size_in_usd: 0,
            size_in_tokens: 0,
            collateral_amount: 0,
            borrowing_factor: 0,
            funding_fee_amount_per_size: 0,
            long_token_claimable_funding_amount_per_size: 0,
            short_token_claimable_funding_amount_per_size: 0,
            increased_at_block: 0,
            decreased_at_block: 0,
            is_long: false,
        }
    }
}
