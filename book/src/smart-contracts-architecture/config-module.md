# Config Module

The Configuration Module is really important because it lets you manage different settings in the project. You can change and view configurations related to contracts, roles, gas limits, markets, and more. It makes sure everything works within set rules and is crucial for the system to operate properly.

Below is a detailed documentation of the Configuration Module, explaining its structures, types, functions, errors, imports, and a sample usage.

It contains the following Cairo library files:

- [adl.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/config/config.cairo)

## Additional Module: Timelock

Within the system, there's a module named `Timelock` designed to handle functionalities related to time-lock mechanisms. This is crucial for operations that require a predefined time delay for execution, enhancing the security and control over critical operations.

## Structures and Types

### `Storage`

This struct encapsulates the storage fields necessary for the Configuration module, providing interfaces to interact with other contracts and a map to manage allowed base keys.

- `role_store`: An interface to interact with the `RoleStore` contract.
- `data_store`: An interface to interact with the `DataStore` contract.
- `event_emitter`: An interface to interact with the `EventEmitter` contract.
- `allowed_base_keys`: A map to manage the allowed base keys for setting configurations.

## Functions

### `constructor`

This function initializes the `Storage` struct with provided contract addresses and calls `init_allowed_base_keys` function to initialize allowed base keys.

### `set_bool`, `set_address`, `set_felt252`

These functions are implementations of the `IConfig` interface, allowing setting configurations of different data types. They ensure the caller has the `CONFIG_KEEPER` role, validate the base key, compute the full key from the base key and additional data, and set the value in the `DataStore`.

### `init_allowed_base_keys`

This function initializes the map of allowed base keys for setting configurations. It writes true to each base key that is allowed to be set.

### `validate_key`

This function checks that a provided base key is in the list of allowed base keys, throwing `ConfigError::INVALID_BASE_KEY` if it's not.

### `get_full_key`

This function computes the full key from the provided base key and additional data. If there's no additional data, it returns the base key. Otherwise, it computes a Poseidon hash of the concatenated base key and data.

## Errors

### `ConfigError`

This module defines a `ConfigError` to handle configuration-specific errors. Here are the defined errors:

- `INVALID_BASE_KEY`: This error is thrown when a base key provided is not in the list of allowed base keys. It is represented by the constant `'invalid_base_key'` in the `ConfigError` module.

## Usage Example

```cairo
// Example of setting a bool configuration
let base_key = /* ... */;
let data = array![];
let value = true;
Config::set_bool(contract_state, base_key, data, value);