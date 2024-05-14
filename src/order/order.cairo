// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use starknet::info::get_block_number;
use array::ArrayTrait;

// Local imports.
use satoru::utils::store_arrays::StoreContractAddressArray;
use satoru::chain::chain::{IChainDispatcher, IChainDispatcherTrait};
use satoru::utils::span32::{Span32, Array32Trait};

/// Struct for orders.
#[derive(Copy, Drop, starknet::Store, Serde, PartialEq)]
struct Order {
    /// The unique identifier of the order.
    key: felt252,
    /// The order type.
    order_type: OrderType,
    // Decrease position swap type.
    decrease_position_swap_type: DecreasePositionSwapType,
    /// The account of the self.
    account: ContractAddress,
    /// The receiver for any token transfers.
    receiver: ContractAddress,
    /// The contract to call for callbacks.
    callback_contract: ContractAddress,
    /// The UI fee receiver.
    ui_fee_receiver: ContractAddress,
    /// The trading market.
    market: ContractAddress,
    /// The initial collateral token for increase orders.
    initial_collateral_token: ContractAddress,
    /// An array of market addresses to swap through.
    swap_path: Span32<ContractAddress>,
    /// The requested change in position size.
    size_delta_usd: u256,
    /// For increase orders, this is the amount of the initialCollateralToken sent in by the user.
    /// For decrease orders, this is the amount of the position's collateralToken to withdraw.
    /// For swaps, this is the amount of initialCollateralToken sent in for the swap.
    initial_collateral_delta_amount: u256,
    /// The trigger price for non-market orders.
    trigger_price: u256,
    /// The acceptable execution price for increase / decrease orders.
    acceptable_price: u256,
    /// The execution fee for keepers.
    execution_fee: u256,
    /// The gas limit for the callbackContract.
    callback_gas_limit: u256,
    /// The minimum output amount for decrease orders and swaps.
    min_output_amount: u256,
    /// The block at which the order was last updated.
    updated_at_block: u64,
    /// Whether the order is for a long or short.
    is_long: bool,
    /// Whether the order is frozen.
    is_frozen: bool,
}

impl DefaultOrder of Default<Order> {
    fn default() -> Order {
        Order {
            key: 0,
            decrease_position_swap_type: DecreasePositionSwapType::NoSwap,
            order_type: OrderType::MarketSwap,
            account: contract_address_const::<0>(),
            receiver: contract_address_const::<0>(),
            callback_contract: contract_address_const::<0>(),
            ui_fee_receiver: contract_address_const::<0>(),
            market: contract_address_const::<0>(),
            initial_collateral_token: contract_address_const::<0>(),
            swap_path: Array32Trait::<ContractAddress>::span32(@ArrayTrait::new()),
            size_delta_usd: 0,
            initial_collateral_delta_amount: 0,
            trigger_price: 0,
            acceptable_price: 0,
            execution_fee: 0,
            callback_gas_limit: 0,
            min_output_amount: 0,
            updated_at_block: 0,
            is_long: true,
            is_frozen: true,
        }
    }
}

#[generate_trait]
impl OrderImpl of OrderTrait {
    fn touch(ref self: Order) {
        // TODO: Fix when it's possible to do starknet calls in pure Cairo programs.
        self.updated_at_block = get_block_number();
    }
}

#[derive(Copy, Drop, starknet::Store, Serde, PartialEq)]
enum OrderType {
    ///  MarketSwap: swap token A to token B at the current market price.
    /// The order will be cancelled if the minOutputAmount cannot be fulfilled.
    MarketSwap,
    ///  LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled.
    LimitSwap,
    ///  MarketIncrease: increase position at the current market price.
    /// The order will be cancelled if the position cannot be increased at the acceptablePrice.
    MarketIncrease,
    /// LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled.
    LimitIncrease,
    ///  MarketDecrease: decrease position at the current market price.
    /// The order will be cancelled if the position cannot be decreased at the acceptablePrice.
    MarketDecrease,
    ///  LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled.
    LimitDecrease,
    ///  StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled.
    StopLossDecrease,
    ///  Liquidation: allows liquidation of positions if the criteria for liquidation are met.
    Liquidation,
}

/// To help further differentiate orders.
#[derive(Drop, starknet::Store, Serde, PartialEq, Copy, Default)]
enum SecondaryOrderType {
    #[default]
    None,
    Adl,
}

// impl SecondaryOrderTypePrintImpl of PrintTrait<SecondaryOrderType> {
//     fn print(self: SecondaryOrderType) {
//         match self {
//             SecondaryOrderType::None => 'None'.print(),
//             SecondaryOrderType::Adl => 'Adl'.print(),
//         }
//     }
// }

/// `DecreasePositionSwapType` is used to indicate whether the decrease order should swap
/// the pnl token to collateral token or vice versa.
#[derive(Drop, Copy, starknet::Store, Serde, PartialEq)]
enum DecreasePositionSwapType {
    NoSwap,
    SwapPnlTokenToCollateralToken,
    SwapCollateralTokenToPnlToken,
}

// impl DecreasePositionSwapTypePrintImpl of PrintTrait<DecreasePositionSwapType> {
//     fn print(self: DecreasePositionSwapType) {
//         match self {
//             DecreasePositionSwapType::NoSwap => 'NoSwap'.print(),
//             DecreasePositionSwapType::SwapPnlTokenToCollateralToken => 'SwapPnlTokenToCollateralToken'
//                 .print(),
//             DecreasePositionSwapType::SwapCollateralTokenToPnlToken => 'SwapCollateralTokenToPnlToken'
//                 .print(),
//         }
//     }
// }

impl OrderTypeInto of Into<OrderType, felt252> {
    fn into(self: OrderType) -> felt252 {
        match self {
            OrderType::MarketSwap => 'MarketSwap',
            OrderType::LimitSwap => 'LimitSwap',
            OrderType::MarketIncrease => 'MarketIncrease',
            OrderType::LimitIncrease => 'LimitIncrease',
            OrderType::MarketDecrease => 'MarketDecrease',
            OrderType::LimitDecrease => 'LimitDecrease',
            OrderType::StopLossDecrease => 'StopLossDecrease',
            OrderType::Liquidation => 'Liquidation',
        }
    }
}
// impl OrderTypePrintImpl of PrintTrait<OrderType> {
//     fn print(self: OrderType) {
//         match self {
//             OrderType::MarketSwap => 'MarketSwap'.print(),
//             OrderType::LimitSwap => 'LimitSwap'.print(),
//             OrderType::MarketIncrease => 'MarketIncrease'.print(),
//             OrderType::LimitIncrease => 'LimitIncrease'.print(),
//             OrderType::MarketDecrease => 'MarketDecrease'.print(),
//             OrderType::LimitDecrease => 'LimitDecrease'.print(),
//             OrderType::StopLossDecrease => 'StopLossDecrease'.print(),
//             OrderType::Liquidation => 'Liquidation'.print(),
//         }
//     }
// }


