use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait, ContractClass};
use starknet::{ContractAddress, contract_address_const, ClassHash, Felt252TryIntoContractAddress};
use traits::Default;

use satoru::deposit::deposit_utils::CreateDepositParams;
use satoru::oracle::oracle_utils::SetPricesParams;
use satoru::exchange::deposit_handler::{IDepositHandlerDispatcher, IDepositHandlerDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::role::role_module::{IRoleModuleDispatcher, IRoleModuleDispatcherTrait};
use satoru::utils::span32::{Span32, Array32Trait};

// TODO add assert and tests when deposit_vault will be implemented

#[test]
fn given_normal_conditions_when_create_cancel_deposit_then_works() {
    let deposit_handler = setup();

    let account = contract_address_const::<'account'>();
    let params = create_deposit_params();
// let key = deposit_handler.create_deposit(account, params);
// deposit_handler.cancel_deposit(key);
}

#[test]
fn given_normal_conditions_when_create_execute_deposit_then_works() {
    let deposit_handler = setup();

    let account = contract_address_const::<'account'>();
    let params = create_deposit_params();

    // let key = deposit_handler.create_deposit(account, params);

    let token1 = contract_address_const::<'token1'>();
    let price_feed_tokens1 = contract_address_const::<'price_feed_tokens'>();
    let oracle_params = SetPricesParams {
        signer_info: 123,
        tokens: array![token1],
        compacted_min_oracle_block_numbers: array![1],
        compacted_max_oracle_block_numbers: array![10],
        compacted_oracle_timestamps: array![1123],
        compacted_decimals: array![18],
        compacted_min_prices: array![2],
        compacted_min_prices_indexes: array![1],
        compacted_max_prices: array![5],
        compacted_max_prices_indexes: array![1],
        signatures: array![array!['signatures'].span()],
        price_feed_tokens: array![price_feed_tokens1],
    };
// deposit_handler.execute_deposit(key, oracle_params);
}

fn create_deposit_params() -> CreateDepositParams {
    CreateDepositParams {
        receiver: contract_address_const::<'receiver'>(),
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
        market: contract_address_const::<'market'>(),
        initial_long_token: contract_address_const::<'initial_long_token'>(),
        initial_short_token: contract_address_const::<'initial_short_token'>(),
        long_token_swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        short_token_swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        min_market_tokens: 10,
        execution_fee: 0,
        callback_gas_limit: 10,
    }
}

fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'data_store'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'role_store'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![], deployed_contract_address).unwrap()
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'event_emitter'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![], deployed_contract_address).unwrap()
}

fn deploy_oracle(
    role_store_address: ContractAddress,
    oracle_store_address: ContractAddress,
    pragma_address: ContractAddress
) -> ContractAddress {
    let contract = declare('Oracle');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'oracle'>();
    start_prank(deployed_contract_address, caller_address);
    contract
        .deploy_at(
            @array![role_store_address.into(), oracle_store_address.into(), pragma_address.into()],
            deployed_contract_address
        )
        .unwrap()
}

fn deploy_oracle_store(
    role_store_address: ContractAddress, event_emitter_address: ContractAddress,
) -> ContractAddress {
    let contract = declare('OracleStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'oracle_store'>();
    start_prank(deployed_contract_address, caller_address);
    contract
        .deploy_at(
            @array![role_store_address.into(), event_emitter_address.into()],
            deployed_contract_address
        )
        .unwrap()
}

fn deploy_deposit_vault(
    role_store_address: ContractAddress, data_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('DepositVault');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'deposit_vault'>();
    start_prank(deployed_contract_address, caller_address);
    contract
        .deploy_at(
            @array![data_store_address.into(), role_store_address.into()], deployed_contract_address
        )
        .unwrap()
}

fn deploy_deposit_handler(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    deposit_vault_address: ContractAddress,
    oracle_address: ContractAddress
) -> ContractAddress {
    let contract = declare('DepositHandler');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'deposit_handler'>();
    start_prank(deployed_contract_address, caller_address);
    contract
        .deploy_at(
            @array![
                data_store_address.into(),
                role_store_address.into(),
                event_emitter_address.into(),
                deposit_vault_address.into(),
                oracle_address.into()
            ],
            deployed_contract_address
        )
        .unwrap()
}

fn setup() -> IDepositHandlerDispatcher {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let event_emitter_address = deploy_event_emitter();
    let oracle_store_address = deploy_oracle_store(role_store_address, event_emitter_address);
    let oracle_address = deploy_oracle(
        role_store_address, oracle_store_address, contract_address_const::<'pragma'>()
    );
    let deposit_vault_address = deploy_deposit_vault(role_store_address, data_store_address);

    let deposit_handler_address = deploy_deposit_handler(
        data_store_address,
        role_store_address,
        event_emitter_address,
        deposit_vault_address,
        oracle_address
    );
    let deposit_handler = IDepositHandlerDispatcher { contract_address: deposit_handler_address };

    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    (deposit_handler)
}
