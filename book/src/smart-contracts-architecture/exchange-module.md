# Exchange Module

The Exchange module contains the core functionalities of the Satoru protocol, handling the creation, execution, and cancellation of various actions.

## Smart Contracts

The module comprises the following smart contracts:

- [AdlHandler](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/adl_handler.cairo): This contract manages the ADL (Automatic Deleveraging) process.
- [BaseOrderHandler](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/base_order_handler.cairo): A base contract encapsulating shared functionalities for order handling.
- [DepositHandler](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/deposit_handler.cairo): Manages the creation, execution, and cancellation of deposit requests.
- [LiquidationHandler](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/liquidation_handler.cairo): Handles the liquidation process.
- [OrderHandler](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/order_handler.cairo): Manages the creation, execution, and cancellation of orders.
- [WithdrawalHandler](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/withdrawal_handler.cairo): Handles the creation, execution, and cancellation of withdrawal requests.

## Libraries

The module also includes the following library files for utility and error handling:

- [error.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/error.cairo): Contains the module's error codes encapsulated as `ExchangeError`.
- [exchange_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/withdrawal_event_utils.cairo): Provides request validation utility functions.