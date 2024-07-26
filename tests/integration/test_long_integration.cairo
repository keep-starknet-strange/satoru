// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.

use result::ResultTrait;
use debug::PrintTrait;
use traits::{TryInto, Into};
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
    ClassHash,
};
use snforge_std::{declare, start_prank, stop_prank, start_roll, ContractClassTrait, ContractClass};


// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::order::order_utils::{IOrderUtilsDispatcher, IOrderUtilsDispatcherTrait};
use satoru::market::market_factory::{IMarketFactoryDispatcher, IMarketFactoryDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::deposit::deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait};
use satoru::deposit::deposit::Deposit;
use satoru::withdrawal::withdrawal::Withdrawal;

use satoru::exchange::withdrawal_handler::{
    IWithdrawalHandlerDispatcher, IWithdrawalHandlerDispatcherTrait
};
use satoru::exchange::deposit_handler::{IDepositHandlerDispatcher, IDepositHandlerDispatcherTrait};
use satoru::router::exchange_router::{IExchangeRouterDispatcher, IExchangeRouterDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::reader::reader::{IReaderDispatcher, IReaderDispatcherTrait};
use satoru::market::market::{Market, UniqueIdMarket};
use satoru::market::market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait};
use satoru::role::role;
use satoru::oracle::oracle_utils::SetPricesParams;
use satoru::test_utils::tests_lib;
use satoru::deposit::deposit_utils::CreateDepositParams;
use satoru::utils::span32::{Span32, DefaultSpan32, Array32Trait};
use satoru::deposit::deposit_utils;
use satoru::bank::bank::{IBankDispatcherTrait, IBankDispatcher};
use satoru::bank::strict_bank::{IStrictBankDispatcher, IStrictBankDispatcherTrait};
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::withdrawal::withdrawal_vault::{
    IWithdrawalVaultDispatcher, IWithdrawalVaultDispatcherTrait
};
use satoru::data::keys;
use satoru::market::market_utils;
use satoru::price::price::{Price, PriceTrait};
use satoru::position::position_utils;
use satoru::withdrawal::withdrawal_utils;

use satoru::exchange::liquidation_handler::{
    ILiquidationHandlerDispatcher, ILiquidationHandlerDispatcherTrait
};
use satoru::order::order::{Order, OrderType, SecondaryOrderType, DecreasePositionSwapType};
use satoru::order::order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait};
use satoru::order::base_order_utils::{CreateOrderParams};
use satoru::oracle::oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::market::{market::{UniqueIdMarketImpl},};
use satoru::exchange::order_handler::{
    OrderHandler, IOrderHandlerDispatcher, IOrderHandlerDispatcherTrait
};
use satoru::test_utils::{
    tests_lib::{setup, create_market, teardown}, deposit_setup::{deposit_setup, exec_order}
};

