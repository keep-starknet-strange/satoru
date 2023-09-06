use satoru::utils::u128_mask::validate_unique_and_set_index;
use integer::BoundedInt;


#[test]
fn test_valid_index_bit_not_set() {
    let mut mask = 0b0000_0000;
    validate_unique_and_set_index(ref mask, 3);
    assert(mask == 0b0000_1000, 'mask not set');
}

#[test]
#[should_panic(expected: ('mask index not unique',))]
fn test_valid_index_bit_already_set() {
    let mut mask = 0b0000_1000;
    validate_unique_and_set_index(ref mask, 3);
}

#[test]
#[should_panic(expected: ('mask index out of bounds',))]
fn test_invalid_index() {
    let mut mask = 0b0000_0000;
    validate_unique_and_set_index(ref mask, 128);
}

#[test]
fn test_edge_case_lowest_index() {
    let mut mask = 0b0000_0000;
    validate_unique_and_set_index(ref mask, 0);
    assert(mask == 0b0000_0001, 'mask not set');
}

#[test]
fn test_edge_case_highest_index() {
    let mut mask = 0b1111_1111;
    validate_unique_and_set_index(ref mask, 127);
    assert(mask == 0x800000000000000000000000000000ff, 'highest bit not set')
}
