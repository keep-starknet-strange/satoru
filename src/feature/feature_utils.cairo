//! Feature is a library contract that allows to validate if a feature is enabled or disabled.
// disabling a feature should only be used if it is absolutely necessary
// disabling of features could lead to unexpected effects, e.g. increasing / decreasing of orders
// could be disabled while liquidations may remain enabled
// this could also occur if the chain is not producing blocks and lead to liquidatable positions
// when block production resumes
// the effects of disabling features should be carefully considered

use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};

// *************************************************************************
//                  Interface of the `Feature` contract.
// *************************************************************************
#[starknet::interface]
trait IFeature<TContractState> {
    fn is_feature_disabled(
        self: @TContractState, data_store: IDataStoreSafeDispatcher, key: felt252
    ) -> bool;
    /// Returns the current block timestamp.
    fn validate_feature(self: @TContractState, data_store: IDataStoreSafeDispatcher, key: felt252);
}

#[starknet::contract]
mod Feature {
    /// Storage is empty since the contract is designed to be stateless and called as a library only.
    #[storage]
    struct Storage {}

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl Chain of super::IFeature<ContractState> {
        /// Return if a feature is disabled.
        /// # Arguments
        /// * `data_store` - The data storage contract dispatcher.
        /// * `key` - The feature key.
        /// # Returns
        /// whether the feature is disabled.
        fn is_feature_disabled(
            self: @ContractState, data_store: super::IDataStoreSafeDispatcher, key: felt252
        ) -> bool {
            // TODO
            true
        }

        /// Validate whether a feature is enabled, reverts if the feature is disabled.
        /// # Arguments
        /// * `data_store` - The data storage contract dispatcher.
        /// * `key` - The feature key.
        fn validate_feature(
            self: @ContractState, data_store: super::IDataStoreSafeDispatcher, key: felt252
        ) { // TODO
        }
    }
}
