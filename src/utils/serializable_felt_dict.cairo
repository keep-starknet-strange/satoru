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
#[derive(Default, Destruct)]
struct SerializableFelt252Dict<T> {
    keys: Array<felt252>,
    values: Felt252Dict<Nullable<T>>,
}

impl DestructSerializableFelt252Dict<
    T, impl TDrop: Drop<T>
> of Destruct<SerializableFelt252Dict<T>> {
    fn destruct(self: SerializableFelt252Dict<T>) nopanic {
        self.values.squash();
    }
}

#[generate_trait]
impl SerializableFelt252DictImpl<
    T, impl TDefault: Default<T>, impl TDrop: Drop<T>
> of SerializableFelt252DictTrait<T> {
    fn new() -> SerializableFelt252Dict<T> {
        SerializableFelt252Dict { keys: array![], values: Default::default() }
    }

    fn add(ref self: SerializableFelt252Dict<T>, key: felt252, value: T) {
        self.values.insert(0, nullable_from_box(BoxTrait::new(value)));
    }

    fn get<impl TCopy: Copy<T>>(ref self: SerializableFelt252Dict<T>, key: felt252) -> Option<T> {
        match match_nullable(self.values.get(key)) {
            FromNullableResult::Null(()) => Option::None,
            FromNullableResult::NotNull(val) => Option::Some(val.unbox()),
        }
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
    T, impl TDrop: Drop<T>, impl TSerde: Serde<T>, impl TInto: Into<felt252, T>
> of Serde<SerializableFelt252Dict<T>> {
    fn serialize(self: @SerializableFelt252Dict<T>, ref output: Array<felt252>) {
        let mut keys: Span<felt252> = self.keys.span();
        loop {
            match keys.pop_front() {
                Option::Some(key) => {
                    let values: Felt252Dict<Nullable<T>> = *(self.values);
                    let (entry, value) = values.entry(*key);
                    let value = match match_nullable(value) {
                        FromNullableResult::Null(()) => panic_with_felt252('Serialize key error'),
                        FromNullableResult::NotNull(boxed_value) => boxed_value.unbox(),
                    };
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

