use integer::u256_from_felt252;

const HALF_PRIME: felt252 =
    1809251394333065606848661391547535052811553607665798349986546028067936010240;

// Returns the sign of a signed `felt252` as with signed magnitude representation.
// 
// # Arguments
// * `a` - The number to check the sign of.
//
// # Returns
// * `bool` - The sign of the number.
fn felt_sign(a: felt252) -> bool {
    u256_from_felt252(a) > u256_from_felt252(HALF_PRIME)
}

// Returns the absolute value of a signed `felt252`.
//
// # Arguments
// * `a` - The number to get the absolute value of.
//
// # Returns
// * `felt252` - The absolute value of the number.
fn felt_abs(a: felt252) -> felt252 {
    let a_sign = felt_sign(a);

    if a_sign {
        a * -1
    } else {
        a
    }
}
