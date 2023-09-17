use satoru::utils::enumerable_set::{Set, SetTrait};

#[test]
fn given_starts_empty_when_enumerable_set_functions_then_works() {
    let mut set = SetTrait::<felt252>::new();
    assert(!set.contains(2) && !set.contains(3) && !set.contains(7), 'New set: Not empty');
    assert(set.length == 0, 'New set: Length not 0');

    let values: Array<felt252> = set.values();
    assert(values.len() == 0, 'New set: Not empty');
}

#[test]
fn given_set_adds_value_when_enumerable_set_functions_then_works() {
    let mut set = SetTrait::<felt252>::new();
    let is_new = set.add(2);
    assert(is_new, 'Set add one: Not new');
    assert(set.contains(2), 'Set add one: Not added');
}

#[test]
fn given_set_adds_several_values_when_enumerable_set_functions_then_works() {
    let mut set = SetTrait::<felt252>::new();
    set.add(2);
    set.add(3);
    assert(set.contains(2) && set.contains(3), 'Set add many: Not added');
    assert(!set.contains(7), 'Set add many: Added wrong');
}

#[test]
fn given_set_adding_existing_values_returns_false_when_enumerable_set_functions_then_works() {
    let mut set = SetTrait::<felt252>::new();
    set.add(2);
    let is_new = set.add(2);
    assert(!is_new, 'Set add existing: Not new');
    assert(set.contains(2), 'Set add existing: Not added');

    let values: Array<felt252> = set.values();
    assert(values.len() == 1, 'Set add existing: Length not 1');
    assert(*values.at(0) == 2, 'Set add existing: Value not 2');
}

#[test]
fn given_fetch_non_existent_when_enumerable_set_functions_then_works() {
    let mut set = SetTrait::<felt252>::new();
    let value: felt252 = set.at(2);
    assert(value == 0, 'Set fetch null: Not 0');
}

#[test]
fn given_set_removes_value_when_enumerable_set_functions_then_works() {
    let mut set = SetTrait::<felt252>::new();
    set.add(2);

    let is_removed = set.remove(2);
    assert(is_removed, 'Set remove: Not removed');

    let values: Array<felt252> = set.values();
    assert(values.len() == 0, 'New set: Not empty');
}

#[test]
fn given_normal_conditions_when_set_adds_and_removes_multiple_then_works() {
    let mut set = SetTrait::<felt252>::new();

    set.add(2);
    set.add(7);

    // [2, 7]

    set.remove(2);
    set.remove(3);

    // [7]

    set.add(3);

    // [7, 3]

    set.add(2);
    set.remove(7);

    // [2, 3]

    set.add(2);
    set.add(3);

    // [2, 3]

    set.add(7);
    set.remove(2);

    // [3, 7]

    set.add(2);
    set.remove(3);

    // [2, 7]

    assert(set.contains(2) && set.contains(7), 'Set add rem: Contains');
    assert(!set.contains(3), 'Set add rem: Does not contain');
    assert(set.length == 2, 'Set add rem: Length');

    let values: Array<felt252> = set.values();
    assert(values.len() == 2, 'Set add rem: Len');
    assert(*values.at(0) == 2, 'Set add rem: Index 0');
    assert(*values.at(1) == 7, 'Set add rem: Index 1');
}