#[test]
fn test_long_increase_decrease_close() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        event_emitter,
        exchange_router,
        deposit_handler,
        deposit_vault,
        oracle,
        order_handler,
        order_vault,
        reader,
        referal_storage,
        withdrawal_handler,
        withdrawal_vault,
        liquidation_handler,
        market,
    ) =
        deposit_setup(
        50000000000000000000000000000, 50000000000000000000000000000
    );

    let balance_caller_ETH = IERC20Dispatcher { contract_address: market.long_token }
        .balance_of(caller_address);
    let balance_caller_USDC = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(caller_address);

    assert(balance_caller_ETH == 10000000000000000000, 'balanc ETH should be 10 ETH');
    assert(balance_caller_USDC == 50000000000000000000000, 'USDC be 50 000 USDC');

    // let pool_value_info = market_utils::get_pool_value_info(
    //     data_store,
    //     market,
    //     Price { min: 5000, max: 5000, },
    //     Price { min: 5000, max: 5000, },
    //     Price { min: 1, max: 1, },
    //     keys::max_pnl_factor_for_deposits(),
    //     true,
    // );

    // pool_value_info.pool_value.mag.print(); // 10000 000000000000000000
    // pool_value_info.long_token_amount.print(); // 5 000000000000000000
    // pool_value_info.short_token_amount.print(); // 25000 000000000000000000

    // ************************************* TEST LONG *********************************************

    'Begining of LONG TEST'.print();

    let key_open_interest = keys::open_interest_key(
        market.market_token, contract_address_const::<'ETH'>(), true
    );
    data_store.set_u256(key_open_interest, 1);
    let max_key_open_interest = keys::max_open_interest_key(market.market_token, true);
    data_store
        .set_u256(
            max_key_open_interest, 1000000000000000000000000000000000000000000000000000
        ); // 1 000 000

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 1000000000000000000); // 1ETH

    'transfer made'.print();
    // Create order_params Struct
    let contract_address = contract_address_const::<0>();
    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 3500000000000000000000,
        initial_collateral_delta_amount: 1000000000000000000, // 10^18
        trigger_price: 0,
        acceptable_price: 3501,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the swap order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1930);
    'try to create prder'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long = exchange_router.create_order(order_params_long);
    'long created'.print();
    let got_order_long = data_store.get_order(key_long);

    // Execute the swap order.
    start_roll(order_handler.contract_address, 1935);
    exec_order(order_handler.contract_address, role_store.contract_address, key_long, 3500, 1);

    'long position SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position = data_store.get_position(position_key_1);

    assert(first_position.size_in_tokens == 1000000000000000000, 'Size token should be 1 ETH');
    assert(first_position.size_in_usd == 3500000000000000000000, 'Size should be 3500$');
    assert(first_position.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position.collateral_amount == 1000000000000000000, 'Collat should be 1 ETH');

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 350000000000000000000, 'PnL should be 350$');

    //////////////////////////////// INCREASE POSITION //////////////////////////////////

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 2000000000000000000); // 2ETH

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_inc = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 7700000000000000000000, // 6000
        initial_collateral_delta_amount: 2000000000000000000, // 1 ETH 10^18
        trigger_price: 0,
        acceptable_price: 3851,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1940);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_inc = exchange_router.create_order(order_params_long_inc);
    'Long increase created'.print();

    // Execute the swap order.
    start_roll(order_handler.contract_address, 1945);
    exec_order(order_handler.contract_address, role_store.contract_address, key_long_inc, 3850, 1);
    'long pos inc SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position_inc = data_store.get_position(position_key_1);

    assert(first_position_inc.size_in_tokens == 3000000000000000000, 'Size token should be 3 ETH');
    assert(first_position_inc.size_in_usd == 11200000000000000000000, 'Size should be 11200$');
    assert(first_position_inc.borrowing_factor == 0, 'borrow should be 0');
    assert(first_position_inc.collateral_amount == 3000000000000000000, 'Collat should be 3 ETH');

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    'pnl'.print();
    assert(position_info.base_pnl_usd.mag == 350000000000000000000, 'PnL should be 350$');

    //////////////////////////////////// DECREASE POSITION //////////////////////////////////////
    'DECREASE POSITION'.print();

    let balance_USDC_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    // Decrease 25% of the position
    // Size = 11200$ -----> 25% = 2800
    // Collateral token amount = 3 ETH -----> 25% = 0.75 ETH

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_dec = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 2800000000000000000000, // 2800
        initial_collateral_delta_amount: 750000000000000000, // 0.75 ETH 10^18
        trigger_price: 0,
        acceptable_price: 3849,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketDecrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1950);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_dec = exchange_router.create_order(order_params_long_dec);
    'long decrease created'.print();
    let got_order_long_dec = data_store.get_order(key_long_dec);

    // Execute the swap order.
    start_roll(order_handler.contract_address, 1955);
    exec_order(order_handler.contract_address, role_store.contract_address, key_long_dec, 3850, 1);
    'long pos dec SUCCEEDED'.print();

    // Recieved 2974.999 USDC

    let first_position_dec = data_store.get_position(position_key_1);

    assert(
        first_position_dec.size_in_tokens == 2250000000000000000, 'Size token should be 2.25 ETH'
    );
    assert(first_position_dec.size_in_usd == 8400000000000000000000, 'Size should be 8400');
    assert(first_position_dec.borrowing_factor == 0, 'Borrow should be 0');
    assert(
        first_position_dec.collateral_amount == 2250000000000000000, 'Collat should be 2.25 ETH'
    );

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 262500000000000000000, 'PnL should be 262,5');

    let balance_USDC_after = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_after = IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .balance_of(caller_address);

    assert(balance_USDC_before == 50000000000000000000000, 'balance USDC should be 50000$');
    // Balance USDC after = (0.75 ETH * 3850$) + 87.499 (PnL)
    assert(balance_USDC_after == 52974999999999999998950, 'balance USDC shld be 52974.99$');
    assert(balance_ETH_before == 7000000000000000000, 'balance ETH before 7');
    assert(balance_ETH_after == 7000000000000000000, 'balance ETH after 7');

    //////////////////////////////////// CLOSE POSITION //////////////////////////////////////
    'CLOSE POSITION'.print();

    let balance_USDC_bef_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_bef_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 4000, max: 4000, },
        long_token_price: Price { min: 4000, max: 4000, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 600000000000000000000, 'PnL should be 600$');

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_dec_2 = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 8400000000000000000000, // 8400
        initial_collateral_delta_amount: 2250000000000000000, // 2.25 ETH 10^18
        trigger_price: 0,
        acceptable_price: 3999,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketDecrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1960);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_dec_2 = exchange_router.create_order(order_params_long_dec_2);
    'long decrease created'.print();
    let got_order_long_dec = data_store.get_order(key_long_dec_2);

    // Execute the long order.
    start_roll(order_handler.contract_address, 1965);
    exec_order(
        order_handler.contract_address, role_store.contract_address, key_long_dec_2, 4000, 1
    );
    'Long pos close SUCCEEDED'.print();

    let first_position_close = data_store.get_position(position_key_1);

    assert(first_position_close.size_in_tokens == 0, 'Size token should be 0');
    assert(first_position_close.size_in_usd == 0, 'Size should be 0');
    assert(first_position_close.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position_close.collateral_amount == 0, 'Collat should be 0');

    let balance_USDC_af_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_af_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    assert(balance_USDC_bef_close == 52974999999999999998950, 'balance USDC shld be 52974.99$');
    assert(balance_USDC_af_close == 62574999999999999998950, 'balance USDC shld be 62574.99$');
    assert(balance_ETH_af_close == 7000000000000000000, 'balance ETH after 7');
    assert(balance_ETH_bef_close == 7000000000000000000, 'balance ETH after 7');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn test_takeprofit_long() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        event_emitter,
        exchange_router,
        deposit_handler,
        deposit_vault,
        oracle,
        order_handler,
        order_vault,
        reader,
        referal_storage,
        withdrawal_handler,
        withdrawal_vault,
        liquidation_handler,
        market,
    ) =
        deposit_setup(
        50000000000000000000000000000, 50000000000000000000000000000
    );

    let balance_caller_ETH = IERC20Dispatcher { contract_address: market.long_token }
        .balance_of(caller_address);
    let balance_caller_USDC = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(caller_address);

    assert(balance_caller_ETH == 10000000000000000000, 'balanc ETH should be 10 ETH');
    assert(balance_caller_USDC == 50000000000000000000000, 'USDC be 50 000 USDC');

    // let pool_value_info = market_utils::get_pool_value_info(
    //     data_store,
    //     market,
    //     Price { min: 5000, max: 5000, },
    //     Price { min: 5000, max: 5000, },
    //     Price { min: 1, max: 1, },
    //     keys::max_pnl_factor_for_deposits(),
    //     true,
    // );

    // pool_value_info.pool_value.mag.print(); // 10000 000000000000000000
    // pool_value_info.long_token_amount.print(); // 5 000000000000000000
    // pool_value_info.short_token_amount.print(); // 25000 000000000000000000

    // ************************************* TEST LONG *********************************************

    'Begining of LONG TEST'.print();

    let key_open_interest = keys::open_interest_key(
        market.market_token, contract_address_const::<'ETH'>(), true
    );
    data_store.set_u256(key_open_interest, 1);
    let max_key_open_interest = keys::max_open_interest_key(market.market_token, true);
    data_store
        .set_u256(
            max_key_open_interest, 1000000000000000000000000000000000000000000000000000
        ); // 1 000 000

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 1000000000000000000); // 1ETH

    'transfer made'.print();
    // Create order_params Struct
    let contract_address = contract_address_const::<0>();
    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 3500000000000000000000,
        initial_collateral_delta_amount: 1000000000000000000, // 10^18
        trigger_price: 0,
        acceptable_price: 3501,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the swap order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1930);
    'try to create prder'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long = exchange_router.create_order(order_params_long);
    'long created'.print();
    let got_order_long = data_store.get_order(key_long);

    // Execute the swap order.
    start_roll(order_handler.contract_address, 1935);
    exec_order(order_handler.contract_address, role_store.contract_address, key_long, 3500, 1);
    'long position SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position = data_store.get_position(position_key_1);

    assert(first_position.size_in_tokens == 1000000000000000000, 'Size token should be 1 ETH');
    assert(first_position.size_in_usd == 3500000000000000000000, 'Size should be 3500$');
    assert(first_position.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position.collateral_amount == 1000000000000000000, 'Collat should be 1 ETH');

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 350000000000000000000, 'PnL should be 350$');

    //////////////////////////////// TRIGGER INCREASE POSITION //////////////////////////////////

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 2000000000000000000); // 2ETH

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_inc = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 7700000000000000000000, // 7700
        initial_collateral_delta_amount: 2000000000000000000, // 2 ETH 10^18
        trigger_price: 3850,
        acceptable_price: 3851,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::LimitIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };

    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1940);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_inc = exchange_router.create_order(order_params_long_inc);
    'Long increase created'.print();

    // Execute the swap order.
    start_roll(order_handler.contract_address, 1945);
    exec_order(order_handler.contract_address, role_store.contract_address, key_long_inc, 3850, 1);
    'long pos inc SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position_inc = data_store.get_position(position_key_1);

    first_position_inc.size_in_tokens.print();

    assert(first_position_inc.size_in_tokens == 3000000000000000000, 'Size token should be 3 ETH');
    assert(first_position_inc.size_in_usd == 11200000000000000000000, 'Size should be 11200$');
    assert(first_position_inc.borrowing_factor == 0, 'borrow should be 0');
    assert(first_position_inc.collateral_amount == 3000000000000000000, 'Collat should be 3 ETH');

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    'pnl'.print();
    assert(position_info.base_pnl_usd.mag == 350000000000000000000, 'PnL should be 350$');

    //////////////////////////////////// TRIGGER DECREASE POSITION //////////////////////////////////////
    'DECREASE POSITION'.print();

    let balance_USDC_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    // Decrease 25% of the position
    // Size = 11200$ -----> 25% = 2800
    // Collateral token amount = 3 ETH -----> 25% = 0.75 ETH

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_dec = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 2800000000000000000000, // 2800
        initial_collateral_delta_amount: 750000000000000000, // 0.75 ETH 10^18
        trigger_price: 3950,
        acceptable_price: 3949,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::LimitDecrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1950);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_dec = exchange_router.create_order(order_params_long_dec);
    'long decrease created'.print();
    let got_order_long_dec = data_store.get_order(key_long_dec);

    // Execute the swap order.
    start_roll(order_handler.contract_address, 1955);
    exec_order(order_handler.contract_address, role_store.contract_address, key_long_dec, 3950, 1);
    'long pos dec SUCCEEDED'.print();

    // Recieved 2974.999 USDC

    let first_position_dec = data_store.get_position(position_key_1);

    assert(
        first_position_dec.size_in_tokens == 2250000000000000000, 'Size token should be 2.25 ETH'
    );
    assert(first_position_dec.size_in_usd == 8400000000000000000000, 'Size should be 8400');
    assert(first_position_dec.borrowing_factor == 0, 'Borrow should be 0');
    assert(
        first_position_dec.collateral_amount == 2250000000000000000, 'Collat should be 2.25 ETH'
    );

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3950, max: 3950, },
        long_token_price: Price { min: 3950, max: 3950, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 487500000000000000000, 'PnL should be 487,5');

    let balance_USDC_after = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_after = IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .balance_of(caller_address);

    assert(balance_USDC_before == 50000000000000000000000, 'balance USDC should be 50000$');
    // Balance USDC after = (0.75 ETH * 3950$) + 162.499 (PnL)
    assert(balance_USDC_after == 53124999999999999996350, 'balance USDC shld be 53124.99$');
    assert(balance_ETH_before == 7000000000000000000, 'balance ETH before 7');
    assert(balance_ETH_after == 7000000000000000000, 'balance ETH after 7');

    //////////////////////////////////// TRIGGER CLOSE POSITION //////////////////////////////////////
    'CLOSE POSITION'.print();

    let balance_USDC_bef_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_bef_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 4000, max: 4000, },
        long_token_price: Price { min: 4000, max: 4000, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 600000000000000000000, 'PnL should be 600$');

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_dec_2 = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 8400000000000000000000, // 8400
        initial_collateral_delta_amount: 2250000000000000000, // 2.25 ETH 10^18
        trigger_price: 4000,
        acceptable_price: 3999,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::LimitDecrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1960);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_dec_2 = exchange_router.create_order(order_params_long_dec_2);
    'long decrease created'.print();
    let got_order_long_dec = data_store.get_order(key_long_dec_2);

    // Execute the swap order.
    start_roll(order_handler.contract_address, 1965);
    exec_order(
        order_handler.contract_address, role_store.contract_address, key_long_dec_2, 4000, 1
    );
    'Long pos close SUCCEEDED'.print();

    let first_position_close = data_store.get_position(position_key_1);

    assert(first_position_close.size_in_tokens == 0, 'Size token should be 0');
    assert(first_position_close.size_in_usd == 0, 'Size should be 0');
    assert(first_position_close.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position_close.collateral_amount == 0, 'Collat should be 0');

    let balance_USDC_af_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_af_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    assert(balance_USDC_bef_close == 53124999999999999996350, 'balance USDC shld be 52974.99$');
    assert(balance_USDC_af_close == 62724999999999999996350, 'balance USDC shld be 62724.99$');
    assert(balance_ETH_af_close == 7000000000000000000, 'balance ETH af close 7');
    assert(balance_ETH_bef_close == 7000000000000000000, 'balance ETH bef close 7');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
