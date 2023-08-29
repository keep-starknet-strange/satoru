//! Contract to validate and store signed values
// Some calculations e.g. calculating the size in tokens for a position
// may not work with zero / negative prices
// as a result, zero / negative prices are considered empty / invalid
// A market may need to be manually settled in this case

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use core::traits::Into;
use starknet::ContractAddress;

// Local imports
use gojo::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use gojo::oracle::{
    oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait},
    oracle_utils::{SetPricesParams, ReportInfo},
};
use gojo::price::price::{Price};
use gojo::oracle::error::OracleError;
use gojo::utils::u128_mask::{Mask};

// *************************************************************************
//                  Interface of the `Oracle` contract.
// *************************************************************************
#[starknet::interface]
trait IOracle<TContractState> {
    //// Initialize the contract.
    //// # Arguments
    //// * `role_store_address` - The address of the role store contract.
    //// * `oracle_store_address` - The address of the oracle store contract.
    fn initialize(
        ref self: TContractState,
        role_store_address: ContractAddress,
        oracle_store_address: ContractAddress
    );
    /// Validate and store signed prices
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
    fn set_primary_price(ref self: TContractState, token: ContractAddress, price: Price,);
    /// Clear all prices
    fn clear_all_prices(ref self: TContractState,);
    /// Get the length of tokens_with_prices
    /// # Returns
    /// The length of tokens_with_prices
    fn get_tokens_with_prices_count(self: @TContractState,) -> u128;
    /// Get the length of tokens_with_prices
    /// # Arguments
    /// * `start` - The start index, the value for this index will be included.
    /// * `end` -  The end index, the value for this index will be excluded.
    /// # Returns
    /// The tokens of tokens_with_prices for the specified indexes
    fn get_tokens_with_prices(
        self: @TContractState, start: u128, end: u128
    ) -> Array<ContractAddress>;
    /// Get the primary price of a token
    /// # Arguments
    /// * `token` - The token to get the price for.
    /// # Returns
    /// The primary price of a token
    fn get_primary_price(self: @TContractState, token: ContractAddress,) -> Price;
    /// Get the stable price of a token
    /// # Arguments
    /// * `token` - The token to get the price for.
    /// # Returns
    /// The stable price of a token
    fn get_stable_price(self: @TContractState, token: ContractAddress,) -> u128;
    /// Get the multiplier value to convert the external price feed price to the price of 1 unit of the token
    /// represented with 30 decimals
    /// # Arguments
    /// * `data_store` - The data store.
    /// * `token` - The token to get the price for.
    /// # Returns
    /// The price feed multiplier
    fn get_price_feed_multiplier(
        self: @TContractState, data_store: IDataStoreSafeDispatcher, token: ContractAddress,
    ) -> u128;
    fn validate_prices(
        self: @TContractState, data_store: IDataStoreSafeDispatcher, params: SetPricesParams,
    ) -> Array<ValidatedPrice>;
}

#[derive(Drop, starknet::Store, Serde)]
struct ValidatedPrice {
    token: ContractAddress,
    min: u128,
    max: u128,
    timestamp: u128,
    min_block_number: u128,
    max_block_number: u128,
}

struct SetPricesCache {
    info: ReportInfo,
    min_block_confirmations: u128,
    /// The max allowed age of price values
    max_price_age: u128,
    max_ref_price_deviation_factor: u128,
    prev_min_oracle_block_number: u128,
    validated_prices: Array<ValidatedPrice>,
}

struct SetPricesInnerCache {
    /// The current signature index to retrieve from the signatures array
    price_index: u128,
    signature_index: u128,
    /// The index of the min price in minPrices for the current signer
    min_price_index: u128,
    /// The index of the max price in maxPrices for the current signer
    max_price_index: u128,
    /// The min prices
    min_prices: Array<u128>,
    /// The max prices
    max_prices: Array<u128>,
    min_price_index_mask: Mask,
    max_price_index_mask: Mask,
}

#[starknet::contract]
mod Oracle {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;
    use starknet::{get_caller_address, ContractAddress, contract_address_const};
    use array::ArrayTrait;
    use traits::Into;
    use debug::PrintTrait;

