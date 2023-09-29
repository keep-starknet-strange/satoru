mod MarketError {
    use starknet::ContractAddress;


    const MARKET_NOT_FOUND: felt252 = 'market_not_found';
    const DIVISOR_CANNOT_BE_ZERO: felt252 = 'zero_divisor';
    const INVALID_MARKET_PARAMS: felt252 = 'invalid_market_params';
    const OPEN_INTEREST_CANNOT_BE_UPDATED_FOR_SWAP_ONLY_MARKET: felt252 =
        'oi_not_updated_swap_only_market';
    const MAX_OPEN_INTEREST_EXCEEDED: felt252 = 'max_open_interest_exceeded';
    const INVALID_POSITION_MARKET: felt252 = 'invalid_position_market';
    const INVALID_COLLATERAL_TOKEN_FOR_MARKET: felt252 = 'invalid_coll_token_for_market';

    const EMPTY_MARKET: felt252 = 'empty_market';
    const DISABLED_MARKET: felt252 = 'minumum position size';

    const EMPTY_MARKET_TOKEN_SUPPLY: felt252 = 'empty_market_token_suppply';
    const INVALID_MARKET_COLLATERAL_TOKEN: felt252 = 'invalid_market_collateral_token';
    const UNABLE_TO_GET_FUNDING_FACTOR_EMPTY_OPEN_INTEREST: felt252 =
        'unable_to_get_funding_factor';
    const UNABLE_TO_GET_BORROWING_FACTOR_EMPTY_POOL_USD: felt252 = 'unable_to_get_borrowing_factor';
    const MAX_SWAP_PATH_LENGTH_EXCEEDED: felt252 = 'max_swap_path_length_exceeded';
    const PNL_EXCEEDED_FOR_LONGS: felt252 = 'pnl_exceeded_for_longs';
    const PNL_EXCEEDED_FOR_SHORTS: felt252 = 'pnl_exceeded_for_shorts';
    const UI_FEE_FACTOR_EXCEEDED: felt252 = 'ui_fee_factor_exceeded';
    const EMPTY_ADDRESS_IN_MARKET_TOKEN_BALANCE_VALIDATION: felt252 =
        'empty_address_in_market_token';
    const INVALID_MARKET_TOKEN_BALANCE: felt252 = 'invalid_market_token_balance';
    const INVALID_MARKET_TOKEN_BALANCE_FOR_COLLATERAL_AMOUNT: felt252 =
        'invalid_market_token_balance';
    const INVALID_MARKET_TOKEN_BALANCE_FOR_CLAIMABLE_FUNDING: felt252 =
        'invalid_market_token_balance';

    fn UNABLE_TO_GET_CACHED_TOKEN_PRICE(token_in: ContractAddress) {
        let mut data = array!['invalid token in'];
        data.append(token_in.into());
        panic(data)
    }
}
