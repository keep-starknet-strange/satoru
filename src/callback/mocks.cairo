use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait};

use satoru::tests_lib::{setup, teardown, deploy_event_emitter};

#[starknet::interface]
trait ICallbackMock<TContractState> {
    fn get_counter(self: @TContractState) -> u32;
}

#[starknet::contract]
mod CallbackMock {
    use satoru::callback::deposit_callback_receiver::interface::IDepositCallbackReceiver;
    use satoru::deposit::deposit::Deposit;
    use satoru::event::event_utils::LogData;

    #[storage]
    struct Storage {
        counter: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.counter.write(1);
    }


    #[external(v0)]
    impl ICallbackMockImpl of super::ICallbackMock<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }
    }

    #[external(v0)]
    impl IDepositCallbackReceiverImpl of IDepositCallbackReceiver<ContractState> {
        fn after_deposit_execution(
            ref self: ContractState, key: felt252, deposit: Deposit, log_data: LogData,
        ) {
            self.counter.write(self.get_counter() + 1);
        }

        fn after_deposit_cancellation(
            ref self: ContractState, key: felt252, deposit: Deposit, log_data: LogData,
        ) {
            self.counter.write(self.get_counter() + 1);
        }
    }
}

fn deploy_callback_mock() -> ICallbackMockDispatcher {
    let contract = declare('CallbackMock');
    let contract_address = contract.deploy(@array![]).unwrap();
    ICallbackMockDispatcher { contract_address }
}
