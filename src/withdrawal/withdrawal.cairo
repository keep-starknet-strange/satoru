// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, contract_address_const};

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
    market_token_amount: u256,
    /// The minimum amount of long tokens that must be withdrawn.
    min_long_token_amount: u256,
    /// The minimum amount of short tokens that must be withdrawn.
    min_short_token_amount: u256,
    /// The block at which the withdrawal was last updated.
    updated_at_block: u64,
    /// The execution fee for the withdrawal.
    execution_fee: u256,
    /// The gas limit for calling the callback contract.
    callback_gas_limit: u256,
}

impl DefaultWithdrawal of Default<Withdrawal> {
    fn default() -> Withdrawal {
        Withdrawal {
            key: 0,
            account: contract_address_const::<0>(),
            receiver: contract_address_const::<0>(),
            callback_contract: contract_address_const::<0>(),
            ui_fee_receiver: contract_address_const::<0>(),
            market: contract_address_const::<0>(),
            long_token_swap_path: Default::default(),
            short_token_swap_path: Default::default(),
            market_token_amount: 0,
            min_long_token_amount: 0,
            min_short_token_amount: 0,
            updated_at_block: 0,
            execution_fee: 0,
            callback_gas_limit: 0,
        }
    }
}
