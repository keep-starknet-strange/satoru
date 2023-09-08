//! Contract for role validation functions

// *************************************************************************
// Interface of the `RoleStore` contract.
// *************************************************************************
#[starknet::interface]
trait IRoleModule<TContractState> {
    /// Only allows addresses with the CONTROLLER role to call the function.
    fn only_controller(self: @TContractState);

    /// Only allows addresses with the ORDER_KEEPER role to call the function.
    fn only_order_keeper(self: @TContractState);
}

#[starknet::contract]
mod RoleModule {
    // *************************************************************************
    //                                  IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_contract_address};

    // Local imports.
    use satoru::role::role;
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::role::error::RoleError;

    // *************************************************************************
    // STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Maps accounts to their roles.
        role_store: IRoleStoreDispatcher,
    }

    // *************************************************************************
    // CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, role_store_address: ContractAddress) {
        self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
    }

    // *************************************************************************
    // EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl RoleModule of super::IRoleModule<ContractState> {
        fn only_controller(self: @ContractState) {
            // TODO
        }

        fn only_order_keeper(self: @ContractState) {
            // TODO
        }
    }
}
