// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use debug::PrintTrait;

// Local imports.
use satoru::utils::store_arrays::StoreContractAddressArray;
use satoru::chain::chain::{IChainDispatcher, IChainDispatcherTrait};

/// Struct for orders.
#[derive(Drop, starknet::Store, Serde)]
struct Order {
    order_type: OrderType,
    /// The account of the order.
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
    swap_path: Array<ContractAddress>,
    /// The requested change in position size.
    size_delta_usd: u128,
    /// For increase orders, this is the amount of the initialCollateralToken sent in by the user.
    /// For decrease orders, this is the amount of the position's collateralToken to withdraw.
    /// For swaps, this is the amount of initialCollateralToken sent in for the swap.
    initial_collateral_delta_amount: u128,
    /// The trigger price for non-market orders.
    trigger_price: u128,
    /// The acceptable execution price for increase / decrease orders.
    acceptable_price: u128,
    /// The execution fee for keepers.
    execution_fee: u128,
    /// The gas limit for the callbackContract.
    callback_gas_limit: u128,
    /// The minimum output amount for decrease orders and swaps.
    min_output_amount: u128,
    /// The block at which the order was last updated.
    updated_at_block: u64,
    /// Whether the order is for a long or short.
    is_long: bool,
    /// Whether to unwrap native tokens before transferring to the user.
    should_unwrap_native_token: bool,
    /// Whether the order is frozen.
    is_frozen: bool,
}

#[generate_trait]
impl OrderImpl of OrderTrait {
    fn touch(ref self: Order, chain: IChainDispatcher) {
        // TODO: Fix when it's possible to do starknet calls in pure Cairo programs.
        self.updated_at_block = chain.get_block_number();
    }
}

#[derive(Drop, starknet::Store, Serde)]
enum OrderType {
    ///  MarketSwap: swap token A to token B at the current market price.
    /// The order will be cancelled if the minOutputAmount cannot be fulfilled.
    MarketSwap: (),
    ///  LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled.
    LimitSwap: (),
    ///  MarketIncrease: increase position at the current market price.
    /// The order will be cancelled if the position cannot be increased at the acceptablePrice.
    MarketIncrease: (),
    /// LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled.
    LimitIncrease: (),
    ///  MarketDecrease: decrease position at the current market price.
    /// The order will be cancelled if the position cannot be decreased at the acceptablePrice.
    MarketDecrease: (),
    ///  LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled.
    LimitDecrease: (),
    ///  StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled.
    StopLossDecrease: (),
    ///  Liquidation: allows liquidation of positions if the criteria for liquidation are met.
    Liquidation: (),
}

/// To help further differentiate orders.
#[derive(Drop, starknet::Store, Serde)]
enum SecondaryOrderType {
    None: (),
    Adl: (),
}

impl SecondaryOrderTypePrintImpl of PrintTrait<SecondaryOrderType> {
    fn print(self: SecondaryOrderType) {
        match self {
            SecondaryOrderType::None => 'None'.print(),
            SecondaryOrderType::Adl => 'Adl'.print(),
        }
    }
}

/// `DecreasePositionSwapType` is used to indicate whether the decrease order should swap
/// the pnl token to collateral token or vice versa.
#[derive(Drop, starknet::Store, Serde)]
enum DecreasePositionSwapType {
    NoSwap: (),
    SwapPnlTokenToCollateralToken: (),
    SwapCollateralTokenToPnlToken: (),
}

impl DecreasePositionSwapTypePrintImpl of PrintTrait<DecreasePositionSwapType> {
    fn print(self: DecreasePositionSwapType) {
        match self {
            DecreasePositionSwapType::NoSwap => 'NoSwap'.print(),
            DecreasePositionSwapType::SwapPnlTokenToCollateralToken => 'SwapPnlTokenToCollateralToken'
                .print(),
            DecreasePositionSwapType::SwapCollateralTokenToPnlToken => 'SwapCollateralTokenToPnlToken'
                .print(),
        }
    }
}

impl OrderTypePrintImpl of PrintTrait<OrderType> {
    fn print(self: OrderType) {
        match self {
            OrderType::MarketSwap => 'MarketSwap'.print(),
            OrderType::LimitSwap => 'LimitSwap'.print(),
            OrderType::MarketIncrease => 'MarketIncrease'.print(),
            OrderType::LimitIncrease => 'LimitIncrease'.print(),
            OrderType::MarketDecrease => 'MarketDecrease'.print(),
            OrderType::LimitDecrease => 'LimitDecrease'.print(),
            OrderType::StopLossDecrease => 'StopLossDecrease'.print(),
            OrderType::Liquidation => 'Liquidation'.print(),
        }
    }
}
