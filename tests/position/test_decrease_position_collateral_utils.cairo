// Core lib imports.
use array::ArrayTrait;
use core::traits::{Into, TryInto};
use snforge_std::{declare, ContractClassTrait, start_prank};
use starknet::{ContractAddress, contract_address_const};

// Local imports.
use satoru::data::{data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait}, keys};
use satoru::event::event_emitter::IEventEmitterDispatcher;
use satoru::market::{market::Market, market_utils::MarketPrices};
use satoru::mock::referral_storage::IReferralStorageDispatcher;
use satoru::oracle::oracle::IOracleDispatcher;
use satoru::order::{
    order::{DecreasePositionSwapType, Order, OrderType, SecondaryOrderType},
    base_order_utils::{ExecuteOrderParams, ExecuteOrderParamsContracts},
    order_vault::IOrderVaultDispatcher
};
use satoru::position::{
    position_utils::{UpdatePositionParams, DecreasePositionCache, DecreasePositionCollateralValues},
    position::Position, decrease_position_collateral_utils
};
use satoru::price::price::Price;
use satoru::swap::swap_handler::ISwapHandlerDispatcher;
use satoru::tests_lib::{setup, teardown, setup_event_emitter};
use satoru::utils::span32::{Span32, Array32Trait};

/// Utility function to deploy a `SwapHandler` contract and return its dispatcher.
fn deploy_swap_handler_address(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('SwapHandler');
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

fn deploy_token() -> ContractAddress {
    let contract = declare('ERC20');
    let constructor_calldata = array!['Test', 'TST', 1000000, 0, 0x101];
    contract.deploy(@constructor_calldata).unwrap()
}

/// Utility function to deploy a `ReferralStorage` contract and return its dispatcher.
fn deploy_referral_storage(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('ReferralStorage');
    let constructor_calldata = array![event_emitter_address.into()];
    contract.deploy(@constructor_calldata).unwrap()
}

#[test]
fn given_good_params_when_process_collateral_then_succeed() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();
    let (event_emitter_address, event_emitter) = setup_event_emitter();
    let long_token_address = deploy_token();

    // setting open_interest to 10_000 to allow decreasing position.
    data_store
        .set_u128(
            keys::open_interest_key(
                contract_address_const::<'market_token'>(), long_token_address, true
            ),
            10_000
        );
    let swap_handler_address = deploy_swap_handler_address(role_store.contract_address);
    let swap_handler = ISwapHandlerDispatcher { contract_address: swap_handler_address };
    let referral_storage_address = deploy_referral_storage(event_emitter_address);

    let params = create_new_update_position_params(
        DecreasePositionSwapType::SwapCollateralTokenToPnlToken,
        swap_handler,
        data_store.contract_address,
        event_emitter_address,
        referral_storage_address,
        long_token_address,
    );

    let values = create_new_decrease_position_cache(long_token_address);

    //
    // Execution
    //
    //TODO add params in process_collateral when function implemented
    // let result = decrease_position_collateral_utils::process_collateral(
    //     event_emitter, params, values
    // );

    // Checks
    let open_interest = data_store
        .get_u128(
            keys::open_interest_key(
                contract_address_const::<'market_token'>(), long_token_address, true
            ),
        );
}

#[test]
fn given_good_params_get_execution_price_then_succeed() {
    // 
    // Setup  
    //   
    let (caller_address, role_store, data_store) = setup();
    let (event_emitter_address, event_emitter) = setup_event_emitter();
    let long_token_address = deploy_token();

    // setting open_interest to 10_000 to allow decreasing position.
    data_store
        .set_u128(
            keys::open_interest_key(
                contract_address_const::<'market_token'>(), long_token_address, true
            ),
            10_000
        );
    let swap_handler_address = deploy_swap_handler_address(role_store.contract_address);
    let swap_handler = ISwapHandlerDispatcher { contract_address: swap_handler_address };
    let referral_storage_address = deploy_referral_storage(event_emitter_address);

    let params = create_new_update_position_params(
        DecreasePositionSwapType::SwapCollateralTokenToPnlToken,
        swap_handler,
        data_store.contract_address,
        event_emitter_address,
        referral_storage_address,
        long_token_address
    );

    //
    // Execution
    //
    let (_, _, execution_price) = decrease_position_collateral_utils::get_execution_price(
        params, Price { min: 10, max: 10 }
    );
    //
    // Checks
    //
    assert(execution_price > 0, 'no execution price');
    teardown(data_store.contract_address);
}

