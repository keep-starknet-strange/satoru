//! Role modules

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;

// *************************************************************************
// Interface of the `RoleModule` contract.
// *************************************************************************
#[starknet::interface]
trait IRoleModule<TContractState> {
    fn initialize(ref self: TContractState, role_store_address: ContractAddress);
    fn only_self(self: @TContractState);
    fn only_timelock_multisig(self: @TContractState);
    fn only_timelock_admin(self: @TContractState);
    fn only_config_keeper(self: @TContractState);
    fn only_controller(self: @TContractState);
    fn only_router_plugin(self: @TContractState);
    fn only_market_keeper(self: @TContractState);
    fn only_fee_keeper(self: @TContractState);
    fn only_order_keeper(self: @TContractState);
    fn only_pricing_keeper(self: @TContractState);
    fn only_liquidation_keeper(self: @TContractState);
    fn only_adl_keeper(self: @TContractState);
}

#[starknet::contract]
mod RoleModule {
    // *************************************************************************
    //                                  IMPORTS
    // *************************************************************************

    // Core lib imports.    
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    // Local imports.
    use satoru::role::{
        role, error::RoleError, role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait}
    };


    #[storage]
    struct Storage {
        role_store: IRoleStoreDispatcher,
    }

    // *************************************************************************
    // CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, role_store_address: ContractAddress) {
        self.initialize(role_store_address);
    }

    // *************************************************************************
    // EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl RoleModule of super::IRoleModule<ContractState> {
        fn initialize(ref self: ContractState, role_store_address: ContractAddress) {
            self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
        }

        fn only_self(self: @ContractState) {
            assert(get_caller_address() == get_contract_address(), RoleError::UNAUTHORIZED_ACCESS);
        }
        fn only_timelock_multisig(self: @ContractState) {
            self._validate_role(role::TIMELOCK_MULTISIG);
        }
        fn only_timelock_admin(self: @ContractState) {
            self._validate_role(role::TIMELOCK_ADMIN);
        }
        fn only_config_keeper(self: @ContractState) {
            self._validate_role(role::CONFIG_KEEPER);
        }
        fn only_controller(self: @ContractState) {
            self._validate_role(role::CONTROLLER);
        }
        fn only_router_plugin(self: @ContractState) {
            self._validate_role(role::ROUTER_PLUGIN);
        }
        fn only_market_keeper(self: @ContractState) {
            self._validate_role(role::MARKET_KEEPER);
        }
        fn only_fee_keeper(self: @ContractState) {
            self._validate_role(role::FEE_KEEPER);
        }
        fn only_order_keeper(self: @ContractState) {
            self._validate_role(role::ORDER_KEEPER);
        }
        fn only_pricing_keeper(self: @ContractState) {
            self._validate_role(role::PRICING_KEEPER);
        }
        fn only_liquidation_keeper(self: @ContractState) {
            self._validate_role(role::LIQUIDATION_KEEPER);
        }
        fn only_adl_keeper(self: @ContractState) {
            self._validate_role(role::ADL_KEEPER);
        }
    }

    // *************************************************************************
    // INTERNAL FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _validate_role(self: @ContractState, role_key: felt252) {
            let caller = get_caller_address();
            let role_store = self.role_store.read();
            assert(role_store.has_role(caller, role_key), RoleError::UNAUTHORIZED_ACCESS);
        }
    }
}
