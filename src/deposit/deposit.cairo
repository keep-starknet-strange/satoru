use starknet::ContractAddress;

/// Deposit
struct Deposit {
    /// The account depositing liquidity.
    account: ContractAddress,
    /// The address to send the liquidity tokens to.
    receiver: ContractAddress,
    /// The callback contract.
    callback_contract: ContractAddress,
    /// The ui fee receiver.
    ui_fee_receiver: ContractAddress,
    /// The market to deposit to.
    market: ContractAddress,
    /// The initial long token address.
    initial_long_token: ContractAddress,
    /// The initial short token address.
    initial_short_token: ContractAddress,
    /// The long token swap path.
    long_token_swap_path: Array<ContractAddress>,
    /// The short token swap path.
    short_token_swap_path: Array<ContractAddress>,
    /// The amount of long tokens to deposit.
    initial_long_token_amount: u256,
    /// The amount of short tokens to deposit.
    initial_short_token_amount: u256,
    /// The minimum acceptable number of liquidity tokens.
    min_market_tokens: u256,
    /// The block that the deposit was last updated at sending funds back to the user in case the deposit gets cancelled.
    updated_at_block: u256,
    /// The execution fee for keepers.
    execution_fee: u256,
    /// The gas limit for the callback contract.
    /// TODO: investigate how we want to handle callback and gas limit for Starknet contracts.
    callback_gas_limit: u256,
}

