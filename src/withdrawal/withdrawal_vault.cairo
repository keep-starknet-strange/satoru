//! Vault for withdrawals.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;

// *************************************************************************
//                  Interface of the `WithdrawalVault` contract.
// *************************************************************************
#[starknet::interface]
trait IWithdrawalVault<TContractState> {
    /// Initialize the contract.
    /// # Arguments
    /// * `strict_bank_address` - The address of the strict bank contract.
    fn initialize(ref self: TContractState, strict_bank_address: ContractAddress,);
    fn record_transfer_in(ref self: TContractState, token: ContractAddress) -> u128;
    fn transfer_out(
        ref self: TContractState,
        token: ContractAddress,
        receiver: ContractAddress,
        amount: u128,
    );
    fn sync_token_balance(ref self: TContractState, token: ContractAddress) -> u128;
}

#[starknet::contract]
mod WithdrawalVault {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;
    use starknet::{ContractAddress};

    // Local imports.
    use satoru::bank::strict_bank::{IStrictBankDispatcher};
    use super::IWithdrawalVault;
    use satoru::withdrawal::error::WithdrawalError;

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Interface to interact with the `DataStore` contract.
        strict_bank: IStrictBankDispatcher,
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************

    /// Constructor of the contract.
    /// # Arguments
    /// * `strict_bank_address` - The address of the strict bank contract.
    #[constructor]
    fn constructor(ref self: ContractState, strict_bank_address: ContractAddress,) {
        self.initialize(strict_bank_address);
    }


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl BankImpl of super::IWithdrawalVault<ContractState> {
        /// Initialize the contract.
        /// # Arguments
        /// * `strict_bank_address` - The address of the strict bank contract.
        fn initialize(ref self: ContractState, strict_bank_address: ContractAddress,) {
            // Make sure the contract is not already initialized.
            assert(
                self.strict_bank.read().contract_address.is_zero(),
                WithdrawalError::ALREADY_INITIALIZED
            );
            self.strict_bank.write(IStrictBankDispatcher { contract_address: strict_bank_address });
        }

        fn record_transfer_in(ref self: ContractState, token: ContractAddress) -> u128 {
            0
        }

        fn transfer_out(
            ref self: ContractState,
            token: ContractAddress,
            receiver: ContractAddress,
            amount: u128,
        ) {}

        fn sync_token_balance(ref self: ContractState, token: ContractAddress) -> u128 {
            0
        }
    }
}
