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

// Local imports.
use satoru::utils::i128::{I128Serde, I128Default};
use satoru::utils::traits::ContractAddressDefault;
use satoru::utils::serializable_dict::{
    Item, ItemTrait, SerializableFelt252Dict, SerializableFelt252DictTrait,
    SerializableFelt252DictSerde
};

// *********************************************************************************************
// *                                      TEST LOGIC                                           *
// *********************************************************************************************

/// Item tests

#[test]
fn test_item_single() {
    let item: Item<u8> = Item::Single(8);

    assert(item.is_single() == true, 'item should be single');
    assert(item.is_array() == false, 'item shouldnt be array');
    assert(item.len() == 1, 'item len not 1');
}

#[test]
fn test_item_multiple() {
    let arr: Array<u8> = array![1, 2, 3, 4, 5];
    let expected_len: usize = arr.len();

    let item: Item<u8> = Item::Array(arr);

    assert(item.is_array() == true, 'item should be array');
    assert(item.is_single() == false, 'item shouldnt be single');
    assert(item.len() == expected_len, 'incorrect len');
}
// SerializableDict tests


