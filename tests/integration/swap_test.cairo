// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.

use result::ResultTrait;
use traits::{TryInto, Into};
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
    ClassHash,
};
use snforge_std::{declare, start_prank, stop_prank, start_roll, ContractClassTrait, ContractClass};
use debug::PrintTrait;

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
use satoru::order::order_utils::{IOrderUtilsDispatcher, IOrderUtilsDispatcherTrait};
use satoru::market::market_factory::{IMarketFactoryDispatcher, IMarketFactoryDispatcherTrait};
use satoru::event::event_emitter::{IEventEmitterDispatcher, IEventEmitterDispatcherTrait};
use satoru::deposit::deposit_vault::{IDepositVaultDispatcher, IDepositVaultDispatcherTrait};
use satoru::deposit::deposit::Deposit;
use satoru::exchange::deposit_handler::{IDepositHandlerDispatcher, IDepositHandlerDispatcherTrait};
use satoru::router::exchange_router::{IExchangeRouterDispatcher, IExchangeRouterDispatcherTrait};
use satoru::market::market::{Market, UniqueIdMarket};
use satoru::market::market_token::{IMarketTokenDispatcher, IMarketTokenDispatcherTrait};
use satoru::role::role;
use satoru::oracle::oracle_utils::SetPricesParams;
use satoru::tests_lib;
use satoru::deposit::deposit_utils::CreateDepositParams;
use satoru::utils::span32::{Span32, DefaultSpan32, Array32Trait};
use satoru::deposit::deposit_utils;
use satoru::bank::bank::{IBankDispatcherTrait, IBankDispatcher};
use satoru::bank::strict_bank::{IStrictBankDispatcher, IStrictBankDispatcherTrait};
use satoru::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use satoru::oracle::oracle::{IOracleDispatcher, IOracleDispatcherTrait};
use satoru::data::keys;
use satoru::market::market_utils;
use satoru::price::price::{Price, PriceTrait};
use satoru::position::position_utils;


use satoru::order::order::{Order, OrderType, SecondaryOrderType, DecreasePositionSwapType};
use satoru::order::order_vault::{IOrderVaultDispatcher, IOrderVaultDispatcherTrait};
use satoru::order::base_order_utils::{CreateOrderParams};
use satoru::oracle::oracle_store::{IOracleStoreDispatcher, IOracleStoreDispatcherTrait};
use satoru::swap::swap_handler::{ISwapHandlerDispatcher, ISwapHandlerDispatcherTrait};
use satoru::mock::referral_storage::{IReferralStorageDispatcher, IReferralStorageDispatcherTrait};
use satoru::market::{market::{UniqueIdMarketImpl},};
use satoru::exchange::order_handler::{
    OrderHandler, IOrderHandlerDispatcher, IOrderHandlerDispatcherTrait
};
const INITIAL_TOKENS_MINTED: felt252 = 1000;

