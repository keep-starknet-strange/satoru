use zeroable::Zeroable;

/// Price
#[derive(Copy, Default, starknet::Store, Drop, Serde)]
struct Price {
    /// The minimum price.
    min: u256,
    /// The maximum price.
    max: u256,
}

/// The trait for `Price` struct.
trait PriceTrait {
    /// Get the average of the min and max values
    /// # Arguments
    /// * `self` - The `Price` struct.
    /// # Returns
    /// * The average of the min and max values.
    fn mid_price(self: @Price) -> u256;

    /// Pick either the min or max value.
    /// # Arguments
    /// * `self` - The `Price` struct.
    /// * `maximize` - If true, pick the max value. Otherwise, pick the min value.
    /// # Returns
    /// * The min or max value.
    fn pick_price(self: @Price, maximize: bool) -> u256;

    /// Pick the min or max price depending on wheter it is for a long or a short position,
    /// and whether the pending pnl should be maximized or not.
    /// # Arguments
    /// * `self` - The `Price` struct.
    /// * `is_long` - Whether it is for a long or a short position.
    /// * `maximize` - Whether the pending pnl should be maximized or not.
    /// # Returns
    /// * The min or max price.
    fn pick_price_for_pnl(self: @Price, is_long: bool, maximize: bool) -> u256;
}


impl PriceImpl of PriceTrait {
    fn mid_price(self: @Price) -> u256 {
        (*self.min + *self.max) / 2
    }

    fn pick_price(self: @Price, maximize: bool) -> u256 {
        if maximize {
            *self.max
        } else {
            *self.min
        }
    }

    fn pick_price_for_pnl(self: @Price, is_long: bool, maximize: bool) -> u256 {
        if is_long {
            self.pick_price(maximize)
        } else {
            self.pick_price(!maximize)
        }
    }
}

impl PriceZeroable of Zeroable<Price> {
    fn zero() -> Price {
        Price { min: 0, max: 0 }
    }
    fn is_zero(self: Price) -> bool {
        self.min == 0 && self.max == 0
    }
    fn is_non_zero(self: Price) -> bool {
        !self.is_zero()
    }
}
