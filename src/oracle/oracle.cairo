//! Contract to validate and store signed values.
//! Some calculations e.g. calculating the size in tokens for a position
//! may not work with zero / negative prices.
//! As a result, zero / negative prices are considered empty / invalid.
//! A market may need to be manually settled in this case.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;

// Local imports
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::oracle::{
    oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait},
    oracle_utils::{SetPricesParams, ReportInfo}, error::OracleError,
};
use satoru::price::price::Price;

// *************************************************************************
//                  Interface of the `Oracle` contract.
// *************************************************************************
#[starknet::interface]
trait IOracle<TContractState> {
    /// Initialize the contract.
    /// # Arguments
    /// * `role_store_address` - The address of the role store contract.
    /// * `oracle_store_address` - The address of the oracle store contract.
    fn initialize(
        ref self: TContractState,
        role_store_address: ContractAddress,
        oracle_store_address: ContractAddress,
        pragma_address: ContractAddress,
    );

    fn set_primary_prices(ref self: TContractState, token: ContractAddress, price: u256);

    /// Get the primary price of a token.
    /// # Arguments
    /// * `token` - The token to get the price for.
    /// # Returns
    /// The primary price of a token.
    fn get_primary_price(self: @TContractState, token: ContractAddress) -> Price;

    fn set_primary_price(ref self: TContractState, token: ContractAddress, price: u256);

    fn set_price_testing_eth(ref self: TContractState, new_price: u256);

}

/// A price that has been validated in validate_prices().
#[derive(Copy, Drop, starknet::Store, Serde)]
struct ValidatedPrice {
    /// The token to validate the price for.
    token: ContractAddress,
    /// The min price of the token.
    min: u256,
    /// The max price of the token.
    max: u256,
    /// The timestamp of the price validated.
    timestamp: u64,
    min_block_number: u64,
    max_block_number: u64,
}

/// Struct used in set_prices as a cache.
#[derive(Default, Drop)]
struct SetPricesCache {
    info: ReportInfo,
    /// The min block confirmations expected.
    min_block_confirmations: u64,
    /// The max allowed age of price values.
    max_price_age: u64,
    /// The max ref_price deviation factor allowed.
    max_ref_price_deviation_factor: u256,
    /// The previous oracle block number of the loop.
    prev_min_oracle_block_number: u64,
    // The prices that have been validated to set.
    validated_prices: Array<ValidatedPrice>,
}

/// Struct used in validate_prices as an inner cache.
#[derive(Default, Drop)]
struct SetPricesInnerCache {
    /// The current price index to retrieve from compacted_min_prices and compacted_max_prices
    /// to construct the min_prices and max_prices array.
    price_index: usize,
    /// The current signature index to retrieve from the signatures array.
    signature_index: usize,
    /// The index of the min price in min_prices for the current signer.
    min_price_index: u256,
    /// The index of the max price in max_prices for the current signer.
    max_price_index: u256,
    /// The min prices.
    min_prices: Array<u256>,
    /// The max prices.
    max_prices: Array<u256>,
    /// The min price index using U256Mask.
    min_price_index_mask: u256,
    /// The max price index using U256Mask.
    max_price_index_mask: u256,
}

#[starknet::contract]
mod Oracle {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;
    use starknet::ContractAddress;
    use starknet::contract_address_const;
    use starknet::info::{get_block_timestamp, get_block_number};
    use starknet::syscalls::get_block_hash_syscall;
    use starknet::SyscallResultTrait;
    use starknet::storage_access::storage_base_address_from_felt252;
    use debug::PrintTrait;

