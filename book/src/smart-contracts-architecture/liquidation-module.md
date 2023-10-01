# Liquidation Module

The Liquidation Module is designed to facilitate and manage liquidations within the system, ensuring stability and solvency of the market.

## Overview

This module contains the following Cairo library file:
- [liquidation_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/liquidation/liquidation_utils.cairo): Entrusted with managing liquidations in the network.

## Structures and Types

### `CreateLiquidationOrderParams`

This struct is used within the `create_liquidation_order` function to encapsulate the necessary parameters for creating a liquidation order, thus preventing stack overflow.

- `data_store`: The `DataStore` contract dispatcher providing access to centralized data storage, crucial for storing and retrieving market, position, and order-related information.
- `event_emitter`: The `EventEmitter` contract dispatcher, essential for emitting events on the blockchain and allowing users and other contracts to monitor system changes.
- `account`: Represents the address of the account associated with the position to be liquidated.
- `market`: Specifies the address of the concerned market, aiding in identifying the specific market parameters and states involved.
- `collateral_token`: Represents the address of the token used as collateral for the position, crucial for determining the liquidation impact.
- `is_long`: A boolean indicating whether the position is long or short, defining the nature of the liquidation.

## Functions

### `create_liquidation_order`

This function creates a liquidation order for a specific position, ensuring market stability and solvency. The function returns a `felt252` type representing the key of the created order, where `felt252` is a type representing a 252-bit field element.

## Usage Example

```cairo
// Example of creating a liquidation order
let params = liquidation_utils::CreateLiquidationOrderParams {
    data_store: /* ... */,
    event_emitter: /* ... */,
    account: /* ... */,
    market: /* ... */,
    collateral_token: /* ... */,
    is_long: /* ... */,
};
liquidation_utils::create_liquidation_order(params);