# Price Module

The Price Module helps manage everything related to prices. It organizes how to handle lowest and highest prices and makes working with these prices easier.

## Cairo Library Files

### [price.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/price/price.cairo)
Defines the `Price` struct and associated methods, serving as a utility to streamline price-related operations in contracts.

## Structures and Types

### `Price`

This struct holds the minimum and maximum prices and provides a set of methods to perform various operations using these prices.

- **min**: The minimum price, represented as `u128`.
- **max**: The maximum price, represented as `u128`.

## Trait and Implementations

### `PriceTrait`

This trait defines a set of methods that can be performed on a `Price` struct.

#### Methods

- **mid_price**:
  - Returns the average of the min and max values of the `Price` struct.
  - Arguments:
    - `self`: The `Price` struct.
  - Returns: The average of the min and max values as `u128`.

- **pick_price**:
  - Picks either the min or max value based on the `maximize` parameter.
  - Arguments:
    - `self`: The `Price` struct.
    - `maximize`: If true, picks the max value. Otherwise, picks the min value.
  - Returns: The min or max value as `u128`.

- **pick_price_for_pnl**:
  - Picks the min or max price depending on whether it is for a long or short position, and whether the pending pnl should be maximized or not.
  - Arguments:
    - `self`: The `Price` struct.
    - `is_long`: Whether it is for a long or a short position.
    - `maximize`: Whether the pending pnl should be maximized or not.
  - Returns: The min or max price as `u128`.

### `PriceImpl`

This implementation block provides concrete implementations for the methods defined in the `PriceTrait` for a `Price` struct.

### `PriceZeroable`

This implementation block provides methods to create a zero `Price` struct and check whether a `Price` struct is zero or non-zero.

#### Methods

- **zero**:
  - Returns a `Price` struct with min and max values set to 0.
  - Returns: A zero `Price` struct.

- **is_zero**:
  - Checks whether the `Price` struct is zero.
  - Arguments:
    - `self`: The `Price` struct.
  - Returns: A boolean value indicating whether the `Price` struct is zero.

- **is_non_zero**:
  - Checks whether the `Price` struct is non-zero.
  - Arguments:
    - `self`: The `Price` struct.
  - Returns: A boolean value indicating whether the `Price` struct is non-zero.