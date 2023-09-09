//! Contract to validate and store signed values.
//! Some calculations e.g. calculating the size in tokens for a position
//! may not work with zero / negative prices.
//! As a result, zero / negative prices are considered empty / invalid.
//! A market may need to be manually settled in this case.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

// Local imports
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
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
        oracle_store_address: ContractAddress
    );

    /// Validate and store signed prices
    ///
    /// The set_prices function is used to set the prices of tokens in the Oracle contract.
    /// It accepts an array of tokens and a signer_info parameter. The signer_info parameter
    /// contains information about the signers that have signed the transaction to set the prices.
    /// The first 16 bits of the signer_info parameter contain the number of signers, and the following
    /// bits contain the index of each signer in the oracle_store. The function checks that the number
    /// of signers is greater than or equal to the minimum number of signers required, and that
    /// the signer indices are unique and within the maximum signer index. The function then calls
    /// set_primary_prices and set_prices_from_price_feeds to set the prices of the tokens.
    ///
    /// Oracle prices are signed as a value together with a precision, this allows
    /// prices to be compacted as uint32 values.
    ///
    /// The signed prices represent the price of one unit of the token using a value
    /// with 30 decimals of precision.
    ///
    /// # Arguments
    /// * `data_store` - The data store.
    /// * `event_emitter` - The event emitter.
    /// * `params` - The set price params.
    fn set_prices(
        ref self: TContractState,
        data_store: IDataStoreSafeDispatcher,
        event_emitter: IEventEmitterDispatcher,
        params: SetPricesParams,
    );

    /// Set the primary price
    /// # Arguments
    /// * `token` - The token to set the price for.
    /// * `price` - The price value to set to.
    fn set_primary_price(ref self: TContractState, token: ContractAddress, price: Price);

    /// Clear all prices
    fn clear_all_prices(ref self: TContractState);

    /// Get the length of tokens_with_prices
    /// # Returns
    /// The length of tokens_with_prices
    fn get_tokens_with_prices_count(self: @TContractState) -> u128;

    /// Get the tokens_with_prices from start to end.
    /// # Arguments
    /// * `start` - The start index, the value for this index will be included.
    /// * `end` -  The end index, the value for this index will be excluded.
    /// # Returns
    /// The tokens of tokens_with_prices for the specified indexes.
    fn get_tokens_with_prices(
        self: @TContractState, start: u128, end: u128
    ) -> Array<ContractAddress>;

    /// Get the primary price of a token.
    /// # Arguments
    /// * `token` - The token to get the price for.
    /// # Returns
    /// The primary price of a token.
    fn get_primary_price(self: @TContractState, token: ContractAddress) -> Price;

    /// Get the stable price of a token.
    /// # Arguments
    /// * `token` - The token to get the price for.
    /// # Returns
    /// The stable price of a token.
    fn get_stable_price(self: @TContractState, token: ContractAddress) -> u128;

    /// Get the multiplier value to convert the external price feed price to the price of 1 unit of the token
    /// represented with 30 decimals.
    /// For example, if USDC has 6 decimals and a price of 1 USD, one unit of USDC would have a price of
    /// 1 / (10 ^ 6) * (10 ^ 30) => 1 * (10 ^ 24)
    /// if the external price feed has 8 decimals, the price feed price would be 1 * (10 ^ 8)
    /// in this case the priceFeedMultiplier should be 10 ^ 46
    /// the conversion of the price feed price would be 1 * (10 ^ 8) * (10 ^ 46) / (10 ^ 30) => 1 * (10 ^ 24)
    /// formula for decimals for price feed multiplier: 60 - (external price feed decimals) - (token decimals)
    /// # Arguments
    /// * `data_store` - The data store dispatcher.
    /// * `token` - The token to get the price for.
    /// # Returns
    /// The price feed multiplier.
    fn get_price_feed_multiplier(
        self: @TContractState, data_store: IDataStoreSafeDispatcher, token: ContractAddress,
    ) -> u128;

    /// Validate prices in `params` for oracles.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `params` - The parameters used to set prices in oracle.
    fn validate_prices(
        self: @TContractState, data_store: IDataStoreSafeDispatcher, params: SetPricesParams,
    ) -> Array<ValidatedPrice>;
}

