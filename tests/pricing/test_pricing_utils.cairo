use satoru::pricing::pricing_utils;

const E20: u128 = 100_000_000_000_000_000_000;
const _3: u128 = 300_000_000_000_000_000_000;
const _2: u128 = 200_000_000_000_000_000_000;
const _1_5: u128 = 150_000_000_000_000_000_000;
const _1_75: u128 = 175_000_000_000_000_000_000;
const _0_001: u128 = 100_000_000_000_000_000;
const _0_0001: u128 = 10_000_000_000_000_000;
const _0_000001: u128 = 1_000_000_000_000;
const _0_0000000000001: u128 = 100_000_000;

#[test]
fn given_good_parameters_when_apply_impact_factor_then_works() {
    // make sure it works for really big values
    assert(
        pricing_utils::apply_impact_factor(
            10000 * E20, 1 * _0_0000000000001, _3
        ) == 100000000000000000000,
        'wrong impact factor 1'
    );
    assert(
        pricing_utils::apply_impact_factor(
            100000 * E20, _0_0000000000001, _3
        ) == 100000000000000000000000,
        'wrong impact factor 2'
    );
    assert(
        pricing_utils::apply_impact_factor(
            1000000 * E20, _0_0000000000001, _3
        ) == 100000000000000000000000000,
        'wrong impact factor 3'
    );
    assert(
        pricing_utils::apply_impact_factor(
            1000000 * E20, E20, _3
        ) == 100000000000000000000000000000000000000,
        'wrong impact factor 4'
    );

    assert(
        pricing_utils::apply_impact_factor(10000 * E20, _0_000001, _2) == 100000000000000000000,
        'wrong impact factor 5'
    );
    assert(
        pricing_utils::apply_impact_factor(100000 * E20, _0_000001, _2) == 10000000000000000000000,
        'wrong impact factor 6'
    );

    assert(
        pricing_utils::apply_impact_factor(
            1000000 * E20, _0_000001, _2
        ) == 1000000000000000000000000,
        'wrong impact factor 7'
    );
    assert(
        pricing_utils::apply_impact_factor(
            10000000 * E20, _0_000001, _2
        ) == 100000000000000000000000000,
        'wrong impact factor 8'
    );

    assert(
        pricing_utils::apply_impact_factor(10000 * E20, _0_000001, _1_75) == 9999999516460977028,
        'wrong impact factor 11'
    );
    assert(
        pricing_utils::apply_impact_factor(100000 * E20, _0_000001, _1_75) == 562341305085252697579,
        'wrong impact factor 12'
    );
    assert(
        pricing_utils::apply_impact_factor(
            1000000 * E20, _0_000001, _1_75
        ) == 31622775559765743614174,
        'wrong impact factor 13'
    );
    assert(
        pricing_utils::apply_impact_factor(
            10000000 * E20, _0_000001, _1_75
        ) == 1778279359983305772602558,
        'wrong impact factor 14'
    );

    // and for small values
    assert(
        pricing_utils::apply_impact_factor(_0_0000000000001, _0_000001, _1_5) == 0,
        'wrong impact factor 15'
    );
    assert(
        pricing_utils::apply_impact_factor(_0_001, _0_000001, _1_5) == 0, 'wrong impact factor 16'
    );
    assert(
        pricing_utils::apply_impact_factor(1 * E20, _0_000001, _1_5) == 1000000000000,
        'wrong impact factor 17'
    );
    assert(
        pricing_utils::apply_impact_factor(1000 * E20, _0_000001, _1_5) == 31622777689150255,
        'wrong impact factor 18'
    );
    assert(
        pricing_utils::apply_impact_factor(10000 * E20, _0_000001, _1_5) == 999999958558642276,
        'wrong impact factor 19'
    );
    assert(
        pricing_utils::apply_impact_factor(100000 * E20, _0_000001, _1_5) == 31622775633373054686,
        'wrong impact factor 20'
    );
    assert(
        pricing_utils::apply_impact_factor(1000000 * E20, _0_000001, _1_5) == 999999971754659821919,
        'wrong impact factor 21'
    );
    assert(
        pricing_utils::apply_impact_factor(
            10000000 * E20, _0_000001, _1_5
        ) == 31622775838897949974052,
        'wrong impact factor 22'
    );

    assert(
        pricing_utils::apply_impact_factor(10000 * E20, _0_0001, E20) == 100000000000000000000,
        'wrong impact factor 23'
    );
    assert(
        pricing_utils::apply_impact_factor(100000 * E20, _0_0001, E20) == 1000000000000000000000,
        'wrong impact factor 24'
    );
    assert(
        pricing_utils::apply_impact_factor(1000000 * E20, _0_0001, E20) == 10000000000000000000000,
        'wrong impact factor 25'
    );
    assert(
        pricing_utils::apply_impact_factor(
            10000000 * E20, _0_0001, E20
        ) == 100000000000000000000000,
        'wrong impact factor 26'
    );
}

