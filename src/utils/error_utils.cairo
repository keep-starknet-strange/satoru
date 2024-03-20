fn get_error_selector_from_data(reason_bytes: Span<felt252>) -> felt252 {
    // TODO
    0
}

fn revert_with_custom_error(reason_bytes: Span<felt252>) -> felt252 {
    // TODO
    0
}

fn get_revert_message(reason_bytes: Span<felt252>) -> felt252 {
    // TODO
    0
}

fn check_division_by_zero(divisor: u256, variable_name: felt252) {
    if divisor.is_zero() {
        panic(array!['division by zero', variable_name])
    }
}
