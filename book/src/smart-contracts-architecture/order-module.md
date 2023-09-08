# Order module

The order module is reponsible for the vault order, functions related to orders.

It contains the following smart contracts:

- [OrderVault](https://github.com/keep-starknet-strange/satoru/blob/main/src/order/order_vault.cairo): Vault for orders

It contains the following Cairo library files:

- [base_order_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/order/base_order_utils.cairo): This library comprises a collection of frequently used order-related functions, designed to facilitate common operations.

- [decrease_order_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/order/decrease_order_utils.cairo): Library for functions to help with processing a decrease order.

- [order.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/order/order.cairo): Struct for orders
