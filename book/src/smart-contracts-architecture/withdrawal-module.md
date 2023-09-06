# Withdrawal module

The withdrawal module is responsible for managing withdrawals.

It contains the following smart contracts:

- [WithdrawalVault](https://github.com/keep-starknet-strange/satoru/blob/main/src/withdrawal/withdrawal_vault.cairo): Vault for withdrawals.

It contains the following Cairo library files:

- [error.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/withdrawal/error.cairo): Contains the error codes of the module.
- [withdrawal_event_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/withdrawal/withdrawal_event_utils.cairo): Contains functions to generate events.
- [withdrawal_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/withdrawal/withdrawal_utils.cairo): Contains withdrawal utility functions.
- [withdrawal.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/withdrawal/withdrawal.cairo): Contains withdrawal struct.