#[test]
fn test_deposit_market_integration() {
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
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a market.
    let market = data_store.get_market(create_market(market_factory));

    // Set params in data_store
    data_store.set_address(keys::fee_token(), market.index_token);
    data_store.set_u256(keys::max_swap_path_length(), 5);

    // Set max pool amount.
    data_store
        .set_u256(
            keys::max_pool_amount_key(market.market_token, market.long_token), 500000000000000000
        );
    data_store
        .set_u256(
            keys::max_pool_amount_key(market.market_token, market.short_token), 500000000000000000
        );

    oracle.set_primary_prices(market.long_token, 5000);
    oracle.set_primary_prices(market.short_token, 1);

    // Fill the pool.
    IERC20Dispatcher { contract_address: market.long_token }.mint(market.market_token, 50000000000);
    IERC20Dispatcher { contract_address: market.short_token }
        .mint(market.market_token, 50000000000);

    IERC20Dispatcher { contract_address: market.long_token }
        .mint(deposit_vault.contract_address, 50000000000);
    IERC20Dispatcher { contract_address: market.short_token }
        .mint(deposit_vault.contract_address, 50000000000);

    let balance_deposit_vault_before = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(deposit_vault.contract_address);

    // Create Deposit
    let user1: ContractAddress = contract_address_const::<'user1'>();
    let user2: ContractAddress = contract_address_const::<'user2'>();

    let addresss_zero: ContractAddress = 0.try_into().unwrap();

    let params = CreateDepositParams {
        receiver: user1,
        callback_contract: user2,
        ui_fee_receiver: addresss_zero,
        market: market.market_token,
        initial_long_token: market.long_token,
        initial_short_token: market.short_token,
        long_token_swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        short_token_swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        min_market_tokens: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
    };

    start_roll(deposit_handler.contract_address, 1910);
    let key = deposit_handler.create_deposit(caller_address, params);
    let first_deposit = data_store.get_deposit(key);

    assert(first_deposit.account == caller_address, 'Wrong account depositer');
    assert(first_deposit.receiver == user1, 'Wrong account receiver');
    assert(first_deposit.initial_long_token == market.long_token, 'Wrong initial long token');
    assert(
        first_deposit.initial_long_token_amount == 50000000000, 'Wrong initial long token amount'
    );
    assert(
        first_deposit.initial_short_token_amount == 50000000000, 'Wrong init short token amount'
    );

    let price_params = SetPricesParams {
        signer_info: 1,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1900, 1900],
        compacted_max_oracle_block_numbers: array![1910, 1910],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![18, 18],
        compacted_min_prices: array![4294967346000000], // 50000000, 1000000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![4294967346000000], // 50000000, 1000000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    start_prank(role_store.contract_address, caller_address);

    role_store.grant_role(caller_address, role::ORDER_KEEPER);
    role_store.grant_role(caller_address, role::ROLE_ADMIN);
    role_store.grant_role(caller_address, role::CONTROLLER);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);

    // Execute Deposit
    start_roll(deposit_handler.contract_address, 1915);
    deposit_handler.execute_deposit(key, price_params);
    //calling swap ^^

    let pool_value_info = market_utils::get_pool_value_info(
        data_store,
        market,
        Price { min: 1999, max: 2000 },
        Price { min: 1999, max: 2000 },
        Price { min: 1999, max: 2000 },
        keys::max_pnl_factor_for_deposits(),
        true,
    );

    assert(pool_value_info.pool_value.mag == 200000000000000, 'wrong pool value amount');
    assert(pool_value_info.long_token_amount == 50000000000, 'wrong long token amount');
    assert(pool_value_info.short_token_amount == 50000000000, 'wrong short token amount');

    let not_deposit = data_store.get_deposit(key);
    let default_deposit: Deposit = Default::default();
    assert(not_deposit == default_deposit, 'Still existing deposit');

    // let market_token_dispatcher = IMarketTokenDispatcher { contract_address: market.market_token };

    // let balance = market_token_dispatcher.balance_of(user1);

    let balance_deposit_vault = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(deposit_vault.contract_address);

    let pool_value_info = market_utils::get_pool_value_info(
        data_store,
        market,
        Price { min: 5000, max: 5000, },
        Price { min: 5000, max: 5000, },
        Price { min: 1, max: 1, },
        keys::max_pnl_factor_for_deposits(),
        true,
    );

    // // --------------------------------------------------SWAP TEST ETH->USDC --------------------------------------------------
    let balance_ETH_before_swap = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);
    assert(balance_ETH_before_swap == 1000000, 'wrong balance ETH before swap');

    let balance_USDC_before_swap = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);
    assert(balance_USDC_before_swap == 1000000, 'wrong balance USDC before swap');

    start_prank(contract_address_const::<'ETH'>(), caller_address); //change to switch swap
    // Send token to order_vault in multicall with create_order
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() } //change to switch swap
        .transfer(order_vault.contract_address, 1);

    let balance_ETH_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    let balance_USDC_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    // Create order_params Struct
    let contract_address = contract_address_const::<0>();
    start_prank(market.long_token, caller_address); //change to switch swap

    let order_params = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: contract_address,
        initial_collateral_token: market.long_token, //change to switch swap
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 1,
        initial_collateral_delta_amount: 1, // 10^18
        trigger_price: 0,
        acceptable_price: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketSwap(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: false,
        referral_code: 0
    };
    // Create the swap order.
    start_roll(order_handler.contract_address, 1920);

    //here we create the order but we do not execute it yet
    let key = order_handler.create_order(caller_address, order_params);

    let got_order = data_store.get_order(key);

    data_store
        .set_u256(
            keys::pool_amount_key(market.market_token, contract_address_const::<'USDC'>()),
            10000000000
        );
    data_store
        .set_u256(
            keys::pool_amount_key(market.market_token, contract_address_const::<'ETH'>()),
            10000000000
        );

    // Execute the swap order.
    let signatures: Span<felt252> = array![0].span();
    let set_price_params = SetPricesParams {
        signer_info: 2,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    let balance_ETH_before_execute = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);
    let balance_USDC_before_execute = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    // assert(balance_ETH_after == 999999, 'wrong balance ETH after swap');

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1925);
    // TODO add real signatures check on Oracle Account -> Later
    order_handler.execute_order_keeper(key, set_price_params, keeper_address); //execute order

    let balance_ETH_after = IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .balance_of(caller_address);

    let balance_USDC_after = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    assert(balance_ETH_after == 999999, 'wrong balance ETH after swap');
    assert(balance_USDC_after == 1005000, 'wrong balance USDC after swap');

    let first_swap_pool_value_info = market_utils::get_pool_value_info(
        data_store,
        market,
        Price { min: 5000, max: 5000, },
        Price { min: 5000, max: 5000, },
        Price { min: 1, max: 1, },
        keys::max_pnl_factor_for_deposits(),
        true,
    );

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