/// A price that has been validated in validate_prices().
#[derive(Drop, starknet::Store, Serde)]
struct ValidatedPrice {
    /// The token to validate the price for.
    token: ContractAddress,
    /// The min price of the token.
    min: u128,
    /// The max price of the token.
    max: u128,
    /// The timestamp of the price validated.
    timestamp: u128,
    min_block_number: u64,
    max_block_number: u64,
}

/// Struct used in set_prices as a cache.
struct SetPricesCache {
    info: ReportInfo,
    /// The min block confirmations expected.
    min_block_confirmations: u128,
    /// The max allowed age of price values.
    max_price_age: u64,
    /// The max ref_price deviation factor allowed.
    max_ref_price_deviation_factor: u128,
    /// The previous oracle block number of the loop.
    prev_min_oracle_block_number: u64,
    // The prices that have been validated to set.
    validated_prices: Array<ValidatedPrice>,
}

/// Struct used in validate_prices as an inner cache.
struct SetPricesInnerCache {
    /// The current price index to retrieve from compactedMinPrices and compactedMaxPrices
    /// to construct the minPrices and maxPrices array.
    price_index: u128,
    /// The current signature index to retrieve from the signatures array.
    signature_index: u128,
    /// The index of the min price in min_prices for the current signer.
    min_price_index: u128,
    /// The index of the max price in max_prices for the current signer.
    max_price_index: u128,
    /// The min prices.
    min_prices: Array<u128>,
    /// The max prices.
    max_prices: Array<u128>,
    /// The min price index using U128Mask.
    min_price_index_mask: u128,
    /// The max price index using U128Mask.
    max_price_index_mask: u128,
}

#[starknet::contract]
mod Oracle {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;
    use starknet::{get_caller_address, ContractAddress, contract_address_const};

    use debug::PrintTrait;

