use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, event_name_hash, Event,
    EventAssertions
};

use satoru::event::event_emitter::{
    EventEmitter, IEventEmitterDispatcher, IEventEmitterDispatcherTrait
};

use satoru::event::event_emitter::EventEmitter::{
  DepositCreated, DepositExecuted, DepositCancelled
};

use satoru::deposit::deposit::Deposit;
use satoru::tests_lib::setup_event_emitter;

// #[test]

/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the event emitter contract.
/// * `IEventEmitterDispatcher` - The event emitter store dispatcher.
fn setup() -> (ContractAddress, IEventEmitterDispatcher) {
    let contract = declare('EventEmitter');
    let contract_address = contract.deploy(@array![]).unwrap();
    let event_emitter = IEventEmitterDispatcher { contract_address };
    return (contract_address, event_emitter);
}


fn create_dummy_deposit_param() -> CreateDepositParams {
    CreateDepositParams {
        /// The address to send the market tokens to.
        receiver: 'receiver'.try_into().unwrap(),
        /// The callback contract linked to this deposit.
        callback_contract: 'callback_contract'.try_into().unwrap(),
        /// The ui fee receiver.
        ui_fee_receiver: 'ui_fee_receiver'.try_into().unwrap(),
        /// The market to deposit into.
        market: 'market'.try_into().unwrap(),
        /// The initial long token address.
        initial_long_token: 'initial_long_token'.try_into().unwrap(),
        /// The initial short token address.
        initial_short_token: 'initial_short_token'.try_into().unwrap(),
        /// The swap path into markets for the long token.
        long_token_swap_path: array![
            1.try_into().unwrap(), 2.try_into().unwrap(), 3.try_into().unwrap()
        ]
            .span32(),
        /// The swap path into markets for the short token.
        short_token_swap_path: array![
            4.try_into().unwrap(), 5.try_into().unwrap(), 6.try_into().unwrap()
        ]
            .span32(),
        /// The minimum acceptable number of liquidity tokens.
        min_market_tokens: 10,
        /// The execution fee for keepers.
        execution_fee: 1,
        /// The gas limit for the callback_contract.
        callback_gas_limit: 20
    }
}