#[test]
fn test_swap_18_deposit_market_integration() {
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
    ) =
        setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a market.
    let market = data_store.get_market(create_market(market_factory));

    // Set params in data_store
    data_store.set_address(keys::fee_token(), market.index_token);
    data_store.set_u256(keys::max_swap_path_length(), 5);

    // Set max pool amount.
    data_store
        .set_u256(
            keys::max_pool_amount_key(market.market_token, market.long_token),
            5000000000000000000000000000000000000000000
        );
    data_store
        .set_u256(
            keys::max_pool_amount_key(market.market_token, market.short_token),
            2500000000000000000000000000000000000000000000
        );

    oracle.set_primary_prices(market.long_token, 5000);
    oracle.set_primary_prices(market.short_token, 1);

    'fill the pool'.print();
    // Fill the pool.
    IERC20Dispatcher { contract_address: market.long_token }
        .mint(market.market_token, 50000000000000000000000000000000000000); // 5 ETH
    IERC20Dispatcher { contract_address: market.short_token }
        .mint(market.market_token, 25000000000000000000000000000000000000000); // 25000 USDC
    'filled pool 1'.print();

    IERC20Dispatcher { contract_address: market.long_token }
        .mint(caller_address, 9999999999999000000); // 9.999 ETH
    IERC20Dispatcher { contract_address: market.short_token }
        .mint(caller_address, 49999999999999999000000); // 49.999 UDC
    'filled account'.print();
    // INITIAL LONG TOKEN IN POOL : 5 ETH
    // INITIAL SHORT TOKEN IN POOL : 25000 USDC

    // TODO Check why we don't need to set pool_amount_key
    // // Set pool amount in data_store.
    // let mut key = keys::pool_amount_key(market.market_token, contract_address_const::<'ETH'>());

    let balance_deposit_vault_before = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(deposit_vault.contract_address);
    let balance_caller_ETH = IERC20Dispatcher { contract_address: market.long_token }
        .balance_of(caller_address);
    let balance_caller_USDC = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(caller_address);

    assert(balance_deposit_vault_before == 0, 'balance deposit should be 0');
    assert(balance_caller_ETH == 10000000000000000000, 'balanc ETH should be 10 ETH');
    assert(balance_caller_USDC == 50000000000000000000000, 'USDC be 50 000 USDC');

    // Send token to deposit in the deposit vault (this should be in a multi call with create_deposit)
    'get balances'.print();
    // start_prank(market.long_token, caller_address);
    // IERC20Dispatcher { contract_address: market.long_token }
    //     .transfer(deposit_vault.contract_address, 5000000000000000000); // 5 ETH

    // start_prank(market.short_token, caller_address);
    // IERC20Dispatcher { contract_address: market.short_token }
    //     .transfer(deposit_vault.contract_address, 25000000000000000000000); // 25000 USDC
    // 'make transfer'.print();

    IERC20Dispatcher { contract_address: market.long_token }
        .mint(deposit_vault.contract_address, 50000000000000000000000000000); // 50 000 000 000
    IERC20Dispatcher { contract_address: market.short_token }
        .mint(deposit_vault.contract_address, 50000000000000000000000000000); // 50 000 000 000
    // Create Deposit

    let addresss_zero: ContractAddress = 0.try_into().unwrap();

    let params = CreateDepositParams {
        receiver: caller_address,
        callback_contract: addresss_zero,
        ui_fee_receiver: addresss_zero,
        market: market.market_token,
        initial_long_token: market.long_token,
        initial_short_token: market.short_token,
        long_token_swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        short_token_swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        min_market_tokens: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
    };

    start_roll(deposit_handler.contract_address, 1910);
    let key = deposit_handler.create_deposit(caller_address, params);
    let first_deposit = data_store.get_deposit(key);

    assert(first_deposit.account == caller_address, 'Wrong account depositer');
    assert(first_deposit.receiver == caller_address, 'Wrong account receiver');
    assert(first_deposit.initial_long_token == market.long_token, 'Wrong initial long token');
    assert(
        first_deposit.initial_long_token_amount == 50000000000000000000000000000,
        'Wrong initial long token amount'
    );
    assert(
        first_deposit.initial_short_token_amount == 50000000000000000000000000000,
        'Wrong init short token amount'
    );

    let price_params = SetPricesParams {
        signer_info: 1,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1900, 1900],
        compacted_max_oracle_block_numbers: array![1910, 1910],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![18, 18],
        compacted_min_prices: array![4294967346000000], // 50000000, 1000000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![4294967346000000], // 50000000, 1000000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    start_prank(role_store.contract_address, caller_address);

    role_store.grant_role(caller_address, role::ORDER_KEEPER);
    role_store.grant_role(caller_address, role::ROLE_ADMIN);
    role_store.grant_role(caller_address, role::CONTROLLER);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);

    // Execute Deposit
    start_roll(deposit_handler.contract_address, 1915);
    deposit_handler.execute_deposit(key, price_params);
    //calling swap ^^

    // let pool_value_info = market_utils::get_pool_value_info(
    //     data_store,
    //     market,
    //     Price { min: 1999, max: 2000 },
    //     Price { min: 1999, max: 2000 },
    //     Price { min: 1999, max: 2000 },
    //     keys::max_pnl_factor_for_deposits(),
    //     true,
    // );

    // assert(pool_value_info.pool_value.mag == 200000000000000, 'wrong pool value amount');
    // assert(pool_value_info.long_token_amount == 50000000000, 'wrong long token amount');
    // assert(pool_value_info.short_token_amount == 50000000000, 'wrong short token amount');

    let not_deposit = data_store.get_deposit(key);
    let default_deposit: Deposit = Default::default();
    assert(not_deposit == default_deposit, 'Still existing deposit');

    // let market_token_dispatcher = IMarketTokenDispatcher { contract_address: market.market_token };

    // let balance = market_token_dispatcher.balance_of(user1);

    let balance_deposit_vault = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(deposit_vault.contract_address);

    let pool_value_info = market_utils::get_pool_value_info(
        data_store,
        market,
        Price { min: 5000, max: 5000, },
        Price { min: 5000, max: 5000, },
        Price { min: 1, max: 1, },
        keys::max_pnl_factor_for_deposits(),
        true,
    );

    pool_value_info.pool_value.mag.print();
    pool_value_info.long_token_amount.print();
    pool_value_info.short_token_amount.print();

    // // --------------------------------------------------SWAP TEST ETH->USDC --------------------------------------------------
    'Swap ETH to USDC'.print();
    let balance_ETH_before_swap = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);
    assert(balance_ETH_before_swap == 10000000000000000000, 'wrong balance ETH before swap');

    'Eth balance: '.print();
    balance_ETH_before_swap.print();

    let balance_USDC_before_swap = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);
    assert(balance_USDC_before_swap == 50000000000000000000000, 'wrong balance USDC before swap');

    'USDC balance: '.print();
    balance_USDC_before_swap.print();

    start_prank(contract_address_const::<'ETH'>(), caller_address); //change to switch swap
    // Send token to order_vault in multicall with create_order
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() } //change to switch swap
        .transfer(order_vault.contract_address, 1000000000000000000);

    let balance_ETH_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    'Eth balance after vault: '.print();
    balance_ETH_before.print();

    let balance_USDC_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    'USDC balance after vault: '.print();
    balance_USDC_before.print();

    // Create order_params Struct
    let contract_address = contract_address_const::<0>();
    start_prank(market.long_token, caller_address); //change to switch swap

    let order_params = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: contract_address,
        initial_collateral_token: market.long_token, //change to switch swap
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 1000000000000000000,
        initial_collateral_delta_amount: 1000000000000000000, // 10^18
        trigger_price: 0,
        acceptable_price: 0,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketSwap(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: false,
        referral_code: 0
    };
    // Create the swap order.
    start_roll(order_handler.contract_address, 1920);

    //here we create the order but we do not execute it yet
    let key = order_handler.create_order(caller_address, order_params);

    let got_order = data_store.get_order(key);

    data_store
        .set_u256(
            keys::pool_amount_key(market.market_token, contract_address_const::<'USDC'>()),
            50000000000000000000000000000
        );
    data_store
        .set_u256(
            keys::pool_amount_key(market.market_token, contract_address_const::<'ETH'>()),
            50000000000000000000000000000
        );

    // Execute the swap order.
    let signatures: Span<felt252> = array![0].span();
    let set_price_params = SetPricesParams {
        signer_info: 2,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    let balance_ETH_before_execute = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);
    let balance_USDC_before_execute = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    'balance eth before execute'.print();
    balance_ETH_before_execute.print();
    // assert(balance_ETH_after == 999999, 'wrong balance ETH after swap');
    'balance usdc before execute'.print();
    balance_USDC_before_execute.print();

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1925);
    // TODO add real signatures check on Oracle Account -> Later
    order_handler.execute_order_keeper(key, set_price_params, keeper_address); //execute order

    let balance_ETH_after = IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .balance_of(caller_address);

    'eth after all the flow'.print();
    balance_ETH_after.print();

    let balance_USDC_after = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    'usdc after all the flow'.print();
    balance_USDC_after.print();

    // assert(balance_ETH_after == 999999, 'wrong balance ETH after swap');
    // assert(balance_USDC_after == 1005000, 'wrong balance USDC after swap');

    let first_swap_pool_value_info = market_utils::get_pool_value_info(
        data_store,
        market,
        Price { min: 5000, max: 5000, },
        Price { min: 5000, max: 5000, },
        Price { min: 1, max: 1, },
        keys::max_pnl_factor_for_deposits(),
        true,
    );

    first_swap_pool_value_info.pool_value.mag.print();
    first_swap_pool_value_info.long_token_amount.print();
    first_swap_pool_value_info.short_token_amount.print();

    balance_ETH_after.print();
    balance_USDC_after.print();
    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}

