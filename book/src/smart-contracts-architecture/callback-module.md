## Callback Module

The Callback module is a part of the Satoru project and manages a two-step process. First, a user sends a request, then a keeper sends another transaction to carry out that request. This module makes it easier to work with other contracts by letting a special contract be specified, which gets called after requests are done or cancelled.

This module contains the following Cairo library files:

- [callback](https://github.com/keep-starknet-strange/satoru/tree/main/src/callback)

## Functions

### `validate_callback_gas_limit`
Validates that the specified `callback_gas_limit` is below a maximum specified value to prevent callback gas limits exceeding the max gas limits per block.

- **Arguments:**
  - `data_store`: The data store to use.
  - `callback_gas_limit`: The callback gas limit.

### `set_saved_callback_contract`
Allows an external entity to associate a callback contract address with a specific account and market.

- **Arguments:**
  - `data_store`: The `DataStore` contract dispatcher.
  - `account`: The account to set callback contract for.
  - `market`: The market to set callback contract for.
  - `callback_contract`: The callback contract address.

### `get_saved_callback_contract`
Retrieves a previously stored callback contract address associated with a given account and market from the data store.

- **Arguments:**
  - `data_store`: The `DataStore` contract dispatcher.
  - `account`: The account to get callback contract for.
  - `market`: The market to get callback contract for.

### function_after_deposit_execution, function_after_deposit_cancellation, function_after_withdrawal_execution, function_after_withdrawal_cancellation, function_after_order_execution, function_after_order_cancellation, and function_after_order_frozen
These functions are callback handlers called after specific actions such as deposit execution, deposit cancellation, withdrawal execution, withdrawal cancellation, order execution, order cancellation, and order frozen respectively.

These functions are callback handlers called after specific actions such as deposit execution, deposit cancellation, withdrawal execution, withdrawal cancellation, order execution, order cancellation, and order frozen respectively.

- **Common Arguments:**
  - `key`: The key of the order/deposit/withdrawal.
  - `order`/`deposit`/`withdrawal`: The order/deposit/withdrawal that was executed/cancelled/frozen.
  - `event_data`: The event log data.
  - `event_emitter`: The event emitter dispatcher.

### `is_valid_callback_contract`
Validates that the given address is a contract.

- **Arguments:**
  - `callback_contract`: The callback contract.

## Errors

### `CallbackError`
This enum encapsulates the error definitions for this module, ensuring that the contract's methods are used correctly and safely.

- `MAX_CALLBACK_GAS_LIMIT_EXCEEDED`: Thrown when the `callback_gas_limit` exceeds the maximum specified value. Error code: `'max_callback_gas_limit_exceeded'`.

## Interface for `DepositCallbackReceiver`

The `DepositCallbackReceiver` interface defines the callback handlers that are triggered after a deposit operation such as execution or cancellation. This interface is crucial for the callback mechanism within the Satoru project, allowing for additional logic to be executed after a deposit operation.

### `IDepositCallbackReceiver<TContractState>`

This interface specifies the methods for handling callbacks after deposit operations.

#### `after_deposit_execution`

Called after a deposit execution.

- **Arguments:**
  - `self`: The contract state.
  - `key`: The key of the deposit.
  - `deposit`: The deposit that was executed.
  - `event_data`: The event log data.

#### `after_deposit_cancellation`

Called after a deposit cancellation.

- **Arguments:**
  - `self`: The contract state.
  - `key`: The key of the deposit.
  - `deposit`: The deposit that was cancelled.
  - `event_data`: The event log data.

## Interface for `OrderCallbackReceiver`

The `OrderCallbackReceiver` interface defines the callback handlers that are triggered after an order operation such as execution, cancellation, or being frozen. This interface is vital for the callback mechanism within the Satoru project, allowing for additional logic to be executed after an order operation.

### `IOrderCallbackReceiver<TContractState>`
This interface specifies the methods for handling callbacks after order operations.

#### `after_order_execution`
Called after an order execution.

- **Arguments:**
  - `self`: The contract state.
  - `key`: The key of the order.
  - `order`: The order that was executed.
  - `event_data`: The event log data.

#### `after_order_cancellation`
Called after an order cancellation.

- **Arguments:**
  - `self`: The contract state.
  - `key`: The key of the order.
  - `order`: The order that was cancelled.
  - `event_data`: The event log data.

#### `after_order_frozen`
Called after an order is frozen.

- **Arguments:**
  - `self`: The contract state.
  - `key`: The key of the order.
  - `order`: The order that was frozen.
  - `event_data`: The event log data.

## Interface for `WithdrawalCallbackReceiver`

The `WithdrawalCallbackReceiver` interface defines the callback handlers that are triggered after a withdrawal operation such as execution or cancellation. This interface is crucial for the callback mechanism within the Satoru project, allowing for additional logic to be executed after a withdrawal operation.

### `IWithdrawalCallbackReceiver<TContractState>`
This interface specifies the methods for handling callbacks after withdrawal operations.

#### `after_withdrawal_execution`
Called after a withdrawal execution.

- **Arguments:**
  - `self`: The contract state.
  - `key`: The key of the withdrawal.
  - `withdrawal`: The withdrawal that was executed.
  - `event_data`: The event log data.

#### `after_withdrawal_cancellation`
Called after a withdrawal cancellation.

- **Arguments:**
  - `self`: The contract state.
  - `key`: The key of the withdrawal.
  - `withdrawal`: The withdrawal that was cancelled.
  - `event_data`: The event log data.

## Usage Example

```cairo
use starknet::ContractAddress;
use satoru::callback::callback;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};

// Assuming data_store, account, market, and callback_contract are already initialized
callback::set_saved_callback_contract(data_store, account, market, callback_contract);

// Retrieving the saved callback contract
let saved_callback_contract = callback::get_saved_callback_contract(data_store, account, market);