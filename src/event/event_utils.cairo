use starknet::{get_caller_address, ContractAddress, contract_address_const};
use array::ArrayTrait;
use satoru::utils::i128::{I128Serde, I128Default};
use traits::Default;
use satoru::utils::traits::ContractAddressDefault;

//TODO Switch the append with a set in the functions when its available

#[derive(Default, Drop, Serde)]
struct EventLogData {
    cant_be_empty: u128, // remove 
// TODO
}

#[derive(Default, Serde, Drop)]
struct LogData {
    address_items: AddressItems,
    uint_items: UintItems,
    int_items: IntItems,
    bool_items: BoolItems,
    felt252_items: Felt252Items,
    array_of_felt_items: ArrayOfFeltItems,
    string_items: StringItems,
}

//ContractAddress
#[derive(Default, Serde, Drop)]
struct AddressItems {
    items: Array<AddressKeyValue>,
    array_items: Array<AddressArrayKeyValue>,
}

#[derive(Default, Serde, Drop)]
struct AddressKeyValue {
    key: felt252,
    value: ContractAddress,
}

#[derive(Default, Serde, Drop)]
struct AddressArrayKeyValue {
    key: felt252,
    value: Array<ContractAddress>,
}

//u128

#[derive(Default, Serde, Drop)]
struct UintItems {
    items: Array<UintKeyValue>,
    array_items: Array<UintArrayKeyValue>,
}

#[derive(Default, Serde, Drop)]
struct UintKeyValue {
    key: felt252,
    value: u128,
}

#[derive(Default, Serde, Drop)]
struct UintArrayKeyValue {
    key: felt252,
    value: Array<u128>,
}

//i128
#[derive(Default, Serde, Drop)]
struct IntItems {
    items: Array<IntKeyValue>,
    array_items: Array<IntArrayKeyValue>,
}

#[derive(Default, Serde, Drop)]
struct IntKeyValue {
    key: felt252,
    value: i128,
}

#[derive(Default, Serde, Drop)]
struct IntArrayKeyValue {
    key: felt252,
    value: Array<i128>,
}

//bool
#[derive(Default, Serde, Drop)]
struct BoolItems {
    items: Array<BoolKeyValue>,
    array_items: Array<BoolArrayKeyValue>,
}

#[derive(Default, Serde, Drop)]
struct BoolKeyValue {
    key: felt252,
    value: bool,
}

#[derive(Default, Serde, Drop)]
struct BoolArrayKeyValue {
    key: felt252,
    value: Array<bool>,
}

//Felt252 
#[derive(Default, Serde, Drop)]
struct Felt252Items {
    items: Array<Felt252KeyValue>,
    array_items: Array<Felt252ArrayKeyValue>,
}

#[derive(Default, Serde, Drop)]
struct Felt252KeyValue {
    key: felt252,
    value: felt252,
}

#[derive(Default, Serde, Drop)]
struct Felt252ArrayKeyValue {
    key: felt252,
    value: Array<felt252>,
}

//Array of Felt
#[derive(Default, Serde, Drop)]
struct ArrayOfFeltItems {
    items: Array<ArrayOfFeltKeyValue>,
    array_items: Array<ArrayOfFeltArrayKeyValue>,
}

#[derive(Default, Serde, Drop)]
struct ArrayOfFeltKeyValue {
    key: felt252,
    value: Array<felt252>,
}
#[derive(Default, Serde, Drop)]
struct ArrayOfFeltArrayKeyValue {
    key: felt252,
    value: Array<Array<felt252>>,
}

//String switch later
#[derive(Default, Serde, Drop)]
struct StringItems {
    items: Array<StringKeyValue>,
    array_items: Array<StringArrayKeyValue>,
}

#[derive(Default, Serde, Drop)]
struct StringKeyValue {
    key: felt252,
    value: felt252,
}

#[derive(Default, Serde, Drop)]
struct StringArrayKeyValue {
    key: felt252,
    value: Array<felt252>,
}

