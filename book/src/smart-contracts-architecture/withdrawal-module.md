# Withdrawal Module

The Withdrawal Module role is to manage the operations related to withdrawals.

## Smart Contracts

### [WithdrawalVault](https://github.com/keep-starknet-strange/satoru/blob/main/src/withdrawal/withdrawal_vault.cairo)
The WithdrawalVault is the vault specifically designed for withdrawals, ensuring the secure management of funds during the withdrawal processes.

## Cairo Library Files

- [error.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/withdrawal/error.cairo): Holds the module-specific error codes.
- [withdrawal_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/withdrawal/withdrawal_utils.cairo): Encapsulates withdrawal-related utility functions.
- [withdrawal.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/withdrawal/withdrawal.cairo): Defines the structures related to withdrawal.

### Withdrawal Creation and Execution
In this module, withdrawals can be created through the `create_withdrawal` function, which needs parameters such as the account initiating the withdrawal, the receiver of the tokens, and various other details related to the withdrawal.

Execution of withdrawals is handled by the `execute_withdrawal` function, requiring parameters such as the unique identifier of the withdrawal and the event emitter used to emit events.

### Swap Mechanism
The module includes a `swap` function, used to swap tokens within the context of executing withdrawals, ensuring the internal state changes are correct before calling external callbacks.

## Structures and Types

### `Storage`
This structure holds the interface to interact with the `DataStore` contract.
- `strict_bank`: Represents the interface to interact with the `IStrictBankDispatcher`.

### `Withdrawal`
This structure represents a withdrawal within the system, holding essential information related to a specific withdrawal operation. The structure includes the following fields:
- `key`: A unique identifier of the withdrawal, represented as a `felt252` type.
- `account`: The account of the order, represented as a `ContractAddress`.
- `receiver`: The receiver for any token transfers, represented as a `ContractAddress`.
- `callback_contract`: The contract to call for callbacks, represented as a `ContractAddress`.
- `ui_fee_receiver`: The UI fee receiver, represented as a `ContractAddress`.
- `market`: The trading market, represented as a `ContractAddress`.
- `long_token_swap_path`: An array of market addresses to swap through for long tokens, represented as a `Span32<ContractAddress>`.
- `short_token_swap_path`: An array of market addresses to swap through for short tokens, represented as a `Span32<ContractAddress>`.
- `market_token_amount`: The amount of market tokens that will be withdrawn, represented as a `u128` type.
- `min_long_token_amount`: The minimum amount of long tokens that must be withdrawn, represented as a `u128` type.
- `min_short_token_amount`: The minimum amount of short tokens that must be withdrawn, represented as a `u128` type.
- `updated_at_block`: The block at which the withdrawal was last updated, represented as a `u64` type.
- `execution_fee`: The execution fee for the withdrawal, represented as a `u128` type.
- `callback_gas_limit`: The gas limit for calling the callback contract, represented as a `u128` type.

### `Balance`
Represents the balance of an asset and includes the following fields:
- `amount`: The total amount of the asset, represented as a `u128` type.
- `locked`: The amount of the asset that is locked, represented as a `u128` type.

### `Asset`
This structure represents an asset within the system and includes the following fields:
- `symbol`: The symbol of the asset, represented as a string.
- `decimals`: The number of decimals the asset uses, represented as a `u8` type.
- `total_supply`: The total supply of the asset, represented as a `u128` type.

### Other Structures
- `CreateWithdrawalParams`: Holds parameters needed for creating a withdrawal, such as the receiver and the market on which the withdrawal will be executed.
- `ExecuteWithdrawalParams`: Holds parameters needed for executing a withdrawal, such as the data store where withdrawal data is stored and the unique identifier of the withdrawal to execute.
- `ExecuteWithdrawalCache`: Utilized to cache the results temporarily when executing a withdrawal.
- `ExecuteWithdrawalResult`: Represents the result of a withdrawal execution, holding details of the output token and its amount.
- `SwapCache`: Holds data related to token swap operations, such as the swap path markets and the output token and its amount.

## Functions

### `initialize`
This function is utilized to initialize the contract with the address of the strict bank contract.

### `record_transfer_in`
Records the transfer in operation and returns a `u128` type representing the recorded value.

### `transfer_out`
Executes the transfer out operation to the specified receiver with the defined amount.

### `sync_token_balance`
Synchronizes the token balance and returns a `u128` type representing the synchronized value.

## Errors

The module employs `WithdrawalError` to address errors inherent to withdrawal operations. Here are the defined errors:
- `ALREADY_INITIALIZED`: Triggered if the contract has already been initialized, represented by the constant `'already_initialized'`.
- `NOT_FOUND`: Triggered when a specified withdrawal is not found in the system, represented by the constant `'withdrawal not found'`.
- `CANT_BE_ZERO`: Triggered when a withdrawal account is zero, represented by the constant `'withdrawal account cant be 0'`.
- `EMPTY_WITHDRAWAL_AMOUNT`: Occurs when an attempt is made to withdraw an empty amount, represented by the constant `'empty withdrawal amount'`.
- `EMPTY_WITHDRAWAL`: Occurs when a withdrawal is empty, represented by the constant `'empty withdrawal'`.

Additionally, the module defines several panic functions to handle specific error scenarios with more context:
- `INSUFFICIENT_FEE_TOKEN_AMOUNT(data_1: u128, data_2: u128)`: Triggered when there is an insufficient amount of fee tokens, providing additional context with `data_1` and `data_2`.
- `INSUFFICIENT_MARKET_TOKENS(data_1: u128, data_2: u128)`: Triggered when there are insufficient market tokens available, providing additional context with `data_1` and `data_2`.
- `INVALID_POOL_VALUE_FOR_WITHDRAWAL(data: u128)`: Triggered when an invalid pool value is provided for withdrawal, providing additional context with `data`.
- `INVALID_WITHDRAWAL_KEY(data: felt252)`: Triggered when an invalid withdrawal key is provided, providing additional context with `data`.