// #[test]
// fn test_swap_market_integration() {
//     // *********************************************************************************************
//     // *                              SETUP                                                        *
//     // *********************************************************************************************
//     let (
//         caller_address,
//         market_factory_address,
//         role_store_address,
//         data_store_address,
//         market_token_class_hash,
//         market_factory,
//         role_store,
//         data_store,
//         event_emitter,
//         exchange_router,
//         deposit_handler,
//         deposit_vault,
//         oracle,
//         order_handler,
//         order_vault,
//     ) =
//         setup();

//     // *********************************************************************************************
//     // *                              TEST LOGIC                                                   *
//     // *********************************************************************************************

//     // Create a market.
//     let market = data_store.get_market(create_market(market_factory));

//     // Set params in data_store
//     data_store.set_address(keys::fee_token(), market.index_token);
//     data_store.set_u256(keys::max_swap_path_length(), 5);

//     // Set max pool amount.
//     data_store
//         .set_u256(
//             keys::max_pool_amount_key(market.market_token, market.long_token), 5000000000000000000000000000000000000
//         );
//     data_store
//         .set_u256(
//             keys::max_pool_amount_key(market.market_token, market.short_token), 5000000000000000000000000000000000000
//         );

//     oracle.set_price_testing_eth(5000000000000000000000);
//     // Fill the pool.
//     IERC20Dispatcher { contract_address: market.long_token }.mint(market.market_token, 500000000000000000000);
//     IERC20Dispatcher { contract_address: market.short_token }
//         .mint(market.market_token, 2500000000000000000000000);

//     IERC20Dispatcher { contract_address: market.long_token }
//         .mint(deposit_vault.contract_address, 5000000000000000000);
//     IERC20Dispatcher { contract_address: market.short_token }
//         .mint(deposit_vault.contract_address, 25000000000000000000000);

//     let balance_deposit_vault_before = IERC20Dispatcher { contract_address: market.short_token }
//         .balance_of(deposit_vault.contract_address);

//     // balance_deposit_vault_before.print();

//     // Create Deposit
//     let user1: ContractAddress = contract_address_const::<'user1'>();
//     let user2: ContractAddress = contract_address_const::<'user2'>();

//     let addresss_zero: ContractAddress = 0.try_into().unwrap();

//     let params = CreateDepositParams {
//         receiver: user1,
//         callback_contract: user2,
//         ui_fee_receiver: addresss_zero,
//         market: market.market_token,
//         initial_long_token: market.long_token,
//         initial_short_token: market.short_token,
//         long_token_swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
//         short_token_swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
//         min_market_tokens: 0,
//         execution_fee: 0,
//         callback_gas_limit: 0,
//     };

//     start_roll(deposit_handler.contract_address, 1910);
//     let key = deposit_handler.create_deposit(caller_address, params);
//     let first_deposit = data_store.get_deposit(key);

//     assert(first_deposit.account == caller_address, 'Wrong account depositer');
//     assert(first_deposit.receiver == user1, 'Wrong account receiver');
//     assert(first_deposit.initial_long_token == market.long_token, 'Wrong initial long token');
//     assert(
//         first_deposit.initial_long_token_amount == 5000000000000000000, 'Wrong initial long token amount'
//     );
//     assert(
//         first_deposit.initial_short_token_amount == 25000000000000000000000, 'Wrong init short token amount'
//     );

//     let price_params = SetPricesParams {
//         signer_info: 1,
//         tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
//         compacted_min_oracle_block_numbers: array![1900, 1900],
//         compacted_max_oracle_block_numbers: array![1910, 1910],
//         compacted_oracle_timestamps: array![9999, 9999],
//         compacted_decimals: array![18, 18],
//         compacted_min_prices: array![4294967346000000], // 50000000, 1000000 compacted
//         compacted_min_prices_indexes: array![0],
//         compacted_max_prices: array![4294967346000000], // 50000000, 1000000 compacted
//         compacted_max_prices_indexes: array![0],
//         signatures: array![
//             array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
//         ],
//         price_feed_tokens: array![]
//     };

