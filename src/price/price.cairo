/// Price
#[derive(Copy, Drop)]
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
}

impl PriceImpl of PriceTrait {
    fn mid_price(self: @Price) -> u256 {
        (*self.min + *self.max) / 2
    }
}
