//! Contract to handle storing and transferring of tokens.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

// *************************************************************************
//                  Interface of the `FeeHandler` contract.
// *************************************************************************
#[starknet::interface]
trait IFeeHandler<TContractState> {
    /// Initialize the contract.
    /// # Arguments
    /// * `data_store_address` - The address of the data store contract.
    /// * `role_store_address` - The address of the role store contract.
    /// * `event_emitter_address` - The address of the event emitter contract.
    fn initialize(
        ref self: TContractState,
        data_store_address: ContractAddress,
        role_store_address: ContractAddress,
        event_emitter_address: ContractAddress,
    );

    /// Claim fees from the specified markets.
    /// # Arguments
    /// * `market` - The markets to claim fees from.
    /// * `tokens` - The fee tokens to claim.
    fn claim_fees(
        ref self: TContractState, market: Array<ContractAddress>, tokens: Array<ContractAddress>
    );
}

#[starknet::contract]
mod FeeHandler {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;
    use starknet::{get_caller_address, ContractAddress, contract_address_const};


    // Local imports.
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
    use satoru::data::keys;
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use super::IFeeHandler;
    use satoru::fee::error::FeeError;
    use satoru::fee::fee_utils;

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Interface to interact with the `DataStore` contract.
        data_store: IDataStoreDispatcher,
        /// Interface to interact with the `RoleStore` contract.
        role_store: IRoleStoreDispatcher,
        /// Interface to interact with the `EventEmitter` contract.
        event_emitter: IEventEmitterDispatcher,
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************

    /// Constructor of the contract.
    /// # Arguments
    /// * `data_store_address` - The address of the data store contract.
    /// * `role_store_address` - The address of the role store contract.
    /// * `event_emitter_address` - The address of the event emitter contract.

    #[constructor]
    fn constructor(
        ref self: ContractState,
        data_store_address: ContractAddress,
        role_store_address: ContractAddress,
        event_emitter_address: ContractAddress,
    ) {
        self.initialize(data_store_address, role_store_address, event_emitter_address);
    }


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl FeeHandlerImpl of super::IFeeHandler<ContractState> {
        fn initialize(
            ref self: ContractState,
            data_store_address: ContractAddress,
            role_store_address: ContractAddress,
            event_emitter_address: ContractAddress,
        ) {
            // Make sure the contract is not already initialized.
            assert(
                self.data_store.read().contract_address.is_zero(), FeeError::ALREADY_INITIALIZED
            );
            self.data_store.write(IDataStoreDispatcher { contract_address: data_store_address });
            self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
            self
                .event_emitter
                .write(IEventEmitterDispatcher { contract_address: event_emitter_address });
        }

        /// Claim fees for the specified market.
        /// # Arguments
        /// * `markets` - The market to claim fees from.
        /// * `tokens` - The fee tokens.
        fn claim_fees(
            ref self: ContractState, market: Array<ContractAddress>, tokens: Array<ContractAddress>
        ) {
            assert(market.len() == tokens.len(), FeeError::INVALID_CLAIM_FEES_INPUT);

            let data_store = self.data_store.read();

            let receiver = data_store.get_address(keys::fee_receiver());

            let mut i = 0;
            loop {
                if i == market.len() {
                    break;
                }

                fee_utils::claim_fees(
                    data_store, self.event_emitter.read(), *market.at(i), *tokens.at(i), receiver
                );

                i += 1;
            };
        }
    }
}
