use starknet::{
    get_caller_address, ContractAddress, Felt252TryIntoContractAddress, ContractAddressIntoFelt252,
    contract_address_const
};
use array::ArrayTrait;
use satoru::utils::i128::i128;
use traits::Default;
use satoru::utils::traits::ContractAddressDefault;

use satoru::utils::serializable_dict::{SerializableFelt252Dict, SerializableFelt252DictTrait};

use alexandria_data_structures::array_ext::SpanTraitExt;


//
//     NEEDED IMPLEMENTATIONS FOR LOGDATA TYPES
//

impl Felt252IntoBool of Into<felt252, bool> {
    fn into(self: felt252) -> bool {
        let as_u128: u128 = self.try_into().expect('u128 Overflow');
        as_u128 > 0
    }
}

impl Felt252IntoU128 of Into<felt252, u128> {
    fn into(self: felt252) -> u128 {
        self.try_into().expect('u128 Overflow')
    }
}

impl Felt252IntoI128 of Into<felt252, i128> {
    fn into(self: felt252) -> i128 {
        self.try_into().expect('i128 Overflow')
    }
}

impl Felt252IntoContractAddress of Into<felt252, ContractAddress> {
    fn into(self: felt252) -> ContractAddress {
        Felt252TryIntoContractAddress::try_into(self).expect('contractaddress overflow')
    }
}

impl I128252DictValue of Felt252DictValue<i128> {
    fn zero_default() -> i128 nopanic {
        i128 { mag: 0, sign: false }
    }
}

impl ContractAddressDictValue of Felt252DictValue<ContractAddress> {
    fn zero_default() -> ContractAddress nopanic {
        contract_address_const::<0>()
    }
}

//
//      LOG DATA IMPLEMENTATION
//

//TODO Switch the append with a set in the functions when its available
#[derive(Default, Serde, Destruct)]
struct EventLogData {
    cant_be_empty: u128, // remove 
// TODO
}

#[derive(Default, Destruct)]
struct LogData {
    address_dict: SerializableFelt252Dict<ContractAddress>,
    uint_dict: SerializableFelt252Dict<u128>,
    int_dict: SerializableFelt252Dict<i128>,
    bool_dict: SerializableFelt252Dict<bool>,
    felt252_dict: SerializableFelt252Dict<felt252>,
    string_dict: SerializableFelt252Dict<felt252>
}

/// Number of dicts presents in LogData
const DICTS_IN_LOGDATA: usize = 6;

/// When serializing dicts into a unique Array<felt252>, this is the value that will
/// be used to recognized a separation between two dicts.
const END_OF_DICT: felt252 = '______';

#[generate_trait]
impl LogDataImpl of LogDataTrait {
    /// Serializes all the sub-dicts of LogData & append all of them into a new felt252 array
    fn serialize(ref self: LogData, ref output: Array<felt252>) {
        let mut serialized_dicts: Array<Array<felt252>> = array![
            self.address_dict.serialize_into(),
            self.uint_dict.serialize_into(),
            self.int_dict.serialize_into(),
            self.bool_dict.serialize_into(),
            self.felt252_dict.serialize_into(),
            self.string_dict.serialize_into()
        ];
        let mut span_arrays = serialized_dicts.span();
        loop {
            match span_arrays.pop_front() {
                Option::Some(arr) => {
                    let mut sub_array_span = arr.span();
                    loop {
                        match sub_array_span.pop_front() {
                            Option::Some(v) => {
                                output.append(*v);
                            },
                            Option::None => {
                                break;
                            }
                        };
                    };
                    output.append(END_OF_DICT);
                },
                Option::None => {
                    break;
                }
            };
        };
    }

    /// Serializes all the sub-dicts of LogData & return the serialized data
    fn serialize_into(ref self: LogData) -> Array<felt252> {
        let mut serialized_data: Array<felt252> = array![];
        self.serialize(ref serialized_data);
        serialized_data
    }

    /// Deserialize all the sub-dicts serialized into a LogData
    fn deserialize(ref serialized: Span<felt252>) -> Option<LogData> {
        // There should be the right amount of dictionnaries serialized
        if serialized.occurrences_of(END_OF_DICT) != DICTS_IN_LOGDATA {
            panic_with_felt252('serialized format error');
        }

        // Deserialize all dicts one by one
        let mut serialized_dict = get_next_dict_serialized(ref serialized);
        let address_dict = SerializableFelt252DictTrait::<ContractAddress>::deserialize(
            ref serialized_dict
        )
            .expect('deserialize err address');

        let mut serialized_dict = get_next_dict_serialized(ref serialized);
        let uint_dict = SerializableFelt252DictTrait::<u128>::deserialize(ref serialized_dict)
            .expect('deserialize err uint');

        let mut serialized_dict = get_next_dict_serialized(ref serialized);
        let int_dict = SerializableFelt252DictTrait::<i128>::deserialize(ref serialized_dict)
            .expect('deserialize err int');

        let mut serialized_dict = get_next_dict_serialized(ref serialized);
        let bool_dict = SerializableFelt252DictTrait::<bool>::deserialize(ref serialized_dict)
            .expect('deserialize err bool');

        let mut serialized_dict = get_next_dict_serialized(ref serialized);
        let felt252_dict = SerializableFelt252DictTrait::<felt252>::deserialize(ref serialized_dict)
            .expect('deserialize err felt252');

        let mut serialized_dict = get_next_dict_serialized(ref serialized);
        let string_dict = SerializableFelt252DictTrait::<felt252>::deserialize(ref serialized_dict)
            .expect('deserialize err string');

        // Create the LogData struct with every dicts
        let log_data: LogData = LogData {
            address_dict, uint_dict, int_dict, bool_dict, felt252_dict, string_dict
        };

        Option::Some(log_data)
    }
}


//
//      UTILITY FUNCTION
//

/// Pop every elements from the span until the next occurences of END_OF_DICT or
/// the end of the Span and return those values in a Span.
fn get_next_dict_serialized(ref serialized: Span<felt252>) -> Span<felt252> {
    let mut dict_data: Array<felt252> = array![];
    loop {
        match serialized.pop_front() {
            Option::Some(v) => {
                if *v == END_OF_DICT {
                    break;
                } else {
                    dict_data.append(*v);
                }
            },
            Option::None => {
                break;
            }
        };
    };
    dict_data.span()
}
