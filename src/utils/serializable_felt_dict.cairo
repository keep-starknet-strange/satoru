use core::array::SpanTrait;
use core::array::ArrayTrait;
use core::traits::Into;
use starknet::{get_caller_address, ContractAddress, contract_address_const};
use traits::Default;
use dict::Felt252DictTrait;
use nullable::{nullable_from_box, match_nullable, FromNullableResult};

///
/// SerializableFelt252Dict
///
/// Wrapper around the Felt252Dict.
/// It behaves the same as a regular dict but has also a keys parameter
/// that keeps track of the keys registered.
/// This allows us to serialize & deserialize the struct, which is not
/// possible with a regular Felt252Dict.
///
/// * keys: Array<felt252> => the keys currently stored in the dictionnary
/// * values: Felt252Dict<Nullable<T>> => dictionnary containing the values of type T
///
#[derive(Default, Drop)]
struct SerializableFelt252Dict<T> {
    keys: Array<felt252>,
    values: Felt252Dict<Nullable<T>>,
}

impl Felt252DictDrop<T, impl TDrop: Drop<T>> of Drop<Felt252Dict<T>>;
impl Felt252DictCopy<T, impl TCopy: Copy<T>> of Copy<Felt252Dict<T>>;

trait SerializableFelt252DictTrait<T> {
    /// Creates a new SerializableFelt252Dict object.
    fn new() -> SerializableFelt252Dict<T>;
    /// Adds an element.
    fn add(ref self: SerializableFelt252Dict<T>, key: felt252, value: T);
    /// Gets an element.
    fn get<impl TCopy: Copy<T>>(ref self: SerializableFelt252Dict<T>, key: felt252) -> T;
    /// Checks if a key is in the dictionnary.
    fn contains_key(self: @SerializableFelt252Dict<T>, key: felt252) -> bool;
    /// Length of the dictionnary.
    fn len(self: @SerializableFelt252Dict<T>) -> usize;
    /// Checks if a dictionnary is empty.
    fn is_empty(self: @SerializableFelt252Dict<T>) -> bool;
}

impl SerializableFelt252DictImpl<
    T, impl TDefault: Felt252DictValue<T>, impl TDrop: Drop<T>, impl TCopy: Copy<T>
> of SerializableFelt252DictTrait<T> {
    fn new() -> SerializableFelt252Dict<T> {
        SerializableFelt252Dict { keys: array![], values: Default::default() }
    }

    fn add(ref self: SerializableFelt252Dict<T>, key: felt252, value: T) {
        self.values.insert(0, nullable_from_box(BoxTrait::new(value)));
    }

    fn get<impl TCopy: Copy<T>>(ref self: SerializableFelt252Dict<T>, key: felt252) -> T {
        match match_nullable(self.values.get(key)) {
            FromNullableResult::Null(()) => panic_with_felt252('No value found'),
            FromNullableResult::NotNull(val) => val.unbox(),
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

    fn len(self: @SerializableFelt252Dict<T>) -> usize {
        self.keys.len()
    }

    fn is_empty(self: @SerializableFelt252Dict<T>) -> bool {
        self.keys.is_empty()
    }
}

/// TODO: Currently only the value is serizalized & we loose the key information.
impl SerializableFelt252DictSerde<
    T, impl TDrop: Drop<T>, impl TCopy: Copy<T>, impl TSerde: Serde<T>, impl TInto: Into<felt252, T>
> of Serde<SerializableFelt252Dict<T>> {
    fn serialize(self: @SerializableFelt252Dict<T>, ref output: Array<felt252>) {
        let mut keys: Span<felt252> = self.keys.span();
        loop {
            match keys.pop_front() {
                Option::Some(key) => {
                    let mut values: Felt252Dict<Nullable<T>> = *self.values;
                    let value = match match_nullable(values.get(*key)) {
                        FromNullableResult::Null(()) => panic_with_felt252('Serialize key error'),
                        FromNullableResult::NotNull(boxed_value) => boxed_value.unbox(),
                    };
                    value.serialize(ref output);
                },
                Option::None => {
                    break;
                },
            };
        }
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<SerializableFelt252Dict<T>> {
        let mut current_key: felt252 = 0;
        let mut d: SerializableFelt252Dict<T> = SerializableFelt252Dict {
            keys: array![], values: Default::default()
        };
        loop {
            match serialized.pop_front() {
                Option::Some(value) => {
                    let value: T = (*value).into();
                    let value = nullable_from_box(BoxTrait::new(value));
                    d.values.insert(current_key, value);
                    d.keys.append(current_key);
                    current_key += 1;
                },
                Option::None => {
                    break;
                },
            };
        };
        Option::Some(d)
    }
}

