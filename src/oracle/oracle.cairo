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
        data_store: IDataStoreDispatcher,
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
    fn get_tokens_with_prices_count(self: @TContractState) -> u32;

    /// Get the tokens_with_prices from start to end.
    /// # Arguments
    /// * `start` - The start index, the value for this index will be included.
    /// * `end` -  The end index, the value for this index will be excluded.
    /// # Returns
    /// The tokens of tokens_with_prices for the specified indexes.
    fn get_tokens_with_prices(
        self: @TContractState, start: u32, end: u32
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
    fn get_stable_price(
        self: @TContractState, data_store: IDataStoreDispatcher, token: ContractAddress
    ) -> u128;

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
        self: @TContractState, data_store: IDataStoreDispatcher, token: ContractAddress,
    ) -> u128;

    /// Validate prices in `params` for oracles.
    /// # Arguments
    /// * `data_store` - The `DataStore` contract dispatcher.
    /// * `params` - The parameters used to set prices in oracle.
    fn validate_prices(
        self: @TContractState, data_store: IDataStoreDispatcher, params: SetPricesParams,
    ) -> Array<ValidatedPrice>;
}

/// A price that has been validated in validate_prices().
#[derive(Copy, Drop, starknet::Store, Serde)]
struct ValidatedPrice {
    /// The token to validate the price for.
    token: ContractAddress,
    /// The min price of the token.
    min: u128,
    /// The max price of the token.
    max: u128,
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
    max_ref_price_deviation_factor: u128,
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
    use starknet::ContractAddress;
    use starknet::info::{get_block_timestamp, get_block_number};
    use starknet::syscalls::get_block_hash_syscall;
    use starknet::SyscallResultTrait;
    use starknet::storage_access::storage_base_address_from_felt252;

    use alexandria_math::BitShift;
    use alexandria_sorting::merge_sort;
    use alexandria_storage::list::{ListTrait, List};
    use poseidon::poseidon_hash_span;
    use debug::PrintTrait;
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
    use satoru::utils::u128_mask::{Mask, MaskTrait, validate_unique_and_set_index};

    use super::{IOracle, SetPricesCache, SetPricesInnerCache, ValidatedPrice};


    // *************************************************************************
    //                              CONSTANTS
    // *************************************************************************
    const SIGNER_INDEX_LENGTH: u128 = 16;
    // subtract 1 as the first slot is used to store number of signers
    const MAX_SIGNERS: u128 = 15; //128 / SIGNER_INDEX_LENGTH - 1;
    // signer indexes are recorded in a signerIndexFlags uint128 value to check for uniqueness
    const MAX_SIGNER_INDEX: u128 = 128;


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

        fn set_prices(
            ref self: ContractState,
            data_store: IDataStoreDispatcher,
            event_emitter: IEventEmitterDispatcher,
            params: SetPricesParams,
        ) {
            let state: RoleModule::ContractState = RoleModule::unsafe_new_contract_state();
            IRoleModule::only_controller(@state);
            let tokens_with_prices_len = self.tokens_with_prices.read().len();
            if !tokens_with_prices_len.is_zero() {
                OracleError::NON_EMPTY_TOKENS_WITH_PRICES(tokens_with_prices_len);
            };

            self.set_prices_from_price_feeds(data_store, event_emitter, @params.price_feed_tokens);
            // it is possible for transactions to be executed using just params.priceFeedTokens
            // in this case if params.tokens is empty, the function can return
            if params.tokens.len().is_zero() {
                return;
            }

            self.set_prices_(data_store, event_emitter, params);
        }

        // Set the primary price
        // Arguments
        // * `token` - The token to set the price for.
        // * `price` - The price value to set to.
        fn set_primary_price(ref self: ContractState, token: ContractAddress, price: Price,) {
            let state: RoleModule::ContractState = RoleModule::unsafe_new_contract_state();
            IRoleModule::only_controller(@state);
            self.set_primary_price_(token, price);
        }

