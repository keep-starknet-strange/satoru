// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, contract_address_const};

// Local imports.
use gojo::utils::store_contract_address_array::StoreContractAddressArray;

// Struct for orders.
#[derive(Drop, starknet::Store, Serde)]
struct Order {
    order_type: OrderType,
    /// The account of the order.
    account: ContractAddress,
    /// The receiver for any token transfers.
    /// This field is meant to allow the output of an order to be
    /// received by an address that is different from the creator of the
    /// order whether this is for swaps or whether the account is the owner of a position
    /// for funding fees and claimable collateral, the funds are still
    /// credited to the owner of the position indicated by order account.
    receiver: ContractAddress,
    /// The contract to call for callbacks.
    callback_contract: ContractAddress,
    /// The UI fee receiver.
    ui_fee_receiver: ContractAddress,
    /// The trading market.
    market: ContractAddress,
    /// The initial collateral token for increase orders.
    /// `initial_collateral_token` is token sent in by the user, the token will be swapped through the speficied swap path, before being deposited 
    /// into the position as collateral for decrease orders.
    /// `initial_collateral_token` is the collateral token of the position withdrawn collateral from the decrease of the position will be swapped
    /// through the specified swap path.
    initial_collateral_token: ContractAddress,
    /// An array of market addresses to swap through.
    swap_path: Array<ContractAddress>,
}

#[derive(Drop, starknet::Store, Serde)]
enum OrderType {
    ///  MarketSwap: swap token A to token B at the current market price
    /// the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap: (),
    ///  LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap: (),
    ///  MarketIncrease: increase position at the current market price
    /// the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease: (),
    /// LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease: (),
    ///  MarketDecrease: decrease position at the current market price
    /// the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease: (),
    ///  LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease: (),
    ///  StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease: (),
    ///  Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation: (),
}
