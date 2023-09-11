use satoru::data::data_store::IDataStoreDispatcherTrait;
use satoru::nonce::nonce_utils::{get_current_nonce, increment_nonce, compute_key};
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

    let nonce = get_current_nonce(data_store);
    assert(nonce == 1, 'Invalid final nonce');

    let key = compute_key(42069.try_into().unwrap(), 2);
    assert(key == 0x24bd38ceb23566640607e8fd6d1ef05cf308413863f984763744a3cfd428b1b, 'Invalid key');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store.contract_address);
}
