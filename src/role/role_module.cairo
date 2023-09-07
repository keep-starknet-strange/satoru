//! Contract for role validation functions

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.

// *************************************************************************
// Interface of the `RoleStore` contract.
// *************************************************************************
#[starknet::interface]
trait IRoleModule<TContractState> {
    /// Only allows the contract itself to call the function.
    fn only_self(self: @TContractState);

    /// Only allows addresses with the TIMELOCK_MULTISIG role to call the function.
    fn only_timelock_multisig(self: @TContractState);

    /// Only allows addresses with the TIMELOCK_ADMIN role to call the function.
    fn only_timelock_admin(self: @TContractState);

    /// Only allows addresses with the CONFIG_KEEPER role to call the function.
    fn only_config_keeper(self: @TContractState);

    /// Only allows addresses with the CONTROLLER role to call the function.
    fn only_controller(self: @TContractState);

    /// Only allows addresses with the ROUTER_PLUGIN role to call the function.
    fn only_router_plugin(self: @TContractState);

    /// Only allows addresses with the MARKET_KEEPER role to call the function.
    fn only_market_keeper(self: @TContractState);

    /// Only allows addresses with the FEE_KEEPER role to call the function.
    fn only_fee_keeper(self: @TContractState);

    /// Only allows addresses with the ORDER_KEEPER role to call the function.
    fn only_order_keeper(self: @TContractState);

    /// Only allows addresses with the PRICING_KEEPER role to call the function.
    fn only_pricing_keeper(self: @TContractState);

    /// Only allows addresses with the LIQUIDATION_KEEPER role to call the function.
    fn only_liquidation_keeper(self: @TContractState);

    /// Only allows addresses with the ADL_KEEPER role to call the function.
    fn only_adl_keeper(self: @TContractState);
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
        fn only_self(self: @ContractState) {
            assert(get_caller_address() == get_contract_address(), RoleError::UNAUTHORIZED_ACCESS);
        }

        fn only_timelock_multisig(self: @ContractState) {
            self.validate_role(role::TIMELOCK_MULTISIG, 'TIMELOCK_MULTISIG');
        }

        fn only_timelock_admin(self: @ContractState) {
            self.validate_role(role::TIMELOCK_ADMIN, 'TIMELOCK_ADMIN');
        }

        fn only_config_keeper(self: @ContractState) {
            self.validate_role(role::CONFIG_KEEPER, 'CONFIG_KEEPER');
        }

        fn only_controller(self: @ContractState) {
            self.validate_role(role::CONTROLLER, 'CONTROLLER');
        }

        fn only_router_plugin(self: @ContractState) {
            self.validate_role(role::ROUTER_PLUGIN, 'ROUTER_PLUGIN');
        }

        fn only_market_keeper(self: @ContractState) {
            self.validate_role(role::MARKET_KEEPER, 'MARKET_KEEPER');
        }

        fn only_fee_keeper(self: @ContractState) {
            self.validate_role(role::FEE_KEEPER, 'FEE_KEEPER');
        }

        fn only_order_keeper(self: @ContractState) {
            self.validate_role(role::ORDER_KEEPER, 'ORDER_KEEPER');
        }

        fn only_pricing_keeper(self: @ContractState) {
            self.validate_role(role::PRICING_KEEPER, 'PRICING_KEEPER');
        }

        fn only_liquidation_keeper(self: @ContractState) {
            self.validate_role(role::LIQUIDATION_KEEPER, 'LIQUIDATION_KEEPER');
        }

        fn only_adl_keeper(self: @ContractState) {
            self.validate_role(role::ADL_KEEPER, 'ADL_KEEPER');
        }
    }

    #[generate_trait]
    impl InternalRoleModuleImpl of InternalRoleModuleTrait {
        fn validate_role(self: @ContractState, role_key: felt252, role_name: felt252) {
            let has_role = self.role_store.read().has_role(get_caller_address(), role_key);
            assert(has_role, role_name);
        }
    }
}
