// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use debug::PrintTrait;

// Local imports.
use satoru::utils::store_arrays::StoreContractAddressArray;
use satoru::chain::chain::{IChainDispatcher, IChainDispatcherTrait};
use alexandria_storage::list::List;
use satoru::utils::arrays::StoreContractAddressSpan;
use satoru::utils::span32::{Span32, DefaultSpan32};

/// Struct for withdrawals.
#[derive(Copy, Drop, starknet::Store, Serde, PartialEq)]
struct Withdrawal {
    /// The unique identifier of the withdrawal.
    key: felt252,
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
    long_token_swap_path: Span32<ContractAddress>,
    /// An array of market addresses to swap through.
    short_token_swap_path: Span32<ContractAddress>,
    /// The amount of market tokens that will be withdrawn.
    market_token_amount: u128,
    /// The minimum amount of long tokens that must be withdrawn.
    min_long_token_amount: u128,
    /// The minimum amount of short tokens that must be withdrawn.
    min_short_token_amount: u128,
    /// The block at which the withdrawal was last updated.
    updated_at_block: u64,
    /// The execution fee for the withdrawal.
    execution_fee: u128,
    /// The gas limit for calling the callback contract.
    callback_gas_limit: u128,
    /// whether to unwrap the native token
    should_unwrap_native_token: bool,
}

impl DefaultWithdrawal of Default<Withdrawal> {
    fn default() -> Withdrawal {
        Withdrawal {
            key: 0,
            account: 0.try_into().unwrap(),
            receiver: 0.try_into().unwrap(),
            callback_contract: 0.try_into().unwrap(),
            ui_fee_receiver: 0.try_into().unwrap(),
            market: 0.try_into().unwrap(),
            long_token_swap_path: Default::default(),
            short_token_swap_path: Default::default(),
            market_token_amount: 0,
            min_long_token_amount: 0,
            min_short_token_amount: 0,
            updated_at_block: 0,
            execution_fee: 0,
            callback_gas_limit: 0,
            should_unwrap_native_token: true,
        }
    }
}