//     start_prank(role_store.contract_address, caller_address);

//     role_store.grant_role(caller_address, role::ORDER_KEEPER);
//     role_store.grant_role(caller_address, role::ROLE_ADMIN);
//     role_store.grant_role(caller_address, role::CONTROLLER);
//     role_store.grant_role(caller_address, role::MARKET_KEEPER);

//     // Execute Deposit
//     start_roll(deposit_handler.contract_address, 1915);
//     deposit_handler.execute_deposit(key, price_params);
//     //calling swap ^^

//     let pool_value_info = market_utils::get_pool_value_info(
//         data_store,
//         market,
//         Price { min: 1999000000000000000000, max: 2000000000000000000000 },
//         Price { min: 1999000000000000000000, max: 2000000000000000000000 },
//         Price { min: 1999000000000000000000, max: 2000000000000000000000 },
//         keys::max_pnl_factor_for_deposits(),
//         true,
//     );
//     'pool_value'.print();
//     (pool_value_info.pool_value.mag).print();
//     // assert(pool_value_info.pool_value.mag == 5050000000000000000000000, 'wrong pool value amount');
//     // assert(pool_value_info.long_token_amount == 2750000000000000000000000, 'wrong long token amount');
//     // assert(pool_value_info.short_token_amount == 2750000000000000000000000, 'wrong short token amount');

//     let not_deposit = data_store.get_deposit(key);
//     let default_deposit: Deposit = Default::default();
//     assert(not_deposit == default_deposit, 'Still existing deposit');

//     // let market_token_dispatcher = IMarketTokenDispatcher { contract_address: market.market_token };

//     // let balance = market_token_dispatcher.balance_of(user1);

//     let balance_deposit_vault = IERC20Dispatcher { contract_address: market.short_token }
//         .balance_of(deposit_vault.contract_address);

//     let pool_value_info = market_utils::get_pool_value_info(
//         data_store,
//         market,
//         Price { min: 5000000000000000000000, max: 5000000000000000000000, },
//         Price { min: 5000000000000000000000, max: 5000000000000000000000, },
//         Price { min: 1000000000000000000, max: 1000000000000000000, },
//         keys::max_pnl_factor_for_deposits(),
//         true,
//     );

//     pool_value_info.pool_value.mag.print();
//     pool_value_info.long_token_amount.print();
//     pool_value_info.short_token_amount.print();

//     // // --------------------------------------------------SWAP TEST ETH->USDC --------------------------------------------------
//     'Swap ETH to USDC'.print();
//     let balance_ETH_before_swap = IERC20Dispatcher {
//         contract_address: contract_address_const::<'ETH'>()
//     }
//         .balance_of(caller_address);
//     assert(balance_ETH_before_swap == 10000000000000000000, 'wrong balance ETH before swap');

//     'Eth balance: '.print();
//     balance_ETH_before_swap.print();

//     let balance_USDC_before_swap = IERC20Dispatcher {
//         contract_address: contract_address_const::<'USDC'>()
//     }
//         .balance_of(caller_address);
//     assert(balance_USDC_before_swap == 100000000000000000000000, 'wrong balance USDC before swap');

//     'USDC balance: '.print();
//     balance_USDC_before_swap.print();

//     start_prank(contract_address_const::<'ETH'>(), caller_address); //change to switch swap
//     // Send token to order_vault in multicall with create_order
//     IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() } //change to switch swap
//         .transfer(order_vault.contract_address, 1000000000000000000);

//     let balance_ETH_before = IERC20Dispatcher {
//         contract_address: contract_address_const::<'ETH'>()
//     }
//         .balance_of(caller_address);

//     'Eth balance after vault: '.print();
//     balance_ETH_before.print();

//     let balance_USDC_before = IERC20Dispatcher {
//         contract_address: contract_address_const::<'USDC'>()
//     }
//         .balance_of(caller_address);

//     'USDC balance after vault: '.print();
//     balance_USDC_before.print();

//     // Create order_params Struct
//     let contract_address = contract_address_const::<0>();
//     start_prank(market.long_token, caller_address); //change to switch swap

//     let order_params = CreateOrderParams {
//         receiver: caller_address,
//         callback_contract: contract_address,
//         ui_fee_receiver: contract_address,
//         market: contract_address,
//         initial_collateral_token: market.long_token, //change to switch swap
//         swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
//         size_delta_usd: 5000000000000000000000,
//         initial_collateral_delta_amount: 5000000000000000000000, // 10^18
//         trigger_price: 0,
//         acceptable_price: 0,
//         execution_fee: 0,
//         callback_gas_limit: 0,
//         min_output_amount: 0,
//         order_type: OrderType::MarketSwap(()),
//         decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
//         is_long: false,
//         referral_code: 0
//     };
//     // Create the swap order.
//     start_roll(order_handler.contract_address, 1920);

//     //here we create the order but we do not execute it yet
//     let key = order_handler.create_order(caller_address, order_params);

//     let got_order = data_store.get_order(key);

//     data_store
//         .set_u256(
//             keys::pool_amount_key(market.market_token, contract_address_const::<'USDC'>()),
//             10000000000000000000000000000
//         );
//     data_store
//         .set_u256(
//             keys::pool_amount_key(market.market_token, contract_address_const::<'ETH'>()),
//             1000000000000000000000000000000
//         );