#[should_panic(expected: ('invalid_order_price', 'LimitIncrease',))]
fn test_takeprofit_long_increase_fails() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        event_emitter,
        exchange_router,
        deposit_handler,
        deposit_vault,
        oracle,
        order_handler,
        order_vault,
        reader,
        referal_storage,
        withdrawal_handler,
        withdrawal_vault,
        liquidation_handler,
        market,
    ) =
        deposit_setup(
        50000000000000000000000000000, 50000000000000000000000000000
    );

    let balance_caller_ETH = IERC20Dispatcher { contract_address: market.long_token }
        .balance_of(caller_address);
    let balance_caller_USDC = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(caller_address);

    assert(balance_caller_ETH == 10000000000000000000, 'balanc ETH should be 10 ETH');
    assert(balance_caller_USDC == 50000000000000000000000, 'USDC be 50 000 USDC');

    // let pool_value_info = market_utils::get_pool_value_info(
    //     data_store,
    //     market,
    //     Price { min: 5000, max: 5000, },
    //     Price { min: 5000, max: 5000, },
    //     Price { min: 1, max: 1, },
    //     keys::max_pnl_factor_for_deposits(),
    //     true,
    // );

    // pool_value_info.pool_value.mag.print(); // 10000 000000000000000000
    // pool_value_info.long_token_amount.print(); // 5 000000000000000000
    // pool_value_info.short_token_amount.print(); // 25000 000000000000000000

    // ************************************* TEST LONG *********************************************

    'Begining of LONG TEST'.print();

    let key_open_interest = keys::open_interest_key(
        market.market_token, contract_address_const::<'ETH'>(), true
    );
    data_store.set_u256(key_open_interest, 1);
    let max_key_open_interest = keys::max_open_interest_key(market.market_token, true);
    data_store
        .set_u256(
            max_key_open_interest, 1000000000000000000000000000000000000000000000000000
        ); // 1 000 000

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 1000000000000000000); // 1ETH

    'transfer made'.print();
    // Create order_params Struct
    let contract_address = contract_address_const::<0>();
    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 3500000000000000000000,
        initial_collateral_delta_amount: 1000000000000000000, // 10^18
        trigger_price: 0,
        acceptable_price: 3501,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the swap order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1930);
    'try to create prder'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long = exchange_router.create_order(order_params_long);
    'long created'.print();
    let got_order_long = data_store.get_order(key_long);

    // Execute the swap order.
    start_roll(order_handler.contract_address, 1935);
    exec_order(order_handler.contract_address, role_store.contract_address, key_long, 3500, 1);
    'long position SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position = data_store.get_position(position_key_1);

    assert(first_position.size_in_tokens == 1000000000000000000, 'Size token should be 1 ETH');
    assert(first_position.size_in_usd == 3500000000000000000000, 'Size should be 3500$');
    assert(first_position.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position.collateral_amount == 1000000000000000000, 'Collat should be 1 ETH');

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 350000000000000000000, 'PnL should be 350$');

    //////////////////////////////// TRIGGER INCREASE POSITION //////////////////////////////////

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 2000000000000000000); // 2ETH

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_inc = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 7700000000000000000000, // 7700
        initial_collateral_delta_amount: 2000000000000000000, // 2 ETH 10^18
        trigger_price: 3850,
        acceptable_price: 3851,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::LimitIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };

    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1940);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_inc = exchange_router.create_order(order_params_long_inc);
    'Long increase created'.print();

    // Execute the swap order.
    start_roll(order_handler.contract_address, 1945);
    exec_order(order_handler.contract_address, role_store.contract_address, key_long_inc, 3860, 1);
    'long pos inc SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position_inc = data_store.get_position(position_key_1);

    first_position_inc.size_in_tokens.print();

    assert(first_position_inc.size_in_tokens == 3000000000000000000, 'Size token should be 3 ETH');
    assert(first_position_inc.size_in_usd == 11200000000000000000000, 'Size should be 11200$');
    assert(first_position_inc.borrowing_factor == 0, 'borrow should be 0');
    assert(first_position_inc.collateral_amount == 3000000000000000000, 'Collat should be 3 ETH');

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    'pnl'.print();
    assert(position_info.base_pnl_usd.mag == 350000000000000000000, 'PnL should be 350$');

    //////////////////////////////////// TRIGGER DECREASE POSITION //////////////////////////////////////
    'DECREASE POSITION'.print();

    let balance_USDC_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    // Decrease 25% of the position
    // Size = 11200$ -----> 25% = 2800
    // Collateral token amount = 3 ETH -----> 25% = 0.75 ETH

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_dec = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 2800000000000000000000, // 2800
        initial_collateral_delta_amount: 750000000000000000, // 0.75 ETH 10^18
        trigger_price: 3950,
        acceptable_price: 3949,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::LimitDecrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1950);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_dec = exchange_router.create_order(order_params_long_dec);
    'long decrease created'.print();
    let got_order_long_dec = data_store.get_order(key_long_dec);

    // Execute the swap order.
    start_roll(order_handler.contract_address, 1955);
    exec_order(order_handler.contract_address, role_store.contract_address, key_long_dec, 3950, 1);
    'long pos dec SUCCEEDED'.print();

    // Recieved 2974.999 USDC

    let first_position_dec = data_store.get_position(position_key_1);

    assert(
        first_position_dec.size_in_tokens == 2250000000000000000, 'Size token should be 2.25 ETH'
    );
    assert(first_position_dec.size_in_usd == 8400000000000000000000, 'Size should be 8400');
    assert(first_position_dec.borrowing_factor == 0, 'Borrow should be 0');
    assert(
        first_position_dec.collateral_amount == 2250000000000000000, 'Collat should be 2.25 ETH'
    );

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3950, max: 3950, },
        long_token_price: Price { min: 3950, max: 3950, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 487500000000000000000, 'PnL should be 487,5');

    let balance_USDC_after = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_after = IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .balance_of(caller_address);

    assert(balance_USDC_before == 50000000000000000000000, 'balance USDC should be 50000$');
    // Balance USDC after = (0.75 ETH * 3950$) + 162.499 (PnL)
    assert(balance_USDC_after == 53124999999999999996350, 'balance USDC shld be 53124.99$');
    assert(balance_ETH_before == 7000000000000000000, 'balance ETH before 7');
    assert(balance_ETH_after == 7000000000000000000, 'balance ETH after 7');

    //////////////////////////////////// TRIGGER CLOSE POSITION //////////////////////////////////////
    'CLOSE POSITION'.print();

    let balance_USDC_bef_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_bef_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 4000, max: 4000, },
        long_token_price: Price { min: 4000, max: 4000, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 600000000000000000000, 'PnL should be 600$');

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_dec_2 = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 8400000000000000000000, // 8400
        initial_collateral_delta_amount: 2250000000000000000, // 2.25 ETH 10^18
        trigger_price: 4000,
        acceptable_price: 3999,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::LimitDecrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1960);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_dec_2 = exchange_router.create_order(order_params_long_dec_2);
    'long decrease created'.print();
    let got_order_long_dec = data_store.get_order(key_long_dec_2);
    // Execute the swap order.
    start_roll(order_handler.contract_address, 1965);
    exec_order(
        order_handler.contract_address, role_store.contract_address, key_long_dec_2, 4000, 1
    );
    'Long pos close SUCCEEDED'.print();

    let first_position_close = data_store.get_position(position_key_1);

    assert(first_position_close.size_in_tokens == 0, 'Size token should be 0');
    assert(first_position_close.size_in_usd == 0, 'Size should be 0');
    assert(first_position_close.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position_close.collateral_amount == 0, 'Collat should be 0');

    let balance_USDC_af_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_af_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    assert(balance_USDC_bef_close == 53124999999999999996350, 'balance USDC shld be 52974.99$');
    assert(balance_USDC_af_close == 62724999999999999996350, 'balance USDC shld be 62724.99$');
    assert(balance_ETH_af_close == 7000000000000000000, 'balance ETH af close 7');
    assert(balance_ETH_bef_close == 7000000000000000000, 'balance ETH bef close 7');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
