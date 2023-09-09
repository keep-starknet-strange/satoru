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
    fn onlySelf(self: @TContractState);
    fn onlyTimelockMultisig(self: @TContractState);
    fn onlyTimelockAdmin(self: @TContractState);
    fn onlyConfigKeeper(self: @TContractState);
    fn onlyController(self: @TContractState);
    fn onlyRouterPlugin(self: @TContractState);
    fn onlyMarketKeeper(self: @TContractState);
    fn onlyFeeKeeper(self: @TContractState);
    fn onlyOrderKeeper(self: @TContractState);
    fn onlyPricingKeeper(self: @TContractState);
    fn onlyLiquidationKeeper(self: @TContractState);
    fn onlyAdlKeeper(self: @TContractState);
}

#[starknet::contract]
mod RoleModule {
    // *************************************************************************
    //                                  IMPORTS
    // *************************************************************************

    // Core lib imports.    
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    // Local imports.
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::role::{role, error::RoleError};


    #[storage]
    struct Storage {
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
        fn onlySelf(self: @ContractState) {
            assert(get_caller_address() == get_contract_address(), RoleError::UNAUTHORIZED_ACCESS);
        }
        fn onlyTimelockMultisig(self: @ContractState) {
            self._validate_role(role::TIMELOCK_MULTISIG);
        }
        fn onlyTimelockAdmin(self: @ContractState) {
            self._validate_role(role::TIMELOCK_ADMIN);
        }
        fn onlyConfigKeeper(self: @ContractState) {
            self._validate_role(role::CONFIG_KEEPER);
        }
        fn onlyController(self: @ContractState) {
            self._validate_role(role::CONTROLLER);
        }
        fn onlyRouterPlugin(self: @ContractState) {
            self._validate_role(role::ROUTER_PLUGIN);
        }
        fn onlyMarketKeeper(self: @ContractState) {
            self._validate_role(role::MARKET_KEEPER);
        }
        fn onlyFeeKeeper(self: @ContractState) {
            self._validate_role(role::FEE_KEEPER);
        }
        fn onlyOrderKeeper(self: @ContractState) {
            self._validate_role(role::ORDER_KEEPER);
        }
        fn onlyPricingKeeper(self: @ContractState) {
            self._validate_role(role::PRICING_KEEPER);
        }
        fn onlyLiquidationKeeper(self: @ContractState) {
            self._validate_role(role::LIQUIDATION_KEEPER);
        }
        fn onlyAdlKeeper(self: @ContractState) {
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

