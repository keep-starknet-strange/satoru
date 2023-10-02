# Market Module

The Market Module helps with trading in different markets. It lets you create markets by choosing specific tokens. This module supports both regular and ongoing trading.

Example markets include:

- ETH/USD: Long collateral as ETH, short collateral as a stablecoin, index token as ETH.
- BTC/USD: Long collateral as WBTC, short collateral as a stablecoin, index token as BTC.
- STRK/USD: Long collateral as ETH, short collateral as a stablecoin, index token as STRK.

In each market, liquidity providers can deposit either the long or the short collateral token, or both, to mint liquidity tokens. The module allows for risk isolation by exposing liquidity providers only to the markets they deposit into, enabling potentially permissionless listings.

It contains the following Cairo library files:

- [market.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/market/market.cairo) 

## Structures and Types

### `Market`

This struct represents a market with the following fields:

- `market_token`: Address of the market token for the market.
- `index_token`: Address of the index token for the market.
- `long_token`: Address of the long token for the market.
- `short_token`: Address of the short token for the market.

## Functions and Traits

### `IntoMarketToken`

This trait provides a method to get the `MarketToken` contract interface of a market.

### `UniqueIdMarket`

This trait provides a method to compute the unique id of a market based on its parameters.

### `ValidateMarket`

This trait provides methods to validate a market, either by returning a boolean value or by asserting the validity.

## Implementations

### `UniqueIdMarketImpl`

This is the implementation of the `UniqueIdMarket` trait for the `Market` struct, providing a method to compute the unique id of a market.

### `ValidateMarketImpl`

This is the implementation of the `ValidateMarket` trait for the `Market` struct, offering methods to validate the market's state.

### `MarketTokenImpl`

This is the implementation of the `IntoMarketToken` trait for the `Market` struct, providing the `MarketToken` contract interface of a market.

## Errors

The module incorporates a `MarketError` enum to manage market-specific errors, primarily to handle cases involving invalid market parameters. Each constant in the `MarketError` module represents a specific error case in the market module. Here are the defined errors:

- **`MARKET_NOT_FOUND`**: Triggered when the specified market cannot be located within the system.
- **`DIVISOR_CANNOT_BE_ZERO`**: Raised when an attempt is made to divide by zero.
- **`INVALID_MARKET_PARAMS`**: Occurs when the parameters provided for the market are invalid.
- **`OPEN_INTEREST_CANNOT_BE_UPDATED_FOR_SWAP_ONLY_MARKET`**: This error is triggered when there is an attempt to update open interest for a swap-only market.
- **`MAX_OPEN_INTEREST_EXCEEDED`**: Occurs when the maximum open interest for a market is surpassed.
- **`EMPTY_ADDRESS_IN_MARKET_TOKEN_BALANCE_VALIDATION`**: Raised when an empty address is found during market token balance validation.
- **`EMPTY_ADDRESS_TOKEN_BALANCE_VAL`**: Triggered when an empty address is discovered during token balance validation.
- **`INVALID_MARKET_TOKEN_BALANCE`**: Occurs when the market token balance is found to be invalid.
- **`INVALID_MARKET_TOKEN_BALANCE_FOR_COLLATERAL_AMOUNT`**: This error is raised when the market token balance for a collateral amount is invalid.
- **`INVALID_MARKET_TOKEN_BALANCE_FOR_CLAIMABLE_FUNDING`**: Triggered when the market token balance for claimable funding is invalid.
- **`EmptyAddressInMarketTokenBalanceValidation`**: Occurs when an empty address is encountered during market token balance validation.
- **`INVALID_POSITION_MARKET`**: Raised when the market for a position is invalid.
- **`INVALID_COLLATERAL_TOKEN_FOR_MARKET`**: Triggered when an invalid collateral token is provided for the market.
- **`EMPTY_MARKET`**: Occurs when the market is found to be empty.
- **`DISABLED_MARKET`**: Triggered when the market is disabled.

Additionally, there is a function `UNABLE_TO_GET_CACHED_TOKEN_PRICE` which panics with a specific message when it is unable to get the cached token price for a given token.

## Usage Example

```cairo
let market = Market {
    market_token: /* ContractAddress of the market token */,
    index_token: /* ContractAddress of the index token */,
    long_token: /* ContractAddress of the long token */,
    short_token: /* ContractAddress of the short token */,
};

// Asserting that the market is valid
market.assert_valid();
// Getting the MarketToken contract interface of the market
let market_token_dispatcher = market.market_token();