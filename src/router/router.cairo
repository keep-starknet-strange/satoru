//! Users will approve this router for token expenditure.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

// *************************************************************************
//                  Interface of the `Router` contract.
// *************************************************************************
#[starknet::interface]
trait IRouter<TContractState> {
    /// Initialize the contract.
    /// # Arguments
    /// * `role_store_address` - The address of the role store contract.
    fn initialize(ref self: TContractState, role_store_address: ContractAddress,);

    /// Transfer the specified amount of tokens from the account to the receiver.
    /// # Arguments
    /// * `token` - The token address to transfer.
    /// * `account` - The account to transfer from.
    /// * `receiver` - The address of the receiver.
    /// * `amount` - The amount of tokens to transfer.
    fn plugin_transfer(
        ref self: TContractState,
        token: ContractAddress,
        account: ContractAddress,
        receiver: ContractAddress,
        amount: u128
    );
}

#[starknet::contract]
mod Router {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;

    use debug::PrintTrait;
    use starknet::{ContractAddress, get_caller_address};


    // Local imports.
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::role::role::ROUTER_PLUGIN;
    use super::IRouter;
    use satoru::router::error::RouterError;
    use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Interface to interact with the `RoleStore` contract.
        role_store: IRoleStoreDispatcher
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************

    /// Constructor of the contract.
    /// # Arguments
    /// * `role_store_address` - The address of the role store contract.
    #[constructor]
    fn constructor(ref self: ContractState, role_store_address: ContractAddress) {
        self.initialize(role_store_address);
    }

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl RouterImpl of super::IRouter<ContractState> {
        fn initialize(ref self: ContractState, role_store_address: ContractAddress,) {
            // Make sure the contract is not already initialized.
            assert(
                self.role_store.read().contract_address.is_zero(), RouterError::ALREADY_INITIALIZED
            );
            self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
        }

        fn plugin_transfer(
            ref self: ContractState,
            token: ContractAddress,
            account: ContractAddress,
            receiver: ContractAddress,
            amount: u128
        ) {
            // Check that the caller has the `ROUTER_PLUGIN` role.
            self.role_store.read().assert_only_role(get_caller_address(), ROUTER_PLUGIN);

            // Transfer tokens from account to receiver.
            // It requires that account's allowance to this contract is at least `amount`.
            IERC20Dispatcher { contract_address: token }
                .transfer_from(account, receiver, amount.into());
        }
    }
}
