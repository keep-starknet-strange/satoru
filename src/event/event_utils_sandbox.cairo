use starknet::{
    get_caller_address, ContractAddress, Felt252TryIntoContractAddress, ContractAddressIntoFelt252,
    contract_address_const
};
use array::ArrayTrait;
use satoru::utils::i128::i128;
use traits::Default;
use satoru::utils::traits::ContractAddressDefault;

use satoru::utils::serializable_dict::{SerializableFelt252Dict, SerializableFelt252DictTrait};

//
//     NEEDED IMPLEMENTATIONS...
//
/// TODO: move those somewhere else?

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

impl Felt252IntoContractAddress of Into<felt252, ContractAddress> {
    #[inline(always)]
    fn into(self: felt252) -> ContractAddress {
        Felt252TryIntoContractAddress::try_into(self).expect('contractaddress overflow')
    }
}

impl I128252DictValue of Felt252DictValue<i128> {
    #[inline(always)]
    fn zero_default() -> i128 nopanic {
        i128 { mag: 0, sign: false }
    }
}

impl ContractAddressDictValue of Felt252DictValue<ContractAddress> {
    #[inline(always)]
    fn zero_default() -> ContractAddress nopanic {
        contract_address_const::<0>()
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
    address_items: SerializableFelt252Dict<ContractAddress>,
    uint_items: SerializableFelt252Dict<u128>,
    int_items: SerializableFelt252Dict<i128>,
    bool_items: SerializableFelt252Dict<bool>,
    felt252_items: SerializableFelt252Dict<felt252>,
    // TODO? Possible? array_of_felt_items: SerializableFelt252Dict<Array<felt252>>,
    string_items: SerializableFelt252Dict<felt252>
}

// uint
fn set_item_uint_items(
    mut dict: SerializableFelt252Dict<u128>, key: felt252, value: u128
) -> SerializableFelt252Dict<u128> {
    dict.add_single(key, value);
    dict
}

fn set_item_array_uint_items(
    mut dict: SerializableFelt252Dict<u128>, key: felt252, values: Array<u128>
) -> SerializableFelt252Dict<u128> {
    dict.add_array(key, values);
    dict
}


// int
fn set_item_int_items(
    mut dict: SerializableFelt252Dict<i128>, key: felt252, value: i128
) -> SerializableFelt252Dict<i128> {
    dict.add_single(key, value);
    dict
}

fn set_item_array_int_items(
    mut dict: SerializableFelt252Dict<i128>, key: felt252, values: Array<i128>
) -> SerializableFelt252Dict<i128> {
    dict.add_array(key, values);
    dict
}


// bool
fn set_item_bool_items(
    mut dict: SerializableFelt252Dict<bool>, key: felt252, value: bool
) -> SerializableFelt252Dict<bool> {
    dict.add_single(key, value);
    dict
}

fn set_item_array_bool_items(
    mut dict: SerializableFelt252Dict<bool>, key: felt252, values: Array<bool>
) -> SerializableFelt252Dict<bool> {
    dict.add_array(key, values);
    dict
}


// felt252
fn set_item_Felt252_items(
    mut dict: SerializableFelt252Dict<felt252>, key: felt252, value: felt252
) -> SerializableFelt252Dict<felt252> {
    dict.add_single(key, value);
    dict
}

fn set_item_array_Felt252_items(
    mut dict: SerializableFelt252Dict<felt252>, key: felt252, values: Array<felt252>
) -> SerializableFelt252Dict<felt252> {
    dict.add_array(key, values);
    dict
}


// string
fn set_item_string_items(
    mut dict: SerializableFelt252Dict<felt252>, key: felt252, value: felt252
) -> SerializableFelt252Dict<felt252> {
    dict.add_single(key, value);
    dict
}

fn set_item_array_string_items(
    mut dict: SerializableFelt252Dict<felt252>, key: felt252, values: Array<felt252>
) -> SerializableFelt252Dict<felt252> {
    dict.add_array(key, values);
    dict
}
