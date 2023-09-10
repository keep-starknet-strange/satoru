use satoru::tests_lib::{setup, teardown};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::bank::bank::{IBankDispatcher, IBankDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use snforge_std::{ declare, ContractClassTrait, start_prank };
use satoru::swap::swap_utils::SwapParams;


fn deploy_data_store(data_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let constructor_calldata = array![data_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_event_emitter(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('EventEmitter');
    let constructor_calldata = array![event_emitter_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_oracle(oracle_address: ContractAddress) -> ContractAddress {
    let contract = declare('Oracle');
    let constructor_calldata = array![oracle_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_bank_address(bank_address: ContractAddress) -> ContractAddress {
    let contract = declare('Bank');
    let constructor_calldata = array![bank_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_role_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('Role');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}


/// Utility function to setup the test environment.
///
/// # Returns
///
/// * `ContractAddress` - The address of the caller.
/// * `IRoleStoreDispatcher` - The role store dispatcher.
/// * `IDataStoreDispatcher` - The data store dispatcher.
fn setup() -> (ContractAddress, IDataStoreDispatcher, IEventEmitterDispatcher, IOracleDispatcher, IBankDispatcher, IRoleStoreDispatcher) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();

    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    let event_emitter_address = deploy_event_emitter(event_emitter.address);
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    let oracle_address = deploy_oracle(oracle.address);
    let oracle = IOracleDispatcher { contract_address: oracle_address };

    let bank_address = deploy_bank_address(bank.address);
    let bank = IBankDispatcher { contract_address: bank_address };

    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };


    start_prank(role_store_address, caller_address);
    start_prank(event_emitter_address, caller_address);
    start_prank(oracle_address, caller_address);
    start_prank(bank_address, caller_address);
    start_prank(data_store_address, caller_address);

    role_store.grant_role(caller_address, role::CONTROLLER);

    (caller_address, data_store, event_emitter, oracle, bank, role_store)
}


#[test]
#[should_panic(expected: ('unauthorized_access',))]
fn test_check_controller_role() {
    let (caller_address, data_store, event_emitter, oracle, bank, role_store) = setup();
    let contract = declare('SwapHandler');
    let contract_address = contract.deploy(@ArrayTrait::new()).unwrap();
    let dispatcher = ISwapHandlerDispatcher { contract_address };
    role_store.revoke_role(caller_address, role::CONTROLLER);

    let mut market =  Market {
        market_token: 1.try_into().unwrap(),
        index_token: 1.try_into().unwrap(),
        long_token: 1.try_into().unwrap(),
        short_token: 1.try_into().unwrap(),
    };

    let mut swap = SwapParams {
        data_store: data_store,
        event_emitter: event_emitter,
        oracle: oracle,
        bank: bank,
        key: 1,
        token_in: 1.try_into().unwrap(),
        amount_in: 1,
        swap_path_markets: ArrayTrait::new(market),
        min_output_amount: 1,
        receiver: 1.try_into().unwrap(),
        ui_fee_receiver: 1.try_into().unwrap(),
        should_unwrap_native_token: true,
    };

    dispatcher.swap(contract_address,swap);
    teardown(data_store.contract_address);
}


struct SwapParams {
    data_store: IDataStoreDispatcher,
    event_emitter: IEventEmitterDispatcher,
    oracle: IOracleDispatcher,
    bank: IBankDispatcher,
    key: felt252,
    token_in: ContractAddress,
    amount_in: u128,
    swap_path_markets: Array<Market>,
    min_output_amount: u128,
    receiver: ContractAddress,
    ui_fee_receiver: ContractAddress,
    should_unwrap_native_token: bool,
}