//! Referral storage for testing and testnets.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;

// *************************************************************************
//                  Interface of the `OracleStore` contract.
// *************************************************************************
#[starknet::interface]
trait IGovernable<TContractState> {
    fn initialize(ref self: TContractState);       
    fn only_gov(self: @TContractState);
    fn transfer_ownership(ref self: TContractState, new_gov: ContractAddress);
    fn accept_ownership(ref self: TContractState);
}

#[starknet::contract]
mod Governable {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;
    use starknet::{get_caller_address, ContractAddress};
    use result::ResultTrait;

    // Local imports.
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use satoru::oracle::error::OracleError;
    use satoru::referral::referral_tier::ReferralTier;
    use satoru::mock::error::MockError;

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        event_emitter: IEventEmitterDispatcher,
        gov: ContractAddress,
        pending_gov: ContractAddress,
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************
    /// Constructor of the contract.
    /// # Arguments
    /// * `data_store_address` - The address of the data store contract.
    /// * `role_store_address` - The address of the role store contract.
    #[constructor]
    fn constructor(ref self: ContractState) {
        self.initialize();
    }

    // let gov: ContractAddress = get_caller_address()
    // let pending_gov: ContractAddress = get_caller_address();

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl Governable of super::IGovernable<ContractState> {
        fn initialize(ref self: ContractState) {
            self._set_gov(get_caller_address())
        }
        
        fn only_gov(self: @ContractState){
            if (get_caller_address() != self.gov.read()){
                panic(array![MockError::UNAUTHORIZED_GOV])
            }
        }

        fn transfer_ownership(ref self: ContractState, new_gov: ContractAddress) {
            self.only_gov();
            self.pending_gov.write(new_gov);
        }

        fn accept_ownership(ref self: ContractState) {
            if (get_caller_address() != self.pending_gov.read()){
                panic(array![MockError::UNAUTHORIZED_PENDING_GOV])
            }
            self._set_gov(get_caller_address());
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _set_gov(ref self: ContractState, _gov: ContractAddress) {
            let prev_gov: ContractAddress = self.gov.read();
            self.gov.write(_gov);
            event_emitter.emit_set_gov(prev_gov, _gov);
        }
    }
}
