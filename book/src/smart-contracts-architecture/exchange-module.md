# Exchange module

The exchange module contains main satoru handlers to create and execute actions.

It contains the following smart contracts:

- [AdlHandler](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/adl_handler.cairo): Contract to handle adl.
- [BaseOrderHandler](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/base_order_handler.cairo): Base contract for shared order handler functions.
- [DepositHandler](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/deposit_handler.cairo): Contract to handle creation, execution and cancellation of deposits.
- [LiquidationHandler](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/liquidation_handler.cairo): Contract to handle liquidation.
- [OrderHandler](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/order_handler.cairo): Contract to handle creation, execution and cancellation of orders.
- [WithdrawalHandler](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/withdrawal_handler.cairo): Contract to handle creation, execution and cancellation of withdrawals.

It contains the following Cairo library files:

- [error.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/error.cairo): Contains the error codes of the module.
- [exchange_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/exchange/withdrawal_event_utils.cairo): Contains request validation utility function.
