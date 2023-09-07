use satoru::data::data_store::IDataStoreSafeDispatcherTrait;
use satoru::utils::global_reentrancy_guard::{non_reentrant_before, non_reentrant_after};
use satoru::tests_lib::{setup, teardown};

#[test]
fn test_reentrancy_values() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (_, _, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Gets initial value as like in contract. It will revert if we directly try to unwrap()
    let initial_value: bool = match data_store.get_bool('REENTRANCY_GUARD_STATUS').unwrap() {
        Option::Some(v) => v,
        Option::None => false,
    };

    assert(!initial_value, 'Initial value wrong'); // Initial value should be false.

    non_reentrant_before(data_store); // Sets value to true

    // Gets value after non_reentrant_before call
    let entrant: bool = match data_store.get_bool('REENTRANCY_GUARD_STATUS').unwrap() {
        Option::Some(v) => v,
        Option::None => false,
    }; // We don't really need to use match, unwrap() should work but however let's keep the same way.
    assert(entrant, 'Entered value wrong'); // Value should be true.

    non_reentrant_after(data_store); // This should set value false.

    // Gets final value
    let after: bool = match data_store.get_bool('REENTRANCY_GUARD_STATUS').unwrap() {
        Option::Some(v) => v,
        Option::None => false,
    }; // We don't really need to use match, unwrap() should work but however let's keep the same way.
    assert(!after, 'Final value wrong');
}

#[test]
#[should_panic(expected: ('ReentrancyGuard: reentrant call',))]
fn test_reentrancy_revert() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (_, _, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    non_reentrant_before(data_store); // Sets value to true

    // Gets value after non_reentrant_before
    let entraant: bool = match data_store.get_bool('REENTRANCY_GUARD_STATUS').unwrap() {
        Option::Some(v) => v,
        Option::None => false,
    };
    assert(entraant, 'Entered value wrong'); // Value should be true.

    non_reentrant_before(data_store); // This should revert, means reentrant call happened.
}
