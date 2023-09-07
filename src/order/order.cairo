// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, contract_address_const};
use starknet::info::get_block_number;
use debug::PrintTrait;

// Local imports.
use satoru::utils::store_arrays::StoreContractAddressArray;
use satoru::chain::chain::{IChainDispatcher, IChainDispatcherTrait};

/// Struct for orders.
#[derive(Drop, Clone, starknet::Store, Serde)]
struct Order {
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
    /// The order account.
    /// # Arguments
    /// * `order` - Order props.
    /// # Returns
    /// * The order account.
    fn account(self: Order) -> ContractAddress {
        self.account
    }

    /// Sets the order account.
    /// # Arguments
    /// * `account` - The order account.
    fn set_account(ref self: Order, value: ContractAddress) {
        self.account = value;
    }

    /// The order receiver.
    /// # Returns
    /// * The order receiver.
    fn receiver(self: Order) -> ContractAddress {
        self.receiver
    }

    /// Sets the order receiver.
    /// # Arguments
    /// * `receiver` - The order receiver.
    fn set_receiver(ref self: Order, value: ContractAddress) {
        self.receiver = value;
    }

    /// The order callback contract.
    /// # Returns
    /// * The callback contract.
    fn callback_contract(self: Order) -> ContractAddress {
        self.callback_contract
    }

    /// Sets the order callback contract.
    /// # Arguments
    /// * `callback_contract` - The order callback contract.
    fn set_callback_contract(ref self: Order, value: ContractAddress) {
        self.callback_contract = value;
    }

    /// The order UI fee receiver.
    /// # Returns
    /// * The order UI fee receiver.
    fn ui_fee_receiver(self: Order) -> ContractAddress {
        self.ui_fee_receiver
    }

    /// Sets the order UI fee receiver.
    /// # Arguments
    /// * `ui_fee_receiver` - The order UI fee receiver.
    fn set_ui_fee_receiver(ref self: Order, value: ContractAddress) {
        self.ui_fee_receiver = value;
    }

    /// The order market.
    /// # Returns
    /// * The order market.
    fn market(self: Order) -> ContractAddress {
        self.market
    }

    /// Sets the order market.
    /// # Arguments
    /// * `market` - The order market.
    fn set_market(ref self: Order, value: ContractAddress) {
        self.market = value;
    }

    /// The order initial collateral token.
    /// # Returns
    /// * The order initial collateral token.
    fn initial_collateral_token(self: Order) -> ContractAddress {
        self.initial_collateral_token
    }

    /// Sets the order initial collateral token.
    /// # Arguments
    /// * `initial_collateral_token` - The order initial collateral token.
    fn set_initial_collateral_token(ref self: Order, value: ContractAddress) {
        self.initial_collateral_token = value;
    }

    /// The order swap path.
    /// # Returns
    /// * The order swap path.
    fn swap_path(self: Order) -> Array<ContractAddress> {
        self.swap_path
    }

    /// Sets the order swap path.
    /// # Arguments
    /// * `swap_path` - The order swap path.
    fn set_swap_path(ref self: Order, value: Array<ContractAddress>) {
        self.swap_path = value;
    }

    /// The order type.
    /// # Returns
    /// * The order type.
    fn order_type(self: Order) -> OrderType {
        self.order_type
    }

    /// Sets the order type.
    /// # Arguments
    /// * `order_type` - The order type.
    fn set_order_type(ref self: Order, value: OrderType) {
        self.order_type = value;
    }

    /// The order decrease position swap type.
    /// # Returns
    /// * The order decrease position swap type.
    fn decrease_position_swap_type(self: Order) -> DecreasePositionSwapType {
        self.decrease_position_swap_type
    }

    /// Sets the order decrease position swap type.
    /// # Arguments
    /// * `decrease_position_swap_type` - The order decrease position swap type.
    fn set_decrease_position_swap_type(ref self: Order, value: DecreasePositionSwapType) {
        self.decrease_position_swap_type = value;
    }

    /// The order size delta USD.
    /// # Returns
    /// * The order size delta USD.
    fn size_delta_usd(self: Order) -> u128 {
        self.size_delta_usd
    }

    /// Sets the order size delta USD.
    /// # Arguments
    /// * `size_delta_usd` - The order size delta USD.
    fn set_size_delta_usd(ref self: Order, value: u128) {
        self.size_delta_usd = value;
    }

