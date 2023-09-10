use satoru::data::data_store::IDataStoreDispatcherTrait;
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

    let nonce = get_current_nonce(data_store);
    assert(nonce == 0, 'Invalid nonce');

    let nonce = increment_nonce(data_store);
    assert(nonce == 1, 'Invalid new nonce');

    let key = get_next_key(data_store);
    assert(key == 0x282524aa644121524f01a2feb9a663ebc4afaf14924efa9565246d4ed9210b3, 'Invalid key');

    let nonce = get_current_nonce(data_store);
    assert(nonce == 2, 'Invalid final nonce');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}
