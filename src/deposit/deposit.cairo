// Core Lib imports
use starknet::{ContractAddress, contract_address_const};

// Satoru imports
use satoru::utils::store_arrays::StoreContractAddressArray;
use satoru::utils::span32::{Span32, Array32Trait, DefaultSpan32};

/// Deposit
#[derive(Copy, Drop, starknet::Store, Serde, PartialEq)]
struct Deposit {
    /// The unique identifier of the order.
    key: felt252,
    /// The account depositing liquidity.
    account: ContractAddress,
    /// The address to send the liquidity tokens to.
    receiver: ContractAddress,
    /// The callback contract.
    callback_contract: ContractAddress,
    /// The ui fee receiver.
    ui_fee_receiver: ContractAddress,
    /// The market to deposit to.
    market: ContractAddress,
    /// The initial long token address.
    initial_long_token: ContractAddress,
    /// The initial short token address.
    initial_short_token: ContractAddress,
    /// The long token swap path.
    long_token_swap_path: Span32<ContractAddress>,
    /// The short token swap path.
    short_token_swap_path: Span32<ContractAddress>,
    /// The amount of long tokens to deposit.
    initial_long_token_amount: u256,
    /// The amount of short tokens to deposit.
    initial_short_token_amount: u256,
    /// The minimum acceptable number of liquidity tokens.
    min_market_tokens: u256,
    /// The block that the deposit was last updated at sending funds back to the user in case the deposit gets cancelled.
    updated_at_block: u64,
    /// The execution fee for keepers.
    execution_fee: u256,
    /// The gas limit for the callback contract.
    /// TODO: investigate how we want to handle callback and gas limit for Starknet contracts.
    callback_gas_limit: u256,
}

impl DefaultDeposit of Default<Deposit> {
    fn default() -> Deposit {
        Deposit {
            key: 0,
            account: contract_address_const::<0>(),
            receiver: contract_address_const::<0>(),
            callback_contract: contract_address_const::<0>(),
            ui_fee_receiver: contract_address_const::<0>(),
            market: contract_address_const::<0>(),
            initial_long_token: contract_address_const::<0>(),
            initial_short_token: contract_address_const::<0>(),
            long_token_swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
            short_token_swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
            initial_long_token_amount: 0,
            initial_short_token_amount: 0,
            min_market_tokens: 0,
            updated_at_block: 0,
            execution_fee: 0,
            callback_gas_limit: 0,
        }
    }
}
