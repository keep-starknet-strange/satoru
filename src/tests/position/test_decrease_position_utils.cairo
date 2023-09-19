use starknet::{get_caller_address, ContractAddress, contract_address_const};
use array::ArrayTrait;
use snforge_std::{declare, ContractClassTrait, start_prank};

fn setup() { // TODO: implement
}

#[test]
fn given_normal_conditions_when_partially_decrease_position() {
    // TODO: implement
    assert(true, 'Not implemented yet');
}

#[test]
fn given_normal_conditions_when_totally_decrease_position() {
    // TODO: implement
    assert(true, 'Not implemented yet');
}
#[test]
#[should_panic]
fn given_invalid_decrease_order_size_when_decrease_position_then_fails() { // TODO: implement
    panic(array!['Not implemented yet']);
}

#[test]
#[should_panic]
fn given_unable_to_withdraw_collateral_when_decrease_position_then_fails() { // TODO: implement
    panic(array!['Not implemented yet']);
}

#[test]
#[should_panic]
fn given_position_should_be_liquidated_when_decrease_position_then_fails() { // TODO: implement
    panic(array!['Not implemented yet']);
}

