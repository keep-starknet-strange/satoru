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
//     NEEDED IMPLEMENTATIONS FOR LOGDATA TYPES
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

#[derive(Default, Destruct)]
struct LogData {
    address_dict: SerializableFelt252Dict<ContractAddress>,
    uint_dict: SerializableFelt252Dict<u128>,
    int_dict: SerializableFelt252Dict<i128>,
    bool_dict: SerializableFelt252Dict<bool>,
    felt252_dict: SerializableFelt252Dict<felt252>,
    // TODO? Possible? array_of_felt_dict: SerializableFelt252Dict<Array<felt252>>,
    string_dict: SerializableFelt252Dict<felt252>
}

#[generate_trait]
impl LogDataImpl of LogDataTrait {
    /// Serializes all the sub-dicts of LogData & append all the felt252 array together
    fn serialize(ref self: LogData, ref output: Array<felt252>) {
        let mut serialized_dicts: Array<Array<felt252>> = array![];
        serialized_dicts.append(self.address_dict.serialize_into());
        serialized_dicts.append(self.uint_dict.serialize_into());
        serialized_dicts.append(self.int_dict.serialize_into());
        serialized_dicts.append(self.bool_dict.serialize_into());
        serialized_dicts.append(self.felt252_dict.serialize_into());
        serialized_dicts.append(self.string_dict.serialize_into());
        append_all_arrays_to_output(serialized_dicts, ref output);
    }

    fn serialize_into(ref self: LogData) -> Array<felt252> {
        let mut serialized_data: Array<felt252> = array![];
        self.serialize(ref serialized_data);
        serialized_data
    }

    /// Deserialize all the sub-dicts serialized into a LogData
    fn deserialize(ref serialized: Span<felt252>) -> Option<LogData> {
        // TODO + needed?
        Option::Some(Default::default())
    }
}

//
//      UTILITIES
//

// When serializing dicts into a unique Array<felt252>, this is the value that will
// be used to recognized a separation between two dicts.
const DICT_SEPARATION: felt252 = '______';

fn append_all_arrays_to_output(array_of_arrays: Array<Array<felt252>>, ref output: Array<felt252>) {
    let mut span_arrays = array_of_arrays.span();

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
                output.append(DICT_SEPARATION);
            },
            Option::None => {
                break;
            }
        };
    }
}
