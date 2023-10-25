use core::serde::Serde;
use core::array::SpanTrait;
use core::array::ArrayTrait;
use core::traits::Into;
use starknet::{get_caller_address, ContractAddress, contract_address_const};
use traits::Default;
use dict::{Felt252DictTrait, Felt252Dict};
use nullable::{nullable_from_box, match_nullable, FromNullableResult, Nullable};

use alexandria_data_structures::array_ext::ArrayTraitExt;

#[derive(Drop, Copy)]
enum Item<T> {
    Single: T,
    Array: Array<T>
}

#[generate_trait]
impl ItemImpl<T> of ItemTrait<T> {
    fn is_single(self: @Item<T>) -> bool {
        match self {
            Item::Single(v) => true,
            Item::Array(arr) => false
        }
    }

    fn is_array(self: @Item<T>) -> bool {
        match self {
            Item::Single(v) => false,
            Item::Array(arr) => true
        }
    }

    fn len(self: @Item<T>) -> usize {
        match self {
            Item::Single(v) => 1,
            Item::Array(arr) => arr.len()
        }
    }
}

#[derive(Default, Copy)]
struct SerializableFelt252Dict<T> {
    keys: Array<felt252>,
    values: Felt252Dict<Nullable<Item<T>>>
}

impl SerializableFelt252DictDestruct<
    T, impl TDrop: Drop<T>, impl TDefault: Felt252DictValue<T>
> of Destruct<SerializableFelt252Dict<T>> {
    fn destruct(self: SerializableFelt252Dict<T>) nopanic {
        self.values.squash();
        self.keys.destruct();
    }
}

impl ArrayTCopy<T> of Copy<Array<T>>;
impl Felt252DictValueTCopy<T> of Copy<Felt252Dict<Nullable<Item<T>>>>;

impl TArraySerialize<
    T,
    impl TDrop: Drop<T>,
    impl TCopy: Copy<T>,
    impl TIntoT: Into<felt252, T>,
    impl TIntoFelt: Into<T, felt252>
