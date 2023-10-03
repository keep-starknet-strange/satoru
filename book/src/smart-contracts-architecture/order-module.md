# Order Module

The Order Module is key for handling orders in the system. It’s important for changing, processing, and looking after orders.

## Overview

This module centralizes the logic related to orders, managing various aspects including processing increasing and decreasing orders, structuring orders, and providing utilities for common order-related operations. Its design allows developers to interact with, modify, or extend the functionalities with ease and precision.

## Smart Contracts

- [OrderVault.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/order/order_vault.cairo): Acts as a secure vault for orders, ensuring their safe storage and accessibility.

## Cairo Library Files

### [base_order_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/order/base_order_utils.cairo)
A collection of essential functions facilitating common order-related operations, enhancing code reusability and organization.

### [decrease_order_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/order/decrease_order_utils.cairo)
Contains functions aiding in the processing of decreasing orders, ensuring their accurate and efficient handling.

### [increase_order_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/order/increase_order_utils.cairo)
Comprises functions to assist in processing increasing orders, maintaining precision and efficiency in operations.

### [order.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/order/order.cairo)
Defines the structure for orders, serving as a blueprint for order objects within the system.

### [order_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/order/order_utils.cairo)
Encompasses various order-related functions, offering utilities to streamline order processing and management.

## Detailed Structure and Types

### `Order`
- Represents the blueprint for creating order objects, defining the properties and characteristics of an order within the system.

#### Properties
- **key**: A unique identifier of the order of type `felt252`.
- **order_type**: Specifies the type of order from the enumerated `OrderType`.
- **decrease_position_swap_type**: Specifies the type of swap for decreasing position orders from the enumerated `DecreasePositionSwapType`.
- **account**: The account of the user creating the order, represented as a `ContractAddress`.
- **receiver**: The receiver for any token transfers, represented as a `ContractAddress`.
- **callback_contract**: The contract to call for callbacks, represented as a `ContractAddress`.
- **ui_fee_receiver**: The UI fee receiver, represented as a `ContractAddress`.
- **market**: The trading market's contract address.
- **initial_collateral_token**: The initial collateral token for increase orders, represented as a `ContractAddress`.
- **swap_path**: An array of market addresses to swap through.
- **size_delta_usd**: The requested change in position size, represented as `u128`.
- **initial_collateral_delta_amount**: Represents different amounts based on the order, either the amount of the initialCollateralToken sent in by the user for increase orders, the amount of the position's collateralToken to withdraw for decrease orders, or the amount of initialCollateralToken sent in for the swap, represented as `u128`.
- **trigger_price**: The trigger price for non-market orders, represented as `u128`.
- **acceptable_price**: The acceptable execution price for increase/decrease orders, represented as `u128`.
- **execution_fee**: The execution fee for keepers, represented as `u128`.
- **callback_gas_limit**: The gas limit for the callbackContract, represented as `u128`.
- **min_output_amount**: The minimum output amount for decrease orders and swaps, represented as `u128`.
- **updated_at_block**: The block at which the order was last updated, represented as `u64`.
- **is_long**: Boolean flag indicating whether the order is for a long or short.
- **is_frozen**: Boolean flag indicating whether the order is frozen.

### Enumerations
#### `OrderType`
Enumerates the various types of orders that can be created in the system, including MarketSwap, LimitSwap, MarketIncrease, LimitIncrease, MarketDecrease, LimitDecrease, StopLossDecrease, and Liquidation.

#### `DecreasePositionSwapType`
Indicates whether the decrease order should swap the pnl token to collateral token or vice versa, with possible values being NoSwap, SwapPnlTokenToCollateralToken, and SwapCollateralTokenToPnlToken.

#### `SecondaryOrderType`
Further differentiates orders, with possible values being None and Adl.

## Core Functionalities and Methods

### `touch`
Updates the `updated_at_block` property of the order to the current block number.

### `OrderTypeInto`
Converts the enumerated `OrderType` to a `felt252` type.

### `OrderTypePrintImpl`
Prints the corresponding string representation of the `OrderType`.

### `SecondaryOrderTypePrintImpl`
Prints the corresponding string representation of the `SecondaryOrderType`.

### `DecreasePositionSwapTypePrintImpl`
Prints the corresponding string representation of the `DecreasePositionSwapType`.

### `DefaultOrder`
Provides a default implementation for creating a new `Order` instance with default values.

## Errors

The module delineates specific error cases to manage anomalies and invalid operations related to orders, ensuring seamless execution of order operations and facilitating troubleshooting and debugging.