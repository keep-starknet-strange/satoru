// Market struct for markets
//
// Markets support both spot and perp trading, they are created by specifying a
// long collateral token, short collateral token and index token.
//
// Examples:
//
// - ETH/USD market with long collateral as ETH, short collateral as a stablecoin, index token as ETH
// - BTC/USD market with long collateral as WBTC, short collateral as a stablecoin, index token as BTC
// - SOL/USD market with long collateral as ETH, short collateral as a stablecoin, index token as SOL
//
// Liquidity providers can deposit either the long or short collateral token or
// both to mint liquidity tokens.
//
// The long collateral token is used to back long positions, while the short
// collateral token is used to back short positions.
//
// Liquidity providers take on the profits and losses of traders for the market
// that they provide liquidity for.
//
// Having separate markets allows for risk isolation, liquidity providers are
// only exposed to the markets that they deposit into, this potentially allow
// for permissionless listings.
//
// Traders can use either the long or short token as collateral for the market.

use starknet::ContractAddress;
use poseidon::poseidon_hash_span;
use traits::Into;
use array::ArrayTrait;
use gojo::utils::ids::UniqueId;

// Deriving the `storage_access::StorageAccess` trait
// allows us to store the `Market` struct in a contract's storage.
// We use `Copy` but this is inneficient.
// TODO: Optimize this.
#[derive(Drop, Copy, storage_access::StorageAccess, Serde)]
struct Market {
    // Address of the market token for the market.
    market_token: ContractAddress,
    // Address of the index token for the market.
    index_token: ContractAddress,
    // Address of the long token for the market.
    long_token: ContractAddress,
    // Address of the short token for the market.
    short_token: ContractAddress,
}

impl UniqueIdMarket of UniqueId<Market> {
    fn unique_id(self: Market) -> felt252 {
        let mut data = array![];
        data.append(self.market_token.into());
        data.append(self.index_token.into());
        data.append(self.long_token.into());
        data.append(self.short_token.into());
        poseidon_hash_span(data.span())
    }
}