> of Serde<Array<T>> {
    fn serialize(self: @Array<T>, ref output: Array<felt252>) {
        let mut span_arr = self.span();
        loop {
            match span_arr.pop_front() {
                Option::Some(v) => {
                    let as_felt: felt252 = (*v).into();
                    output.append(as_felt);
                },
                Option::None => {
                    break;
                }
            };
        }
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<Array<T>> {
        let mut arr: Array<T> = array![];
        loop {
            match serialized.pop_front() {
                Option::Some(v) => {
                    arr.append((*v).into());
                },
                Option::None => {
                    break;
                }
            };
        };
        Option::Some(arr)
    }
}

trait SerializableFelt252DictTrait<T> {
    /// Creates a new SerializableFelt252Dict object.
    fn new() -> SerializableFelt252Dict<T>;
    /// Adds an element.
    fn add_single(ref self: SerializableFelt252Dict<T>, key: felt252, value: T);
    /// Adds an array of elements.
    fn add_array(ref self: SerializableFelt252Dict<T>, key: felt252, values: Array<T>);
    /// Gets an element.
    fn get<impl TCopy: Copy<T>>(
        ref self: SerializableFelt252Dict<T>, key: felt252
    ) -> Option<Item<T>>;
    /// Checks if a key is in the dictionnary.
    fn contains_key(self: @SerializableFelt252Dict<T>, key: felt252) -> bool;
    /// Checks if a dictionnary is empty.
    fn is_empty(self: @SerializableFelt252Dict<T>) -> bool;
/// TODO: When Scarb is updated we can use unique() from Alexandria & have fn len()
}

impl SerializableFelt252DictTraitImpl<
    T, impl TDefault: Felt252DictValue<T>, impl TDrop: Drop<T>, impl TCopy: Copy<T>
> of SerializableFelt252DictTrait<T> {
    fn new() -> SerializableFelt252Dict<T> {
        SerializableFelt252Dict { keys: array![], values: Default::default() }
    }

    fn add_single(ref self: SerializableFelt252Dict<T>, key: felt252, value: T) {
        let value = Item::Single(value);
        self.values.insert(0, nullable_from_box(BoxTrait::new(value)));
    }

    fn add_array(ref self: SerializableFelt252Dict<T>, key: felt252, values: Array<T>) {
        let values = Item::Array(values);
        self.values.insert(0, nullable_from_box(BoxTrait::new(values)));
    }

    fn get<impl TCopy: Copy<T>>(
        ref self: SerializableFelt252Dict<T>, key: felt252
    ) -> Option<Item<T>> {
        match match_nullable(self.values.get(key)) {
            FromNullableResult::Null(()) => Option::None,
            FromNullableResult::NotNull(val) => Option::Some(val.unbox()),
        }
    }

    fn contains_key(self: @SerializableFelt252Dict<T>, key: felt252) -> bool {
        let mut keys: Span<felt252> = self.keys.span();
        let mut contains_key: bool = false;
        loop {
            match keys.pop_front() {
                Option::Some(value) => {
                    if *value == key {
                        contains_key = true;
                        break;
                    }
                },
                Option::None => {
                    break;
                },
            };
        };
        return contains_key;
    }

    fn is_empty(self: @SerializableFelt252Dict<T>) -> bool {
        self.keys.is_empty()
    }
}


impl SerializableFelt252DictSerde<
    T,
    impl TCopy: Copy<T>,
    impl TDrop: Drop<T>,
    impl FeltIntoT: Into<felt252, T>,
    impl TIntoFelt: Into<T, felt252>,
> of Serde<SerializableFelt252Dict<T>> {
    //
    // Serialization of an SerializableFelt252Dict
    //
    // An SerializableFelt252Dict is serialized as follow:
    // [ KEY | NB_ELEMENTS | X | Y | ... | KEY | NB_ELEMENTS | X | ...]
    //
    //
    // e.g. if we try to serialize this Dict:
    //      keys: [0, 1]
    //      values: {
    //          0: 1,
    //          1: [1, 2, 3]
    //      }
    //
    // will give:
    //
    //        key: 0       key: 1
    //      | ------ | ----------- |
    //      [0, 1, 1, 1, 3, 1, 2, 3] (Array<felt252>)
    //
    fn serialize(self: @SerializableFelt252Dict<T>, ref output: Array<felt252>) {
        let mut keys: Span<felt252> = self.keys.span();
        let mut included_keys: Array<felt252> = array![];
        loop {
            match keys.pop_back() {
                Option::Some(key) => {
                    if (!included_keys.contains(*key)) {
                        continue;
                    }
                    let mut ordered_dict = (*self);
                    let nullable_value: Nullable<Item<T>> = ordered_dict.values.get(*key);
                    let value: Item<T> = match match_nullable(nullable_value) {
                        FromNullableResult::Null(()) => panic_with_felt252(
                            'key not found (serialize)'
                        ),
                        FromNullableResult::NotNull(boxed_value) => boxed_value.unbox(),
                    };
                    match value {
                        Item::Single(v) => {
                            output.append(*key); // key
                            output.append(1_felt252); // len
                            output.append(v.into()); // value
                        },
                        Item::Array(arr) => {
                            output.append(*key); // key
                            output.append(arr.len().into()); // len
                            let mut arr_as_span: Span<T> = arr.span();
                            loop {
                                match arr_as_span.pop_front() {
                                    Option::Some(v) => {
                                        output.append((*v).into());
                                    },
                                    Option::None => {
                                        break;
                                    }
                                };
                            }
                        }
                    };
                    included_keys.append(*key);
                },
                Option::None => {
                    break;
                },
            };
        }
    }

    //
    // Deserialization of an SerializableFelt252Dict
    //
    // An SerializableFelt252Dict is serialized as follow:
    // [ KEY | NB_ELEMENTS | X | Y | ... | KEY | NB_ELEMENTS | X | ...]
    //
    fn deserialize(ref serialized: Span<felt252>) -> Option<SerializableFelt252Dict<T>> {
        let mut d: SerializableFelt252Dict<T> = SerializableFelt252Dict {
            keys: array![], values: Default::default()
        };
        loop {
            // Try to retrive the next key
            match serialized.pop_front() {
                Option::Some(key) => {
                    // Key found; try to retrieved the size of elements
                    match serialized.pop_front() {
                        Option::Some(size) => {
                            // If only one element, insert it & quit
                            if ((*size) == 1) {
                                let value: T = get_next_value_from(serialized);
                                let value: Item<T> = Item::Single(value);
                                d.values.insert(*key, nullable_from_box(BoxTrait::new(value)));
                                continue;
                            }
                            // Else append all elements into an array ...
                            let mut arr_size: felt252 = *size;
                            let mut arr_values: Array<T> = array![];
                            loop {
                                if (arr_size) == 0 {
                                    break;
                                };
                                let value: T = get_next_value_from(serialized);
                                arr_values.append(value);
                                arr_size -= 1;
                            };
                            // ... & insert it
                            let values: Item<T> = Item::Array(arr_values);
                            d.values.insert(*key, nullable_from_box(BoxTrait::new(values)));
                        },
                        Option::None => panic_with_felt252('err getting size')
                    }
                },
                Option::None => {
                    break;
                },
            };
        };
        Option::Some(d)
    }
}


fn get_next_value_from<T, impl TInto: Into<felt252, T>>(mut serialized: Span<felt252>) -> T {
    let value = match serialized.pop_front() {
        Option::Some(value) => value,
        Option::None => panic_with_felt252('err getting value')
    };
    let value: T = (*value).into();
    value
}
