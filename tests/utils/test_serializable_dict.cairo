//! Test file for `src/utils/serializable_dict.cairo`.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use serde::Serde;
use starknet::{
    get_caller_address, ContractAddress, Felt252TryIntoContractAddress, ContractAddressIntoFelt252,
    contract_address_const
};
use array::ArrayTrait;
use array::SpanTrait;
use traits::Default;
use alexandria_data_structures::array_ext::ArrayTraitExt;

// Local imports.
use satoru::utils::traits::ContractAddressDefault;
use satoru::event::event_utils::{
    Felt252IntoBool, Felt252IntoContractAddress, I256252DictValue, ContractAddressDictValue,
    U256252DictValue, U256IntoFelt252
};
use satoru::utils::serializable_dict::{
    Item, ItemTrait, SerializableFelt252Dict, SerializableFelt252DictTrait,
    SerializableFelt252DictTraitImpl
};

// *********************************************************************************************
// *                                      TEST LOGIC                                           *
// *********************************************************************************************

/// Item tests

#[test]
fn test_item_single() {
    let item: Item<u256> = Item::Single(8);

    assert(item.is_single() == true, 'item should be single');
    assert(item.is_span() == false, 'item shouldnt be a span');
    assert(item.len() == 1, 'item len not 1');
}

#[test]
fn test_item_span() {
    let arr: Array<u256> = array![1, 2, 3, 4, 5];
    let expected_len: usize = arr.len();

    let item: Item<u256> = Item::Span(arr.span());

    assert(item.is_span() == true, 'item should be a span');
    assert(item.is_single() == false, 'item shouldnt be single');
    assert(item.len() == expected_len, 'incorrect len');
}

#[test]
fn test_item_comparison_single_equals() {
    let item_a: Item<u256> = Item::Single(42);
    let item_b: Item<u256> = Item::Single(42);
    assert(item_a == item_b, 'u256 should be equals');

    let item_a: Item<u256> = Item::Single(42);
    let item_b: Item<u256> = Item::Single(69);
    assert(item_a != item_b, 'u256 shouldnt be equals');

    let item_a: Item<felt252> = Item::Single(69);
    let item_b: Item<felt252> = Item::Single(69);
    assert(item_a == item_b, 'felt252 should be equals');

    let item_a: Item<felt252> = Item::Single(42);
    let item_b: Item<felt252> = Item::Single(69);
    assert(item_a != item_b, 'felt252 shouldnt be equals');
}

#[test]
fn test_item_comparison_spans() {
    let item_a: Item<u256> = Item::Span(array![1, 2, 3].span());
    let item_b: Item<u256> = Item::Span(array![1, 2, 3].span());
    assert(item_a == item_b, 'u256 should be equals');

    let item_a: Item<u256> = Item::Span(array![1, 2, 3].span());
    let item_b: Item<u256> = Item::Span(array![4, 5].span());
    assert(item_a != item_b, 'u256 shouldnt be equals');

    let item_a: Item<felt252> = Item::Span(array![1, 2, 3].span());
    let item_b: Item<felt252> = Item::Span(array![1, 2, 3].span());
    assert(item_a == item_b, 'felt252 should be equals');

    let item_a: Item<felt252> = Item::Span(array![1, 2, 3].span());
    let item_b: Item<felt252> = Item::Span(array![1, 2, 9].span());
    assert(item_a != item_b, 'felt252 shouldnt be equals');

    let item_a: Item<ContractAddress> = Item::Span(
        array![contract_address_const::<'satoshi'>(), contract_address_const::<'nakamoto'>()].span()
    );
    let item_b: Item<ContractAddress> = Item::Span(
        array![contract_address_const::<'satoshi'>(), contract_address_const::<'nakamoto'>()].span()
    );
    assert(item_a == item_b, 'contract should be equals');

    let item_a: Item<ContractAddress> = Item::Span(
        array![contract_address_const::<'satoshi'>(), contract_address_const::<'nakamoto'>()].span()
    );
    let item_b: Item<ContractAddress> = Item::Span(
        array![contract_address_const::<'nakamoto'>(), contract_address_const::<'satoshi'>()].span()
    );
    assert(item_a != item_b, 'contract shouldnt be equals');
}

#[test]
#[should_panic(expected: ('should be a span',))]
fn test_item_unwrap_single_as_span() {
    let item: Item<u256> = Item::Single(8);
    item.unwrap_span();
}

