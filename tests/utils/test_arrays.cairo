use satoru::utils::arrays;

#[test]
fn given_normal_conditions_when_arrays_get_then_works() {
    let arr = array![4, 5, 6];
    assert(arrays::get_felt252(arr.span(), 0) == 4, 'fail');
    assert(arrays::get_felt252(arr.span(), 2) == 6, 'fail');
    assert(arrays::get_felt252(arr.span(), 3) == 0, 'fail');
    assert(arrays::get_felt252(arr.span(), 9999999) == 0, 'fail');
}

#[test]
fn given_normal_conditions_when_arrays_are_eq_then_works() {
    let arr = array![7, 7, 7];
    assert(arrays::are_eq(arr.span(), 7), 'fail');
    let arr = array![7, 7, 8];
    assert(!arrays::are_eq(arr.span(), 7), 'fail');
}

#[test]
fn given_normal_conditions_when_arrays_are_gt_then_works() {
    let arr = array![10, 8, 42];
    assert(arrays::are_gt(arr.span(), 7), 'fail');
    let arr = array![10, 8, 7];
    assert(!arrays::are_gt(arr.span(), 7), 'fail');
}

#[test]
fn given_normal_conditions_when_arrays_are_gte_then_works() {
    let arr = array![10, 7, 42];
    assert(arrays::are_gte(arr.span(), 7), 'fail');
    let arr = array![10, 7, 6];
    assert(!arrays::are_gte(arr.span(), 7), 'fail');
}

#[test]
fn given_normal_conditions_when_arrays_are_lt_then_works() {
    let arr = array![4, 5, 6];
    assert(arrays::are_lt(arr.span(), 7), 'fail');
    let arr = array![4, 5, 7];
    assert(!arrays::are_lt(arr.span(), 7), 'fail');
}

#[test]
fn given_normal_conditions_when_arrays_are_lte_then_works() {
    let arr = array![5, 6, 7];
    assert(arrays::are_lte(arr.span(), 7), 'fail');
    let arr = array![5, 6, 8];
    assert(!arrays::are_lte(arr.span(), 7), 'fail');
}

#[test]
fn given_normal_conditions_when_arrays_get_median_then_works() {
    let (arr, expected) = (array![1, 2, 3], 2);
    assert(arrays::get_median(arr.span()) == expected, 'fail');

    let (arr, expected) = (array![1, 2, 3, 4], 2);
    assert(arrays::get_median(arr.span()) == expected, 'fail');

    let (arr, expected) = (array![11, 12, 14, 15], 13);
    assert(arrays::get_median(arr.span()) == expected, 'fail');

    let (arr, expected) = (array![1, 12, 14, 10000], 13);
    assert(arrays::get_median(arr.span()) == expected, 'fail');

    let (arr, expected) = (array![1000000, 1000050, 1000100, 2000000], 1000075);
    assert(arrays::get_median(arr.span()) == expected, 'fail');
}
