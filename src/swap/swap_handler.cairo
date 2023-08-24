//! Contract to help with swap functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
use gojo::swap::swap_utils::{SwapParams};

// Core lib imports.
use starknet::ContractAddress;

// *************************************************************************
//                  Interface of the `SwapHandler` contract.
// *************************************************************************
#[starknet::interface]
trait ISwapHandler<TContractState> {
    /// Perform a swap based on the given params.
    /// # Arguments
    /// * `params` - SwapParams.
    /// # Returns
    /// * (outputToken, outputAmount)
    fn swap(ref self: TContractState, params: SwapParams) -> (ContractAddress, u128);
}

#[starknet::contract]
mod SwapHandler {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Local imports.
    use gojo::swap::swap_utils::{SwapParams};
    use gojo::role::role_store::{IRoleStoreLibraryDispatcher};
    use gojo::bank::error::BankError;
    use gojo::swap::error::SwapError;

    use starknet::ContractAddress;

    use result::ResultTrait;
    use traits::{Into, TryInto};
    use option::OptionTrait;


    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {}

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************

    /// Constructor of the contract.
    #[constructor]
    fn constructor(ref self: ContractState) {}


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl SwapHandler of super::ISwapHandler<ContractState> {
        /// Perform a swap based on the given params.
        /// # Arguments
        /// * `params` - SwapParams.
        /// # Returns
        /// * (outputToken, outputAmount)
        fn swap(ref self: ContractState, params: SwapParams) -> (ContractAddress, u128) {
            (0.try_into().unwrap(), 0)
        }
    }
}
