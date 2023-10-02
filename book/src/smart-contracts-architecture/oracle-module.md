# Oracle Module

The purpose of the oracle module is to validate and store signed values.

## Price representation in Oracle

Representing the prices in this way allows for conversions between token amounts
and fiat values to be simplified, e.g. to calculate the fiat value of a given
number of tokens the calculation would just be: `token amount * oracle price`,
to calculate the token amount for a fiat value it would be: `fiat value oracle price`.

The trade-off of this simplicity in calculation is that tokens with a small USD
price and a lot of decimals may have precision issues it is also possible that
a token's price changes significantly and results in requiring higher precision.

### Example 1

The price of ETH is 5000, and ETH has 18 decimals.

The price of one unit of ETH is `5000 (10 ^ 18), 5 * (10 ^ -15)`.

To handle the decimals, multiply the value by `(10 ^ 30)`.

Price would be stored as `5000 (10 ^ 18) * (10 ^ 30) => 5000 * (10 ^ 12)`.

For gas optimization, these prices are sent to the oracle in the form of a uint8
decimal multiplier value and uint32 price value.

If the decimal multiplier value is set to 8, the uint32 value would be `5000 * (10 ^ 12) (10 ^ 8) => 5000 * (10 ^ 4)`.

With this config, ETH prices can have a maximum value of `(2 ^ 32) (10 ^ 4) => 4,294,967,296 (10 ^ 4) => 429,496.7296` with 4 decimals of precision.

### Example 2

The price of BTC is 60,000, and BTC has 8 decimals.

The price of one unit of BTC is `60,000 (10 ^ 8), 6 * (10 ^ -4)`.

Price would be stored as `60,000 (10 ^ 8) * (10 ^ 30) => 6 * (10 ^ 26) => 60,000 * (10 ^ 22)`.

BTC prices maximum value: `(2 ^ 32) (10 ^ 2) => 4,294,967,296 (10 ^ 2) => 42,949,672.96`.

Decimals of precision: 2.

### Example 3

The price of USDC is 1, and USDC has 6 decimals.

The price of one unit of USDC is `1 (10 ^ 6), 1 * (10 ^ -6)`.

Price would be stored as `1 (10 ^ 6) * (10 ^ 30) => 1 * (10 ^ 24)`.

USDC prices maximum value: `(2 ^ 64) (10 ^ 6) => 4,294,967,296 (10 ^ 6) => 4294.967296`.

Decimals of precision: 6.

### Example 4

The price of DG is 0.00000001, and DG has 18 decimals.

The price of one unit of DG is `0.00000001 (10 ^ 18), 1 * (10 ^ -26)`.

Price would be stored as `1 * (10 ^ -26) * (10 ^ 30) => 1 * (10 ^ 3)`.

DG prices maximum value: `(2 ^ 64) (10 ^ 11) => 4,294,967,296 (10 ^ 11) => 0.04294967296`.

Decimals of precision: 11.

### Decimal Multiplier

The formula to calculate what the decimal multiplier value should be set to:

Decimals: 30 - (token decimals) - (number of decimals desired for precision)

- ETH: 30 - 18 - 4 => 8
- BTC: 30 - 8 - 2 => 20
- USDC: 30 - 6 - 6 => 18
- DG: 30 - 18 - 11 => 1.


### Oracle primary and secondary price

It is possible to update the oracle to support a primary_price and a secondary_price
which would allow for stop-loss orders to be executed at exactly the trigger_price

However, this may lead to gaming issues, an example:
- The current price is $2020
- A user has a long position and creates a stop-loss decrease order for < $2010
- If the order has a swap from ETH to USDC and the user is able to cause the order
to be frozen / unexecutable by manipulating state or otherwise
- Then if price decreases to $2000, and the user is able to manipulate state such that
the order becomes executable with $2010 being used as the price instead
- Then the user would be able to perform the swap at a higher price than should possible

Additionally, using the exact order's trigger_price could lead to gaming issues during times
of volatility due to users setting tight stop-losses to minimize loss while betting on a
directional price movement, fees and price impact should help a bit with this, but there
still may be some probability of success

The order keepers can use the closest oracle price to the trigger_price for execution, which
should lead to similar order execution prices with reduced gaming risks

If an order is frozen, the frozen order keepers should use the most recent price for order
execution instead

---

It contains the following files:

- [oracle_modules.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/oracle/oracle_modules.cairo): Modifiers for oracles.
- [oracle_store.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/oracle/oracle_modules.cairo): Storage for oracles.
- [oracle_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/oracle/oracle_utils.cairo): Contains utility structs and functions for Oracles.
- [oracle.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/oracle/oracle_modules.cairo): Main oracle smart contract.