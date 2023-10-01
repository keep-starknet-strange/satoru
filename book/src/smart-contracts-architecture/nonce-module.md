# Nonce Module

The Nonce Module is pivotal in maintaining a progressively increasing nonce value, a critical element in the generation of unique keys. This module is fundamental for ensuring the uniqueness of transactions and order operations within the system.

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

## Imports

The module imports several libraries and modules to facilitate its functionalities. Here are the imports along with a brief description:

### Core Library Imports
- `starknet`: A core library providing foundational functionalities required for StarkNet contracts such as handling contract addresses.
- `poseidon`: A library used for hashing operations within the module.

### Local Imports from `satoru` project
- `data_store`: Module for data storage functionalities, essential for storing and retrieving nonce-related information.
- `keys`: Module containing utilities related to key operations.

## Usage Example

```cairo
// Example of getting the next key
let data_store: IDataStoreDispatcher = /* ... */;
let next_key: felt252 = nonce_utils::get_next_key(data_store);