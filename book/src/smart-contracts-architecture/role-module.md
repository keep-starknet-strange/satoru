# Role module

The role module is responsible for role-based access control.

It contains the following smart contracts:

- [RoleStore](https://github.com/keep-starknet-strange/satoru/blob/main/src/role/role_store.cairo): The main smart contract of the module. It is responsible for storing the roles of the protocol and for managing the access control.

It contains the following Cairo library files:

- [role.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/role/role.cairo): Contains the different roles of the protocol.
- [error.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/role/error.cairo): Contains the error codes of the module.
