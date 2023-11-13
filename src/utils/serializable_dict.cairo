use core::serde::Serde;
use core::array::SpanTrait;
use core::array::ArrayTrait;
use core::traits::Into;
use starknet::{get_caller_address, ContractAddress, contract_address_const};
use traits::Default;
use dict::{Felt252DictTrait, Felt252Dict};
use nullable::{nullable_from_box, match_nullable, FromNullableResult, Nullable};

use alexandria_data_structures::array_ext::ArrayTraitExt;

///
/// Item
///
/// Enumeration used to store a value in a SerializableDict.
/// It allows to store either a simple value (Single) or a 
/// Span & comes with utilities functions.
///
#[derive(Drop, Copy)]
enum Item<T> {
    Single: T,
    Span: Span<T>
}

#[generate_trait]
impl ItemImpl<T> of ItemTrait<T> {
    fn is_single(self: @Item<T>) -> bool {
        match self {
            Item::Single(v) => true,
            Item::Span(arr) => false
        }
    }

    fn is_span(self: @Item<T>) -> bool {
        !self.is_single()
    }

    fn len(self: @Item<T>) -> usize {
        match self {
            Item::Single(v) => 1,
            Item::Span(s) => (*s).len()
        }
    }

    fn unwrap_single<impl TCopy: Copy<T>>(self: @Item<T>) -> T {
        match self {
            Item::Single(v) => (*v),
            Item::Span(arr) => panic_with_felt252('should be single')
        }
    }

    fn unwrap_span(self: @Item<T>) -> Span<T> {
        match self {
            Item::Single(v) => panic_with_felt252('should be a span'),
            Item::Span(arr) => *arr
        }
    }
}

impl ItemPartialEq<T, +Copy<T>, +PartialEq<T>, +Drop<T>> of PartialEq<Item<T>> {
    fn eq(lhs: @Item<T>, rhs: @Item<T>) -> bool {
        if lhs.is_single() && rhs.is_single() {
            return lhs.unwrap_single() == rhs.unwrap_single();
        } else if lhs.is_span() && rhs.is_span() {
            return lhs.unwrap_span() == rhs.unwrap_span();
        }
        return false;
    }
    fn ne(lhs: @Item<T>, rhs: @Item<T>) -> bool {
        if lhs.is_single() && rhs.is_single() {
            return !(lhs.unwrap_single() == rhs.unwrap_single());
        } else if lhs.is_span() && rhs.is_span() {
            return !(lhs.unwrap_span() == rhs.unwrap_span());
        }
        return true;
    }
}

///
/// SerializableFelt252Dict
///
/// Wrapper around the Felt252Dict.
/// It behaves the same as a regular dict but has also a keys parameter
/// that keeps track of the keys registered.
/// This allows us to serialize & deserialize the struct, which is not
/// possible with a regular Felt252Dict.
/// The values are wrapped around an Item struct that allows to store
/// different types of data: a simple value or a span.
///
#[derive(Default)]
struct SerializableFelt252Dict<T> {
    keys: Array<felt252>,
    values: Felt252Dict<Nullable<Item<T>>>
}

impl SerializableFelt252DictDestruct<
    T, +Drop<T>, +Felt252DictValue<T>
> of Destruct<SerializableFelt252Dict<T>> {
    fn destruct(self: SerializableFelt252Dict<T>) nopanic {
        self.values.squash();
        self.keys.destruct();
    }
}

trait SerializableFelt252DictTrait<T> {
    /// Creates a new SerializableFelt252Dict object.
    fn new() -> SerializableFelt252Dict<T>;
    /// Adds an element.
    fn insert_single(ref self: SerializableFelt252Dict<T>, key: felt252, value: T);
    /// Adds an array of elements.
    fn insert_span(ref self: SerializableFelt252Dict<T>, key: felt252, values: Span<T>);
    /// Gets an element.
    fn get(ref self: SerializableFelt252Dict<T>, key: felt252) -> Option<Item<T>>;
    /// Checks if a key is in the dictionnary.
    fn contains(self: @SerializableFelt252Dict<T>, key: felt252) -> bool;
    /// Number of keys in the dictionnary.
    fn len(self: @SerializableFelt252Dict<T>) -> usize;
    /// Checks if a dictionnary is empty.
    fn is_empty(self: @SerializableFelt252Dict<T>) -> bool;
    /// Serializes the dictionnary & return the result
    fn serialize_into(ref self: SerializableFelt252Dict<T>) -> Array<felt252>;
    /// Serializes the dictionnary into the provided output array
    fn serialize(ref self: SerializableFelt252Dict<T>, ref output: Array<felt252>);
    /// Deserializes the serialized array & return the dictionnary
    fn deserialize(ref serialized: Span<felt252>) -> Option<SerializableFelt252Dict<T>>;
}

