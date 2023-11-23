//! Market struct for markets.
//!
//! Markets support both spot and perp trading, they are created by specifying a
//! long collateral token, short collateral token and index token.
//!
//! Examples:
//!
//! - ETH/USD market with long collateral as ETH, short collateral as a stablecoin, index token as ETH
//! - BTC/USD market with long collateral as WBTC, short collateral as a stablecoin, index token as BTC
//! - SOL/USD market with long collateral as ETH, short collateral as a stablecoin, index token as SOL
//!
//! Liquidity providers can deposit either the long or short collateral token or
//! both to mint liquidity tokens.
//!
//! The long collateral token is used to back long positions, while the short
//! collateral token is used to back short positions.
//!
//! Liquidity providers take on the profits and losses of traders for the market
//! that they provide liquidity for.
//!
//! Having separate markets allows for risk isolation, liquidity providers are
//! only exposed to the markets that they deposit into, this potentially allow
//! for permissionless listings.
//!
//! Traders can use either the long or short token as collateral for the market.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use poseidon::poseidon_hash_span;


use zeroable::Zeroable;

// Local imports.
use satoru::market::error::MarketError;
use satoru::market::market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait};

/// Deriving the `storage_access::Store` trait
/// allows us to store the `Market` struct in a contract's storage.
/// We use `Copy` but this is inneficient.
/// TODO: Optimize this.
#[derive(Drop, Copy, starknet::Store, Serde, PartialEq)]
struct Market {
    /// Address of the market token for the market.
    market_token: ContractAddress,
    /// Address of the index token for the market.
    index_token: ContractAddress,
    /// Address of the long token for the market.
    long_token: ContractAddress,
    /// Address of the short token for the market.
    short_token: ContractAddress,
}

impl DefaultMarket of Default<Market> {
    fn default() -> Market {
        Market {
            market_token: Zeroable::zero(),
            index_token: Zeroable::zero(),
            long_token: Zeroable::zero(),
            short_token: Zeroable::zero()
        }
    }
}

// *************************************************************************
//                      Market traits.
// *************************************************************************

/// Trait for getting the `MarketToken` contract interface of a market.
/// TODO: Use proper `Into` trait.
trait IntoMarketToken {
    /// Returns the `MarketToken` contract interface of the market.
    /// # Arguments
    /// * `self` - The market.
    /// # Returns
    /// * The `MarketToken` contract interface of the market.
    fn market_token(self: Market) -> IMarketTokenDispatcher;
}

/// Trait for getting the unique id of a market.
trait UniqueIdMarket {
    /// Returns the unique id of the market, computed based on the market's parameters.
    /// # Arguments
    /// * `self` - The market.
    /// * `market_type` - The type of the market, either spot or perp.
    /// # Returns
    /// * The unique id of the market.
    fn unique_id(self: Market, market_type: felt252) -> felt252;
}

/// Trait for validating a market.
trait ValidateMarket {
    /// Returns true if the market is valid, false otherwise.
    /// # Arguments
    /// * `self` - The market.
    /// # Returns
    /// * True if the market is valid, false otherwise.
    fn is_valid(self: Market) -> bool;

    /// Asserts that the market is valid.
    /// # Arguments
    /// * `self` - The market.
    /// # Revert
    /// * If the market is not valid.
    fn assert_valid(self: Market);
}

// *************************************************************************
//                      Implementations of Market traits.
// *************************************************************************

/// Implementation of the `UniqueIdMarket` trait for the `Market` struct.
impl UniqueIdMarketImpl of UniqueIdMarket {
    fn unique_id(self: Market, market_type: felt252) -> felt252 {
        let mut data = array![];
        data.append(self.market_token.into());
        data.append(self.index_token.into());
        data.append(self.long_token.into());
        data.append(self.short_token.into());
        data.append(market_type);
        poseidon_hash_span(data.span())
    }
}

/// Implementation of the `ValidateMarket` trait for the `Market` struct.
impl ValidateMarketImpl of ValidateMarket {
    fn is_valid(self: Market) -> bool {
        self.market_token != self.index_token
            && self.market_token != self.long_token
            && self.market_token != self.short_token
            && self.market_token.is_non_zero()
            && self.index_token.is_non_zero()
            && self.long_token.is_non_zero()
            && self.short_token.is_non_zero()
    }

    fn assert_valid(self: Market) {
        assert(self.is_valid(), MarketError::INVALID_MARKET_PARAMS);
    }
}

/// Implementation of the `MarketToken` trait for the `Market` struct.
impl MarketTokenImpl of IntoMarketToken {
    fn market_token(self: Market) -> IMarketTokenDispatcher {
        IMarketTokenDispatcher { contract_address: self.market_token }
    }
}