#[should_panic(expected: ('invalid_order_price', 'LimitDecrease',))]
fn test_takeprofit_long_decrease_fails() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        event_emitter,
        exchange_router,
        deposit_handler,
        deposit_vault,
        oracle,
        order_handler,
        order_vault,
        reader,
        referal_storage,
        withdrawal_handler,
        withdrawal_vault,
        liquidation_handler,
        market,
    ) =
        deposit_setup(
        50000000000000000000000000000, 50000000000000000000000000000
    );

    let balance_caller_ETH = IERC20Dispatcher { contract_address: market.long_token }
        .balance_of(caller_address);
    let balance_caller_USDC = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(caller_address);

    assert(balance_caller_ETH == 10000000000000000000, 'balanc ETH should be 10 ETH');
    assert(balance_caller_USDC == 50000000000000000000000, 'USDC be 50 000 USDC');

    // let pool_value_info = market_utils::get_pool_value_info(
    //     data_store,
    //     market,
    //     Price { min: 5000, max: 5000, },
    //     Price { min: 5000, max: 5000, },
    //     Price { min: 1, max: 1, },
    //     keys::max_pnl_factor_for_deposits(),
    //     true,
    // );

    // pool_value_info.pool_value.mag.print(); // 10000 000000000000000000
    // pool_value_info.long_token_amount.print(); // 5 000000000000000000
    // pool_value_info.short_token_amount.print(); // 25000 000000000000000000

    // ************************************* TEST LONG *********************************************

    'Begining of LONG TEST'.print();

    let key_open_interest = keys::open_interest_key(
        market.market_token, contract_address_const::<'ETH'>(), true
    );
    data_store.set_u256(key_open_interest, 1);
    let max_key_open_interest = keys::max_open_interest_key(market.market_token, true);
    data_store
        .set_u256(
            max_key_open_interest, 1000000000000000000000000000000000000000000000000000
        ); // 1 000 000

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 1000000000000000000); // 1ETH

    'transfer made'.print();
    // Create order_params Struct
    let contract_address = contract_address_const::<0>();
    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 3500000000000000000000,
        initial_collateral_delta_amount: 1000000000000000000, // 10^18
        trigger_price: 0,
        acceptable_price: 3501,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the swap order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1930);
    'try to create prder'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long = exchange_router.create_order(order_params_long);
    'long created'.print();
    let got_order_long = data_store.get_order(key_long);

    // Execute the swap order.

    let signatures: Span<felt252> = array![0].span();
    let set_price_params = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![3500, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1935);
    // TODO add real signatures check on Oracle Account
    order_handler.execute_order(key_long, set_price_params);
    'long position SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position = data_store.get_position(position_key_1);

    assert(first_position.size_in_tokens == 1000000000000000000, 'Size token should be 1 ETH');
    assert(first_position.size_in_usd == 3500000000000000000000, 'Size should be 3500$');
    assert(first_position.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position.collateral_amount == 1000000000000000000, 'Collat should be 1 ETH');

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 350000000000000000000, 'PnL should be 350$');

    //////////////////////////////// TRIGGER INCREASE POSITION //////////////////////////////////

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 2000000000000000000); // 2ETH

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_inc = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 7700000000000000000000, // 7700
        initial_collateral_delta_amount: 2000000000000000000, // 2 ETH 10^18
        trigger_price: 3850,
        acceptable_price: 3851,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::LimitIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };

    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1940);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_inc = exchange_router.create_order(order_params_long_inc);
    'Long increase created'.print();

    // Execute the swap order.

    let set_price_params_inc = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![3850, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1945);
    // TODO add real signatures check on Oracle Account
    order_handler.execute_order(key_long_inc, set_price_params_inc);
    'long pos inc SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position_inc = data_store.get_position(position_key_1);

    first_position_inc.size_in_tokens.print();

    assert(first_position_inc.size_in_tokens == 3000000000000000000, 'Size token should be 3 ETH');
    assert(first_position_inc.size_in_usd == 11200000000000000000000, 'Size should be 11200$');
    assert(first_position_inc.borrowing_factor == 0, 'borrow should be 0');
    assert(first_position_inc.collateral_amount == 3000000000000000000, 'Collat should be 3 ETH');

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    'pnl'.print();
    assert(position_info.base_pnl_usd.mag == 350000000000000000000, 'PnL should be 350$');

    //////////////////////////////////// TRIGGER DECREASE POSITION //////////////////////////////////////
    'DECREASE POSITION'.print();

    let balance_USDC_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    // Decrease 25% of the position
    // Size = 11200$ -----> 25% = 2800
    // Collateral token amount = 3 ETH -----> 25% = 0.75 ETH

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_dec = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 2800000000000000000000, // 2800
        initial_collateral_delta_amount: 750000000000000000, // 0.75 ETH 10^18
        trigger_price: 3950,
        acceptable_price: 3949,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::LimitDecrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1950);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_dec = exchange_router.create_order(order_params_long_dec);
    'long decrease created'.print();
    let got_order_long_dec = data_store.get_order(key_long_dec);

    // Execute the swap order.
    let set_price_params_dec = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![3940, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1955);
    order_handler.execute_order(key_long_dec, set_price_params_dec);
    'long pos dec SUCCEEDED'.print();

    // Recieved 2974.999 USDC

    let first_position_dec = data_store.get_position(position_key_1);

    assert(
        first_position_dec.size_in_tokens == 2250000000000000000, 'Size token should be 2.25 ETH'
    );
    assert(first_position_dec.size_in_usd == 8400000000000000000000, 'Size should be 8400');
    assert(first_position_dec.borrowing_factor == 0, 'Borrow should be 0');
    assert(
        first_position_dec.collateral_amount == 2250000000000000000, 'Collat should be 2.25 ETH'
    );

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3950, max: 3950, },
        long_token_price: Price { min: 3950, max: 3950, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 487500000000000000000, 'PnL should be 487,5');

    let balance_USDC_after = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_after = IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .balance_of(caller_address);

    assert(balance_USDC_before == 50000000000000000000000, 'balance USDC before 50000$');
    // Balance USDC after = (0.75 ETH * 3950$) + 162.499 (PnL)
    assert(balance_USDC_after == 53124999999999999996350, 'balance USDC after 53124.99$');
    assert(balance_ETH_before == 7000000000000000000, 'balance ETH before 7');
    assert(balance_ETH_after == 7000000000000000000, 'balance ETH after 7');

    //////////////////////////////////// TRIGGER CLOSE POSITION //////////////////////////////////////
    'CLOSE POSITION'.print();

    let balance_USDC_bef_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_bef_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 4000, max: 4000, },
        long_token_price: Price { min: 4000, max: 4000, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 600000000000000000000, 'PnL should be 600$');

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_dec_2 = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 8400000000000000000000, // 8400
        initial_collateral_delta_amount: 2250000000000000000, // 2.25 ETH 10^18
        trigger_price: 4000,
        acceptable_price: 3999,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::LimitDecrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1960);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_dec_2 = exchange_router.create_order(order_params_long_dec_2);
    'long decrease created'.print();
    let got_order_long_dec = data_store.get_order(key_long_dec_2);
    // Execute the swap order.

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    let set_price_params_dec2 = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![4000, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1965);
    // TODO add real signatures check on Oracle Account
    order_handler.execute_order(key_long_dec_2, set_price_params_dec2);
    'Long pos close SUCCEEDED'.print();

    let first_position_close = data_store.get_position(position_key_1);

    assert(first_position_close.size_in_tokens == 0, 'Size token should be 0');
    assert(first_position_close.size_in_usd == 0, 'Size should be 0');
    assert(first_position_close.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position_close.collateral_amount == 0, 'Collat should be 0');

    let balance_USDC_af_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_af_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    assert(balance_USDC_bef_close == 53124999999999999996350, 'balance USDC bef clse 53124.99$');
    assert(balance_USDC_af_close == 62724999999999999996350, 'balance USDC af close 62724.99$');
    assert(balance_ETH_af_close == 7000000000000000000, 'balance ETH af close 7');
    assert(balance_ETH_bef_close == 7000000000000000000, 'balance ETH bef close 7');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
