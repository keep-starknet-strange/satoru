mod MarketError {
    const DIVISOR_CANNOT_BE_ZERO: felt252 = 'zero_divisor';
    const INVALID_MARKET_PARAMS: felt252 = 'invalid_market_params';
    const OPEN_INTEREST_CANNOT_BE_UPDATED_FOR_SWAP_ONLY_MARKET: felt252 =
        'oi_not_updated_swap_only_market';
    const MAX_OPEN_INTEREST_EXCEEDED: felt252 = 'max_open_interest_exceeded';

    const EMPTY_ADDRESS_IN_MARKET_TOKEN_BALANCE_VALIDATION: felt252 =
        'empty_addr_market_balance_val';
    const EMPTY_ADDRESS_TOKEN_BALANCE_VAL: felt252 = 'empty_addr_token_balance_val';
    const INVALID_MARKET_TOKEN_BALANCE: felt252 = 'invalid_market_token_balance';
    const INVALID_MARKET_TOKEN_BALANCE_FOR_COLLATERAL_AMOUNT: felt252 =
        'invalid_mkt_tok_bal_collat_amnt';
    const INVALID_MARKET_TOKEN_BALANCE_FOR_CLAIMABLE_FUNDING: felt252 =
        'invalid_mkt_tok_bal_collat_amnt';
    const EmptyAddressInMarketTokenBalanceValidation: felt252 = 'EmptyAddressMarketBalanceVal';
}
