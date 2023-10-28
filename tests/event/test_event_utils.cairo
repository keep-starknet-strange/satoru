use starknet::{
    get_caller_address, ContractAddress, Felt252TryIntoContractAddress, ContractAddressIntoFelt252,
    contract_address_const
};
use satoru::event::event_utils_sandbox::{
    Felt252IntoBool, Felt252IntoU128, Felt252IntoI128, Felt252IntoContractAddress, I128252DictValue,
    ContractAddressDictValue, LogData
};
use satoru::utils::traits::{ContractAddressDefault};
use traits::Default;
use satoru::utils::serializable_dict::{
    Item, ItemTrait, SerializableFelt252Dict, SerializableFelt252DictTrait,
    SerializableFelt252DictTraitImpl
};

#[test]
fn test_log_data_default() {
    let mut log_data: LogData = Default::default();

    // try to add things
    log_data.address_items.insert_single('test', contract_address_const::<0>());
    log_data.uint_items.insert_single('test', 12_u128);

    // assert results OK
    let addr_item = log_data.address_items.get('test').expect('key not found');
    let addr_value = addr_item.unwrap_single();
    assert(addr_value == contract_address_const::<0>(), 'addr value wrong');

    let uint_item = log_data.uint_items.get('test').expect('key not found');
    let uint_value = uint_item.unwrap_single();
    assert(uint_value == 12_u128, 'uint value wrong');
}

#[test]
fn test_log_data_default_each() {
    let mut log_data: LogData = LogData {
        address_items: Default::default(),
        uint_items: Default::default(),
        int_items: Default::default(),
        bool_items: Default::default(),
        felt252_items: Default::default(),
        string_items: Default::default()
    };

    // try to add things
    log_data.address_items.insert_single('test', contract_address_const::<0>());
    log_data.uint_items.insert_single('test', 12_u128);

    // assert results OK
    let addr_item = log_data.address_items.get('test').expect('key not found');
    let addr_value = addr_item.unwrap_single();
    assert(addr_value == contract_address_const::<0>(), 'addr value wrong');

    let uint_item = log_data.uint_items.get('test').expect('key not found');
    let uint_value = uint_item.unwrap_single();
    assert(uint_value == 12_u128, 'uint value wrong');
}

#[test]
fn test_log_data_multiple_types() {
    let mut log_data: LogData = Default::default();

    let arr_to_add: Array<ContractAddress> = array![
        contract_address_const::<'cairo'>(),
        contract_address_const::<'starknet'>(),
        contract_address_const::<'rust'>()
    ];

    // try to add unique
    log_data.address_items.insert_single('test', contract_address_const::<0>());
    log_data.address_items.insert_span('test_arr', arr_to_add.span());

    // assert results OK
    let addr_item = log_data.address_items.get('test').expect('key not found');
    let addr_value = addr_item.unwrap_single();
    assert(addr_value == contract_address_const::<0>(), 'addr value wrong');

    let addr_span_item: Item = log_data
        .address_items
        .get('test_arr')
        .expect('key should be in dict');
    let out_span: Span<ContractAddress> = addr_span_item.unwrap_span();
    assert(out_span.at(0) == arr_to_add.at(0), 'wrong at idx 0');
    assert(out_span.at(1) == arr_to_add.at(1), 'wrong at idx 1');
    assert(out_span.at(2) == arr_to_add.at(2), 'wrong at idx 2');
}

#[test]
fn test_log_data_serialization() {
    let mut log_data: LogData = Default::default();

    let arr_to_add: Array<ContractAddress> = array![
        contract_address_const::<'cairo'>(),
        contract_address_const::<'starknet'>(),
        contract_address_const::<'rust'>()
    ];

    // try to add unique
    log_data.address_items.insert_single('test', contract_address_const::<0>());
    log_data.address_items.insert_span('test_arr', arr_to_add.span());
}
