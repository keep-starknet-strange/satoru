# Mock module

The Mock module is used to store mocked implementation of contracts to use them in tests.

It contains the following Cairo library files:

- [error.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/mock/error.cairo): Contains the error codes of the module.

It contains the following smart contracts:

- [ReferralStorage.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/mock/referral_stoage.cairo): Set and Get of functions for managing referral-related data and operations.
- [Governable.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/referral/governable.cairo): Referral storage for testing and testnets
