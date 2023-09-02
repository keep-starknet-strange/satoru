//! Library for deposit functions, to help with the depositing of liquidity
//! into a market in return for market tokens.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;
use traits::Into;
use debug::PrintTrait;
// Local imports.
use gojo::utils::store_arrays::StoreContractAddressArray;

/// Helps with deposit creation.
#[derive(Drop, starknet::Store, Serde)]
struct CreateDepositParams {
    /// The address to send the market tokens to.
    receiver: ContractAddress,
    /// The callback contract linked to this deposit.
    callback_contract: ContractAddress,
    /// The ui fee receiver.
    ui_fee_receiver: ContractAddress,
    /// The market to deposit into.
    market: ContractAddress,
    /// The initial long token address.
    initial_long_token: ContractAddress,
    /// The initial short token address.
    initial_short_token: ContractAddress,
    /// The swap path into markets for the long token.
    long_token_swap_path: Array<ContractAddress>,
    /// The swap path into markets for the short token.
    short_token_swap_path: Array<ContractAddress>,
    /// The minimum acceptable number of liquidity tokens.
    min_market_tokens: u128,
    /// Whether to unwrap the native token when sending funds back
    /// to the user in case the deposit gets cancelled.
    should_unwrap_native_token: bool,
    /// The execution fee for keepers.
    execution_fee: u128,
    /// The gas limit for the callback_contract.
    callback_gas_limit: u128,
}

