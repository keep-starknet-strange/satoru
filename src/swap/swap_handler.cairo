//! Contract to help with swap functions.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

// Local imports.
use satoru::swap::swap_utils::{SwapParams};

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
    // Core lib imports    
    use starknet::ContractAddress;

    // Local imports.
    use satoru::swap::swap_utils::SwapParams;
    use satoru::swap::swap_utils;
    use satoru::role::role_module::{RoleModule, IRoleModule};
    use satoru::utils::i128::{StoreI128, I128Serde};

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
    fn constructor(ref self: ContractState, role_store_address: ContractAddress) {
        let mut role_module: RoleModule::ContractState = RoleModule::unsafe_new_contract_state();
        IRoleModule::initialize(ref role_module, role_store_address)
    }


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl SwapHandler of super::ISwapHandler<ContractState> {
        fn swap(ref self: ContractState, params: SwapParams) -> (ContractAddress, u128) {
            //TODO nonReentrant when openzeppelin is available
            let mut role_module: RoleModule::ContractState =
                RoleModule::unsafe_new_contract_state();
            role_module.only_controller();
            swap_utils::swap(@params)
        }
    }
}
