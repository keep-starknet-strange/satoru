// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;
use result::ResultTrait;
use traits::{Into, TryInto};
use option::OptionTrait;

// Local imports.
use gojo::data::data_store::{IDataStoreSafeDispatcher, IDataStoreSafeDispatcherTrait};
use gojo::withdrawal::withdrawal::{Withdrawal};

fn get(data_store: IDataStoreSafeDispatcher, key: felt252) -> Withdrawal {
    //TODO
    let contrac_zero: ContractAddress = 0.try_into().unwrap();
    Withdrawal {
        account: contrac_zero,
        receiver: contrac_zero,
        callback_contract: contrac_zero,
        ui_fee_receiver: contrac_zero,
        market: contrac_zero,
        long_token_swap_path: ArrayTrait::new(),
        short_token_swap_path: ArrayTrait::new(),
        market_token_amount: 0,
        min_long_token_amount: 0,
        min_short_token_amount: 0,
        updated_at_block: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
        should_unwrap_native_token: true,
    }
}

#[inline(always)]
fn set(data_store: IDataStoreSafeDispatcher, key: felt252, withdrawal: Withdrawal) { //TODO
}

fn remove(data_store: IDataStoreSafeDispatcher, key: felt252, account: ContractAddress) { //TODO
}

fn get_withdrawal_count(data_store: IDataStoreSafeDispatcher) -> u128 {
    //TODO
    0
}

fn get_withdrawal_keys(
    data_store: IDataStoreSafeDispatcher, start: u128, end: u128
) -> Array<felt252> {
    //TODO
    ArrayTrait::new()
}

fn get_account_withdrawal_count(
    data_store: IDataStoreSafeDispatcher, account: ContractAddress
) -> u128 {
    //TODO
    0
}

fn get_account_withdrawal_keys(
    data_store: IDataStoreSafeDispatcher, account: ContractAddress, start: u128, end: u128
) -> Array<felt252> {
    //TODO
    ArrayTrait::new()
}
