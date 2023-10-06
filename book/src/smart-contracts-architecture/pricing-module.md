# Pricing module

The pricing module is responsible for functions linked to price computations.

## Price impact

Price impact is calculated as:

```
(initial imbalance) ^ (price impact exponent) * (price impact factor / 2) - (next imbalance) ^ (price impact exponent) * (price impact factor / 2)
```

For spot actions (deposits, withdrawals, swaps), imbalance is calculated as the
difference in the worth of the long tokens and short tokens.

For example:

- A pool has 10 long tokens, each long token is worth $5000
- The pool also has 50,000 short tokens, each short token is worth $1
- The `price impact exponent` is set to 2 and `price impact factor` is set
  to `0.01 / 50,000`
- The pool is equally balanced with $50,000 of long tokens and $50,000 of
  short tokens
- If a user deposits 10 long tokens, the pool would now have $100,000 of long
  tokens and $50,000 of short tokens
- The change in imbalance would be from $0 to -$50,000
- There would be negative price impact charged on the user's deposit,
  calculated as `0 ^ 2 * (0.01 / 50,000) - 50,000 ^ 2 * (0.01 / 50,000) => -$500`
- If the user now withdraws 5 long tokens, the balance would change
  from -$50,000 to -$25,000, a net change of +$25,000
- There would be a positive price impact rebated to the user in the form of
  additional long tokens, calculated as `50,000 ^ 2 * (0.01 / 50,000) - 25,000 ^ 2 * (0.01 / 50,000) => $375`

For position actions (increase / decrease position), imbalance is calculated
as the difference in the long and short open interest.

`price impact exponents` and `price impact factors` are configured per market
and can differ for spot and position actions.

The purpose of the price impact is to help reduce the risk of price manipulation,
since the contracts use an oracle price which would be an average or median price
of multiple reference exchanges. Without a price impact, it may be profitable to
manipulate the prices on reference exchanges while executing orders on the contracts.

This risk will also be present if the positive and negative price impact values
are similar, for that reason the positive price impact should be set to a low
value in times of volatility or irregular price movements.

It contains the following Cairo library files:

- [position_pricing_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/pricing/position_pricing_utils.cairo): Library for position pricing functions.
- [pricing_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/pricing/pricing_utils.cairo): Library for pricing functions.
- [swap_pricing_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/pricing/swap_pricing_utils.cairo): Library for pricing functions linked to swaps.