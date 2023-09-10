// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use integer::Felt252TryIntoU128;
use option::OptionTrait;
use array::ArrayTrait;

/// gasleft() mock implementation.
/// Accepts Array<felt252> because we don't know how many parameters we need in future.
/// In mock way, the first element of array returned as result of gasleft.
#[inline(always)]
fn sn_gasleft(params: Array<felt252>) -> u128 {
    if (params.len() == 0) {
        return 0_u128;
    }

    let value: felt252 = *params.at(0);

    let result: u128 = value.try_into().unwrap();

    result
}

/// tx.gasprice mock implementation.
/// If its mock implementation, returns first element of parameter as result.
#[inline(always)]
fn sn_gasprice(params: Array<felt252>) -> u128 {
    if (params.len() == 0) {
        return 0_u128;
    }

    let value: felt252 = *params.at(0);

    let result: u128 = value.try_into().unwrap();

    result
}
