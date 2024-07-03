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
use satoru::test_utils::{tests_lib::{setup, create_market, teardown}, deposit_setup::deposit_setup};
const INITIAL_TOKENS_MINTED: felt252 = 1000;

#[test]
fn test_short_increase_decrease_close() {
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

    // ************************************* TEST SHORT *********************************************

    'Begining of SHORT TEST'.print();

    let key_open_interest = keys::open_interest_key(
        market.market_token, contract_address_const::<'USDC'>(), false
    );
    data_store.set_u256(key_open_interest, 1);
    let max_key_open_interest = keys::max_open_interest_key(market.market_token, false);
    data_store
        .set_u256(
            max_key_open_interest, 1000000000000000000000000000000000000000000000000000
        ); // 1 000 000

    let balance_caller_ETH = IERC20Dispatcher { contract_address: market.long_token }
        .balance_of(caller_address);
    let balance_caller_USDC = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(caller_address);

    assert(balance_caller_ETH == 10000000000000000000, 'balanc ETH should be 10 ETH');
    assert(balance_caller_USDC == 50000000000000000000000, 'USDC be 50 000 USDC');

    // Send token to order_vault in multicall with create_order
    start_prank(contract_address_const::<'USDC'>(), caller_address);
    IERC20Dispatcher { contract_address: contract_address_const::<'USDC'>() }
        .transfer(order_vault.contract_address, 7000000000000000000000); // 7000 USDC

    'transfer made'.print();
    // Create order_params Struct
    let contract_address = contract_address_const::<0>();
    start_prank(market.market_token, caller_address);
    start_prank(market.short_token, caller_address);
    let order_params_short = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.short_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![]),
        size_delta_usd: 7000000000000000000000,
        initial_collateral_delta_amount: 7000000000000000000000, // 10^18
        trigger_price: 0,
        acceptable_price: 1,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketIncrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: false,
        referral_code: 0
    };
    // Create the short order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1930);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_short = exchange_router.create_order(order_params_short);
    'short created'.print();

    let balance_caller_ETH = IERC20Dispatcher { contract_address: market.long_token }
        .balance_of(caller_address);
    let balance_caller_USDC = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(caller_address);

    assert(balance_caller_ETH == 10000000000000000000, 'balanc ETH caller 10 ETH');
    assert(balance_caller_USDC == 43000000000000000000000, 'USDC be 43 000 USDC');

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
    order_handler.execute_order(key_short, set_price_params);
    'short position SUCCEEDED'.print();

    let position_key = data_store.get_account_position_keys(caller_address, 0, 10);
    let position_key_1: felt252 = *position_key.at(0);
    let first_position = data_store.get_position(position_key_1);

    assert(first_position.size_in_tokens == 2000000000000000000, 'Size token should be 2 ETH');
    assert(first_position.size_in_usd == 7000000000000000000000, 'Size should be 7000$');
    assert(first_position.borrowing_factor == 0, 'Borrow should be 0');
    assert(
        first_position.collateral_amount == 7000000000000000000000, 'Collat should be 7000 USDC'
    );
    assert(first_position.collateral_token == market.short_token, 'should be USDC');

    // Test the PnL if the price goes up
    let market_prices = market_utils::MarketPrices {
        index_token_price: Price { min: 3850, max: 3850, },
        long_token_price: Price { min: 3850, max: 3850, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );

    // The sign field is true for negative integers, and false for non-negative integers.
    assert(position_info.base_pnl_usd.sign == true, 'should be negative');
    assert(position_info.base_pnl_usd.mag == 700000000000000000000, 'PnL should be -700$');

    let balance_caller_ETH = IERC20Dispatcher { contract_address: market.long_token }
        .balance_of(caller_address);
    let balance_caller_USDC = IERC20Dispatcher { contract_address: market.short_token }
        .balance_of(caller_address);

    assert(balance_caller_ETH == 10000000000000000000, 'balanc ETH caller 10 ETH');
    assert(balance_caller_USDC == 43000000000000000000000, 'USDC caller 43000 USDC');

    // //////////////////////////////////// CLOSE POSITION //////////////////////////////////////
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
        index_token_price: Price { min: 3000, max: 3000, },
        long_token_price: Price { min: 3000, max: 3000, },
        short_token_price: Price { min: 1, max: 1, },
    };

    let position_info = reader
        .get_position_info(
            data_store, referal_storage, position_key_1, market_prices, 0, contract_address, true
        );
    assert(position_info.base_pnl_usd.mag == 1000000000000000000000, 'PnL should be 1000$');
    assert(position_info.base_pnl_usd.sign == false, 'should be positive');

    start_prank(market.market_token, caller_address);
    start_prank(market.short_token, caller_address);
    let order_params_short_dec_2 = CreateOrderParams {
        receiver: caller_address,
        callback_contract: contract_address,
        ui_fee_receiver: contract_address,
        market: market.market_token,
        initial_collateral_token: market.short_token,
        swap_path: Array32Trait::<ContractAddress>::span32(@array![market.market_token]),
        size_delta_usd: 7000000000000000000000, // 7000
        initial_collateral_delta_amount: 7000000000000000000000, // 7000 USDC 10^18
        trigger_price: 0,
        acceptable_price: 1,
        execution_fee: 0,
        callback_gas_limit: 0,
        min_output_amount: 0,
        order_type: OrderType::MarketDecrease(()),
        decrease_position_swap_type: DecreasePositionSwapType::NoSwap(()),
        is_long: false,
        referral_code: 0
    };
    // Create the long order.
    role_store.grant_role(exchange_router.contract_address, role::CONTROLLER);
    start_roll(exchange_router.contract_address, 1960);
    'try to create order'.print();
    start_prank(exchange_router.contract_address, caller_address);
    let key_short_dec_2 = exchange_router.create_order(order_params_short_dec_2);
    'short decrease created'.print();

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
        compacted_max_prices: array![3000, 1], // 500000, 10000 compacted
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
    order_handler.execute_order(key_short_dec_2, set_price_params_dec2);
    'Short pos close SUCCEEDED'.print();

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

    assert(balance_USDC_bef_close == 43000000000000000000000, 'balance USDC bef close 43000$');
    assert(balance_USDC_af_close == 43000000000000000000000, 'balance USDC af close 43000$');
    assert(balance_ETH_af_close == 12666666666666666666, 'balance ETH af close 12.66');
    assert(balance_ETH_bef_close == 10000000000000000000, 'balance ETH bef close 10');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown(data_store, market_factory);
}
