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
use debug::PrintTrait;
use snforge_std::{declare, ContractClassTrait, start_roll};


// Local imports.
use satoru::chain::chain::{IChainDispatcher, IChainDispatcherTrait};
use satoru::order::order::{Order, OrderType, OrderTrait};

#[test]
fn given_normal_conditions_when_touch_then_expected_results() {
    // *********************************************************************************************
    // *                              SETUP                                                        *
    // *********************************************************************************************
    let (caller_address, chain) = setup();

    // *********************************************************************************************
    // *                              TEST LOGIC                                                   *
    // *********************************************************************************************

    // Create a dummy order.
    let mut order = create_dummy_order();

    // Set current block to 42000.
    start_roll(chain.contract_address, 42000);

    // Call the `touch` function.
    order.touch(chain);

    assert(order.updated_at_block == 42000, 'bad value');

    // *********************************************************************************************
    // *                              TEARDOWN                                                     *
    // *********************************************************************************************
    teardown();
}

fn create_dummy_order() -> Order {
    let mut swap_path = array![];
    swap_path.append(contract_address_const::<'swap_path_0'>());
    swap_path.append(contract_address_const::<'swap_path_1'>());
    Order {
        key: 111,
        order_type: OrderType::StopLossDecrease,
        account: contract_address_const::<'account'>(),
        receiver: contract_address_const::<'receiver'>(),
        callback_contract: contract_address_const::<'callback_contract'>(),
        ui_fee_receiver: contract_address_const::<'ui_fee_receiver'>(),
        market: contract_address_const::<'market'>(),
        initial_collateral_token: contract_address_const::<'initial_collateral_token'>(),
        //swap_path,
        size_delta_usd: 1000,
        initial_collateral_delta_amount: 500,
        trigger_price: 2000,
        acceptable_price: 2500,
        execution_fee: 100,
        callback_gas_limit: 300000,
        min_output_amount: 100,
        updated_at_block: 0,
        is_long: true,
        should_unwrap_native_token: false,
        is_frozen: false,
    }
}

/// Utility function to setup the test environment.
fn setup() -> ( // This caller address will be used with `start_prank` cheatcode to mock the caller address.,
    ContractAddress, // An interface to interact with `Chain` contract.
     IChainDispatcher,
) {
    // Create a fake caller address.
    let caller_address = contract_address_const::<'caller'>();
    // Deploy the `Chain` contract.

    let contract = declare('Chain');
    let constructor_arguments: @Array::<felt252> = @ArrayTrait::new();
    let contract_address_chain = contract.deploy(constructor_arguments).unwrap();

    let chain = IChainDispatcher { contract_address: contract_address_chain };
    // Return the test environment.
    (caller_address, chain)
}

/// Utility function to teardown the test environment.
fn teardown() {}
