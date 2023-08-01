use gojo::price::price::{Price, PriceTrait};

#[test]
fn test_mid_price() {
    let price = Price { min: 100, max: 200 };
    assert(price.mid_price() == 150, 'wrong mid price');
}
