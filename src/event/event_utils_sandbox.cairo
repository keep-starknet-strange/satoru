use starknet::{get_caller_address, ContractAddress, contract_address_const};
use array::ArrayTrait;
use satoru::utils::i128::{I128Serde, I128Default};
use traits::Default;
use satoru::utils::traits::ContractAddressDefault;

use satoru::utils::ordered_dict::{OrderedDict, OrderedDictTraitImpl, OrderedDictSerde};

//
//     NEEDED IMPLEMENTATIONS...
//

impl Felt252IntoBool of Into<felt252, bool> {
    #[inline(always)]
    fn into(self: felt252) -> bool {
        let as_u128: u128 = self.try_into().expect('u128 Overflow');
        as_u128 > 0
    }
}

impl Felt252IntoU128 of Into<felt252, u128> {
    #[inline(always)]
    fn into(self: felt252) -> u128 {
        self.try_into().expect('u128 Overflow')
    }
}

impl Felt252IntoI128 of Into<felt252, i128> {
    #[inline(always)]
    fn into(self: felt252) -> i128 {
        self.try_into().expect('i128 Overflow')
    }
}
impl I128252DictValue of Felt252DictValue<i128> {
    #[inline(always)]
    fn zero_default() -> i128 nopanic {
        0
    }
}

//
//      LOG DATA
//

//TODO Switch the append with a set in the functions when its available
#[derive(Default, Serde, Destruct)]
struct EventLogData {
    cant_be_empty: u128, // remove 
// TODO
}

#[derive(Default, Destruct, Serde)]
struct LogData {
    uint_items: OrderedDict<u128>,
    int_items: OrderedDict<i128>,
    bool_items: OrderedDict<bool>,
}

// uint
fn set_item_uint_items(
    mut dict: OrderedDict<u128>, index: u32, key: felt252, value: u128
) -> OrderedDict<u128> {
    OrderedDictTraitImpl::add_single(ref dict, key, value);
    dict
}

fn set_item_array_uint_items(
    mut dict: OrderedDict<u128>, index: u32, key: felt252, values: Array<u128>
) -> OrderedDict<u128> {
    OrderedDictTraitImpl::add_multiple(ref dict, key, values);
    dict
}


// int
fn set_item_int_items(
    mut dict: OrderedDict<i128>, index: u32, key: felt252, value: i128
) -> OrderedDict<i128> {
    OrderedDictTraitImpl::add_single(ref dict, key, value);
    dict
}

fn set_item_array_int_items(
    mut dict: OrderedDict<i128>, index: u32, key: felt252, values: Array<i128>
) -> OrderedDict<i128> {
    OrderedDictTraitImpl::add_multiple(ref dict, key, values);
    dict
}


// bool
fn set_item_bool_items(
    mut dict: OrderedDict<bool>, index: u32, key: felt252, value: bool
) -> OrderedDict<bool> {
    OrderedDictTraitImpl::add_single(ref dict, key, value);
    dict
}

fn set_item_array_bool_items(
    mut dict: OrderedDict<bool>, index: u32, key: felt252, values: Array<bool>
) -> OrderedDict<bool> {
    OrderedDictTraitImpl::add_multiple(ref dict, key, values);
    dict
}
