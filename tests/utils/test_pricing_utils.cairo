use satoru::pricing::pricing_utils::{
    apply_impact_factor, get_price_impact_usd_for_same_side_rebalance,
    get_price_impact_usd_for_crossover_rebalance
};
// *************************************************************************
//                  Tests for apply_impact_factor function
// *************************************************************************
#[test]
fn test_apply_impact_factor_zero() { //TODO finish this test and add others test once apply_exponent_factor is implemented
    // assert(apply_impact_factor(0, 0, 0) == 0, 'should be 0');
    assert(1 == 1, '');
}

// *************************************************************************
//       Tests for get_price_impact_usd_for_same_side_rebalance function
// *************************************************************************
#[test]
fn test_get_price_impact_usd_for_same_side_rebalance_positive_impact() { //TODO finish this test and add others test once apply_exponent_factor is implemented
    //assert(get_price_impact_usd_for_same_side_rebalance(x, y, z, k) == r, 'should be r');
    assert(1 == 1, '');
}


// *************************************************************************
//       Tests for get_price_impact_usd_for_crossover_rebalance function
// *************************************************************************
#[test]
fn test_get_price_impact_usd_for_crossover_side_rebalance_positive_impact() { //TODO finish this test and add others test once apply_exponent_factor is implemented
    //assert(get_price_impact_usd_for_crossover_rebalance(x, y, z, k) == r, 'should be r');
    assert(1 == 1, '');
}

#[test]
fn test_get_price_impact_usd_for_crossover_side_rebalance_negative_impact() { //assert(get_price_impact_usd_for_crossover_rebalance(x, y, z, k) == r, 'should be r');
    assert(1 == 1, '');
}