//     // Execute the swap order.
//     let signatures: Span<felt252> = array![0].span();
//     let set_price_params = SetPricesParams {
//         signer_info: 2,
//         tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
//         compacted_min_oracle_block_numbers: array![1910, 1910],
//         compacted_max_oracle_block_numbers: array![1920, 1920],
//         compacted_oracle_timestamps: array![9999, 9999],
//         compacted_decimals: array![1, 1],
//         compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
//         compacted_min_prices_indexes: array![0],
//         compacted_max_prices: array![2147483648010000], // 500000, 10000 compacted
//         compacted_max_prices_indexes: array![0],
//         signatures: array![
//             array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
//         ],
//         price_feed_tokens: array![]
//     };

//     let balance_ETH_before_execute = IERC20Dispatcher {
//         contract_address: contract_address_const::<'ETH'>()
//     }
//         .balance_of(caller_address);
//     let balance_USDC_before_execute = IERC20Dispatcher {
//         contract_address: contract_address_const::<'USDC'>()
//     }
//         .balance_of(caller_address);

//     'balance eth before execute'.print();
//     balance_ETH_before_execute.print();
//     // assert(balance_ETH_after == 999999, 'wrong balance ETH after swap');
//     'balance usdc before execute'.print();
//     balance_USDC_before_execute.print();

//     let keeper_address = contract_address_const::<'keeper'>();
//     role_store.grant_role(keeper_address, role::ORDER_KEEPER);

//     stop_prank(order_handler.contract_address);
//     start_prank(order_handler.contract_address, keeper_address);
//     start_roll(order_handler.contract_address, 1925);
//     // TODO add real signatures check on Oracle Account -> Later
//     order_handler.execute_order_keeper(key, set_price_params, keeper_address); //execute order

//     let balance_ETH_after = IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
//         .balance_of(caller_address);

//     'eth after all the flow'.print();
//     balance_ETH_after.print();

//     let balance_USDC_after = IERC20Dispatcher {
//         contract_address: contract_address_const::<'USDC'>()
//     }
//         .balance_of(caller_address);

//     'usdc after all the flow'.print();
//     balance_USDC_after.print();

//     assert(balance_ETH_after == 9999999999999999999, 'wrong balance ETH after swap');
//     assert(balance_USDC_after == 105000000000000000000000, 'wrong balance USDC after swap');

//     let first_swap_pool_value_info = market_utils::get_pool_value_info(
//         data_store,
//         market,
//         Price { min: 5000000000000000000000, max: 5000000000000000000000, },
//         Price { min: 5000000000000000000000, max: 5000000000000000000000, },
//         Price { min: 1000000000000000000, max: 1000000000000000000, },
//         keys::max_pnl_factor_for_deposits(),
//         true,
//     );

//     first_swap_pool_value_info.pool_value.mag.print();
//     first_swap_pool_value_info.long_token_amount.print();
//     first_swap_pool_value_info.short_token_amount.print();

//     // *********************************************************************************************
//     // *                              TEARDOWN                                                     *
//     // *********************************************************************************************
//     teardown(data_store, market_factory);
// }

fn create_market(market_factory: IMarketFactoryDispatcher) -> ContractAddress {
    // Create a market.
    let (index_token, short_token) = deploy_tokens();
    let market_type = 'market_type';

    // Index token is the same as long token here.
    market_factory.create_market(index_token, index_token, short_token, market_type)
}

/// Utility functions to deploy tokens for a market.
fn deploy_tokens() -> (ContractAddress, ContractAddress) {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let contract = declare('ERC20');

    let eth_address = contract_address_const::<'ETH'>();
    let constructor_calldata = array!['Ethereum', 'ETH', 1000000, 0, caller_address.into()];
    // let constructor_calldata = array!['Ethereum', 'ETH', 10000000000000000000, 0, caller_address.into()];
    contract.deploy_at(@constructor_calldata, eth_address).unwrap();

    let usdc_address = contract_address_const::<'USDC'>();
    let constructor_calldata = array!['usdc', 'USDC', 1000000, 0, caller_address.into()];
    // let constructor_calldata = array!['usdc', 'USDC', 100000000000000000000000, 0, caller_address.into()];
    contract.deploy_at(@constructor_calldata, usdc_address).unwrap();
    (eth_address, usdc_address)
}

/// Utility function to setup the test environment.
fn setup() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress,
    // Address of the `MarketFactory` contract.
    ContractAddress,
    // Address of the `RoleStore` contract.
    ContractAddress,
    // Address of the `DataStore` contract.
    ContractAddress,
    // The `MarketToken` class hash for the factory.
    ContractClass,
    // Interface to interact with the `MarketFactory` contract.
    IMarketFactoryDispatcher,
    // Interface to interact with the `RoleStore` contract.
    IRoleStoreDispatcher,
    // Interface to interact with the `DataStore` contract.
    IDataStoreDispatcher,
    // Interface to interact with the `EventEmitter` contract.
    IEventEmitterDispatcher,
    // Interface to interact with the `ExchangeRouter` contract.
    IExchangeRouterDispatcher,
    // Interface to interact with the `DepositHandler` contract.
    IDepositHandlerDispatcher,
    // Interface to interact with the `DepositHandler` contract.
    IDepositVaultDispatcher,
    IOracleDispatcher,
    IOrderHandlerDispatcher,
    IOrderVaultDispatcher,
) {
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
    ) =
        setup_contracts();
    grant_roles_and_prank(caller_address, role_store, data_store, market_factory);
    (
        caller_address,
        market_factory.contract_address,
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
    )
}

