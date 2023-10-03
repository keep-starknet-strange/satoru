# Router module

The exchange router is the place where users go to start token trades, swaps, and moves.

## Front-running solution

To avoid front-running issues, most actions require two steps to execute:

- User sends transaction with request details, e.g. deposit / withdraw liquidity,
  swap, increase / decrease position.
- Keepers listen for the transactions, include the prices for the request then
  send a transaction to execute the request.

## Oracle keepers

Prices are provided by an off-chain oracle system:

- Oracle keepers continually check the latest blocks.
- When there is a new block, oracle keepers fetch the latest prices from
  reference exchanges.
- Oracle keepers then sign the median price for each token together with
  the block hash.
- Oracle keepers then send the data and signature to archive nodes.
- Archive nodes display this information for anyone to query.

### Example

- Block 100 is finalized on the blockchain.
- Oracle keepers observe this block.
- Oracle keepers pull the latest prices from reference exchanges,
  token A: price 20,000, token B: price 80,000.
- Oracle keepers sign [chainId, blockhash(100), 20,000], [chainId, blockhash(100), 80,000].
- If in block 100, there was a market order to open a long position for token A,
  the market order would have a block number of 100.
- The prices signed at block 100 can be used to execute this order.
- Order keepers would bundle the signature and price data for token A
  then execute the order.

It contains the following smart contracts:

- [Router](https://github.com/keep-starknet-strange/satoru/blob/main/src/router/router.cairo): Users will approve this router for token expenditures.
- [ExchangeRouter](https://github.com/keep-starknet-strange/satoru/blob/main/src/router/exchange_router.cairo): Router for exchange functions, supports functions which require token transfers from the user.