    use alexandria_math::BitShift;
    use alexandria_sorting::merge_sort;
    use alexandria_storage::list::{ListTrait, List};
    use poseidon::poseidon_hash_span;
    // Local imports.
    use satoru::data::{data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait}, keys};
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use satoru::price::price::Price;
    use satoru::oracle::{
        oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait}, oracle_utils,
        oracle_utils::{SetPricesParams, ReportInfo}, error::OracleError,
        price_feed::{
            IPriceFeedDispatcher, IPriceFeedDispatcherTrait, DataType, PragmaPricesResponse,
        }
    };
    use satoru::role::role_module::{
        IRoleModule, RoleModule
    }; //::role_store::IInternalContractMemberStateTrait as RoleModuleStateTrait;
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::utils::{arrays, arrays::pow, bits, calc, precision};
    use satoru::utils::u256_mask::{Mask, MaskTrait, validate_unique_and_set_index};

    use super::{IOracle, SetPricesCache, SetPricesInnerCache, ValidatedPrice};


    // *************************************************************************
    //                              CONSTANTS
    // *************************************************************************
    const SIGNER_INDEX_LENGTH: u256 = 16;
    // subtract 1 as the first slot is used to store number of signers
    const MAX_SIGNERS: u256 = 15; //256 / SIGNER_INDEX_LENGTH - 1;
    // signer indexes are recorded in a signerIndexFlags uint256 value to check for uniqueness
    const MAX_SIGNER_INDEX: u256 = 256;


    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Interface to interact with the `RoleStore` contract.
        role_store: IRoleStoreDispatcher,
        /// Interface to interact with the `OracleStore` contract.
        oracle_store: IOracleStoreDispatcher,
        /// Interface to interact with the Pragma Oracle.
        price_feed: IPriceFeedDispatcher,
        /// List of Prices related to a token.
        tokens_with_prices: List<ContractAddress>,
        /// Mapping between tokens and prices.
        primary_prices: LegacyMap::<ContractAddress, Price>,
        // Only for testing
        eth_price: Price,
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************

    /// Constructor of the contract.
    /// # Arguments
    /// * `role_store_address` - The address of the role store contract.
    /// * `oracle_store_address` - The address of the oracle store contract.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        role_store_address: ContractAddress,
        oracle_store_address: ContractAddress,
        pragma_address: ContractAddress,
    ) {
        self.initialize(role_store_address, oracle_store_address, pragma_address);
    }

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl OracleImpl of super::IOracle<ContractState> {
        fn initialize(
            ref self: ContractState,
            role_store_address: ContractAddress,
            oracle_store_address: ContractAddress,
            pragma_address: ContractAddress,
        ) {
            // Make sure the contract is not already initialized.
            assert(
                self.role_store.read().contract_address.is_zero(), OracleError::ALREADY_INITIALIZED
            );
            self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
            self
                .oracle_store
                .write(IOracleStoreDispatcher { contract_address: oracle_store_address });
            self.price_feed.write(IPriceFeedDispatcher { contract_address: pragma_address });
        }

        // Only for testing
        fn set_price_testing_eth(ref self: ContractState, new_price: u256) {
            self.eth_price.write(Price { min: new_price, max: new_price })
        }

        fn set_primary_prices(ref self: ContractState, token: ContractAddress, price: u256) {
            self.primary_prices.write(token, Price { min: price, max: price });
        }

        fn get_primary_price(self: @ContractState, token: ContractAddress) -> Price {
            if token.is_zero() {
                return Price { min: 0, max: 0 };
            }
            let price = self.primary_prices.read(token);

            if price.is_zero() {
                OracleError::EMPTY_PRIMARY_PRICE();
            }
            price
        }

        fn set_primary_price(ref self: ContractState, token: ContractAddress, price: u256) {
            // TODO add security check keeper
            self.primary_prices.write(token, Price { min: price, max: price});
        }

    }

    // *************************************************************************
    //                          INTERNAL FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl InternalImpl of InternalTrait {
 
        /// Emits an `OraclePriceUpdated` event for a specific token.
        /// # Parameters
        /// * `event_emitter`: Dispatcher used for emitting events.
        /// * `token`: The contract address of the token for which the price is being updated.
        /// * `min_price`: The minimum price value for the token.
        /// * `max_price`: The maximum price value for the token.
        /// * `is_price_feed`: A boolean flag indicating whether the source is a price feed.
        fn emit_oracle_price_updated(
            self: @ContractState,
            event_emitter: IEventEmitterDispatcher,
            token: ContractAddress,
            min_price: u256,
            max_price: u256,
            is_price_feed: bool,
        ) {
            event_emitter.emit_oracle_price_updated(token, min_price, max_price, is_price_feed);
        }
    }
}