// Utility function to grant roles and prank the caller address.
/// Grants roles and pranks the caller address.
///
/// # Arguments
///
/// * `caller_address` - The address of the caller.
/// * `role_store` - The interface to interact with the `RoleStore` contract.
/// * `data_store` - The interface to interact with the `DataStore` contract.
/// * `market_factory` - The interface to interact with the `MarketFactory` contract.
fn grant_roles_and_prank(
    caller_address: ContractAddress,
    role_store: IRoleStoreDispatcher,
    data_store: IDataStoreDispatcher,
    market_factory: IMarketFactoryDispatcher,
) {
    start_prank(role_store.contract_address, caller_address);

    // Grant the caller the `CONTROLLER` role.
    role_store.grant_role(caller_address, role::CONTROLLER);

    // Grant the call the `MARKET_KEEPER` role.
    // This role is required to create a market.
    role_store.grant_role(caller_address, role::MARKET_KEEPER);

    // Prank the caller address for calls to `DataStore` contract.
    // We need this so that the caller has the CONTROLLER role.
    start_prank(data_store.contract_address, caller_address);

    // Start pranking the `MarketFactory` contract. This is necessary to mock the behavior of the contract
    // for testing purposes.
    start_prank(market_factory.contract_address, caller_address);
}

/// Utility function to teardown the test environment.
fn teardown(data_store: IDataStoreDispatcher, market_factory: IMarketFactoryDispatcher) {
    stop_prank(data_store.contract_address);
    stop_prank(market_factory.contract_address);
}

/// Setup required contracts.
fn setup_contracts() -> (
    // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress,
    // Address of the `MarketFactory` contract.
    ContractAddress,
    // Address of the `RoleStore` contract.
    ContractAddress,
    // Address of the `DataStore` contract.
    ContractAddress,
    // The `MarketToken` class hash for the factory.
    ContractClass,
    // Interface to interact with the `MarketFactory` contract.
    IMarketFactoryDispatcher,
    // Interface to interact with the `RoleStore` contract.
    IRoleStoreDispatcher,
    // Interface to interact with the `DataStore` contract.
    IDataStoreDispatcher,
    // Interface to interact with the `EventEmitter` contract.
    IEventEmitterDispatcher,
    // Interface to interact with the `ExchangeRouter` contract.
    IExchangeRouterDispatcher,
    // Interface to interact with the `DepositHandler` contract.
    IDepositHandlerDispatcher,
    // Interface to interact with the `DepositHandler` contract.
    IDepositVaultDispatcher,
    IOracleDispatcher,
    IOrderHandlerDispatcher,
    IOrderVaultDispatcher,
) {
    // Deploy the role store contract.
    let role_store_address = deploy_role_store();

    // Create a role store dispatcher.
    let role_store = IRoleStoreDispatcher { contract_address: role_store_address };

    // Deploy the contract.
    let data_store_address = deploy_data_store(role_store_address);
    // Create a safe dispatcher to interact with the contract.
    let data_store = IDataStoreDispatcher { contract_address: data_store_address };

    // Declare the `MarketToken` contract.
    let market_token_class_hash = declare_market_token();

    // Deploy the event emitter contract.
    let event_emitter_address = deploy_event_emitter();
    // Create a safe dispatcher to interact with the contract.
    let event_emitter = IEventEmitterDispatcher { contract_address: event_emitter_address };

    // Deploy the router contract.
    let router_address = deploy_router(role_store_address);

    // Deploy the market factory.
    let market_factory_address = deploy_market_factory(
        data_store_address, role_store_address, event_emitter_address, market_token_class_hash
    );
    // Create a safe dispatcher to interact with the contract.
    let market_factory = IMarketFactoryDispatcher { contract_address: market_factory_address };

    let oracle_store_address = deploy_oracle_store(role_store_address, event_emitter_address);
    let oracle_address = deploy_oracle(
        role_store_address, oracle_store_address, contract_address_const::<'pragma'>()
    );

    let oracle = IOracleDispatcher { contract_address: oracle_address };

    let deposit_vault_address = deploy_deposit_vault(role_store_address, data_store_address);

    let deposit_vault = IDepositVaultDispatcher { contract_address: deposit_vault_address };
    let deposit_handler_address = deploy_deposit_handler(
        data_store_address,
        role_store_address,
        event_emitter_address,
        deposit_vault_address,
        oracle_address
    );
    let deposit_handler = IDepositHandlerDispatcher { contract_address: deposit_handler_address };

    let withdrawal_vault_address = deploy_withdrawal_vault(data_store_address, role_store_address);
    let withdrawal_handler_address = deploy_withdrawal_handler(
        data_store_address,
        role_store_address,
        event_emitter_address,
        withdrawal_vault_address,
        oracle_address
    );

    let order_vault_address = deploy_order_vault(
        data_store.contract_address, role_store.contract_address
    );
    let order_vault = IOrderVaultDispatcher { contract_address: order_vault_address };

    let swap_handler_address = deploy_swap_handler_address(role_store_address, data_store_address);
    let referral_storage_address = deploy_referral_storage(event_emitter_address);
    let increase_order_class_hash = declare_increase_order();
    let decrease_order_class_hash = declare_decrease_order();
    let swap_order_class_hash = declare_swap_order();

    let order_utils_class_hash = declare_order_utils();

    let order_handler_address = deploy_order_handler(
        data_store_address,
        role_store_address,
        event_emitter_address,
        order_vault_address,
        oracle_address,
        swap_handler_address,
        referral_storage_address,
        order_utils_class_hash,
        increase_order_class_hash,
        decrease_order_class_hash,
        swap_order_class_hash
    );
    let order_handler = IOrderHandlerDispatcher { contract_address: order_handler_address };

    let exchange_router_address = deploy_exchange_router(
        router_address,
        data_store_address,
        role_store_address,
        event_emitter_address,
        deposit_handler_address,
        withdrawal_handler_address,
        order_handler_address
    );
    let exchange_router = IExchangeRouterDispatcher { contract_address: exchange_router_address };

    let bank_address = deploy_bank(data_store_address, role_store_address);

    //Create a safe dispatcher to interact with the Bank contract.
    let bank = IBankDispatcher { contract_address: bank_address };

    // Deploy the strict bank contract
    let strict_bank_address = deploy_strict_bank(data_store_address, role_store_address);

    //Create a safe dispatcher to interact with the StrictBank contract.
    let strict_bank = IStrictBankDispatcher { contract_address: strict_bank_address };

    (
        contract_address_const::<'caller'>(),
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
    )
}

