//! Stuct for positions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{ContractAddress, contract_address_const};

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
    size_in_usd: u256,
    /// The size of the position in tokens.
    size_in_tokens: u256,
    /// The amount of collateralToken for collateral.
    collateral_amount: u256,
    /// The borrowing factor of the position.
    borrowing_factor: u256,
    /// The position funding fee per size..
    funding_fee_amount_per_size: u256,
    /// the position's claimable funding amount per size for the market.long_token
    long_token_claimable_funding_amount_per_size: u256,
    /// the position's claimable funding amount per size for the market.short_token
    short_token_claimable_funding_amount_per_size: u256,
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
            key: 0,
            account: contract_address_const::<0>(),
            market: contract_address_const::<0>(),
            collateral_token: contract_address_const::<0>(),
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