        fn clear_all_prices(ref self: ContractState) {
            let state: RoleModule::ContractState = RoleModule::unsafe_new_contract_state();
            IRoleModule::only_controller(@state);
            let mut len = 0;
            loop {
                if len == self.tokens_with_prices.read().len() {
                    break;
                }
                let token = self.tokens_with_prices.read().get(len).expect('array get failed');
                self.remove_primary_price(token);
                len += 1;
            }
        }


        fn get_tokens_with_prices_count(self: @ContractState) -> u32 {
            let token_with_prices = self.tokens_with_prices.read();
            let tokens_with_prices_len = token_with_prices.len();
            let mut count = 0;
            let mut i = 0;
            loop {
                if i == tokens_with_prices_len {
                    break;
                }
                if !token_with_prices.get(i).expect('array get failed').is_zero() {
                    count += 1;
                }
                i += 1;
            };
            count
        }

        fn get_tokens_with_prices(
            self: @ContractState, start: u32, mut end: u32
        ) -> Array<ContractAddress> {
            let mut arr: Array<ContractAddress> = array![];
            let tokens_with_prices = self.tokens_with_prices.read();
            let tokens_with_prices_len = tokens_with_prices.len();
            if end > tokens_with_prices_len {
                end = tokens_with_prices_len;
            }
            if tokens_with_prices.len().is_zero() {
                return arr;
            }
            let mut arr: Array<ContractAddress> = array![];
            let mut index = start;
            loop {
                if index >= end {
                    break;
                }
                arr.append(tokens_with_prices[index]);
                index += 1;
            };
            arr
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


        fn get_stable_price(
            self: @ContractState, data_store: IDataStoreDispatcher, token: ContractAddress
        ) -> u128 {
            data_store.get_u128(keys::stable_price_key(token))
        }

        fn get_price_feed_multiplier(
            self: @ContractState, data_store: IDataStoreDispatcher, token: ContractAddress,
        ) -> u128 {
            let multiplier = data_store.get_u128(keys::price_feed_multiplier_key(token));

            if multiplier.is_zero() {
                OracleError::EMPTY_PRICE_FEED_MULTIPLIER();
            }
            multiplier
        }

        fn validate_prices(
            self: @ContractState, data_store: IDataStoreDispatcher, params: SetPricesParams,
        ) -> Array<ValidatedPrice> {
            self.validate_prices_(data_store, params)
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
        fn set_prices_(
            ref self: ContractState,
            data_store: IDataStoreDispatcher,
            event_emitter: IEventEmitterDispatcher,
            params: SetPricesParams,
        ) {
            let validated_prices = self.validate_prices(data_store, params);

            let mut len = 0;
            loop {
                if len == validated_prices.len() {
                    break;
                }

                let validated_price = *validated_prices.at(len);
                if !self.primary_prices.read(validated_price.token).is_zero() {
                    OracleError::DUPLICATED_TOKEN_PRICE();
                }
                self
                    .emit_oracle_price_updated(
                        event_emitter,
                        validated_price.token,
                        validated_price.min,
                        validated_price.max,
                        false
                    );
                self
                    .set_primary_price_(
                        validated_price.token,
                        Price { min: validated_price.min, max: validated_price.max }
                    );
                len += 1;
            };
        }

        /// Validate prices in params.
        /// # Arguments
        /// * `data_store` - The data store.
        /// * `params` - The set price params.
        fn validate_prices_(
            self: @ContractState, data_store: IDataStoreDispatcher, params: SetPricesParams,
        ) -> Array<ValidatedPrice> {
            let signers = self.get_signers_(data_store, @params);

            let mut cache: SetPricesCache = Default::default();
            cache
                .min_block_confirmations = data_store
                .get_u128(keys::min_oracle_block_confirmations())
                .try_into()
                .expect('get_u128 into u64 failed');

            cache
                .max_price_age = data_store
                .get_u128(keys::max_oracle_price_age())
                .try_into()
                .expect('get_u128 into u64 failed');

            cache
                .max_ref_price_deviation_factor = data_store
                .get_u128(keys::max_oracle_ref_price_deviation_factor());

            let mut i = 0;
            loop {
                let mut report_info: ReportInfo = Default::default();
                let mut inner_cache: SetPricesInnerCache = Default::default();
                if i == params.tokens.len() {
                    break;
                }

                report_info
                    .min_oracle_block_number =
                        oracle_utils::get_uncompacted_oracle_block_number(
                            params.compacted_min_oracle_block_numbers.span(), i.into()
                        );

                report_info
                    .max_oracle_block_number =
                        oracle_utils::get_uncompacted_oracle_block_number(
                            params.compacted_max_oracle_block_numbers.span(), i.into()
                        );

                if report_info.min_oracle_block_number > report_info.max_oracle_block_number {
                    OracleError::INVALID_MIN_MAX_BLOCK_NUMBER(
                        report_info.min_oracle_block_number, report_info.max_oracle_block_number
                    );
                }

                report_info
                    .oracle_timestamp =
                        oracle_utils::get_uncompacted_oracle_timestamp(
                            params.compacted_oracle_timestamps.span(), i
                        );
                if report_info.min_oracle_block_number > get_block_number() {
                    OracleError::INVALID_BLOCK_NUMBER(
                        report_info.min_oracle_block_number, get_block_number()
                    );
                }

                if report_info.oracle_timestamp + cache.max_price_age < get_block_timestamp() {
                    OracleError::MAX_PRICE_EXCEEDED(
                        report_info.oracle_timestamp, get_block_timestamp()
                    );
                }

                if report_info.min_oracle_block_number < cache.prev_min_oracle_block_number {
                    OracleError::BLOCK_NUMBER_NOT_SORTED(
                        report_info.min_oracle_block_number, cache.prev_min_oracle_block_number
                    );
                }

                cache.prev_min_oracle_block_number = report_info.min_oracle_block_number;

                if get_block_number()
                    - report_info.max_oracle_block_number <= cache.min_block_confirmations {
                    report_info
                        .block_hash = get_block_hash_syscall(report_info.max_oracle_block_number)
                        .unwrap_syscall();
                }   

                report_info.token = *params.tokens.at(i);

                report_info
                    .precision =
                        pow(
                            10,
                            oracle_utils::get_uncompacted_decimal(
                                params.compacted_decimals.span(), i.into()
                            )
                                .try_into()
                                .expect('u128 into u32 failed')
                        );

                report_info
                    .token_oracle_type = data_store
                    .get_felt252(keys::oracle_type_key(report_info.token));

                let mut j = 0;
                let signers_len = signers.len();
                let compacted_min_prices_span = params.compacted_min_prices.span();
                let compacted_max_prices_span = params.compacted_max_prices.span();
                loop {
                    if j == signers_len {
                        break;
                    }
                    inner_cache.price_index = (i * signers_len + j).into();
                    inner_cache
                        .min_prices
                        .append(
                            oracle_utils::get_uncompacted_price(
                                compacted_min_prices_span, inner_cache.price_index
                            )
                        );

                    inner_cache
                        .max_prices
                        .append(
                            oracle_utils::get_uncompacted_price(
                                compacted_max_prices_span, inner_cache.price_index
                            )
                        );
                    if j != 0 {
                        if *inner_cache.min_prices.at(j - 1) > *inner_cache.min_prices.at(j) {
                            OracleError::MIN_PRICES_NOT_SORTED(report_info.token, *inner_cache.min_prices.at(j), *inner_cache.min_prices.at(j - 1));
                        }

                        if *inner_cache.max_prices.at(j - 1) > *inner_cache.max_prices.at(j) {
                            OracleError::MAX_PRICES_NOT_SORTED(report_info.token, *inner_cache.max_prices.at(j), *inner_cache.max_prices.at(j - 1));
                        }
                    }
                    j += 1;
                };

                let compacted_min_indexes_span = params.compacted_min_prices_indexes.span();
                let compacted_max_indexes_span = params.compacted_max_prices_indexes.span();
                let inner_cache_save = @inner_cache;
                let signatures_span = params.signatures.span();
                let signers_span = signers.span();
                let mut j = 0;
                loop {
                    if j == signers_len {
                        break;
                    }

                    inner_cache.signature_index = (i * signers_len + j).into();

                    inner_cache
                        .min_price_index =
                            oracle_utils::get_uncompacted_price_index(
                                compacted_min_indexes_span, inner_cache.signature_index
                            );
                    inner_cache
                        .max_price_index =
                            oracle_utils::get_uncompacted_price_index(
                                compacted_max_indexes_span, inner_cache.signature_index
                            );
                    if inner_cache.signature_index >= signatures_span.len() {
                        OracleError::ARRAY_OUT_OF_BOUNDS_FELT252(
                            signatures_span, inner_cache.signature_index, 'signatures'
                        );
                    }
                    if inner_cache.min_price_index >= inner_cache.min_prices.len().into() {
                        OracleError::ARRAY_OUT_OF_BOUNDS_U128(
                            inner_cache.min_prices.span(), inner_cache.min_price_index, 'min_prices'
                        );
                    }

                    if inner_cache.max_price_index >= inner_cache.max_prices.len().into() {
                        OracleError::ARRAY_OUT_OF_BOUNDS_U128(
                            inner_cache.max_prices.span(), inner_cache.max_price_index, 'max_prices'
                        );
                    }

                    // since minPrices, maxPrices have the same length as the signers array
                    // and the signers array length is less than MAX_SIGNERS
                    // minPriceIndexMask and maxPriceIndexMask should be able to store the indexes
                    // using Uint256Mask
                    validate_unique_and_set_index(
                        ref inner_cache.min_price_index_mask, inner_cache.min_price_index
                    );

                    validate_unique_and_set_index(
                        ref inner_cache.max_price_index_mask, inner_cache.max_price_index
                    );

                    report_info
                        .min_price = *inner_cache
                        .min_prices
                        .at(inner_cache.min_price_index.try_into().expect('array at failed'));

                    report_info
                        .max_price = *inner_cache
                        .max_prices
                        .at(inner_cache.max_price_index.try_into().expect('array at failed'));

                    if report_info.min_price > report_info.max_price {
                        OracleError::INVALID_SIGNER_MIN_MAX_PRICE(
                            report_info.min_price, report_info.max_price
                        );
                    }
                    // oracle_utils::validate_signer(
                    //     self.get_salt(),
                    //     report_info,
                    //     *signatures_span.at(inner_cache.signature_index),
                    //     signers_span.at(j)
                    // );

                    j += 1;
                };

                let median_min_price = arrays::get_median(inner_cache_save.min_prices.span())
                    * report_info.precision;

                let median_max_price = arrays::get_median(inner_cache_save.max_prices.span())
                    * report_info.precision;
                
                let (has_price_feed, ref_price) = self
                    .get_price_feed_price(data_store, report_info.token);

                if has_price_feed {
                    self
                        .validate_ref_price(
                            report_info.token,
                            median_min_price,
                            ref_price,
                            cache.max_ref_price_deviation_factor
                        );

                    self
                        .validate_ref_price(
                            report_info.token,
                            median_max_price,
                            ref_price,
                            cache.max_ref_price_deviation_factor
                        );
                }

                if median_min_price.is_zero() || median_max_price.is_zero() {
                    OracleError::INVALID_ORACLE_PRICE(report_info.token);
                }

                if median_min_price > median_max_price {
                    OracleError::INVALID_MEDIAN_MIN_MAX_PRICE(median_min_price, median_max_price);
                }

                let validated_price = ValidatedPrice {
                    token: report_info.token,
                    min: median_min_price,
                    max: median_max_price,
                    timestamp: report_info.oracle_timestamp,
                    min_block_number: report_info.min_oracle_block_number,
                    max_block_number: report_info.max_oracle_block_number
                };

                cache.validated_prices.append(validated_price);

                i += 1;
            };
            cache.validated_prices
        }

        /// Get the signers
        /// # Arguments
        /// * `data_store` - The data store dispatcher.
        /// * `token` - The token to get the price for.
        /// # Returns
        /// The signers
        fn get_signers_(
            self: @ContractState, data_store: IDataStoreDispatcher, params: @SetPricesParams,
        ) -> Array<ContractAddress> {
            let mut signers: Array<ContractAddress> = array![];

            let signers_len = *params.signer_info & bits::BITMASK_16;
            if signers_len < data_store.get_u128(keys::min_oracle_signers()) {
                OracleError::MIN_ORACLE_SIGNERS(
                    signers_len, data_store.get_u128(keys::min_oracle_signers())
                );
            }

            if signers_len > MAX_SIGNERS {
                OracleError::MAX_ORACLE_SIGNERS(signers_len, MAX_SIGNERS);
            }

            let mut signers_index_mask = Mask { bits: 0 };

            let mut len = 0;
            loop {
                if len == signers_len {
                    break;
                }

                let signer_index: u128 = BitShift::shr(
                    *params.signer_info, (8 + 8 * len) & bits::BITMASK_16
                );

                if signer_index >= MAX_SIGNER_INDEX {
                    OracleError::MAX_SIGNERS_INDEX(signer_index, MAX_SIGNER_INDEX);
                }

                signers_index_mask.validate_unique_and_set_index(signer_index);

                signers
                    .append(
                        self
                            .oracle_store
                            .read()
                            .get_signer(signer_index.try_into().expect('u128 into u32 failed'))
                    );

                if (*signers.at(len.try_into().expect('u128 into u32 failed'))).is_zero() {
                    OracleError::EMPTY_SIGNER(signer_index);
                }

                len += 1;
            };

            signers
        }

        /// Compute a salt for validate_signer().
        /// # Returns
        /// The computed salt.
        fn get_salt(self: @ContractState,) -> felt252 {
            let data: Array<felt252> = array![
                starknet::info::get_tx_info().unbox().chain_id, 'xget-oracle-v1'
            ];
            poseidon_hash_span(data.span())
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
        ) {
            let diff = calc::diff(price, ref_price);

            let diff_factor = precision::to_factor(diff, ref_price);
            if diff_factor > max_ref_price_deviation_factor {
                OracleError::MAX_REFPRICE_DEVIATION_EXCEEDED(
                    token, price, ref_price, max_ref_price_deviation_factor
                );
            }
        }

        /// Set the primary price.
        /// # Arguments
        /// * `token` - The token to set the price for.
        /// * `price` - The price value to set to.
        fn set_primary_price_(ref self: ContractState, token: ContractAddress, price: Price) {
            match self.get_token_with_price_index(token) {
                Option::Some(i) => (),
                Option::None(_) => {
                    self.primary_prices.write(token, price);

                    let mut tokens_with_prices = self.tokens_with_prices.read();
                    let index_of_zero = self.get_token_with_price_index(Zeroable::zero());
                    // If an entry with zero address is found the entry is set to the new token,
                    // otherwise the new token is appended to the list. This is to avoid the list 
                    // to grow indefinitely.
                    match index_of_zero {
                        Option::Some(i) => { tokens_with_prices.set(i, token); },
                        Option::None => { tokens_with_prices.append(token); }
                    }
                }
            }
        }

        /// Remove the primary price.
        /// # Arguments
        /// * `token` - The token to set the price for.
        fn remove_primary_price(ref self: ContractState, token: ContractAddress) {
            self.primary_prices.write(token, Zeroable::zero());

            let token_index = self.get_token_with_price_index(token);
            match token_index {
                Option::Some(i) => {
                    let mut tokens_with_prices = self.tokens_with_prices.read();
                    tokens_with_prices.set(i, Zeroable::zero());
                },
                Option::None => (),
            }
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
            self: @ContractState, data_store: IDataStoreDispatcher, token: ContractAddress,
        ) -> (bool, u128) {
            let token_id = data_store.get_token_id(token);
            if token_id == 0 {
                return (false, 0);
            }
            let response = self.price_feed.read().get_data_median(DataType::SpotEntry(token_id));

            if response.price <= 0 {
                OracleError::INVALID_PRICE_FEED(token, response.price);
            }

            let heart_beat_duration = data_store
                .get_u128(keys::price_feed_heartbeat_duration_key(token));

            let current_timestamp = get_block_timestamp();
            if current_timestamp > response.last_updated_timestamp && current_timestamp
                - response
                    .last_updated_timestamp > heart_beat_duration
                    .try_into()
                    .expect('u128 into u32 failed') {
                OracleError::PRICE_FEED_NOT_UPDATED(
                    token, response.last_updated_timestamp, heart_beat_duration
                );
            }

            let precision_ = self.get_price_feed_multiplier(data_store, token);
            let adjusted_price = precision::mul_div(
                response.price, precision_, precision::FLOAT_PRECISION
            );

            (true, adjusted_price)
        }

        /// Set prices using external price feeds to save costs for tokens with stable prices.
        /// # Arguments
        /// * `data_store` - The data store.
        /// * `event_emitter` - The event emitter.
        /// * `price_feed_tokens` - The tokens to set the prices using the price feeds for.
        fn set_prices_from_price_feeds(
            ref self: ContractState,
            data_store: IDataStoreDispatcher,
            event_emitter: IEventEmitterDispatcher,
            price_feed_tokens: @Array<ContractAddress>,
        ) {
            let self_copy = @self;
            let mut len = 0;

            loop {
                if len == price_feed_tokens.len() {
                    break;
                }

                let token = *price_feed_tokens.at(len);

                let stored_price = self.primary_prices.read(token);
                if !stored_price.is_zero() {
                    OracleError::PRICE_ALREADY_SET(token, stored_price.min, stored_price.max);
                }

                let (has_price_feed, price) = self_copy.get_price_feed_price(data_store, token);

                if (!has_price_feed) {
                    OracleError::EMPTY_PRICE_FEED(token);
                }

                let stable_price = self.get_stable_price(data_store, token);

                let mut price_props: Price = Zeroable::zero();

                if !stable_price.is_zero() {
                    price_props =
                        Price {
                            min: if price < stable_price {
                                price
                            } else {
                                stable_price
                            },
                            max: if price < stable_price {
                                stable_price
                            } else {
                                price
                            }
                        }
                } else {
                    price_props = Price { min: price, max: price }
                }

                self.set_primary_price_(token, price_props);

                self
                    .emit_oracle_price_updated(
                        event_emitter, token, price_props.min, price_props.max, true
                    );
                len += 1;
            };
        }

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
            min_price: u128,
            max_price: u128,
            is_price_feed: bool,
        ) {
            event_emitter.emit_oracle_price_updated(token, min_price, max_price, is_price_feed);
        }

        /// Returns the index of a given `token` in the `tokens_with_prices` list.
        /// # Arguments
        /// * `token` - A `ContractAddress` representing the token whose index we want to find.
        /// # Returns
        /// * `Option<usize>` - Returns `Some(index)` if the token is found.
        ///   Returns `None` if the token is not found.
        fn get_token_with_price_index(
            self: @ContractState, token: ContractAddress
        ) -> Option<usize> {
            let mut tokens_with_prices = self.tokens_with_prices.read();
            let mut index = Option::None;
            let mut len = 0;
            loop {
                if len == tokens_with_prices.len() {
                    break;
                }
                let token_with_price = tokens_with_prices.get(len);
                match token_with_price {
                    Option::Some(t) => {
                        if token_with_price.unwrap() == token {
                            index = Option::Some(len);
                        }
                    },
                    Option::None => (),
                }
                len += 1;
            };
            index
        }
    }
}

