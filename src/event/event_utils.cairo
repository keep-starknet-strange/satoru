// NOTE: temporary mock in order to complet withdrawal_utils.
use starknet::ContractAddress;

#[derive(Default, Drop, Serde)]
struct EventLogData {
    address_items: AddressItems,
    uint_items: UintItems,
    int_items: IntItems,
    bool_items: BoolItems,
    bytes32_items: Bytes32Items,
    bytes_items: BytesItems,
    string_items: StringItems,
}


#[derive(Default, Drop, Serde)]
struct AddressItems {
    items: Array<AddressKeyValue>,
    array_items: Array<AddressArrayKeyValue>,
}

#[derive(Default, Drop, Serde)]
struct UintItems {
    items: Array<UintKeyValue>,
    array_items: Array<UintArrayKeyValue>,
}

#[derive(Default, Drop, Serde)]
struct IntItems {
    items: Array<IntKeyValue>,
    array_items: Array<IntArrayKeyValue>,
}

#[derive(Default, Drop, Serde)]
struct BoolItems {
    items: Array<BoolKeyValue>,
    array_items: Array<BoolArrayKeyValue>,
}

#[derive(Default, Drop, Serde)]
struct Bytes32Items {
    items: Array<Bytes32KeyValue>,
    array_items: Array<Bytes32ArrayKeyValue>,
}

#[derive(Default, Drop, Serde)]
struct BytesItems {
    items: Array<BytesKeyValue>,
    array_items: Array<BytesArrayKeyValue>,
}

#[derive(Default, Drop, Serde)]
struct StringItems {
    items: Array<StringKeyValue>,
    array_items: Array<StringArrayKeyValue>,
}

#[derive(Drop, Serde)]
struct AddressKeyValue {
    key: felt252,
    value: ContractAddress,
}

impl DefaultAddressKeyValue of Default<AddressKeyValue> {
    fn default() -> AddressKeyValue {
        AddressKeyValue { key: 0, value: Zeroable::zero() }
    }
}

#[derive(Default, Drop, Serde)]
struct AddressArrayKeyValue {
    key: felt252,
    value: Array<ContractAddress>,
}

#[derive(Default, Drop, Serde)]
struct UintKeyValue {
    key: felt252,
    value: u128,
}

#[derive(Default, Drop, Serde)]
struct UintArrayKeyValue {
    key: felt252,
    value: Array<u128>,
}

#[derive(Default, Drop, Serde)]
struct IntKeyValue {
    key: felt252,
    value: i128,
}

#[derive(Default, Drop, Serde)]
struct IntArrayKeyValue {
    key: felt252,
    value: Array<u128>,
}

#[derive(Default, Drop, Serde)]
struct BoolKeyValue {
    key: felt252,
    value: bool,
}

#[derive(Default, Drop, Serde)]
struct BoolArrayKeyValue {
    key: felt252,
    value: Array<bool>,
}

#[derive(Default, Drop, Serde)]
struct Bytes32KeyValue {
    key: felt252,
    value: felt252,
}

#[derive(Default, Drop, Serde)]
struct Bytes32ArrayKeyValue {
    key: felt252,
    value: Array<felt252>,
}

#[derive(Default, Drop, Serde)]
struct BytesKeyValue {
    key: felt252,
    value: felt252,
}

#[derive(Default, Drop, Serde)]
struct BytesArrayKeyValue {
    key: felt252,
    value: Array<felt252>,
}

#[derive(Default, Drop, Serde)]
struct StringKeyValue {
    key: felt252,
    value: felt252,
}

#[derive(Default, Drop, Serde)]
struct StringArrayKeyValue {
    key: felt252,
    value: Array<felt252>
}

trait EventUtilsTrait<T, A> {
    fn set_item(ref self: T, key: felt252, value: A);
}

impl EventUtilsAddressItemsImpl of EventUtilsTrait<AddressItems, ContractAddress> {
    fn set_item(ref self: AddressItems, key: felt252, value: ContractAddress) {
        self.items.append(AddressKeyValue { key, value });
    }
}

impl EventUtilsUintItems of EventUtilsTrait<UintItems, u128> {
    fn set_item(ref self: UintItems, key: felt252, value: u128) {
        self.items.append(UintKeyValue { key, value });
    }
}

impl EventUtilsIntItems of EventUtilsTrait<IntItems, i128> {
    fn set_item(ref self: IntItems, key: felt252, value: i128) {
        self.items.append(IntKeyValue { key, value });
    }
}

impl EventUtilsBoolItems of EventUtilsTrait<BoolItems, bool> {
    fn set_item(ref self: BoolItems, key: felt252, value: bool) {
        self.items.append(BoolKeyValue { key, value });
    }
}

impl DefaultInt of Default<i128> {
    fn default() -> i128 {
        0
    }
}

impl I128Serde of Serde<i128> {
    fn serialize(self: @i128, ref output: Array<felt252>) {
        Into::<i128, felt252>::into(*self).serialize(ref output);
    }
    fn deserialize(ref serialized: Span<felt252>) -> Option<i128> {
        Option::Some(((*serialized.pop_front()?).try_into())?)
    }
}
