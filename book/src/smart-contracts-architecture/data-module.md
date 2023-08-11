# Data module

The data module is reponsible for storing and managing the data of the protocol.

It contains the following smart contracts:

[DataStore](https://github.com/keep-starknet-strange/gojo/blob/main/src/data/data_store.cairo): The main smart contract of the module. It is responsible for storing the data of the protocol.

It contains the following Cairo library files:

- [keys.cairo](https://github.com/keep-starknet-strange/gojo/blob/main/src/data/keys.cairo): Contains functions to generate the keys (entries in the data store) of the protocol.