/// Utility function to declare a `MarketToken` contract.
fn declare_market_token() -> ContractClass {
    declare('MarketToken')
}

/// Utility function to deploy a market factory contract and return its address.
fn deploy_market_factory(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    market_token_class_hash: ContractClass,
) -> ContractAddress {
    let contract = declare('MarketFactory');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'market_factory'>();
    start_prank(deployed_contract_address, caller_address);
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    constructor_calldata.append(event_emitter_address.into());
    constructor_calldata.append(market_token_class_hash.class_hash.into());
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}


fn deploy_data_store(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('DataStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address: ContractAddress = 0x1.try_into().unwrap();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_role_store() -> ContractAddress {
    let contract = declare('RoleStore');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'role_store'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![caller_address.into()], deployed_contract_address).unwrap()
}

fn deploy_event_emitter() -> ContractAddress {
    let contract = declare('EventEmitter');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'event_emitter'>();
    start_prank(deployed_contract_address, caller_address);
    contract.deploy_at(@array![], deployed_contract_address).unwrap()
}

fn deploy_router(role_store_address: ContractAddress) -> ContractAddress {
    let contract = declare('Router');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'router'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
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

fn deploy_withdrawal_handler(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    withdrawal_vault_address: ContractAddress,
    oracle_address: ContractAddress
) -> ContractAddress {
    let contract = declare('WithdrawalHandler');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'withdrawal_handler'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![
        data_store_address.into(),
        role_store_address.into(),
        event_emitter_address.into(),
        withdrawal_vault_address.into(),
        oracle_address.into()
    ];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_withdrawal_vault(
    data_store_address: ContractAddress, role_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('WithdrawalVault');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'withdrawal_vault'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![data_store_address.into(), role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn declare_increase_order() -> ClassHash {
    declare('IncreaseOrderUtils').class_hash
}
fn declare_decrease_order() -> ClassHash {
    declare('DecreaseOrderUtils').class_hash
}
fn declare_swap_order() -> ClassHash {
    declare('SwapOrderUtils').class_hash
}


fn declare_order_utils() -> ClassHash {
    declare('OrderUtils').class_hash
}

fn deploy_order_handler(
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    order_vault_address: ContractAddress,
    oracle_address: ContractAddress,
    swap_handler_address: ContractAddress,
    referral_storage_address: ContractAddress,
    order_utils_class_hash: ClassHash,
    increase_order_class_hash: ClassHash,
    decrease_order_class_hash: ClassHash,
    swap_order_class_hash: ClassHash
) -> ContractAddress {
    let contract = declare('OrderHandler');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'order_handler'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![
        data_store_address.into(),
        role_store_address.into(),
        event_emitter_address.into(),
        order_vault_address.into(),
        oracle_address.into(),
        swap_handler_address.into(),
        referral_storage_address.into(),
        order_utils_class_hash.into(),
        increase_order_class_hash.into(),
        decrease_order_class_hash.into(),
        swap_order_class_hash.into()
    ];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_swap_handler_address(
    role_store_address: ContractAddress, data_store_address: ContractAddress
) -> ContractAddress {
    let contract = declare('SwapHandler');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'swap_handler'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![role_store_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_referral_storage(event_emitter_address: ContractAddress) -> ContractAddress {
    let contract = declare('ReferralStorage');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'referral_storage'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![event_emitter_address.into()];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_exchange_router(
    router_address: ContractAddress,
    data_store_address: ContractAddress,
    role_store_address: ContractAddress,
    event_emitter_address: ContractAddress,
    deposit_handler_address: ContractAddress,
    withdrawal_handler_address: ContractAddress,
    order_handler_address: ContractAddress
) -> ContractAddress {
    let contract = declare('ExchangeRouter');
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let deployed_contract_address = contract_address_const::<'exchange_router'>();
    start_prank(deployed_contract_address, caller_address);
    let constructor_calldata = array![
        router_address.into(),
        data_store_address.into(),
        role_store_address.into(),
        event_emitter_address.into(),
        deposit_handler_address.into(),
        withdrawal_handler_address.into(),
        order_handler_address.into()
    ];
    contract.deploy_at(@constructor_calldata, deployed_contract_address).unwrap()
}

fn deploy_order_vault(
    data_store_address: ContractAddress, role_store_address: ContractAddress,
) -> ContractAddress {
    let contract = declare('OrderVault');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    tests_lib::deploy_mock_contract(contract, @constructor_calldata)
}

fn deploy_bank(
    data_store_address: ContractAddress, role_store_address: ContractAddress,
) -> ContractAddress {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let bank_address: ContractAddress = contract_address_const::<'bank'>();
    let contract = declare('Bank');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    start_prank(data_store_address, caller_address);
    contract.deploy_at(@constructor_calldata, bank_address).unwrap()
}

fn deploy_strict_bank(
    data_store_address: ContractAddress, role_store_address: ContractAddress,
) -> ContractAddress {
    let caller_address: ContractAddress = contract_address_const::<'caller'>();
    let strict_bank_address: ContractAddress = contract_address_const::<'strict_bank'>();
    let contract = declare('StrictBank');
    let mut constructor_calldata = array![];
    constructor_calldata.append(data_store_address.into());
    constructor_calldata.append(role_store_address.into());
    start_prank(strict_bank_address, caller_address);
    contract.deploy_at(@constructor_calldata, strict_bank_address).unwrap()
}

fn deploy_erc20_token(deposit_vault_address: ContractAddress) -> ContractAddress {
    let erc20_contract = declare('ERC20');
    let constructor_calldata3 = array![
        'satoru', 'STU', INITIAL_TOKENS_MINTED, 0, deposit_vault_address.into()
    ];
    erc20_contract.deploy(@constructor_calldata3).unwrap()
}
