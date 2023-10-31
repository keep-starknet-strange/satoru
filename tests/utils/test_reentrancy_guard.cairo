use satoru::data::data_store::IDataStoreDispatcherTrait;
use satoru::utils::global_reentrancy_guard::{non_reentrant_before, non_reentrant_after};
use satoru::tests_lib::{setup, teardown};

#[test]
fn given_normal_conditions_when_non_reentrancy_before_and_after_then_works() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (_, _, data_store) = setup();
    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Gets initial value as like in contract.
    let initial_value = data_store.get_bool('REENTRANCY_GUARD_STATUS');

    // Initial value should be false.
    assert(initial_value == false, 'Initial value wrong');

    // Sets value to true
    non_reentrant_before(data_store);

    // Gets value after non_reentrant_before call
    let entrant = data_store.get_bool('REENTRANCY_GUARD_STATUS');
    assert(entrant, 'Entered value wrong');

    non_reentrant_after(data_store); // This should set value false.
    // Gets final value
    let after: bool = data_store.get_bool('REENTRANCY_GUARD_STATUS');

    assert(!after, 'Final value wrong');
}

#[test]
#[should_panic(expected: ('ReentrancyGuard: reentrant call',))]
fn given_reentrant_call_when_reentrancy_before_and_after_then_fails() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (_, _, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Sets value to true
    non_reentrant_before(data_store);

    // Gets value after non_reentrant_before
    let entraant: bool = data_store.get_bool('REENTRANCY_GUARD_STATUS');
    assert(entraant, 'Entered value wrong');

    // This should revert, means reentrant call happened.
    non_reentrant_before(data_store);
}
