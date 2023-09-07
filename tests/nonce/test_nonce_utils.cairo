use satoru::data::data_store::IDataStoreSafeDispatcherTrait;
use satoru::nonce::nonce_utils::{get_current_nonce, increment_nonce, get_next_key};
use satoru::tests_lib::{setup, teardown};

#[test]
fn test_nonce_utils() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (_, _, data_store) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    let nonce = get_current_nonce(data_store).unwrap();
    assert(nonce == 0, 'Invalid nonce');

    let nonce = increment_nonce(data_store).unwrap();
    assert(nonce == 1, 'Invalid new nonce');

    let key = get_next_key(data_store).unwrap();
    assert(key == 0x3f84fbc06ce0aca2f042f92dbe31a1426167c15392bba1e905ec3c3f0c177f7, 'Invalid key');

    let nonce = get_current_nonce(data_store).unwrap();
    assert(nonce == 2, 'Invalid final nonce');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}
