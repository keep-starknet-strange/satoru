// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use debug::PrintTrait;

// Local imports.
use gojo::utils::store_arrays::StoreContractAddressArray;
use gojo::chain::chain::{IChainDispatcher, IChainDispatcherTrait};

/// Struct for withdrawals.
#[derive(Drop, Starknet::Store, Serde)]
struct Withdrawal {
    /// The account of the order.
    account: ContractAddress,
    /// The receiver for any token transfers.
    receiver: ContractAddress,
    /// The contract to call for callbacks.
    callback_contract: ContractAddress,
    /// The UI fee receiver.
    ui_fee_receiver: ContractAddress,
    /// The trading market.
    market: ContractAddress,
    /// An array of market addresses to swap through.
    long_token_swap_path: Array<ContractAddress>,
    /// An array of market addresses to swap through.
    short_token_swap_path: Array<ContractAddress>,
    /// The amount of market tokens that will be withdrawn.
    market_token_amount: u128,
    /// The minimum amount of long tokens that must be withdrawn.
    min_long_token_amount: u128,
    /// The minimum amount of short tokens that must be withdrawn.
    min_short_token_amount: u128,
    /// The block at which the withdrawal was last updated.
    updated_at_block: u128,
    /// The execution fee for the withdrawal.
    execution_fee: u128,
    /// The gas limit for calling the callback contract.
    callback_gas_limit: u128,
    /// whether to unwrap the native token
    should_unwrap_native_token: bool,
}
