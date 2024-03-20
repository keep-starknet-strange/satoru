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
    fn get_signer_count(self: @TContractState) -> u256;

    /// Get the total signer at index.
    /// # Arguments
    /// * `index` - Index of the signer to get.
    /// # Returns
    /// Signer at index.
    fn get_signer(self: @TContractState, index: usize) -> ContractAddress;

    /// Get signers from start to end.
    /// # Arguments
    /// * `start` - Start index, included.
    /// * `end` - End index, not included.
    /// # Returns
    /// Signer for specified indexes.
    fn get_signers(self: @TContractState, start: u256, end: u256) -> Array<ContractAddress>;
}

#[starknet::contract]
mod OracleStore {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;
    use starknet::{ContractAddress, contract_address_const};

    use alexandria_storage::list::{ListTrait, List};

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
        // NOTE: temporarily implemented to complete oracle tests.
        signers: List<ContractAddress>,
        signers_indexes: LegacyMap<ContractAddress, u32>
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
    #[abi(embed_v0)]
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

        fn add_signer(ref self: ContractState, account: ContractAddress) {
            let mut signers = self.signers.read();
            let index = signers.len();
            signers.append(account);
            self.signers_indexes.write(account, index);
        }

        fn remove_signer(ref self: ContractState, account: ContractAddress) {
            let mut signers = self.signers.read();
            let last_signer_index = signers.len();
            let signer_to_remove_index = self.signers_indexes.read(account);
            let last_signer = signers.get(last_signer_index).expect('failed to get last signer');
            signers.set(signer_to_remove_index, last_signer);
            self.signers_indexes.write(last_signer, signer_to_remove_index);
            signers.len = signers.len() - 1;
        }

        fn get_signer_count(self: @ContractState) -> u256 {
            self.signers.read().len().into()
        }

        fn get_signer(self: @ContractState, index: usize) -> ContractAddress {
            // self.signers.read().get(index).expect('failed to get signer')
            contract_address_const::<'signer'>() // TODO
        }

        fn get_signers(self: @ContractState, start: u256, end: u256) -> Array<ContractAddress> {
            let mut signers_subset: Array<ContractAddress> = ArrayTrait::new();
            let signers = self.signers.read();

            let mut index: u32 = start.try_into().expect('failed convertion u32 to u256');
            loop {
                if start == end {
                    break;
                }
                signers_subset.append(signers.get(index).expect('out of bound signer index'))
            };

            signers_subset
        }
    }
}
