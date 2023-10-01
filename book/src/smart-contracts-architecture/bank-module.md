# Bank Module (Token Handling)

This module helps to store and move tokens within a contract. It's crucial for a bigger project, letting you do basic bank tasks like starting the contract and sending tokens to a receiver.

It contains the following Cairo library files:

- [bank.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/bank/bank.cairo)

## Structures

### `Storage`
This struct houses the interface to interact with the `DataStore` contract, which is essential for the storage of data within the contract.

- `data_store`: An instance of `IDataStoreDispatcher` providing the necessary methods to interact with the `DataStore` contract.

## Interface

### `IBank<TContractState>`
This interface defines the contract's structure and methods. The generic `TContractState` allows for a flexible contract state definition.

- `initialize`: This method sets up the contract with the necessary addresses for the data store and role store contracts.
- `transfer_out`: A method to facilitate the transfer of tokens from this contract to a specified receiver.

## Implementation

### `Bank` Module
This module provides the implementation for the `IBank` interface and additional helper methods necessary for the contract's functionality.

#### `constructor`
This is the constructor method for the contract, which calls the `initialize` method to set up the contract's state.

#### `BankImpl` of `IBank<ContractState>`
This implementation provides the methods defined in the `IBank` interface.

- `initialize`: Ensures the contract is not already initialized, sets up the role module, and writes the data store address to the contract's state.
- `transfer_out`: Ensures the caller is a controller before proceeding to call the internal method for token transfer.

#### `BankHelperImpl` of `BankHelperTrait`
This implementation provides additional helper methods for the contract.

- `transfer_out_internal`: Checks that the receiver is not this contract itself, then performs the token transfer using the `transfer` method from `token_utils`.

## StrictBank Module
The StrictBank module extends the functionalities of the Bank module by implementing a sync function to update token balances, which can be particularly useful in scenarios of token burns or similar balance changes.

### Interface

#### `IStrictBank<TContractState>`
This interface extends the `IBank` interface and includes an additional method for syncing token balances.

- `sync_token_balance`: Updates the `token_balances` in case of token burns or similar balance changes. This function returns the new balance of the specified token.

### Implementation

#### `StrictBank` of `IStrictBank<ContractState>`
This implementation provides the methods defined in the `IStrictBank` interface. It relies on the `Bank` module for `initialize` and `transfer_out` methods, while providing a custom implementation for `sync_token_balance` method which currently returns a placeholder value of `0`.

## Errors

### `BankError`
This enum encapsulates the error definitions for this contract, ensuring that the contract's methods are used correctly and safely.

- `ALREADY_INITIALIZED`: Thrown if an attempt is made to initialize the contract when it's already initialized. Error code: `'already_initialized'`.
- `SELF_TRANSFER_NOT_SUPPORTED`: Thrown if an attempt is made to transfer tokens to the contract itself. Error code: `'self_transfer_not_supported'`.
- `TOKEN_TRANSFER_FAILED`: Thrown if a token transfer operation fails. Error code: `'token_transfer_failed'`.

## Usage Example

Here's a simplified example demonstrating how to initialize and interact with the `Bank` contract in Cairo:

```cairo
use starknet::{ContractAddress, contract_address_const};
use satoru::bank::bank::{IBankDispatcherTrait, IBankDispatcher};

// Deploying the Bank contract
let bank_contract = declare('Bank');
let constructor_calldata = array![data_store_contract_address.into(), role_store_contract_address.into()];
let bank_contract_address = bank_contract.deploy(@constructor_calldata).unwrap();
let bank_dispatcher = IBankDispatcher { contract_address: bank_contract_address };

// Transferring tokens using the Bank contract
let receiver_address: ContractAddress = 0x202.try_into().unwrap();
bank_dispatcher.transfer_out(erc20_contract_address, receiver_address, 100_u128);