    // Local imports.
    use gojo::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
    use gojo::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
    use gojo::oracle::{
        oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait},
        oracle_utils::{SetPricesParams},
    };
    use gojo::price::price::{Price};
    use super::{IOracle, ValidatedPrice};
    use gojo::oracle::error::OracleError;

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
        /// Initialize the contract.
        /// # Arguments
        /// * `role_store_address` - The address of the role store contract.
        /// * `oracle_store_address` - The address of the oracle store contract.
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

        /// Validate and store signed prices
        ///
        /// The setPrices function is used to set the prices of tokens in the Oracle contract.
        /// It accepts an array of tokens and a signerInfo parameter. The signerInfo parameter
        /// contains information about the signers that have signed the transaction to set the prices.
        /// The first 16 bits of the signerInfo parameter contain the number of signers, and the following
        /// bits contain the index of each signer in the oracleStore. The function checks that the number
        /// of signers is greater than or equal to the minimum number of signers required, and that
        /// the signer indices are unique and within the maximum signer index. The function then calls
        /// _setPrices and _setPricesFromPriceFeeds to set the prices of the tokens.
        ///
        /// Oracle prices are signed as a value together with a precision, this allows
        /// prices to be compacted as uint32 values.
        ///
        /// The signed prices represent the price of one unit of the token using a value
        /// with 30 decimals of precision.
        ///
        /// Representing the prices in this way allows for conversions between token amounts
        /// and fiat values to be simplified, e.g. to calculate the fiat value of a given
        /// number of tokens the calculation would just be: `token amount * oracle price`,
        /// to calculate the token amount for a fiat value it would be: `fiat value / oracle price`.
        ///
        /// The trade-off of this simplicity in calculation is that tokens with a small USD
        /// price and a lot of decimals may have precision issues it is also possible that
        /// a token's price changes significantly and results in requiring higher precision.
        ///
        /// ## Example 1
        ///
        /// The price of ETH is 5000, and ETH has 18 decimals.
        ///
        /// The price of one unit of ETH is `5000 / (10 ^ 18), 5 * (10 ^ -15)`.
        ///
        /// To handle the decimals, multiply the value by `(10 ^ 30)`.
        ///
        /// Price would be stored as `5000 / (10 ^ 18) * (10 ^ 30) => 5000 * (10 ^ 12)`.
        ///
        /// For gas optimization, these prices are sent to the oracle in the form of a uint8
        /// decimal multiplier value and uint32 price value.
        ///
        /// If the decimal multiplier value is set to 8, the uint32 value would be `5000 * (10 ^ 12) / (10 ^ 8) => 5000 * (10 ^ 4)`.
        ///
        /// With this config, ETH prices can have a maximum value of `(2 ^ 32) / (10 ^ 4) => 4,294,967,296 / (10 ^ 4) => 429,496.7296` with 4 decimals of precision.
        ///
        /// ## Example 2
        ///
        /// The price of BTC is 60,000, and BTC has 8 decimals.
        ///
        /// The price of one unit of BTC is `60,000 / (10 ^ 8), 6 * (10 ^ -4)`.
        ///
        /// Price would be stored as `60,000 / (10 ^ 8) * (10 ^ 30) => 6 * (10 ^ 26) => 60,000 * (10 ^ 22)`.
        ///
        /// BTC prices maximum value: `(2 ^ 32) / (10 ^ 2) => 4,294,967,296 / (10 ^ 2) => 42,949,672.96`.
        ///
        /// Decimals of precision: 2.
        ///
        /// ## Example 3
        ///
        /// The price of USDC is 1, and USDC has 6 decimals.
        ///
        /// The price of one unit of USDC is `1 / (10 ^ 6), 1 * (10 ^ -6)`.
        ///
        /// Price would be stored as `1 / (10 ^ 6) * (10 ^ 30) => 1 * (10 ^ 24)`.
        ///
        /// USDC prices maximum value: `(2 ^ 64) / (10 ^ 6) => 4,294,967,296 / (10 ^ 6) => 4294.967296`.
        ///
        /// Decimals of precision: 6.
        ///
        /// ## Example 4
        ///
        /// The price of DG is 0.00000001, and DG has 18 decimals.
        ///
        /// The price of one unit of DG is `0.00000001 / (10 ^ 18), 1 * (10 ^ -26)`.
        ///
        /// Price would be stored as `1 * (10 ^ -26) * (10 ^ 30) => 1 * (10 ^ 3)`.
        ///
        /// DG prices maximum value: `(2 ^ 64) / (10 ^ 11) => 4,294,967,296 / (10 ^ 11) => 0.04294967296`.
        ///
        /// Decimals of precision: 11.
        ///
        /// ## Decimal Multiplier
        ///
        /// The formula to calculate what the decimal multiplier value should be set to:
        ///
        /// Decimals: 30 - (token decimals) - (number of decimals desired for precision)
        ///
        /// - ETH: 30 - 18 - 4 => 8
        /// - BTC: 30 - 8 - 2 => 20
        /// - USDC: 30 - 6 - 6 => 18
        /// - DG: 30 - 18 - 11 => 1.
        /// # Arguments
        /// * `data_store` - The data store.
        /// * `event_emitter` - The event emitter.
        /// * `params` - The set price params.
        fn set_prices(
            ref self: ContractState,
            data_store: IDataStoreSafeDispatcher,
            event_emitter: IEventEmitterDispatcher,
            params: SetPricesParams,
        ) { // TODO
        }

        /// Set the primary price
        /// # Arguments
        /// * `token` - The token to set the price for.
        /// * `price` - The price value to set to.
        fn set_primary_price(
            ref self: ContractState, token: ContractAddress, price: Price,
        ) { // TODO
        }

        /// Clear all prices
        fn clear_all_prices(ref self: ContractState,) { // TODO
        }

        /// Get the length of tokens_with_prices
        /// # Returns
        /// The length of tokens_with_prices
        fn get_tokens_with_prices_count(self: @ContractState,) -> u128 {
            // TODO
            0
        }

        /// Get the length of tokens_with_prices
        /// # Arguments
        /// * `start` - The start index, the value for this index will be included.
        /// * `end` -  The end index, the value for this index will be excluded.
        /// # Returns
        /// The tokens of tokens_with_prices for the specified indexes
        fn get_tokens_with_prices(
            self: @ContractState, start: u128, end: u128
        ) -> Array<ContractAddress> {
            // TODO
            ArrayTrait::new()
        }

        /// Get the primary price of a token
        /// # Arguments
        /// * `token` - The token to get the price for.
        /// # Returns
        /// The primary price of a token
        fn get_primary_price(self: @ContractState, token: ContractAddress,) -> Price {
            // TODO
            Price { min: 0, max: 0 }
        }

        /// Get the stable price of a token
        /// # Arguments
        /// * `token` - The token to get the price for.
        /// # Returns
        /// The stable price of a token
        fn get_stable_price(self: @ContractState, token: ContractAddress,) -> u128 {
            // TODO
            0
        }

        /// Get the multiplier value to convert the external price feed price to the price of 1 unit of the token
        /// represented with 30 decimals
        /// for example, if USDC has 6 decimals and a price of 1 USD, one unit of USDC would have a price of
        /// 1 / (10 ^ 6) * (10 ^ 30) => 1 * (10 ^ 24)
        /// if the external price feed has 8 decimals, the price feed price would be 1 * (10 ^ 8)
        /// in this case the priceFeedMultiplier should be 10 ^ 46
        /// the conversion of the price feed price would be 1 * (10 ^ 8) * (10 ^ 46) / (10 ^ 30) => 1 * (10 ^ 24)
        /// formula for decimals for price feed multiplier: 60 - (external price feed decimals) - (token decimals)
        /// # Arguments
        /// * `data_store` - The data store.
        /// * `token` - The token to get the price for.
        /// # Returns
        /// The price feed multiplier
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
        /// Validate and set prices
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

        /// Validate
        /// # Arguments
        /// * `data_store` - The data store.
        /// * `params` - The set price params.
        fn validate_prices(
            self: @ContractState, data_store: IDataStoreSafeDispatcher, params: SetPricesParams,
        ) { // TODO
        }

        /// Get the signers
        /// # Arguments
        /// * `data_store` - The data store.
        /// * `token` - The token to get the price for.
        /// # Returns
        /// The signers
        fn get_signers(
            self: @ContractState, data_store: IDataStoreSafeDispatcher, params: SetPricesParams,
        ) -> Array<ContractAddress> {
            // TODO
            ArrayTrait::new()
        }

        /// # Returns
        /// The salt
        fn get_salt(
            self: @ContractState, data_store: IDataStoreSafeDispatcher, params: SetPricesParams,
        ) -> felt252 {
            // TODO
            0
        }

        /// # Arguments
        /// * `data_store` - The data store.
        /// * `params` - The set price params.
        fn validate_ref_price(
            self: @ContractState,
            token: ContractAddress,
            price: u128,
            ref_price: u128,
            max_ref_price_deviation_from_factor: u128,
        ) { // TODO
        }

        /// Set the primary price
        /// # Arguments
        /// * `token` - The token to set the price for.
        /// * `price` - The price value to set to.
        fn set_primary_price(
            ref self: ContractState, token: ContractAddress, price: Price,
        ) { // TODO
        }

        /// Remove the primary price
        /// # Arguments
        /// * `token` - The token to set the price for.
        fn remove_primary_price(ref self: ContractState, token: ContractAddress,) { // TODO
        }

        /// Get the price feed prices
        /// there is a small risk of stale pricing due to latency in price updates or if the chain is down
        /// this is meant to be for temporary use until low latency price feeds are supported for all tokens
        /// # Arguments
        /// * `data_store` - The data store.
        /// * `token` - The token to get the price for.
        /// # Returns
        /// The price feed multiplier
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
