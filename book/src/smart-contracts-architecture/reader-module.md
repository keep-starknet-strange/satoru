# Reader Module

The Reader Module gets market data and is like a utility library for trading. It’s especially important for markets that need lots of calculations and data for operating and evaluating the market.

## Cairo Library Files

The module contains the following Cairo files:
- [reader_pricing_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/reader/reader_pricing_utils.cairo): Utility functions for trading price calculations, impact, and fees.
- [reader_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/reader/reader_utils.cairo): External utility functions for trading operations.
- [reader.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/reader/reader.cairo): Library for reading and calculating financial market data and trading operations.