# Position Module

The purpose of the position module is to help with management of positions.

## Fees in position

Borrowing fees for position require only a borrowing_factor to track. An example on how this works is if the global cumulative_borrowing_factor is 10020% a position would be opened with borrowingFactor as 10020%. After some time, if the cumulative\_\_borrowing_factor is updated to 10025% the position would owe 5% of the position size as borrowing fees. The total pending borrowing fees of all positions is factored into the calculation of the pool value for LPs. When a position is increased or decreased, the pending borrowing fees for the position is deducted from the position's
collateral and transferred into the LP pool.

The same borrowing fee factor tracking cannot be applied for funding fees as those calculations consider pending funding fees based on the fiat value of the position sizes.

For example, if the price of the long_token is $2000 and a long position owes $200 in funding fees, the opposing short position claims the funding fees of 0.1 longToken ($200), if the price of the longToken changes to $4000 later, the long position would only owe 0.05 longToken ($200). This would result in differences between the amounts deducted and amounts paid out, for this reason, the actual token amounts to be deducted and to be paid out need to be tracked instead.

For funding fees, there are four values to consider:

1. long positions with market.long_token as collateral.
2. long positions with market.short_token as collateral.
3. short positions with market.long_token as collateral.
4. short positions with market.short_token as collateral.

---

It contains the following files:

- [decrease_position_collateral_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/position/decrease_position_collateral_utils.cairo): Library for functions to help with the calculations when decreasing a position.
- [decrease_position_swap_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/position/decrease_position_swap_utils.cairo): Library for functions related to decrease of position involving swaps.
- [decrease_position_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/position/decrease_position_utils.cairo): Library for functions to help with decreasing a position.
- [increase_position_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/position/increase_position_utils.cairo): Library for functions to help with increasing a position.
- [position_event_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/position/position_event_utils.cairo): Library with helper functions to emit position related events.
- [position_utils.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/position/position_utils.cairo): Library with various utility functions for positions.
- [position.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/position/position.cairo): Contains main Position struct.
