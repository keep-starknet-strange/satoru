//! Test file for `src/event/event_utils.cairo`.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
use starknet::{
    get_caller_address, ContractAddress, Felt252TryIntoContractAddress, ContractAddressIntoFelt252,
    contract_address_const
};
use satoru::event::event_utils::{
    Felt252IntoBool, Felt252IntoContractAddress, I256252DictValue,
    ContractAddressDictValue, LogData, LogDataTrait, U256252DictValue, U256IntoFelt252
};
use satoru::utils::traits::{ContractAddressDefault};
use traits::Default;
use satoru::utils::serializable_dict::{
    Item, ItemTrait, SerializableFelt252Dict, SerializableFelt252DictTrait,
};

// *********************************************************************************************
// *                                      TEST LOGIC                                           *
// *********************************************************************************************

#[test]
fn test_log_data_default() {
    let mut log_data: LogData = Default::default();

    // try to add things
    log_data.address_dict.insert_single('test', contract_address_const::<0>());
    log_data.uint_dict.insert_single('test', 12_u256);

    // assert results OK
    let addr_item = log_data.address_dict.get('test').expect('key not found');
    let addr_value = addr_item.unwrap_single();
    assert(addr_value == contract_address_const::<0>(), 'addr value wrong');

    let uint_item = log_data.uint_dict.get('test').expect('key not found');
    let uint_value = uint_item.unwrap_single();
    assert(uint_value == 12_u256, 'uint value wrong');
}

#[test]
fn test_log_data_default_each() {
    let mut log_data: LogData = LogData {
        address_dict: Default::default(),
        uint_dict: Default::default(),
        int_dict: Default::default(),
        bool_dict: Default::default(),
        felt252_dict: Default::default(),
        string_dict: Default::default()
    };

    // try to add things
    log_data.address_dict.insert_single('test', contract_address_const::<0>());
    log_data.uint_dict.insert_single('test', 12_u256);

    // assert results OK
    let addr_item = log_data.address_dict.get('test').expect('key not found');
    let addr_value = addr_item.unwrap_single();
    assert(addr_value == contract_address_const::<0>(), 'addr value wrong');

    let uint_item = log_data.uint_dict.get('test').expect('key not found');
    let uint_value = uint_item.unwrap_single();
    assert(uint_value == 12_u256, 'uint value wrong');
}

#[test]
fn test_log_data_multiple_types() {
    let mut log_data: LogData = Default::default();

    let arr_to_add: Array<ContractAddress> = array![
        contract_address_const::<'cairo'>(),
        contract_address_const::<'starknet'>(),
        contract_address_const::<'rust'>()
    ];

    // try to add unique
    log_data.address_dict.insert_single('test', contract_address_const::<0>());
    log_data.address_dict.insert_span('test_arr', arr_to_add.span());

    // assert results OK
    let addr_item = log_data.address_dict.get('test').expect('key not found');
    let addr_value = addr_item.unwrap_single();
    assert(addr_value == contract_address_const::<0>(), 'addr value wrong');

    let addr_span_item: Item = log_data
        .address_dict
        .get('test_arr')
        .expect('key should be in dict');
    let out_span: Span<ContractAddress> = addr_span_item.unwrap_span();
    assert(out_span.at(0) == arr_to_add.at(0), 'wrong at idx 0');
    assert(out_span.at(1) == arr_to_add.at(1), 'wrong at idx 1');
    assert(out_span.at(2) == arr_to_add.at(2), 'wrong at idx 2');
}

#[test]
fn test_log_data_serialization() {
    let mut log_data: LogData = Default::default();

    log_data.address_dict.insert_single('addr_test', contract_address_const::<42>());
    log_data.bool_dict.insert_single('bool_test', false);
    log_data.felt252_dict.insert_single('felt_test', 1);
    log_data.felt252_dict.insert_single('felt_test_two', 2);
    log_data.string_dict.insert_single('string_test', 'hello world');
    log_data
        .string_dict
        .insert_span('string_arr_test', array!['hello', 'world', 'from', 'starknet'].span());

    // serialize the data
    let mut serialized_data = log_data.serialize_into().span();

    // deserialize
    let mut d_log_data: LogData = LogDataTrait::deserialize(ref serialized_data)
        .expect('err while deserializing');

    // Check the values inserted before
    // addr dict
    let mut expected_dict = log_data.address_dict;
    let mut out_dict = d_log_data.address_dict;
    assert_same_single_value_for_dicts(ref expected_dict, ref out_dict, 'addr_test');

    // bool dict
    let mut expected_dict = log_data.bool_dict;
    let mut out_dict = d_log_data.bool_dict;
    assert_same_single_value_for_dicts(ref expected_dict, ref out_dict, 'bool_test');

    // felt252 dict
    let mut expected_dict = log_data.felt252_dict;
    let mut out_dict = d_log_data.felt252_dict;
    assert_same_single_value_for_dicts(ref expected_dict, ref out_dict, 'felt_test');
    assert_same_single_value_for_dicts(ref expected_dict, ref out_dict, 'felt_test_two');

    // string dict
    assert(d_log_data.string_dict.contains('string_arr_test'), 'key not found');
    let v: Item<felt252> = d_log_data.string_dict.get('string_arr_test').unwrap();
    let span_strings: Span<felt252> = v.unwrap_span();
    assert(span_strings.len() == 4, 'err span len');
    assert(span_strings.at(0) == @'hello', 'err idx 0');
    assert(span_strings.at(1) == @'world', 'err idx 1');
    assert(span_strings.at(2) == @'from', 'err idx 2');
    assert(span_strings.at(3) == @'starknet', 'err idx 3');
}


// *********************************************************************************************
// *                                   UTILITIES                                               *
// *********************************************************************************************

use debug::PrintTrait;

fn assert_same_single_value_for_dicts<
    T,
    +Felt252DictValue<T>,
    +Drop<T>,
    +Copy<T>,
    +Into<felt252, T>,
    +Into<T, felt252>,
    +PartialEq<T>,
>(
    ref lhs: SerializableFelt252Dict<T>, ref rhs: SerializableFelt252Dict<T>, key: felt252
) {
    assert(lhs.contains(key), 'key not found: lhs');
    assert(rhs.contains(key), 'key not found: rhs');

    let lhs_value: Item<T> = lhs.get(key).unwrap();
    let rhs_value: Item<T> = rhs.get(key).unwrap();

    assert(lhs_value == rhs_value, 'err value');
}
