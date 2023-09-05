//! Contract to handle time lock.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

// *************************************************************************
//                  Interface of the `DepositVault` contract.
// *************************************************************************
#[starknet::interface]
trait IDepositVault<TContractState> {}

#[starknet::contract]
mod DepositVault {
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
    /// * `role_store_address` - The address of the role store contract.
    /// * `data_store_address` - The address of the data store contract.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        role_store_address: ContractAddress,
        data_store_address: ContractAddress,
    ) {
        self.data_store.write(IDataStoreDispatcher { contract_address: data_store_address });
        self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
    }


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl DepositVaultImpl of super::IDepositVault<ContractState> {}
}
