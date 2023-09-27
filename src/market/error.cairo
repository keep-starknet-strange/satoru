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
    const DISABLED_MARKET: felt252 = 'disabled_market';

    fn UNABLE_TO_GET_CACHED_TOKEN_PRICE(token_in: ContractAddress) {
        let mut data = array!['invalid token in'];
        data.append(token_in.into());
        panic(data)
    }

    const MAX_POOL_AMOUNT_EXCEEDED: felt252 = 'max_pool_amount_exceeded';
    const MAX_RESERVE_EXCEEDED: felt252 = 'max_reserve_exceeded';
    const INSUFFICIENT_RESERVE: felt252 = 'insufficient_reserve';
    const UNEXCEPTED_BORROWING_FACTOR: felt252 = 'unexpected_borrowing_factor';
    const UNEXCEPTED_TOKEN: felt252 = 'unexpected_token';
}