    /// The order initial collateral delta amount.
    /// # Returns
    /// * The order initial collateral delta amount.
    fn initial_collateral_delta_amount(self: Order) -> u128 {
        self.initial_collateral_delta_amount
    }

    /// Sets the order initial collateral delta amount.
    /// # Arguments
    /// * `initial_collateral_delta_amount` - The order initial collateral delta amount.
    fn set_initial_collateral_delta_amount(ref self: Order, value: u128) {
        self.initial_collateral_delta_amount = value;
    }

    /// The order trigger price.
    /// # Returns
    /// * The order trigger price.
    fn trigger_price(self: Order) -> u128 {
        self.trigger_price
    }

    /// Sets the order trigger price.
    /// # Arguments
    /// * `trigger_price` - The order trigger price.
    fn set_trigger_price(ref self: Order, value: u128) {
        self.trigger_price = value;
    }

    /// The order acceptable price.
    /// # Arguments   
    /// # Returns
    /// * The order acceptable price.
    fn acceptable_price(self: Order) -> u128 {
        self.acceptable_price
    }

    /// Sets the order acceptable price.
    /// # Arguments
    /// * `acceptable_price` - The order acceptable price.
    fn set_acceptable_price(ref self: Order, value: u128) {
        self.acceptable_price = value;
    }

    /// The order execution fee.
    /// # Returns
    /// * The order execution fee.
    fn execution_fee(self: Order) -> u128 {
        self.execution_fee
    }

    /// Sets the order execution fee.
    /// # Arguments
    /// * `execution_fee` - The order execution fee.
    fn set_execution_fee(ref self: Order, value: u128) {
        self.execution_fee = value;
    }

    /// The order callback gas limit.
    /// # Returns
    /// * The order callback gas limit.
    fn callback_gas_limit(self: Order) -> u128 {
        self.callback_gas_limit
    }

    /// Sets the order callback gas limit.
    /// # Arguments
    /// * `callback_gas_limit` - The order callback gas limit.
    fn set_callback_gas_limit(ref self: Order, value: u128) {
        self.callback_gas_limit = value;
    }

    /// The order min output amount.
    /// # Returns
    /// * The order min output amount.
    fn min_output_amount(self: Order) -> u128 {
        self.min_output_amount
    }

    /// Sets the order min output amount.
    /// # Arguments
    /// * `min_output_amount` - The order min output amount.
    fn set_min_output_amount(ref self: Order, value: u128) {
        self.min_output_amount = value;
    }

    /// The order updated at block.
    /// # Returns
    /// * The order updated at block.
    fn updated_at_block(self: Order) -> u64 {
        self.updated_at_block
    }

    /// Sets the order updated at block.
    /// # Arguments
    /// * `updated_at_block` - The order updated at block.
    fn set_updated_at_block(ref self: Order, value: u64) {
        self.updated_at_block = value;
    }

    /// Whether the order is for a long or short.
    /// # Returns
    /// * Whether the order is for a long or short.
    fn is_long(self: Order) -> bool {
        self.is_long
    }

    /// Sets whether the order is for a long or short.
    /// # Arguments
    /// * `is_long` - Whether the order is for a long or short.
    fn set_is_long(ref self: Order, value: bool) {
        self.is_long = value;
    }

    /// Whether to unwrap the native token before transfers to the user.
    /// # Returns
    /// * Whether to unwrap the native token before transfers to the user.
    fn should_unwrap_native_token(self: Order) -> bool {
        self.should_unwrap_native_token
    }

    /// Sets whether to unwrap the native token before transfers to the user.
    /// # Arguments
    /// * `should_unwrap_native_token` - Whether to unwrap the native token before transfers to the user.
    fn set_should_unwrap_native_token(ref self: Order, value: bool) {
        self.should_unwrap_native_token = value;
    }

    /// Whether the order is frozen.
    /// # Returns
    /// * Whether the order is frozen.
    fn is_frozen(self: Order) -> bool {
        self.is_frozen
    }

    /// Sets whether the order is frozen.
    /// # Arguments
    /// * `is_frozen` - Whether the order is frozen.
    fn set_is_frozen(ref self: Order, value: bool) {
        self.is_frozen = value;
    }

    fn touch(ref self: Order, chain: IChainDispatcher) {
        // TODO: Fix when it's possible to do starknet calls in pure Cairo programs.
        self.updated_at_block = chain.get_block_number();
    }
}

#[derive(Drop, Copy, starknet::Store, Serde, PartialEq)]
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
#[derive(Drop, Copy, starknet::Store, Serde)]
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