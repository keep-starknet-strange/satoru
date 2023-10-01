# Fee Module

The Fee Module takes care of everything related to fees. It’s crucial for moving and claiming fees in specific markets.

The module incorporates the following components:
- [FeeHandler.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/fee/fee_handler.cairo): The nucleus of the module, entrusted with initializing the contract and claiming fees from identified markets.
- [fee_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/fee/fee_utils.cairo): A collection of utility functions vital for orchestrating fee actions and interactions such as claiming and incrementing fees.
- [error.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/fee/error.cairo): A repository of error codes and messages related to fee operations, essential for accurate error handling and resolution.

## Structures and Types

### `FeeHandler`

The `FeeHandler` struct is pivotal within the module, managing the interactions and executions of fee-related functions, ensuring the integrity of fee transfers and claims.

- `data_store`: The `DataStore` contract dispatcher, a centralized repository for data storage, crucial for retrieving and storing information related to markets, positions, orders, etc.
- `role_store`: The `RoleStore` contract dispatcher, responsible for managing roles and permissions within the system.
- `event_emitter`: The `EventEmitter` contract dispatcher, vital for emitting events and notifications within the blockchain, allowing the tracking of system alterations.

## Functions

### `initialize`
- **Objective:** Initialize the FeeHandler contract with essential components like `DataStore`, `RoleStore`, and `EventEmitter`.

### `claim_fees`
- **Objective:** Execute fee claims from specified markets for given tokens.

## Error Handling
### `FeeError`
- **ALREADY_INITIALIZED:** Triggered when there is an attempt to initialize an already initialized contract.
- **INVALID_CLAIM_FEES_INPUT:** Occurs when the lengths of the market and tokens arrays do not match during a fee claim operation.