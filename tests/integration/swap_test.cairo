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
use satoru::tests_lib;
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
use satoru::tests_lib::{setup, create_market, teardown};
const INITIAL_TOKENS_MINTED: felt252 = 1000;

#[test]
fn test_swap_market() {
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
            5000000000000000000000000000000000000000000 //500 000 ETH
        );
    data_store
        .set_u256(
            keys::max_pool_amount_key(market.market_token, market.short_token),
            2500000000000000000000000000000000000000000000 //250 000 000 USDC
        );

    let factor_for_deposits: felt252 = keys::max_pnl_factor_for_deposits();
    data_store
        .set_u256(
            keys::max_pnl_factor_key(factor_for_deposits, market.market_token, true),
            50000000000000000000000000000000000000000000000
        );
    let factor_for_withdrawal: felt252 = keys::max_pnl_factor_for_withdrawals();
    data_store
        .set_u256(
            keys::max_pnl_factor_key(factor_for_withdrawal, market.market_token, true),
            50000000000000000000000000000000000000000000000
        );
    data_store.set_u256(keys::reserve_factor_key(market.market_token, true), 1000000000000000000);
    data_store
        .set_u256(
            keys::open_interest_reserve_factor_key(market.market_token, true), 1000000000000000000
        );

    data_store.set_bool('REENTRANCY_GUARD_STATUS', false);

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
    start_prank(market.long_token, caller_address);
    start_prank(market.short_token, caller_address);
    IERC20Dispatcher { contract_address: market.long_token }
        .approve(caller_address, 20000000000000000000);
    IERC20Dispatcher { contract_address: market.short_token }
        .approve(caller_address, 100000000000000000000000);

    IERC20Dispatcher { contract_address: market.long_token }
        .mint(caller_address, 20000000000000000000); // 20 ETH
    IERC20Dispatcher { contract_address: market.short_token }
        .mint(caller_address, 100000000000000000000000); // 100 000 USDC

    // role_store.grant_role(exchange_router.contract_address, role::ROUTER_PLUGIN);
    // role_store.grant_role(caller_address, role::ROUTER_PLUGIN);

    exchange_router
        .send_tokens(market.long_token, deposit_vault.contract_address, 20000000000000000000);
    exchange_router
        .send_tokens(market.short_token, deposit_vault.contract_address, 100000000000000000000000);

    stop_prank(market.long_token);
    stop_prank(market.short_token);

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
    'create deposit'.print();

    start_roll(deposit_handler.contract_address, 1910);
    let key = deposit_handler.create_deposit(caller_address, params);
    let first_deposit = data_store.get_deposit(key);

    'created deposit'.print();

    assert(first_deposit.account == caller_address, 'Wrong account depositer');
    assert(first_deposit.receiver == caller_address, 'Wrong account receiver');
    assert(first_deposit.initial_long_token == market.long_token, 'Wrong initial long token');
    assert(
        first_deposit.initial_long_token_amount == 20000000000000000000,
        'Wrong initial long token amount'
    );
    assert(
        first_deposit.initial_short_token_amount == 100000000000000000000000,
        'Wrong init short token amount'
    );

    let price_params = SetPricesParams {
        signer_info: 0,
        tokens: array![contract_address_const::<'ETH'>(), contract_address_const::<'USDC'>()],
        compacted_min_oracle_block_numbers: array![1910, 1910],
        compacted_max_oracle_block_numbers: array![1920, 1920],
        compacted_oracle_timestamps: array![9999, 9999],
        compacted_decimals: array![1, 1],
        compacted_min_prices: array![2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: array![0],
        compacted_max_prices: array![5000, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: array![0],
        signatures: array![
            array!['signatures1', 'signatures2'].span(), array!['signatures1', 'signatures2'].span()
        ],
        price_feed_tokens: array![]
    };

    start_prank(role_store.contract_address, caller_address);

    role_store.grant_role(caller_address, role::ORDER_KEEPER);
    role_store.grant_role(caller_address, role::ROLE_ADMIN);
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    role_store.grant_role(caller_address, role::MARKET_KEEPER);

    'execute deposit'.print();

    // Execute Deposit
    start_roll(deposit_handler.contract_address, 1915);
    deposit_handler.execute_deposit(key, price_params);

    'executed deposit'.print();

    let not_deposit = data_store.get_deposit(key);
    let default_deposit: Deposit = Default::default();
    assert(not_deposit == default_deposit, 'Still existing deposit');

    let market_token_dispatcher = IMarketTokenDispatcher { contract_address: market.market_token };
    let balance_market_token = market_token_dispatcher.balance_of(caller_address);

    assert(balance_market_token != 0, 'should receive market token');

    let pool_value_info = market_utils::get_pool_value_info(
        data_store,
        market,
        Price { min: 5000, max: 5000, },
        Price { min: 5000, max: 5000, },
        Price { min: 1, max: 1, },
        keys::max_pnl_factor_for_deposits(),
        true,
    );

    // 200 000 USD
    assert(pool_value_info.pool_value.mag == 200000000000000000000000, 'wrong pool_value balance');
    // 20 ETH
    assert(pool_value_info.long_token_amount == 20000000000000000000, 'wrong long_token balance');
    // 100 000 USDC
    assert(
        pool_value_info.short_token_amount == 100000000000000000000000, 'wrong short_token balance'
    );

    // // --------------------------------------------------SWAP TEST ETH->USDC --------------------------------------------------
    'Swap ETH to USDC'.print();
    let balance_ETH_before_swap = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    let balance_USDC_before_swap = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    // 10 ETH
    assert(balance_ETH_before_swap == 10000000000000000000, 'wrong balance ETH before swap');
    // 50 000 USDC
    assert(balance_USDC_before_swap == 50000000000000000000000, 'wrong balance USDC before swap');

    start_prank(contract_address_const::<'ETH'>(), caller_address); //change to switch swap
    // Send token to order_vault in multicall with create_order
    IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() } //change to switch swap
        .transfer(order_vault.contract_address, 1000000000000000000);

    let balance_ETH_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'ETH'>()
    }
        .balance_of(caller_address);

    let balance_USDC_before = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    // Balance caller address after sending 1 ETH to the vault
    // 9 ETH
    assert(balance_ETH_before == 9000000000000000000, 'wrng ETH blce after vault');
    // 50 000 USDC
    assert(balance_USDC_before == 50000000000000000000000, 'wrng USDC blce after vlt 1');

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
        acceptable_price: 4999,
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

    // Create the order but we do not execute it yet
    let key = order_handler.create_order(caller_address, order_params);

    let got_order = data_store.get_order(key);

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
        compacted_max_prices: array![5000, 1], // 500000, 10000 compacted
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

    // 9 ETH
    assert(balance_ETH_before_execute == 9000000000000000000, 'wrng ETH blce after vault');
    // 50 000 USDC
    assert(balance_USDC_before_execute == 50000000000000000000000, 'wrng USDC blce after vlt 2');

    let keeper_address = contract_address_const::<'keeper'>();
    role_store.grant_role(keeper_address, role::ORDER_KEEPER);

    stop_prank(order_handler.contract_address);
    start_prank(order_handler.contract_address, keeper_address);
    start_roll(order_handler.contract_address, 1925);
    order_handler.execute_order(key, set_price_params);

    let balance_ETH_after = IERC20Dispatcher { contract_address: contract_address_const::<'ETH'>() }
        .balance_of(caller_address);

    let balance_USDC_after = IERC20Dispatcher {
        contract_address: contract_address_const::<'USDC'>()
    }
        .balance_of(caller_address);

    // 9 ETH
    assert(balance_ETH_after == 9000000000000000000, 'wrng ETH blce after vault');
    // 55 000 USDC
    assert(balance_USDC_after == 55000000000000000000000, 'wrng USDC blce after vault');

    let first_swap_pool_value_info = market_utils::get_pool_value_info(
        data_store,
        market,
        Price { min: 5000, max: 5000, },
        Price { min: 5000, max: 5000, },
        Price { min: 1, max: 1, },
        keys::max_pnl_factor_for_deposits(),
        true,
    );

    // 200 000 USD
    assert(
        first_swap_pool_value_info.pool_value.mag == 200000000000000000000000,
        'wrong pool_value balance'
    );
    // 21 ETH
    assert(
        first_swap_pool_value_info.long_token_amount == 21000000000000000000,
        'wrong long_token balance'
    );
    // 95 000 USDC
    assert(
        first_swap_pool_value_info.short_token_amount == 95000000000000000000000,
        'wrong short_token balance'
    );

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}