#[should_panic(expected: ('invalid_order_price', 'LimitDecrease',))]
fn test_takeprofit_long_close_fails() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        event_emitter,
        exchange_router,
        deposit_handler,
        deposit_vault,
        oracle,
        order_handler,
        order_vault,
        reader,
        referal_storage,
        withdrawal_handler,
        withdrawal_vault,
        liquidation_handler,
        market,
    ) =
        deposit_setup(
        50000000000000000000000000000, 50000000000000000000000000000
    );

    let balance_caller_ETH = IERC20Dispatcher { contract_address: market.long_token }
        .balance_of(caller_address);
    let balance_caller_USDC = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(caller_address);

    assert(balance_caller_ETH == 10000000000000000000, 'balanc ETH should be 10 ETH');
    assert(balance_caller_USDC == 50000000000000000000000, 'USDC be 50 000 USDC');

    // let pool_value_info = market_utils::get_pool_value_info(
    //     data_store,
    //     market,
    //     Price { min: 5000, max: 5000, },
    //     Price { min: 5000, max: 5000, },
    //     Price { min: 1, max: 1, },
    //     keys::max_pnl_factor_for_deposits(),
    //     true,
    // );

    // pool_value_info.pool_value.mag.print(); // 10000 000000000000000000
    // pool_value_info.long_token_amount.print(); // 5 000000000000000000
    // pool_value_info.short_token_amount.print(); // 25000 000000000000000000

    // ************************************* TEST LONG *********************************************

    'Begining of LONG TEST'.print();

    let key_open_interest = keys::open_interest_key(
        market.market_token, contract_address_const::<'ETH'>(), true
    );
    data_store.set_u256(key_open_interest, 1);
    let max_key_open_interest = keys::max_open_interest_key(market.market_token, true);
    data_store
        .set_u256(
            max_key_open_interest, 1000000000000000000000000000000000000000000000000000
        ); // 1 000 000

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 1000000000000000000); // 1ETH

    'transfer made'.print();
    // Create order_params Struct
    let contract_address = contract_address_const::<0>();
    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 3500000000000000000000,
        initial_collateral_delta_amount: 1000000000000000000, // 10^18
        trigger_price: 0,
        acceptable_price: 3501,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the swap order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1930);
    'try to create prder'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long = exchange_router.create_order(order_params_long);
    'long created'.print();
    let got_order_long = data_store.get_order(key_long);

    // Execute the swap order.

    let signatures: Span<felt252> = array![0].span();
    let set_price_params = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![3500, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1935);
    // TODO add real signatures check on Oracle Account
    order_handler.execute_order(key_long, set_price_params);
    'long position SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position = data_store.get_position(position_key_1);

    assert(first_position.size_in_tokens == 1000000000000000000, 'Size token should be 1 ETH');
    assert(first_position.size_in_usd == 3500000000000000000000, 'Size should be 3500$');
    assert(first_position.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position.collateral_amount == 1000000000000000000, 'Collat should be 1 ETH');

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 350000000000000000000, 'PnL should be 350$');

    //////////////////////////////// TRIGGER INCREASE POSITION //////////////////////////////////

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 2000000000000000000); // 2ETH

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_inc = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 7700000000000000000000, // 7700
        initial_collateral_delta_amount: 2000000000000000000, // 2 ETH 10^18
        trigger_price: 3850,
        acceptable_price: 3851,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::LimitIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };

    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1940);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_inc = exchange_router.create_order(order_params_long_inc);
    'Long increase created'.print();

    // Execute the swap order.

    let set_price_params_inc = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![3850, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1945);
    // TODO add real signatures check on Oracle Account
    order_handler.execute_order(key_long_inc, set_price_params_inc);
    'long pos inc SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position_inc = data_store.get_position(position_key_1);

    first_position_inc.size_in_tokens.print();

    assert(first_position_inc.size_in_tokens == 3000000000000000000, 'Size token should be 3 ETH');
    assert(first_position_inc.size_in_usd == 11200000000000000000000, 'Size should be 11200$');
    assert(first_position_inc.borrowing_factor == 0, 'borrow should be 0');
    assert(first_position_inc.collateral_amount == 3000000000000000000, 'Collat should be 3 ETH');

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    'pnl'.print();
    assert(position_info.base_pnl_usd.mag == 350000000000000000000, 'PnL should be 350$');

    //////////////////////////////////// TRIGGER DECREASE POSITION //////////////////////////////////////
    'DECREASE POSITION'.print();

    let balance_USDC_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    // Decrease 25% of the position
    // Size = 11200$ -----> 25% = 2800
    // Collateral token amount = 3 ETH -----> 25% = 0.75 ETH

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_dec = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 2800000000000000000000, // 2800
        initial_collateral_delta_amount: 750000000000000000, // 0.75 ETH 10^18
        trigger_price: 3950,
        acceptable_price: 3949,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::LimitDecrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1950);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_dec = exchange_router.create_order(order_params_long_dec);
    'long decrease created'.print();
    let got_order_long_dec = data_store.get_order(key_long_dec);

    // Execute the swap order.
    let set_price_params_dec = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![3950, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1955);
    order_handler.execute_order(key_long_dec, set_price_params_dec);
    'long pos dec SUCCEEDED'.print();

    // Recieved 2974.999 USDC

    let first_position_dec = data_store.get_position(position_key_1);

    assert(
        first_position_dec.size_in_tokens == 2250000000000000000, 'Size token should be 2.25 ETH'
    );
    assert(first_position_dec.size_in_usd == 8400000000000000000000, 'Size should be 8400');
    assert(first_position_dec.borrowing_factor == 0, 'Borrow should be 0');
    assert(
        first_position_dec.collateral_amount == 2250000000000000000, 'Collat should be 2.25 ETH'
    );

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3950, max: 3950, },
        long_token_price: Price { min: 3950, max: 3950, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 487500000000000000000, 'PnL should be 487,5');

    let balance_USDC_after = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_after = IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .balance_of(caller_address);

    assert(balance_USDC_before == 50000000000000000000000, 'balance USDC before 50000$');
    // Balance USDC after = (0.75 ETH * 3950$) + 162.499 (PnL)
    assert(balance_USDC_after == 53124999999999999996350, 'balance USDC shld be 53124.99$');
    assert(balance_ETH_before == 7000000000000000000, 'balance ETH before 7');
    assert(balance_ETH_after == 7000000000000000000, 'balance ETH after 7');

    //////////////////////////////////// TRIGGER CLOSE POSITION //////////////////////////////////////
    'CLOSE POSITION'.print();

    let balance_USDC_bef_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_bef_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 4000, max: 4000, },
        long_token_price: Price { min: 4000, max: 4000, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 600000000000000000000, 'PnL should be 600$');

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_dec_2 = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 8400000000000000000000, // 8400
        initial_collateral_delta_amount: 2250000000000000000, // 2.25 ETH 10^18
        trigger_price: 4000,
        acceptable_price: 3999,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::LimitDecrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1960);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_dec_2 = exchange_router.create_order(order_params_long_dec_2);
    'long decrease created'.print();
    let got_order_long_dec = data_store.get_order(key_long_dec_2);
    // Execute the swap order.

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    let set_price_params_dec2 = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![3990, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1965);
    // TODO add real signatures check on Oracle Account
    order_handler.execute_order(key_long_dec_2, set_price_params_dec2);
    'Long pos close SUCCEEDED'.print();

    let first_position_close = data_store.get_position(position_key_1);

    assert(first_position_close.size_in_tokens == 0, 'Size token should be 0');
    assert(first_position_close.size_in_usd == 0, 'Size should be 0');
    assert(first_position_close.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position_close.collateral_amount == 0, 'Collat should be 0');

    let balance_USDC_af_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_af_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    assert(balance_USDC_bef_close == 53124999999999999996350, 'balance USDC shld be 53124.99$');
    assert(balance_USDC_af_close == 62724999999999999996350, 'balance USDC shld be 62724.99$');
    assert(balance_ETH_af_close == 7000000000000000000, 'balance ETH af close 7');
    assert(balance_ETH_bef_close == 7000000000000000000, 'balance ETH bef close 7');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn test_long_liquidation() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        event_emitter,
        exchange_router,
        deposit_handler,
        deposit_vault,
        oracle,
        order_handler,
        order_vault,
        reader,
        referal_storage,
        withdrawal_handler,
        withdrawal_vault,
        liquidation_handler,
        market,
    ) =
        deposit_setup(
        50000000000000000000000000000, 50000000000000000000000000000
    );

    let balance_caller_ETH = IERC20Dispatcher { contract_address: market.long_token }
        .balance_of(caller_address);
    let balance_caller_USDC = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(caller_address);

    assert(balance_caller_ETH == 10000000000000000000, 'balanc ETH should be 10 ETH');
    assert(balance_caller_USDC == 50000000000000000000000, 'USDC be 50 000 USDC');

    let pool_value_info = market_utils::get_pool_value_info(
        data_store,
        market,
        Price { min: 3500, max: 3500, },
        Price { min: 3500, max: 3500, },
        Price { min: 1, max: 1, },
        keys::max_pnl_factor_for_deposits(),
        true,
    );

    assert(
        pool_value_info.pool_value.mag == 175050000000000000000000000000000, 'wrong pool value 1'
    );
    assert(
        pool_value_info.long_token_amount == 50000000000000000000000000000,
        'wrong long token amount 1'
    );
    assert(
        pool_value_info.short_token_amount == 50000000000000000000000000000,
        'wrong short token amount 1'
    );

    // ************************************* TEST LONG *********************************************

    'Begining of LONG TEST'.print();

    let key_open_interest = keys::open_interest_key(
        market.market_token, contract_address_const::<'ETH'>(), true
    );
    data_store.set_u256(key_open_interest, 1);
    let max_key_open_interest = keys::max_open_interest_key(market.market_token, true);
    data_store
        .set_u256(
            max_key_open_interest, 1000000000000000000000000000000000000000000000000000
        ); // 1 000 000

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 1000000000000000000); // 1ETH

    'transfer made'.print();
    // Create order_params Struct
    let contract_address = contract_address_const::<0>();
    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 3500000000000000000000,
        initial_collateral_delta_amount: 1000000000000000000, // 10^18
        trigger_price: 0,
        acceptable_price: 3501,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the swap order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1930);
    'try to create prder'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long = exchange_router.create_order(order_params_long);
    'long created'.print();
    let got_order_long = data_store.get_order(key_long);

    // Execute the swap order.

    let signatures: Span<felt252> = array![0].span();
    let set_price_params = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![3500, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1935);
    // TODO add real signatures check on Oracle Account
    order_handler.execute_order(key_long, set_price_params);
    'long position SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position = data_store.get_position(position_key_1);

    assert(first_position.size_in_tokens == 1000000000000000000, 'Size token should be 1 ETH');
    assert(first_position.size_in_usd == 3500000000000000000000, 'Size should be 3500$');
    assert(first_position.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position.collateral_amount == 1000000000000000000, 'Collat should be 1 ETH');

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 350000000000000000000, 'PnL should be 350$');

    let balance_USDC = IERC20Dispatcher { contract_address: contract_address_const::<'USDC'>() }
        .balance_of(caller_address);

    let balance_ETH = IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .balance_of(caller_address);

    assert(balance_USDC == 50000000000000000000000, 'balance USDC 50 000$');
    assert(balance_ETH == 9000000000000000000, 'balance ETH 9');

    let pool_value_info = market_utils::get_pool_value_info(
        data_store,
        market,
        Price { min: 3500, max: 3500, },
        Price { min: 3500, max: 3500, },
        Price { min: 1, max: 1, },
        keys::max_pnl_factor_for_deposits(),
        true,
    );

    assert(
        pool_value_info.pool_value.mag == 175050000000000000000000000000001, 'wrong pool value 2'
    );
    assert(
        pool_value_info.long_token_amount == 50000000000000000000000000000,
        'wrong long token amount 2'
    );
    assert(
        pool_value_info.short_token_amount == 50000000000000000000000000000,
        'wrong short token amount 2'
    );

    /////////////////////////////////////// LIQUIDATION LONG ///////////////////////////////////////

    'Check if liquidable 1000$'.print();

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 1000, max: 1000, },
        long_token_price: Price { min: 1000, max: 1000, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let (is_liquiditable, reason) = reader
        .is_position_liquidable(
            data_store, referal_storage, first_position, market, market_prices, true
        );

    assert(is_liquiditable == true, 'Position is liquidable');

    'Check if liquidable 3000$'.print();

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3000, max: 3000, },
        long_token_price: Price { min: 3000, max: 3000, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let (is_liquiditable, reason) = reader
        .is_position_liquidable(
            data_store, referal_storage, first_position, market, market_prices, true
        );

    assert(is_liquiditable == false, 'Position is not liquidable');

    let signatures: Span<felt252> = array![0].span();
    let set_price_params = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![1000, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    // Execute Liquidation
    liquidation_handler
        .execute_liquidation(
            first_position.account,
            first_position.market,
            first_position.collateral_token,
            first_position.is_long,
            set_price_params
        );

    let first_position_liq = data_store.get_position(position_key_1);

    assert(first_position_liq.size_in_tokens == 0, 'Size token should be 0');
    assert(first_position_liq.size_in_usd == 0, 'Size should be 0');
    assert(first_position_liq.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position_liq.collateral_amount == 0, 'Collat should be 0');

    let balance_USDC_af_liq = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_af_liq = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    assert(balance_USDC_af_liq == 50000000000000000000000, 'balance USDC 50 000$');
    assert(balance_ETH_af_liq == 9000000000000000000, 'balance ETH 9');

    let pool_value_info = market_utils::get_pool_value_info(
        data_store,
        market,
        Price { min: 3500, max: 3500, },
        Price { min: 3500, max: 3500, },
        Price { min: 1, max: 1, },
        keys::max_pnl_factor_for_deposits(),
        true,
    );

    assert(
        pool_value_info.pool_value.mag == 175050000003500000000000000000000, 'wrong pool value 3'
    );
    assert(
        pool_value_info.long_token_amount == 50000000001000000000000000000,
        'wrong long token amount 3'
    );
    assert(
        pool_value_info.short_token_amount == 50000000000000000000000000000,
        'wrong short token amount 3'
    );

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn test_long_leverage_positif_close() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        event_emitter,
        exchange_router,
        deposit_handler,
        deposit_vault,
        oracle,
        order_handler,
        order_vault,
        reader,
        referal_storage,
        withdrawal_handler,
        withdrawal_vault,
        liquidation_handler,
        market,
    ) =
        deposit_setup(
        50000000000000000000000000000, 50000000000000000000000000000
    );

    let balance_caller_ETH = IERC20Dispatcher { contract_address: market.long_token }
        .balance_of(caller_address);
    let balance_caller_USDC = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(caller_address);

    assert(balance_caller_ETH == 10000000000000000000, 'balanc ETH should be 10 ETH');
    assert(balance_caller_USDC == 50000000000000000000000, 'USDC be 50 000 USDC');

    // let pool_value_info = market_utils::get_pool_value_info(
    //     data_store,
    //     market,
    //     Price { min: 5000, max: 5000, },
    //     Price { min: 5000, max: 5000, },
    //     Price { min: 1, max: 1, },
    //     keys::max_pnl_factor_for_deposits(),
    //     true,
    // );

    // pool_value_info.pool_value.mag.print(); // 10000 000000000000000000
    // pool_value_info.long_token_amount.print(); // 5 000000000000000000
    // pool_value_info.short_token_amount.print(); // 25000 000000000000000000

    // ************************************* TEST LONG *********************************************

    'LONG TEST x10 leverage'.print();

    let key_open_interest = keys::open_interest_key(
        market.market_token, contract_address_const::<'ETH'>(), true
    );
    data_store.set_u256(key_open_interest, 1);
    let max_key_open_interest = keys::max_open_interest_key(market.market_token, true);
    data_store
        .set_u256(
            max_key_open_interest, 1000000000000000000000000000000000000000000000000000
        ); // 1 000 000

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 1000000000000000000); // 1ETH

    'transfer made'.print();
    // Create order_params Struct
    let contract_address = contract_address_const::<0>();
    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 35000000000000000000000,
        initial_collateral_delta_amount: 1000000000000000000, // 10^18
        trigger_price: 0,
        acceptable_price: 3501,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the swap order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1930);
    'try to create prder'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long = exchange_router.create_order(order_params_long);
    'long created'.print();
    let got_order_long = data_store.get_order(key_long);

    // Execute the swap order.

    let signatures: Span<felt252> = array![0].span();
    let set_price_params = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![3500, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1935);
    // TODO add real signatures check on Oracle Account
    order_handler.execute_order(key_long, set_price_params);
    'long position SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position = data_store.get_position(position_key_1);

    assert(first_position.size_in_tokens == 10000000000000000000, 'Size token should be 1 ETH');
    assert(first_position.size_in_usd == 35000000000000000000000, 'Size should be 35000$');
    assert(first_position.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position.collateral_amount == 1000000000000000000, 'Collat should be 1 ETH');

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 3500000000000000000000, 'PnL should be 3500$');

    //////////////////////////////////// CLOSE POSITION //////////////////////////////////////
    'CLOSE POSITION'.print();

    let balance_USDC_bef_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_bef_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 4000, max: 4000, },
        long_token_price: Price { min: 4000, max: 4000, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 5000000000000000000000, 'PnL should be 5000$');

    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long_dec_2 = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 35000000000000000000000, // 8400
        initial_collateral_delta_amount: 1000000000000000000, // 2.25 ETH 10^18
        trigger_price: 0,
        acceptable_price: 3850,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketDecrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1960);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long_dec_2 = exchange_router.create_order(order_params_long_dec_2);
    'long decrease created'.print();
    let got_order_long_dec = data_store.get_order(key_long_dec_2);
    // Execute the swap order.

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    let set_price_params_dec2 = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![3850, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1965);
    // TODO add real signatures check on Oracle Account
    order_handler.execute_order(key_long_dec_2, set_price_params_dec2);
    'Long pos close SUCCEEDED'.print();

    let first_position_close = data_store.get_position(position_key_1);

    assert(first_position_close.size_in_tokens == 0, 'Size token should be 0');
    assert(first_position_close.size_in_usd == 0, 'Size should be 0');
    assert(first_position_close.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position_close.collateral_amount == 0, 'Collat should be 0');

    let balance_USDC_af_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_af_close = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    assert(balance_USDC_bef_close == 50000000000000000000000, 'balance USDC shld be 50000$');
    assert(balance_USDC_af_close == 57349999999999999996500, 'balance USDC shld be 57350$');
    assert(balance_ETH_af_close == 9000000000000000000, 'balance ETH after 9');
    assert(balance_ETH_bef_close == 9000000000000000000, 'balance ETH after 9');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn test_long_leverage_liquidation() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (
        caller_address,
        market_factory_address,
        role_store_address,
        data_store_address,
        market_token_class_hash,
        market_factory,
        role_store,
        data_store,
        event_emitter,
        exchange_router,
        deposit_handler,
        deposit_vault,
        oracle,
        order_handler,
        order_vault,
        reader,
        referal_storage,
        withdrawal_handler,
        withdrawal_vault,
        liquidation_handler,
        market,
    ) =
        deposit_setup(
        50000000000000000000000000000, 50000000000000000000000000000
    );

    let balance_caller_ETH = IERC20Dispatcher { contract_address: market.long_token }
        .balance_of(caller_address);
    let balance_caller_USDC = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(caller_address);

    assert(balance_caller_ETH == 10000000000000000000, 'balanc ETH should be 10 ETH');
    assert(balance_caller_USDC == 50000000000000000000000, 'USDC be 50 000 USDC');

    let pool_value_info = market_utils::get_pool_value_info(
        data_store,
        market,
        Price { min: 3500, max: 3500, },
        Price { min: 3500, max: 3500, },
        Price { min: 1, max: 1, },
        keys::max_pnl_factor_for_deposits(),
        true,
    );

    assert(
        pool_value_info.pool_value.mag == 175050000000000000000000000000000, 'wrong pool value 1'
    );
    assert(
        pool_value_info.long_token_amount == 50000000000000000000000000000,
        'wrong long token amount 1'
    );
    assert(
        pool_value_info.short_token_amount == 50000000000000000000000000000,
        'wrong short token amount 1'
    );

    // ************************************* TEST LONG *********************************************

    'Begining of LONG TEST'.print();

    let key_open_interest = keys::open_interest_key(
        market.market_token, contract_address_const::<'ETH'>(), true
    );
    data_store.set_u256(key_open_interest, 1);
    let max_key_open_interest = keys::max_open_interest_key(market.market_token, true);
    data_store
        .set_u256(
            max_key_open_interest, 1000000000000000000000000000000000000000000000000000
        ); // 1 000 000

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'ETH'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .transfer(order_vault.contract_address, 1000000000000000000); // 1ETH

    'transfer made'.print();
    // Create order_params Struct
    let contract_address = contract_address_const::<0>();
    start_prank(market.market_token, caller_address);
    start_prank(market.long_token, caller_address);
    let order_params_long = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.long_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 35000000000000000000000,
        initial_collateral_delta_amount: 1000000000000000000, // 10^18
        trigger_price: 0,
        acceptable_price: 3501,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: true,
        referral_code: 0
    };
    // Create the swap order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1930);
    'try to create prder'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_long = exchange_router.create_order(order_params_long);
    'long created'.print();
    let got_order_long = data_store.get_order(key_long);

    // Execute the swap order.

    let signatures: Span<felt252> = array![0].span();
    let set_price_params = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![3500, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1935);
    // TODO add real signatures check on Oracle Account
    order_handler.execute_order(key_long, set_price_params);
    'long position SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position = data_store.get_position(position_key_1);

    assert(first_position.size_in_tokens == 10000000000000000000, 'Size token should be 10 ETH');
    assert(first_position.size_in_usd == 35000000000000000000000, 'Size should be 35000$');
    assert(first_position.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position.collateral_amount == 1000000000000000000, 'Collat should be 1 ETH');

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 3500000000000000000000, 'PnL should be 3500$');

    let balance_USDC = IERC20Dispatcher { contract_address: contract_address_const::<'USDC'>() }
        .balance_of(caller_address);

    let balance_ETH = IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .balance_of(caller_address);

    assert(balance_USDC == 50000000000000000000000, 'balance USDC 50 000$');
    assert(balance_ETH == 9000000000000000000, 'balance ETH 9');

    let pool_value_info = market_utils::get_pool_value_info(
        data_store,
        market,
        Price { min: 3500, max: 3500, },
        Price { min: 3500, max: 3500, },
        Price { min: 1, max: 1, },
        keys::max_pnl_factor_for_deposits(),
        true,
    );

    assert(
        pool_value_info.pool_value.mag == 175050000000000000000000000000001, 'wrong pool value 2'
    );
    assert(
        pool_value_info.long_token_amount == 50000000000000000000000000000,
        'wrong long token amount 2'
    );
    assert(
        pool_value_info.short_token_amount == 50000000000000000000000000000,
        'wrong short token amount 2'
    );

    /////////////////////////////////////// LIQUIDATION LONG ///////////////////////////////////////

    'Check if liquidable 3000$'.print();

    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3000, max: 3000, },
        long_token_price: Price { min: 3000, max: 3000, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let (is_liquiditable, reason) = reader
        .is_position_liquidable(
            data_store, referal_storage, first_position, market, market_prices, true
        );
    // position x10 leverage is liquidable at 3000$, position x1 leverage is not liquidable at 3000$
    assert(is_liquiditable == true, 'Position is liquidable');

    let signatures: Span<felt252> = array![0].span();
    let set_price_params = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![1000, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    // Execute Liquidation
    liquidation_handler
        .execute_liquidation(
            first_position.account,
            first_position.market,
            first_position.collateral_token,
            first_position.is_long,
            set_price_params
        );

    let first_position_liq = data_store.get_position(position_key_1);

    assert(first_position_liq.size_in_tokens == 0, 'Size token should be 0');
    assert(first_position_liq.size_in_usd == 0, 'Size should be 0');
    assert(first_position_liq.borrowing_factor == 0, 'Borrow should be 0');
    assert(first_position_liq.collateral_amount == 0, 'Collat should be 0');

    let balance_USDC_af_liq = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    let balance_ETH_af_liq = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    assert(balance_USDC_af_liq == 50000000000000000000000, 'balance USDC 50 000$');
    assert(balance_ETH_af_liq == 9000000000000000000, 'balance ETH 9');

    let pool_value_info = market_utils::get_pool_value_info(
        data_store,
        market,
        Price { min: 3500, max: 3500, },
        Price { min: 3500, max: 3500, },
        Price { min: 1, max: 1, },
        keys::max_pnl_factor_for_deposits(),
        true,
    );

    assert(
        pool_value_info.pool_value.mag == 175050000003500000000000000000000, 'wrong pool value 3'
    );
    assert(
        pool_value_info.long_token_amount == 50000000001000000000000000000,
        'wrong long token amount 3'
    );
    assert(
        pool_value_info.short_token_amount == 50000000000000000000000000000,
        'wrong short token amount 3'
    );

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}
