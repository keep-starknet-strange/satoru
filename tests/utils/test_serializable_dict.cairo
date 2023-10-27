//! Test file for `src/utils/serializable_dict.cairo`.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::{
    get_caller_address, ContractAddress, Felt252TryIntoContractAddress, ContractAddressIntoFelt252,
    contract_address_const
};
use array::ArrayTrait;
use traits::Default;
use alexandria_data_structures::array_ext::ArrayTraitExt;

// Local imports.
use satoru::utils::traits::ContractAddressDefault;
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
    let item: Item<u8> = Item::Single(8);

    assert(item.is_single() == true, 'item should be single');
    assert(item.is_span() == false, 'item shouldnt be a span');
    assert(item.len() == 1, 'item len not 1');
}

#[test]
fn test_item_span() {
    let arr: Array<u8> = array![1, 2, 3, 4, 5];
    let expected_len: usize = arr.len();

    let item: Item<u8> = Item::Span(arr.span());

    assert(item.is_span() == true, 'item should be a span');
    assert(item.is_single() == false, 'item shouldnt be single');
    assert(item.len() == expected_len, 'incorrect len');
}

// SerializableDict tests

#[test]
fn test_serializable_dict_add_single() {
    let mut dict: SerializableFelt252Dict<u8> = SerializableFelt252DictTrait::new();

    let key: felt252 = 'starknet';
    let expected_value: u8 = 42;

    dict.add_single(key, expected_value);

    let retrieved_item: Item = dict.get(key).expect('key should be in dict');
    let out_value: u8 = retrieved_item.unwrap_single();

    assert(out_value == expected_value, 'wrong value');
}

#[test]
fn test_serializable_dict_add_span() {
    let mut dict: SerializableFelt252Dict<u8> = SerializableFelt252DictTrait::new();

    let key: felt252 = 'starknet';
    let expected_array: Array<u8> = array![1, 2, 3];

    dict.add_span(key, expected_array.span());

    let retrieved_item: Item = dict.get(key).expect('key should be in dict');
    let out_span: Span<u8> = retrieved_item.unwrap_span();

    assert(dict.keys.contains(key), 'key should be in dict');
    assert(out_span.at(0) == expected_array.at(0), 'wrong at idx 0');
    assert(out_span.at(1) == expected_array.at(1), 'wrong at idx 0');
    assert(out_span.at(2) == expected_array.at(2), 'wrong at idx 0');
}
