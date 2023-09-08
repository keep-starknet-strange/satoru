use satoru::utils::precision;

#[test]
fn test_apply_factor_u128() {
    // Test avec des valeurs positives
    assert_eq!(apply_factor_u128(10_000, 2_000), 20_000);
    assert_eq!(apply_factor_u128(100, 3), 300);
    
    // Test avec des valeurs nulles
    assert_eq!(apply_factor_u128(0, 2_000), 0);
    assert_eq!(apply_factor_u128(100, 0), 0);
    
    // Test avec des valeurs négatives
    assert_eq!(apply_factor_u128(-10_000, 2_000), -20_000);
    assert_eq!(apply_factor_u128(100, -3), -300);
}

#[test]
fn test_apply_factor_i128() {
    // Test avec des valeurs positives et négatives
    assert(apply_factor_i128(10_000, 2_000), 20_000);
    assert(apply_factor_i128(-10_000, 2_000), -20_000);
    assert(apply_factor_i128(10_000, -2_000), -20_000);
    
    // Test avec des valeurs nulles
    assert(apply_factor_i128(0, 2_000), 0);
    assert(apply_factor_i128(100, 0), 0);
}

#[test]
fn test_apply_factor_roundup_magnitude() {
    // Test avec des valeurs positives
    assert(apply_factor_roundup_magnitude(10_000, 2_000, true), 20_000);
    assert(apply_factor_roundup_magnitude(10_000, 2_000, false), 20_000);
    
    // Test avec des valeurs nulles
    assert(apply_factor_roundup_magnitude(0, 2_000, true), 0);
    assert(apply_factor_roundup_magnitude(100, 0, false), 0);
    
    // Test avec des valeurs négatives
    assert(apply_factor_roundup_magnitude(-10_000, 2_000, true), -20_000);
    assert(apply_factor_roundup_magnitude(10_000, -2_000, false), -20_000);
}

#[test]
fn test_mul_div() {
    // Test case 1: Basic multiplication and division
    let value1: u128 = 10;
    let numerator1: u128 = 3;
    let denominator1: u128 = 2;
    let result1 = mul_div(value1, numerator1, denominator1);
    assert(result1, 15);

    // Test case 2: Division by zero should panic
    let value2: u128 = 5;
    let numerator2: u128 = 2;
    let denominator2: u128 = 0;
    // In this case, the function should panic with "Division by 0"
    // assert!(std::panic::catch_unwind(|| mul_div(value2, numerator2, denominator2)).is_err());

    // Test case 3: Large values
    let value3: u128 = u128::MAX;
    let numerator3: u128 = 2;
    let denominator3: u128 = 3;
    let result3 = mul_div(value3, numerator3, denominator3);
    assert(result3, 170_550_156_503_850_974_095_668_916_586_433);

    // Test case 4: Zero value should always return zero
    let value4: u128 = 0;
    let numerator4: u128 = 123;
    let denominator4: u128 = 456;
    let result4 = mul_div(value4, numerator4, denominator4);
    assert(result4, 0);
}