impl SerializableFelt252DictTraitImpl<
    T,
    impl TDefault: Felt252DictValue<T>,
    impl TDrop: Drop<T>,
    impl TCopy: Copy<T>,
    impl FeltIntoT: Into<felt252, T>,
    impl TIntoFelt: Into<T, felt252>,
> of SerializableFelt252DictTrait<T> {
    fn new() -> SerializableFelt252Dict<T> {
        SerializableFelt252Dict { keys: array![], values: Default::default() }
    }

    fn insert_single(ref self: SerializableFelt252Dict<T>, key: felt252, value: T) {
        let value = Item::Single(value);
        if !self.keys.contains(key) {
            self.keys.append(key);
        }
        self.values.insert(key, nullable_from_box(BoxTrait::new(value)));
    }

    fn insert_span(ref self: SerializableFelt252Dict<T>, key: felt252, values: Span<T>) {
        let values = Item::Span(values);
        if !self.keys.contains(key) {
            self.keys.append(key);
        }
        self.values.insert(key, nullable_from_box(BoxTrait::new(values)));
    }

    fn get(ref self: SerializableFelt252Dict<T>, key: felt252) -> Option<Item<T>> {
        match match_nullable(self.values.get(key)) {
            FromNullableResult::Null(()) => Option::None,
            FromNullableResult::NotNull(val) => Option::Some(val.unbox()),
        }
    }

    fn contains(self: @SerializableFelt252Dict<T>, key: felt252) -> bool {
        let mut keys: Span<felt252> = self.keys.span();
        let mut contains_key: bool = false;
        loop {
            match keys.pop_front() {
                Option::Some(value) => { if *value == key {
                    contains_key = true;
                    break;
                } },
                Option::None => { break; },
            };
        };
        return contains_key;
    }

    fn len(self: @SerializableFelt252Dict<T>) -> usize {
        self.keys.len()
    }

    fn is_empty(self: @SerializableFelt252Dict<T>) -> bool {
        self.len() == 0
    }

    fn serialize_into(ref self: SerializableFelt252Dict<T>) -> Array<felt252> {
        let mut serialized_data: Array<felt252> = array![];
        self.serialize(ref serialized_data);
        serialized_data
    }

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
    fn serialize(ref self: SerializableFelt252Dict<T>, ref output: Array<felt252>) {
        let mut keys: Span<felt252> = self.keys.span();
        loop {
            match keys.pop_front() {
                Option::Some(key) => {
                    let value: Item<T> = self.get(*key).expect('key should exist');
                    match value {
                        Item::Single(v) => {
                            output.append(*key); // key
                            output.append(1); // len
                            output.append(v.into()); // value
                        },
                        Item::Span(mut arr) => {
                            output.append(*key); // key
                            output.append(arr.len().into()); // len
                            loop { // append each values
                                match arr.pop_front() {
                                    Option::Some(v) => { output.append((*v).into()); },
                                    Option::None => { break; }
                                };
                            };
                        },
                    };
                },
                Option::None => { break; },
            };
        };
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
                                let value: T = match serialized.pop_front() {
                                    Option::Some(value) => (*value).into(),
                                    Option::None => panic_with_felt252('err getting value')
                                };
                                let value: Item<T> = Item::Single(value);
                                d.keys.append(*key);
                                d.values.insert(*key, nullable_from_box(BoxTrait::new(value)));
                                continue;
                            };
                            // Else append all elements into an array ...
                            let mut arr_size: felt252 = *size;
                            let mut arr_values: Array<T> = array![];
                            loop {
                                if (arr_size) == 0 {
                                    break;
                                };
                                let value: T = match serialized.pop_front() {
                                    Option::Some(value) => (*value).into(),
                                    Option::None => panic_with_felt252('err getting value')
                                };
                                arr_values.append(value);
                                arr_size -= 1;
                            };
                            // ... & insert it
                            let values: Item<T> = Item::Span(arr_values.span());
                            d.keys.append(*key);
                            d.values.insert(*key, nullable_from_box(BoxTrait::new(values)));
                        },
                        Option::None => panic_with_felt252('err getting size')
                    }
                },
                Option::None => { break; },
            };
        };
        Option::Some(d)
    }
}