//TODO for the functions we need to implement the set instead of append and use the set with index.

//AddressItems

fn set_item_address_items(
    mut items: AddressItems, index: u32, key: felt252, value: ContractAddress
) {
    let address_key_value: AddressKeyValue = AddressKeyValue { key, value };
    items.items.append(address_key_value);
}

fn set_item_array_address_items(
    mut items: AddressItems, index: u32, key: felt252, value: Array<ContractAddress>
) {
    let address_array_key_value: AddressArrayKeyValue = AddressArrayKeyValue { key, value };
    items.array_items.append(address_array_key_value);
}

// Uint

fn set_item_uint_items(mut items: UintItems, index: u32, key: felt252, value: u128) {
    let uint_key_value: UintKeyValue = UintKeyValue { key, value };
    items.items.append(uint_key_value);
}

fn set_item_array_uint_items(mut items: UintItems, index: u32, key: felt252, value: Array<u128>) {
    let uint_array_key_value: UintArrayKeyValue = UintArrayKeyValue { key, value };
    items.array_items.append(uint_array_key_value);
}

// in128

fn set_item_int_items(mut items: IntItems, index: u32, key: felt252, value: i128) {
    let int_key_value: IntKeyValue = IntKeyValue { key, value };
    // items.items.set(index, int_key_value);
    items.items.append(int_key_value);
}

fn set_item_array_int_items(mut items: IntItems, index: u32, key: felt252, value: Array<i128>) {
    let int_array_key_value: IntArrayKeyValue = IntArrayKeyValue { key, value };
    items.array_items.append(int_array_key_value);
}

// bool

fn set_item_bool_items(mut items: BoolItems, index: u32, key: felt252, value: bool) {
    let bool_key_value: BoolKeyValue = BoolKeyValue { key, value };
    items.items.append(bool_key_value);
}

fn set_item_array_bool_items(mut items: BoolItems, index: u32, key: felt252, value: Array<bool>) {
    let bool_array_key_value: BoolArrayKeyValue = BoolArrayKeyValue { key, value };
    items.array_items.append(bool_array_key_value);
}

// felt252

fn set_item_Felt252_items(mut items: Felt252Items, index: u32, key: felt252, value: felt252) {
    let Felt252_key_value: Felt252KeyValue = Felt252KeyValue { key, value };
    items.items.append(Felt252_key_value);
}

fn set_item_array_Felt252_items(
    mut items: Felt252Items, index: u32, key: felt252, value: Array<felt252>
) {
    let Felt252_array_key_value: Felt252ArrayKeyValue = Felt252ArrayKeyValue { key, value };
    items.array_items.append(Felt252_array_key_value);
}

// array of felt

fn set_item_array_of_felt_items_items(
    mut items: ArrayOfFeltItems, index: u32, key: felt252, value: Array<felt252>
) {
    let array_of_felt_items_key_value: ArrayOfFeltKeyValue = ArrayOfFeltKeyValue { key, value };
    items.items.append(array_of_felt_items_key_value);
}

fn set_item_array_array_of_felt_items(
    mut items: ArrayOfFeltItems, index: u32, key: felt252, value: Array<Array<felt252>>
) {
    let array_of_felt_array_key_value: ArrayOfFeltArrayKeyValue = ArrayOfFeltArrayKeyValue {
        key, value
    };
    items.array_items.append(array_of_felt_array_key_value);
}

// string

fn set_item_string_items(mut items: StringItems, index: u32, key: felt252, value: felt252) {
    let string_key_value: StringKeyValue = StringKeyValue { key, value };
    items.items.append(string_key_value);
}

fn set_item_array_string_items(
    mut items: StringItems, index: u32, key: felt252, value: Array<felt252>
) {
    let string_array_key_value: StringArrayKeyValue = StringArrayKeyValue { key, value };
    items.array_items.append(string_array_key_value);
}
