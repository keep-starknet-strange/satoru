//! Contract to handle storing and transferring of tokens.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

// *************************************************************************
//                  Interface of the `Bank` contract.
// *************************************************************************
#[starknet::interface]
trait IBank<TContractState> {
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
}

#[starknet::contract]
mod Bank {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;
    use starknet::{get_caller_address, ContractAddress, contract_address_const};

    use debug::PrintTrait;

    // Local imports.
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
    use super::IBank;
    use satoru::bank::error::BankError;

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Interface to interact with the `DataStore` contract.
        data_store: IDataStoreDispatcher,
        /// Interface to interact with the `RoleStore` contract.
        role_store: IRoleStoreDispatcher,
    }

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
    impl BankImpl of super::IBank<ContractState> {
        fn initialize(
            ref self: ContractState,
            data_store_address: ContractAddress,
            role_store_address: ContractAddress,
        ) {
            // Make sure the contract is not already initialized.
            assert(
                self.data_store.read().contract_address.is_zero(), BankError::ALREADY_INITIALIZED
            );
            self.data_store.write(IDataStoreDispatcher { contract_address: data_store_address });
            self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
        }

        fn transfer_out(
            ref self: ContractState,
            token: ContractAddress,
            receiver: ContractAddress,
            amount: u128,
        ) {
            // FIXME: #29 - https://github.com/keep-starknet-strange/satoru/issues/29
            'not_implemented'.print();
        }
    }
}
