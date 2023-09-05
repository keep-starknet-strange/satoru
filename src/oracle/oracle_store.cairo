//! Contract to stores the list of oracle signers.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;

// *************************************************************************
//                  Interface of the `OracleStore` contract.
// *************************************************************************
#[starknet::interface]
trait IOracleStore<TContractState> {
    /// Initialize the contract.
    /// # Arguments
    /// * `role_store_address` - The address of the role store contract.
    /// * `event_emitter_address` - The address of the event emitter contract.
    fn initialize(
        ref self: TContractState,
        role_store_address: ContractAddress,
        event_emitter_address: ContractAddress,
    );

    /// Adds a signer.
    /// # Arguments
    /// * `signer` - account address of the signer to add.
    fn add_signer(ref self: TContractState, account: ContractAddress);

    /// Removes a signer.
    /// # Arguments
    /// * `signer` - account address of the signer to remove.
    fn remove_signer(ref self: TContractState, account: ContractAddress);

    /// Get the total number of signers.
    /// # Returns
    /// Signer count.
    fn get_signer_count(self: @TContractState) -> u128;

    /// Get the total signer at index.
    /// # Arguments
    /// * `index` - Index of the signer to get.
    /// # Returns
    /// Signer at index.
    fn get_signer(self: @TContractState, index: u128) -> ContractAddress;

    /// Get signers from start to end.
    /// # Arguments
    /// * `start` - Start index, included.
    /// * `end` - End index, not included.
    /// # Returns
    /// Signer for specified indexes.
    fn get_signers(self: @TContractState, start: u128, end: u128) -> Array<ContractAddress>;
}

#[starknet::contract]
mod OracleStore {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;
    use starknet::ContractAddress;

    use result::ResultTrait;

    // Local imports.
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::event::event_emitter::{IEventEmitterDispatcher};
    use satoru::oracle::error::OracleError;
    use super::IOracleStore;

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
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
    /// * `role_store_address` - The address of the role store contract.
    /// * `event_emitter_address` - The address of the event emitter contract.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        role_store_address: ContractAddress,
        event_emitter_address: ContractAddress,
    ) {
        self.initialize(role_store_address, event_emitter_address);
    }


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl OracleStoreImpl of super::IOracleStore<ContractState> {
        fn initialize(
            ref self: ContractState,
            role_store_address: ContractAddress,
            event_emitter_address: ContractAddress,
        ) {
            // Make sure the contract is not already initialized.
            assert(
                self.event_emitter.read().contract_address.is_zero(),
                OracleError::ALREADY_INITIALIZED
            );
            self
                .event_emitter
                .write(IEventEmitterDispatcher { contract_address: event_emitter_address });
            self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
        }

        fn add_signer(ref self: ContractState, account: ContractAddress) { // TODO
        }

        fn remove_signer(ref self: ContractState, account: ContractAddress) { // TODO
        }

        fn get_signer_count(self: @ContractState) -> u128 { // TODO
            0
        }

        fn get_signer(self: @ContractState, index: u128) -> ContractAddress { // TODO
            0.try_into().unwrap()
        }

        fn get_signers(
            self: @ContractState, start: u128, end: u128
        ) -> Array<ContractAddress> { // TODO
            ArrayTrait::new()
        }
    }
}
