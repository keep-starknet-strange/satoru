# Deposit Module

The deposit module contains main Satoru functions for deposit, to manage the depositing of liquidity into a market.

It contains the following Cairo library files:

- [deposit_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/deposit/deposit_utils.cairo): Library for deposit functions, to help with the depositing of liquidity into a market in return for market tokens.
- [deposit.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/deposit/deposit.cairo): Contains Deposit struct.
- [execute_deposit_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/deposit/execute_deposit_utils.cairo): Library for deposit functions, to help with the depositing of liquidity into a market in return for market tokens.

## Structures and Types

### `CreateDepositParams`

This struct is utilized within the `create_deposit` function to encapsulate parameters needed for the deposit creation.

- `receiver`: The address to send the market tokens to.
- `callback_contract`: The callback contract linked to this deposit.
- `ui_fee_receiver`: The UI fee receiver.
- `market`: The market to deposit into.
- `initial_long_token`: The initial long token address.
- `initial_short_token`: The initial short token address.
- `long_token_swap_path`: The swap path into markets for the long token.
- `short_token_swap_path`: The swap path into markets for the short token.
- `min_market_tokens`: The minimum acceptable number of liquidity tokens.
- `execution_fee`: The execution fee for keepers.
- `callback_gas_limit`: The gas limit for the `callback_contract`.

### `Deposit`

A structure to represent a deposit in the system, containing information such as the addresses of the tokens, amounts deposited, and parameters of the concerned market.

### `DepositError`

Module for deposit-specific error operations.

- `DEPOSIT_NOT_FOUND`: Deposit not found.
- `DEPOSIT_INDEX_NOT_FOUND`: Deposit index not found.
- `CANT_BE_ZERO`: Can't be zero.
- `EMPTY_DEPOSIT_AMOUNTS`: Empty deposit amounts.
- `EMPTY_DEPOSIT`: Empty deposit.

## Functions

### `create_deposit`

Creates a deposit with the specified parameters, recording the transfer of initial tokens and validating the swap paths.

### `cancel_deposit`

Cancels a deposit, funds are sent back to the user.

### `execute_deposit`

Executes a deposit according to the provided parameters. (Function to be developed)

### `swap`

Performs a token swap according to the provided parameters. (Function to be developed)

## Contracts

### `DepositVault`

The `DepositVault` contract provides functions to initialize the contract, transfer tokens out of the contract, and record a token transfer into the contract.

## Usage Example

```cairo
// Example of creating a deposit
let params = CreateDepositParams {
    receiver: /* ... */,
    callback_contract: /* ... */,
    ui_fee_receiver: /* ... */,
    market: /* ... */,
    initial_long_token: /* ... */,
    initial_short_token: /* ... */,
    long_token_swap_path: /* ... */,
    short_token_swap_path: /* ... */,
    min_market_tokens: /* ... */,
    execution_fee: /* ... */,
    callback_gas_limit: /* ... */,
};

let key = create_deposit(
    data_store,
    event_emitter,
    deposit_vault,
    account,
    params
);