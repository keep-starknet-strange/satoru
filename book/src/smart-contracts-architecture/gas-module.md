# Gas Module

The Gas Module is developed to manage execution fee estimations and payments within the system.

This module comprises the following Cairo library files:
- [GasUtils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/gas/gas_utils.cairo): Entrusted with the responsibility for execution fee estimation and payments.

## Structures and Types

### `ContractAddress`
- A specialized type representing the address of a contract within the Starknet network.

## Functions

### `get_min_handle_execution_error_gas`
- **Objective:** Retrieve the minimal gas required to handle execution errors from the data store.

### `get_execution_gas`
- **Objective:** Validate that the starting gas is higher than the minimum handle execution gas and return the remaining gas after subtracting the minimum handle error gas.

### `pay_execution_fee`
- **Objective:** Pays the execution fee to the keeper and refunds any excess amount to the refund receiver.

### `validate_execution_fee`
- **Objective:** Validate that the provided execution fee is sufficient based on the estimated gas limit.

### `adjust_gas_usage`
- **Objective:** Adjust the gas usage to ensure keepers are paid a nominal amount.

### `adjust_gas_limit_for_estimate`
- **Objective:** Adjust the estimated gas limit to ensure the execution fee is sufficient during the actual execution.

### `estimate_execute_deposit_gas_limit`, `estimate_execute_withdrawal_gas_limit`, `estimate_execute_order_gas_limit`
- **Objective:** Estimate the gas limits for deposits, withdrawals, and orders respectively based on different parameters.

### `pay_execution_fee_deposit`
- **Objective:** Pay the deposit execution fee to the keeper and refund any excess amount to the refund receiver. It is specifically designed to handle deposit transactions.

### `estimate_execute_increase_order_gas_limit`, `estimate_execute_decrease_order_gas_limit`, `estimate_execute_swap_order_gas_limit`
- **Objective:** Estimate the gas limits for increase orders, decrease orders, and swap orders respectively, based on different parameters.

## Errors

### `GasError`
- **INSUFF_EXEC_GAS (`'insufficient_gas_for_execute'`):** Triggered when the starting gas is less than the minimum required to handle execution errors.
- **INSUFF_EXEC_FEE (`'insufficient_execution_fee'`):** Occurs when the provided execution fee is less than the minimum execution fee calculated based on the estimated gas limit.