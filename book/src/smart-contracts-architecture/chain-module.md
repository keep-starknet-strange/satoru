## Chain Module

The Chain module provides functionalities to query chain-specific variables. It is designed as a library contract for retrieving the current block number and timestamp.

This module contains the following Cairo library file:

- [chain.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/chain/chain.cairo)

## Functions

### `get_block_number`
Returns the current block number on the Starknet network.

- **Arguments:** None.

- **Returns:** `u64` - The current block number.

### `get_block_timestamp`
Returns the timestamp of the current block on the Starknet network.

- **Arguments:** None.

- **Returns:** `u64` - The timestamp of the current block.

## Errors

This module does not define any custom errors.

## Interface for `Chain`

The `Chain` interface defines the methods to query chain-specific variables like block number and block timestamp. These methods are crucial for contracts that need to interact with or check chain data.

### `IChain<TContractState>`
This interface specifies the methods for querying chain-specific variables.

#### `get_block_number`
Called to retrieve the current block number.

- **Arguments:**
  - `self`: The contract state.

- **Returns:** `u64` - The current block number.

#### `get_block_timestamp`
Called to retrieve the timestamp of the current block.

- **Arguments:**
  - `self`: The contract state.

- **Returns:** `u64` - The timestamp of the current block.

## Usage Example

```cairo
TODO