/// Utility function to create new UpdatePositionParams struct
fn create_new_update_position_params(
    decrease_position_swap_type: DecreasePositionSwapType,
    swap_handler: ISwapHandlerDispatcher,
    data_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    referral_storage_address: ContractAddress,
    long_token_address: ContractAddress
) -> UpdatePositionParams {
    let order_vault = contract_address_const::<'order_vault'>();
    let oracle = contract_address_const::<'oracle'>();
    let contracts = ExecuteOrderParamsContracts {
        data_store: IDataStoreDispatcher { contract_address: data_store_address },
        event_emitter: IEventEmitterDispatcher { contract_address: event_emitter_address },
        order_vault: IOrderVaultDispatcher { contract_address: order_vault },
        oracle: IOracleDispatcher { contract_address: oracle },
        swap_handler,
        referral_storage: IReferralStorageDispatcher { contract_address: referral_storage_address }
    };

    let market = Market {
        market_token: contract_address_const::<'market_token'>(),
        index_token: long_token_address,
        long_token: long_token_address,
        short_token: contract_address_const::<'short_token'>()
    };

    let order = Order {
        key: 123456789,
        order_type: OrderType::StopLossDecrease,
        decrease_position_swap_type,
        account: contract_address_const::<'account'>(),
        receiver: contract_address_const::<'receiver'>(),
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
        market: contract_address_const::<'market'>(),
        initial_collateral_token: contract_address_const::<'token1'>(),
        swap_path: array![
            contract_address_const::<'swap_path_0'>(), contract_address_const::<'swap_path_1'>()
        ]
            .span32(),
        size_delta_usd: 1000,
        initial_collateral_delta_amount: 1000,
        trigger_price: 11111,
        acceptable_price: 11111,
        execution_fee: 10,
        callback_gas_limit: 300000,
        min_output_amount: 10,
        updated_at_block: 1,
        is_long: true,
        is_frozen: false
    };

    let position = Position {
        key: 123456789,
        account: contract_address_const::<'account'>(),
        market: contract_address_const::<'market'>(),
        collateral_token: contract_address_const::<'collateral_token'>(),
        size_in_usd: 1000,
        size_in_tokens: 1000,
        collateral_amount: 1000,
        borrowing_factor: 1,
        funding_fee_amount_per_size: 1,
        long_token_claimable_funding_amount_per_size: 10,
        short_token_claimable_funding_amount_per_size: 10,
        increased_at_block: 1,
        decreased_at_block: 3,
        is_long: false,
    };

    let params = UpdatePositionParams {
        contracts,
        market,
        order,
        order_key: 123456789,
        position,
        position_key: 123456789,
        secondary_order_type: SecondaryOrderType::None
    };

    params
}

/// Utility function to create new DecreasePositionCache struct
fn create_new_decrease_position_cache(
    long_token_address: ContractAddress
) -> DecreasePositionCache {
    let price = Price { min: 1, max: 1 };
    DecreasePositionCache {
        prices: MarketPrices {
            index_token_price: price, long_token_price: price, short_token_price: price,
        },
        estimated_position_pnl_usd: 100,
        estimated_realized_pnl_usd: 0,
        estimated_remaining_pnl_usd: 100,
        pnl_token: long_token_address,
        pnl_token_price: price,
        collateral_token_price: price,
        initial_collateral_amount: 100,
        next_position_size_in_usd: 500,
        next_position_borrowing_factor: 100000,
    }
}
