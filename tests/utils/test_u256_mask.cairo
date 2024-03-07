use satoru::utils::u256_mask::validate_unique_and_set_index;
use integer::BoundedInt;
use debug::PrintTrait;

#[test]
fn given_valid_index_bit_not_set_when_validate_unique_and_set_index_then_works() {
    let mut mask = 0b0000_0000;
    validate_unique_and_set_index(ref mask, 3);
    assert(mask == 0b0000_1000, 'mask not set');
}

#[test]
#[should_panic(expected: ('mask index not unique',))]
fn given_valid_index_bit_already_set_when_validate_unique_and_set_index_then_fails() {
    let mut mask = 0b0000_1000;
    validate_unique_and_set_index(ref mask, 3);
}

#[test]
#[should_panic(expected: ('mask index out of bounds',))]
fn given_invalid_index_when_validate_unique_and_set_index_then_fails() {
    let mut mask = 0b0000_0000;
    validate_unique_and_set_index(ref mask, 256);
}

#[test]
fn given_edge_case_lowest_index_when_validate_unique_and_set_index_then_works() {
    let mut mask = 0b0000_0000;
    validate_unique_and_set_index(ref mask, 0);
    assert(mask == 0b0000_0001, 'mask not set');
}

#[test]
fn given_edge_case_highest_index_when_validate_unique_and_set_index_then_works() {
    let mut mask = 0b1111_1111;
    validate_unique_and_set_index(ref mask, 127);
    assert(mask == 0x800000000000000000000000000000ff, 'highest bit not set')
}