    // Local imports.
    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
    use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use satoru::price::price::Price;
    use super::{IOracle, ValidatedPrice};
    use satoru::oracle::{
        oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait},
        oracle_utils::{SetPricesParams, ReportInfo}, error::OracleError,
    };


    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Interface to interact with the `RoleStore` contract.
        role_store: IRoleStoreDispatcher,
        /// Interface to interact with the `OracleStore` contract.
        oracle_store: IOracleStoreDispatcher,
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
        oracle_store_address: ContractAddress
    ) {
        self.initialize(role_store_address, oracle_store_address);
    }


    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl OracleImpl of super::IOracle<ContractState> {
        fn initialize(
            ref self: ContractState,
            role_store_address: ContractAddress,
            oracle_store_address: ContractAddress
        ) {
            // Make sure the contract is not already initialized.
            assert(
                self.role_store.read().contract_address.is_zero(), OracleError::ALREADY_INITIALIZED
            );
            self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
            self
                .oracle_store
                .write(IOracleStoreDispatcher { contract_address: oracle_store_address })
        }

        fn set_prices(
            ref self: ContractState,
            data_store: IDataStoreSafeDispatcher,
            event_emitter: IEventEmitterDispatcher,
            params: SetPricesParams,
        ) { // TODO
        }

        fn set_primary_price(
            ref self: ContractState, token: ContractAddress, price: Price,
        ) { // TODO
        }

        fn clear_all_prices(ref self: ContractState) { // TODO
        }

        fn get_tokens_with_prices_count(self: @ContractState) -> u128 {
            // TODO
            0
        }

        fn get_tokens_with_prices(
            self: @ContractState, start: u128, end: u128
        ) -> Array<ContractAddress> {
            // TODO
            ArrayTrait::new()
        }

        fn get_primary_price(self: @ContractState, token: ContractAddress) -> Price {
            // TODO
            Price { min: 0, max: 0 }
        }

        fn get_stable_price(self: @ContractState, token: ContractAddress) -> u128 {
            // TODO
            0
        }

        fn get_price_feed_multiplier(
            self: @ContractState, data_store: IDataStoreSafeDispatcher, token: ContractAddress,
        ) -> u128 {
            // TODO
            0
        }

        fn validate_prices(
            self: @ContractState, data_store: IDataStoreSafeDispatcher, params: SetPricesParams,
        ) -> Array<ValidatedPrice> {
            // TODO
            ArrayTrait::new()
        }
    }

    // *************************************************************************
    //                          INTERNAL FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Validate and set prices.
        /// The _set_prices() function is a helper function that is called by the
        /// setPrices() function. It takes in several parameters: a DataStore contract
        /// instance, an EventEmitter contract instance, an array of signers, and an
        /// OracleUtils.SetPricesParams struct containing information about the tokens
        /// and their prices.
        /// The function first initializes a SetPricesCache struct to store some temporary
        /// values that will be used later in the function. It then loops through the array
        /// of tokens and sets the corresponding values in the cache struct. For each token,
        /// the function also loops through the array of signers and validates the signatures
        /// for the min and max prices for that token. If the signatures are valid, the
        /// function calculates the median min and max prices and sets them in the DataStore
        /// contract.
        /// Finally, the function emits an event to signal that the prices have been set.
        /// # Arguments
        /// * `data_store` - The data store.
        /// * `event_emitter` - The event emitter.
        /// * `params` - The set price params.
        fn set_primary_prices(
            ref self: ContractState,
            data_store: IDataStoreSafeDispatcher,
            event_emitter: IEventEmitterDispatcher,
            params: SetPricesParams,
        ) { // TODO
        }

        /// Validate prices in params.
        /// # Arguments
        /// * `data_store` - The data store.
        /// * `params` - The set price params.
        fn validate_prices(
            self: @ContractState, data_store: IDataStoreSafeDispatcher, params: SetPricesParams,
        ) { // TODO
        }

        /// Get the signers
        /// # Arguments
        /// * `data_store` - The data store dispatcher.
        /// * `token` - The token to get the price for.
        /// # Returns
        /// The signers
        fn get_signers(
            self: @ContractState, data_store: IDataStoreSafeDispatcher, params: SetPricesParams,
        ) -> Array<ContractAddress> {
            // TODO
            ArrayTrait::new()
        }

        /// Compute a salt for validate_signer().
        /// # Returns
        /// The computed salt.
        fn get_salt(self: @ContractState,) -> felt252 {
            // TODO
            0
        }

        /// Validate that price does not deviate too much from ref_price.
        /// # Arguments
        /// * `token` - The token the price is check from.
        /// * `price` - The price to validate.
        /// * `ref_price` - The reference price.
        /// * `max_ref_price_deviation_from_factor` - The max ref_price deviation factor allowed.
        fn validate_ref_price(
            self: @ContractState,
            token: ContractAddress,
            price: u128,
            ref_price: u128,
            max_ref_price_deviation_factor: u128,
        ) { // TODO
        }

        /// Set the primary price.
        /// # Arguments
        /// * `token` - The token to set the price for.
        /// * `price` - The price value to set to.
        fn set_primary_price(
            ref self: ContractState, token: ContractAddress, price: Price,
        ) { // TODO
        }

        /// Remove the primary price.
        /// # Arguments
        /// * `token` - The token to set the price for.
        fn remove_primary_price(ref self: ContractState, token: ContractAddress) { // TODO
        }

        /// Get the price feed prices.
        /// There is a small risk of stale pricing due to latency in price updates or if the chain is down.
        /// This is meant to be for temporary use until low latency price feeds are supported for all tokens.
        /// # Arguments
        /// * `data_store` - The data store.
        /// * `token` - The token to get the price for.
        /// # Returns
        /// The price feed multiplier.
        fn get_price_feed_price(
            self: @ContractState, data_store: IDataStoreSafeDispatcher, token: ContractAddress,
        ) -> (bool, u128) {
            // TODO
            (true, 0)
        }

        /// Set prices using external price feeds to save costs for tokens with stable prices.
        /// # Arguments
        /// * `data_store` - The data store.
        /// * `event_emitter` - The event emitter.
        /// * `price_feed_tokens` - The tokens to set the prices using the price feeds for.
        fn set_prices_from_price_feeds(
            ref self: ContractState,
            data_store: IDataStoreSafeDispatcher,
            event_emitter: IEventEmitterDispatcher,
            price_feed_tokens: Array<ContractAddress>,
        ) { // TODO
        }

        /// Emit events about the new oracle price updates.
        fn emit_oracle_price_updated(
            self: @ContractState,
            event_emitter: IEventEmitterDispatcher,
            token: ContractAddress,
            min_price: u128,
            max_price: u128,
            is_price_feed: bool,
        ) { // TODO
        }
    }
}
