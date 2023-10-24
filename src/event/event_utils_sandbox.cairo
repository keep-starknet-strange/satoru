use starknet::{get_caller_address, ContractAddress, contract_address_const};
use array::ArrayTrait;
use satoru::utils::i128::{I128Serde, I128Default};
use traits::Default;
use satoru::utils::traits::ContractAddressDefault;

use satoru::utils::ordered_dict::{OrderedDict, OrderedDictTraitImpl, OrderedDictSerde, Value};

//TODO Switch the append with a set in the functions when its available
#[derive(Serde, Destruct)]
struct EventLogData {
    cant_be_empty: u128, // remove 
// TODO
}

#[derive(Default, Destruct, Serde)]
struct LogData {
    bool_items: OrderedDict<bool>,
}

// bool
fn set_item_bool_items(
    mut dict: OrderedDict<bool>, index: u32, key: felt252, value: bool
) -> OrderedDict<bool> {
    OrderedDictTraitImpl::add_single(ref dict, key, value);
    dict
}

fn set_item_array_bool_items(
    mut dict: OrderedDict<bool>, index: u32, key: felt252, value: Array<bool>
) -> OrderedDict<bool> {
    OrderedDictTraitImpl::add_multiple(ref dict, key, value);
    dict
}
