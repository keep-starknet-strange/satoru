# Auto-Deleveraging (ADL) Module

The ADL Module helps with automatic reduction of leverage in specific markets. This is particularly important for markets where the main token is different from the long token, like a STRK / USD perpetual market where ETH is the long token.

It contains the following Cairo library files:

- [adl.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/adl/adl_utils.cairo)

## Structures and Types

### `CreateAdlOrderParams`

This struct is utilized within the `create_adl_order` function to encapsulate parameters needed for the order creation, aiding in avoiding stack overflow.

- `data_store`: The `DataStore` contract dispatcher which provides access to a centralized data storage, used for storing and retrieving information about markets, positions, orders, etc.
- `event_emitter`: The `EventEmitter` contract dispatcher utilized for emitting events on the blockchain, allowing users and other contracts to track changes in the system.
- `account`: The address of the account whose position is to be reduced. In the ADL context, this typically means closing profitable positions to maintain system solvency.
- `market`: Address of the concerned market. Each market may have its own parameters and states, and this address helps identify the specific market to be dealt with.
- `collateral_token`: The address of the token used as collateral for the position. For instance, it's ETH in a STRK/USD market as per the given example.
- `is_long`: Indicates whether the position is long or short. A long position benefits from a price increase in the market, while a short position benefits from a price decrease.
- `size_delta_usd`: The size of the position to be reduced, expressed in US Dollars. This specifies how much of the position should be reduced to maintain system solvency.
- `updated_at_block`: The block number at which the order was updated. This tracks when the ADL order was last created or modified.

## Functions

### `update_adl_state`

Checks the pending profit state and updates an `isAdlEnabled` flag to avoid repeatedly validating whether auto-deleveraging is required. It uses an oracle to fetch market prices and emits an `adl_state_updated` event to notify about the state change. The function also updates the latest ADL block to the current block number to ensure that the ADL status is associated with the most recent data.

### `create_adl_order`

Constructs an ADL order to reduce a profitable position. The function returns a `felt252` type representing the key of the created order, where `felt252` is a type representing a 252-bit field element.

### `validate_adl`

Validates if the requested ADL can be executed by checking the ADL enabled state and ensuring the oracle block numbers are recent enough.

### `get_latest_adl_block`, `set_latest_adl_block`

These functions interact with the `data_store` to retrieve and update the latest ADL block number respectively. `get_latest_adl_block` returns the latest block number at which the ADL flag was updated, and `set_latest_adl_block` sets the latest block number to a new value.

### `get_adl_enabled`, `set_adl_enabled`

Interact with the `data_store` to get and set the ADL enabled state for a specified market and position type (long/short).

### `emit_adl_state_updated`

Emits ADL state update events to notify about changes in the ADL state, including the market, position type, PnL to pool factor, max PnL factor, and whether ADL was enabled or disabled.

## Errors

The module defines an `AdlError` to handle ADL-specific errors. Each constant in the `AdlError` module represents a specific error case in the ADL module. Here are the defined errors:

- `ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED`: This error is thrown when the block numbers from the oracle are smaller than required. It ensures that the data being used is recent enough to be reliable.
  
- `INVALID_SIZE_DELTA_FOR_ADL`: Triggered when the size of the position to be reduced is invalid, for example, if it's larger than the current position size. It ensures that the ADL order size is valid and can be executed.

- `ADL_NOT_ENABLED`: This error occurs if an ADL operation is attempted when ADL is not enabled for the specified market. It serves as a guard to prevent unwanted ADL operations.

- `POSITION_NOT_VALID`: Thrown when a position is not valid, for instance, if it doesn't exist or has already been closed. This error ensures that the position associated with the ADL order is valid and open.

### Others
- Additional utility modules are imported for array operations, error handling, and callback utilities to support various functionalities within the ADL module.

## Usage Example

```cairo
// Example of creating an ADL order
let params = adl_utils::CreateAdlOrderParams {
    data_store: /* ... */,
    event_emitter: /* ... */,
    account: /* ... */,
    market: /* ... */,
    collateral_token: /* ... */,
    is_long: /* ... */,
    size_delta_usd: /* ... */,
    updated_at_block: /* ... */,
};
adl_utils::create_adl_order(params);