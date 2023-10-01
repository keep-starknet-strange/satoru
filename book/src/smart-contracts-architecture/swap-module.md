# Swap Module

The Swap Module is integral for performing token swaps in the system. It enables the exchange of one token for another within specified market conditions, adjusting for various factors such as price impact and fees.

## Smart Contracts

- [SwapHandler](https://github.com/keep-starknet-strange/satoru/blob/main/src/swap/swap_handler): This contract is responsible for handling swaps, ensuring that only authorized entities can invoke the swap function. It validates the swap parameters and interacts with the `swap_utils` to perform the swap.

## Cairo Library Files

- [swap_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/swap/swap_utils.cairo): Implements the logic for performing swaps, including validating markets, calculating price impacts, applying fees, and transferring tokens.
  
- [error.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/swap/error.cairo): Defines errors specific to the Swap Module, handling cases like insufficient output amount, invalid input token, and duplicated market in swap path.

## Structures and Types

### `SwapParams`
This struct is used to pass parameters needed for executing a swap. It includes fields like:
- `data_store`: Provides access to on-chain data storage.
- `event_emitter`: Enables the emission of events.
- `oracle`: Provides access to price data from oracles.
- `bank`: Provides the funds for the swap.
- `token_in`: The address of the token being swapped.
- `amount_in`: The amount of the token being swapped.
- `swap_path_markets`: An array specifying the markets in which the swap should be executed.
- `min_output_amount`: The minimum amount of tokens that should be received as part of the swap.
- `receiver`: The address where the swapped tokens should be sent.

### `SwapCache`
This struct caches data during a swap operation, including token addresses, prices, amounts, and price impacts.

## Functions

### `swap`
Executes a swap based on the given `SwapParams`, returning the address of the received token and the amount of the received token. It handles edge cases, such as zero amount in or empty swap path markets, and applies the swap to single or multiple markets as specified in the `swap_path_markets`.

### `_swap`
Performs a swap on a single market, dealing with various conditions like token validity, price impact, and fees, and returns the token and amount that were swapped.

## Errors

### `SwapError`
Handles errors like:
- `INSUFFICIENT_OUTPUT_AMOUNT`: Triggered when the output amount is less than the minimum specified.
- `INVALID_TOKEN_IN`: Raised when the input token is not valid.
- `SWAP_PRICE_IMPACT_EXCEEDS_AMOUNT_IN`: Occurs when the price impact is more than the amount in.
- `DUPLICATED_MARKET_IN_SWAP_PATH`: Triggered when there is a duplicate market in the swap path.

### Core Library Imports
- **starknet**: Provides foundational functionalities required for StarkNet contracts, such as handling contract addresses.
- **core::integer::I128Neg**: Provides functionalities for handling signed 128-bit integers.

### Local Imports from `satoru` project
- **satoru::data::data_store**: Module for data storage functionalities.
- **satoru::event::event_emitter**: Module for emitting events on the blockchain.
- **satoru::bank::bank**: Provides access to the funds for the swap.
- **satoru::oracle::oracle**: Module for fetching market price data.
- **satoru::market::market_utils**: Contains utilities related to market operations.
- **satoru::fee::fee_utils**: Contains utilities for handling fees.
- **satoru::pricing::swap_pricing_utils**: Handles the pricing aspects during a swap.

### Others
This module also imports several other modules and libraries for error handling, array operations, and more to support its functionalities.

## Usage Example

```cairo
let params = swap_utils::SwapParams {
    data_store: /* ... */,
    event_emitter: /* ... */,
    oracle: /* ... */,
    bank: /* ... */,
    key: /* ... */,
    token_in: /* ... */,
    amount_in: /* ... */,
    swap_path_markets: /* ... */,
    min_output_amount: /* ... */,
    receiver: /* ... */,
    ui_fee_receiver: /* ... */,
};
swap_utils::swap(params);
