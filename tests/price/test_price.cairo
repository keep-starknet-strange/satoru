use satoru::price::price::{Price, PriceTrait};

#[test]
fn test_mid_price() {
    let price = Price { min: 100, max: 200 };
    assert(price.mid_price() == 150, 'wrong mid price');
}

#[test]
fn test_pick_price() {
    let price = Price { min: 100, max: 200 };
    assert(price.pick_price(false) == 100, 'wrong pick price');
    assert(price.pick_price(true) == 200, 'wrong pick price');
}

#[test]
fn test_pick_price_for_pnl() {
    let price = Price { min: 100, max: 200 };
    assert(price.pick_price_for_pnl(true, true) == 200, 'wrong pick price');
    assert(price.pick_price_for_pnl(true, false) == 100, 'wrong pick price');
    assert(price.pick_price_for_pnl(false, true) == 100, 'wrong pick price');
    assert(price.pick_price_for_pnl(false, false) == 200, 'wrong pick price');
}
