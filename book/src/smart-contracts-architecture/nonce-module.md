# Nonce Module

The Nonce Module keeps track of a number that goes up one at a time, which is crucial for creating unique keys. This is really important to make sure every operation in the system is unique.

It contains the following smart contract:

- [NonceUtils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/nonce/nonce_utils.cairo): The principal smart contract in the module, responsible for sustaining an incrementing nonce value crucial for key generation.

## Structures and Types

### `IDataStoreDispatcher`
- The dispatcher for `DataStore` contract provides methods to interact with the centralized data storage, essential for storing and retrieving nonce-related information.

## Functions

### `get_current_nonce`
- Retrieves the current nonce value from the data store.
- **Arguments:**
  - `data_store`: The data store to use.
- **Returns:**
  - The current nonce value.

### `increment_nonce`
- Increments the current nonce value in the data store.
- **Arguments:**
  - `data_store`: The data store to use.
- **Returns:**
  - The new nonce value.

### `get_next_key`
- Computes a `felt252` hash using the next nonce and can also use the nonce directly as a key.
- **Arguments:**
  - `data_store`: The data store to use.
- **Returns:**
  - The `felt252` hash using the next nonce value.

## Core Logic

### `compute_key`
- Computes a key using the provided `data_store_address` and `nonce`.
- **Arguments:**
  - `data_store_address`: The address of the data store.
  - `nonce`: The nonce value.
- **Returns:**
  - A `felt252` key.

## Errors

The module defines specific errors to handle nonce-specific anomalies and invalid operations, ensuring smooth and accurate operations within the module. 

## Usage Example

```cairo
// Example of getting the next key
let data_store: IDataStoreDispatcher = /* ... */;
let next_key: felt252 = nonce_utils::get_next_key(data_store);