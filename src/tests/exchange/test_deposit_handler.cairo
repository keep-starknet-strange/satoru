use snforge_std::{declare, start_prank, stop_prank, ContractClassTrait, ContractClass};
use satoru::exchange::liquidation_handler::{
    LiquidationHandler, ILiquidationHandlerDispatcher, ILiquidationHandler,
    ILiquidationHandlerDispatcherTrait
};
use starknet::{ContractAddress, contract_address_const, ClassHash, Felt252TryIntoContractAddress};
use debug::PrintTrait;
use satoru::mock::referral_storage;
use traits::Default;
use satoru::oracle::oracle_utils::SetPricesParams;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait, IDataStore};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::role::role;
use satoru::role::role_module::{IRoleModuleDispatcher, IRoleModuleDispatcherTrait};
use satoru::order::order::{Order, OrderType, OrderTrait, DecreasePositionSwapType};
use satoru::utils::span32::{Span32, Array32Trait};

#[test]
fn given_normal_conditions_when_create_cancel_deposit_then_works() {
    let account = contract_address_const<'account'>();
    let params = CreateDepositParams {
        receiver: contract_address_const<'account'>(),
        callback_contract: contract_address_const<'account'>(),
        ui_fee_receiver: contract_address_const<'account'>(),
        market: contract_address_const<'account'>(),
        initial_long_token: contract_address_const<'account'>(),
        initial_short_token: contract_address_const<'account'>(),
        long_token_swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        short_token_swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        min_market_tokens: 10,
        execution_fee: 5,
        callback_gas_limit: 10,
    };

    let key = deposit_handler.create_deposit(account, params);

    deposit_handler.cancel_deposit(key);
}

#[test]
fn given_normal_conditions_when_create_execute_deposit_then_works() {
    let account = contract_address_const<'account'>();
    let params = CreateDepositParams {
        receiver: contract_address_const<'account'>(),
        callback_contract: contract_address_const<'account'>(),
        ui_fee_receiver: contract_address_const<'account'>(),
        market: contract_address_const<'account'>(),
        initial_long_token: contract_address_const<'account'>(),
        initial_short_token: contract_address_const<'account'>(),
        long_token_swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        short_token_swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
        min_market_tokens: 10,
        execution_fee: 5,
        callback_gas_limit: 10,
    };

    let key = deposit_handler.create_deposit(account, params);

    SetPricesParams {
        signer_info: u128,
        tokens: Array<ContractAddress>,
        compacted_min_oracle_block_numbers: Array<u64>,
        compacted_max_oracle_block_numbers: Array<u64>,
        compacted_oracle_timestamps: Array<u64>,
        compacted_decimals: Array<u128>,
        compacted_min_prices: Array<u128>,
        compacted_min_prices_indexes: Array<u128>,
        compacted_max_prices: Array<u128>,
        compacted_max_prices_indexes: Array<u128>,
        signatures: Array<felt252>,
        price_feed_tokens: Array<ContractAddress>,
    }

    deposit_handler.execute_deposit(key);
}

//test cancel un truc qui n'existe pas

//test simulateexecute

//test excute un truc qui n'existe pas

fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    contract.deploy(@array![]).unwrap()
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    contract.deploy(@array![]).unwrap()
}

fn deploy_oracle(
    role_store_address: ContractAddress,
    oracle_store_address: ContractAddress,
    pragma_address: ContractAddress
) -> ContractAddress {
    let contract = declare('Oracle');
    contract
        .deploy(
            @array![role_store_address.into(), oracle_store_address.into(), pragma_address.into()]
        )
        .unwrap()
}

fn deploy_referral_storage() -> ContractAddress {
    let contract = declare('ReferralStorage');
    contract.deploy(@array![]).unwrap()
}

fn deploy_oracle_store(
    role_store_address: ContractAddress, event_emitter_address: ContractAddress,
) -> ContractAddress {
    let contract = declare('OracleStore');
    contract.deploy(@array![role_store_address.into(), event_emitter_address.into()]).unwrap()
}

fn _setup() -> (
    IDataStoreDispatcher, ContractAddress, ContractAddress, ILiquidationHandlerDispatcher
) {
    let caller_address: ContractAddress = 0x101.try_into().unwrap();
    let liquidation_keeper: ContractAddress = 0x2233.try_into().unwrap();
    let role_store_address = deploy_role_store();
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };
    let data_store_address = deploy_data_store(role_store_address);
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };
    let event_emitter_address = deploy_event_emitter();
    let order_vault_address = deploy_order_vault(data_store_address, role_store_address);
    let swap_handler_address = deploy_swap_handler(role_store_address);
    let oracle_store_address = deploy_oracle_store(role_store_address, event_emitter_address);
    let oracle_address = deploy_oracle(
        role_store_address, oracle_store_address, contract_address_const::<'pragma'>()
    );
    //let referral_storage_address = deploy_referral_storage();
    let liquidation_handler_address = deploy_liquidation_handler(
        role_store_address,
        data_store_address,
        event_emitter_address,
        order_vault_address,
        swap_handler_address,
        oracle_address
    );
    let liquidation_handler_dispatcher = ILiquidationHandlerDispatcher {
        contract_address: liquidation_handler_address
    };
    let role_module = deploy_role_module(role_store_address);
    start_prank(role_store_address, caller_address);
    role_store.grant_role(caller_address, role::CONTROLLER);
    role_store.grant_role(liquidation_keeper, role::LIQUIDATION_KEEPER);
    role_store.grant_role(liquidation_keeper, role::ORDER_KEEPER);
    role_store.grant_role(liquidation_handler_address, role::FROZEN_ORDER_KEEPER);
    role_store.grant_role(liquidation_handler_address, role::CONTROLLER);
    start_prank(data_store_address, caller_address);
    (data_store, liquidation_keeper, liquidation_handler_address, liquidation_handler_dispatcher)
}
