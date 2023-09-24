//! Contract to handle storing and transferring of tokens.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

// *************************************************************************
//                  Interface of the `StrictBank` contract.
// *************************************************************************
#[starknet::interface]
trait IStrictBank<TContractState> {
    /// Initialize the contract.
    /// # Arguments
    /// * `data_store_address` - The address of the data store contract.
    /// * `role_store_address` - The address of the role store contract.
    fn initialize(
        ref self: TContractState,
        data_store_address: ContractAddress,
        role_store_address: ContractAddress,
    );

    /// Transfer tokens from this contract to a receiver.
    /// # Arguments
    /// * `token` - The token address to transfer.
    /// * `receiver` - The address of the receiver.
    /// * `amount` - The amount of tokens to transfer.
    fn transfer_out(
        ref self: TContractState, token: ContractAddress, receiver: ContractAddress, amount: u128,
    );

    /// Updates the `token_balances` in case of token burns or similar balance changes.
    /// The `prev_balance` is not validated to be more than the `next_balance` as this
    /// could allow someone to block this call by transferring into the contract.
    /// # Arguments
    /// * `token` - The token to record the burn for.
    /// # Returns
    /// * The new balance.
    fn sync_token_balance(ref self: TContractState, token: ContractAddress) -> u128;
}

#[starknet::contract]
mod StrictBank {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::{get_caller_address, ContractAddress, contract_address_const};

    use debug::PrintTrait;

    // Local imports.
    use satoru::bank::bank::{Bank, IBank};
    use super::IStrictBank;

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {}

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************
    /// Constructor of the contract.
    /// # Arguments
    /// * `data_store_address` - The address of the data store contract.
    /// * `role_store_address` - The address of the role store contract.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        data_store_address: ContractAddress,
        role_store_address: ContractAddress,
    ) {
        self.initialize(data_store_address, role_store_address);
    }


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl StrictBank of super::IStrictBank<ContractState> {
        fn initialize(
            ref self: ContractState,
            data_store_address: ContractAddress,
            role_store_address: ContractAddress,
        ) {
            let mut state: Bank::ContractState = Bank::unsafe_new_contract_state();
            IBank::initialize(ref state, data_store_address, role_store_address);
        }

        fn transfer_out(
            ref self: ContractState,
            token: ContractAddress,
            receiver: ContractAddress,
            amount: u128,
        ) {
            let mut state: Bank::ContractState = Bank::unsafe_new_contract_state();
            IBank::transfer_out(ref state, token, receiver, amount);
        }

        fn sync_token_balance(ref self: ContractState, token: ContractAddress) -> u128 {
            0
        }
    }
}