#[test]
#[should_panic(expected: ('should be single',))]
fn test_item_unwrap_span_as_single() {
    let item: Item<u256> = Item::Span(array![1, 2].span());
    item.unwrap_single();
}

// SerializableDict tests

#[test]
fn test_serializable_dict_insert_single() {
    let mut dict: SerializableFelt252Dict<u256> = SerializableFelt252DictTrait::new();

    let key: felt252 = 'starknet';
    let expected_value: u256 = 42;

    dict.insert_single(key, expected_value);

    let retrieved_item: Item = dict.get(key).expect('key should be in dict');
    let out_value: u256 = retrieved_item.unwrap_single();

    assert(dict.contains(key), 'key should be in dict');
    assert(dict.len() == 1, 'wrong dict len');
    assert(out_value == expected_value, 'wrong value');
}

#[test]
fn test_serializable_dict_insert_span() {
    let mut dict: SerializableFelt252Dict<u256> = SerializableFelt252DictTrait::new();

    let key: felt252 = 'starknet';
    let expected_array: Array<u256> = array![1, 2, 3];

    dict.insert_span(key, expected_array.span());

    let retrieved_item: Item = dict.get(key).expect('key should be in dict');
    let out_span: Span<u256> = retrieved_item.unwrap_span();

    assert(dict.contains(key), 'key should be in dict');
    assert(dict.len() == 1, 'wrong dict len');
    assert(out_span.at(0) == expected_array.at(0), 'wrong at idx 0');
    assert(out_span.at(1) == expected_array.at(1), 'wrong at idx 1');
    assert(out_span.at(2) == expected_array.at(2), 'wrong at idx 2');
}

#[test]
fn test_serializable_dict_serialize() {
    let mut dict: SerializableFelt252Dict<u256> = SerializableFelt252DictTrait::new();

    assert(dict.is_empty(), 'dict should be empty');
    assert(dict.len() == 0, 'wrong empty dict len');

    let expected_value: u256 = 42;
    let expected_array: Array<u256> = array![1, 2, 3];

    dict.insert_single('test', expected_value);
    dict.insert_span('test_span', expected_array.span());

    let serialized: Array<felt252> = dict.serialize_into();

    let mut span_serialized: Span<felt252> = serialized.span();
    let mut deserialized_dict: SerializableFelt252Dict<u256> =
        match SerializableFelt252DictTrait::<u256>::deserialize(ref span_serialized) {
        Option::Some(d) => d,
        Option::None => panic_with_felt252('err while recreating d')
    };

    assert(dict.contains('test'), 'key should be in dict');
    let retrieved_item: Item<u256> = dict.get('test').expect('key should be in dict');
    let out_value: u256 = retrieved_item.unwrap_single();

    assert(dict.contains('test_span'), 'key should be in dict');
    let retrieved_item: Item<u256> = deserialized_dict
        .get('test_span')
        .expect('key should be in dict');
    let out_span: Span<u256> = retrieved_item.unwrap_span();
    assert(dict.len() == 2, 'wrong deserialized dict len');
    assert(dict.contains('test'), 'test should be in dict');
    assert(dict.contains('test_span'), 'test should be in dict');
    assert(out_span.at(0) == expected_array.at(0), 'wrong at idx 0');
    assert(out_span.at(1) == expected_array.at(1), 'wrong at idx 1');
    assert(out_span.at(2) == expected_array.at(2), 'wrong at idx 2');
}

#[test]
#[should_panic(expected: ('err getting value',))]
fn test_error_deserialize_value() {
    let serialized_dict: Array<felt252> = array!['key', 1, 1, 'key_2', 2, 1];
    let mut span_serialized: Span<felt252> = serialized_dict.span();

    match SerializableFelt252DictTrait::<u256>::deserialize(ref span_serialized) {
        Option::Some(d) => panic_with_felt252('should have panicked'),
        Option::None => ()
    };
}

#[test]
#[should_panic(expected: ('err getting size',))]
fn test_error_deserialize_size() {
    let serialized_dict: Array<felt252> = array!['key', 1, 1, 'key_2'];
    let mut span_serialized: Span<felt252> = serialized_dict.span();

    match SerializableFelt252DictTrait::<u256>::deserialize(ref span_serialized) {
        Option::Some(d) => panic_with_felt252('should have panicked'),
        Option::None => ()
    };
}
