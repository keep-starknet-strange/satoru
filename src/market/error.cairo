mod MarketError {
    use starknet::ContractAddress;

    const MARKET_NOT_FOUND: felt252 = 'market_not_found';
    const DIVISOR_CANNOT_BE_ZERO: felt252 = 'zero_divisor';
    const INVALID_MARKET_PARAMS: felt252 = 'invalid_market_params';
    const OPEN_INTEREST_CANNOT_BE_UPDATED_FOR_SWAP_ONLY_MARKET: felt252 =
        'oi_not_updated_swap_only_market';
    const INVALID_SWAP_MARKET: felt252 = 'invalid_swap_market';
    const EMPTY_ADDRESS_IN_MARKET_TOKEN_BALANCE_VALIDATION: felt252 =
        'empty_addr_market_balance_val';
    const EMPTY_ADDRESS_TOKEN_BALANCE_VAL: felt252 = 'empty_addr_token_balance_val';
    const INVALID_MARKET_TOKEN_BALANCE: felt252 = 'invalid_market_token_balance';
    const EmptyAddressInMarketTokenBalanceValidation: felt252 = 'EmptyAddressMarketBalanceVal';
    const INVALID_POSITION_MARKET: felt252 = 'invalid_position_market';
    const INVALID_COLLATERAL_TOKEN_FOR_MARKET: felt252 = 'invalid_coll_token_for_market';
    const UNABLE_TO_GET_OPPOSITE_TOKEN: felt252 = 'unable_to_get_opposite_token';
    const EMPTY_MARKET: felt252 = 'empty_market';
    const COLLATERAL_ALREADY_CLAIMED: felt252 = 'collateral_already_claimed';

    fn DISABLED_MARKET(is_market_disabled: bool) {
        panic(array!['minimum_position_size', is_market_disabled.into()])
    }

    fn EMPTY_MARKET_TOKEN_SUPPLY(supply: u128) {
        panic(array!['empty_market_token_supply', supply.into()])
    }

    fn INVALID_MARKET_COLLATERAL_TOKEN(market: ContractAddress, token: ContractAddress) {
        panic(array!['invalid_market_collateral_token', market.into(), token.into()])
    }

    fn UNABLE_TO_GET_FUNDING_FACTOR_EMPTY_OPEN_INTEREST(total_open_interest: u128) {
        panic(array!['unable_to_get_funding_factor', total_open_interest.into()])
    }

    fn MAX_SWAP_PATH_LENGTH_EXCEEDED(token_swap_path_length: u32, max_swap_path_length: u128) {
        panic(
            array![
                'max_swap_path_length_exceeded',
                token_swap_path_length.into(),
                max_swap_path_length.into()
            ]
        )
    }

    fn PNL_EXCEEDED_FOR_LONGS(is_pnl_factor_exceeded_for_longs: bool) {
        panic(array!['pnl_exceeded_for_longs', is_pnl_factor_exceeded_for_longs.into()])
    }

    fn PNL_EXCEEDED_FOR_SHORTS(is_pnl_factor_exceeded_for_shorts: bool) {
        panic(array!['pnl_exceeded_for_shorts', is_pnl_factor_exceeded_for_shorts.into()])
    }

    fn UI_FEE_FACTOR_EXCEEDED(ui_fee_factor: u128, max_ui_fee_factor: u128) {
        panic(array!['ui_fee_factor_exceeded', ui_fee_factor.into(), max_ui_fee_factor.into()])
    }

    fn INVALID_MARKET_TOKEN_BALANCE_FOR_COLLATERAL_AMOUNT(balance: u128, collateral_amount: u128) {
        panic(array!['invalid_market_token_balance', balance.into(), collateral_amount.into()])
    }

    fn INVALID_MARKET_TOKEN_BALANCE_FOR_CLAIMABLE_FUNDING(
        balance: u128, claimable_funding_fee_amount: u128
    ) {
        panic(
            array![
                'invalid_market_token_balance', balance.into(), claimable_funding_fee_amount.into()
            ]
        )
    }

    fn UNABLE_TO_GET_BORROWING_FACTOR_EMPTY_POOL_USD(pool_usd: u128) {
        panic(array!['unable_to_get_borrowing_factor', pool_usd.into()])
    }

    fn MAX_OPEN_INTEREST_EXCEDEED(open_interest: u128, max_open_interest: u128) {
        panic(array!['max_open_interest_exceeded', open_interest.into(), max_open_interest.into()])
    }

    fn UNABLE_TO_GET_CACHED_TOKEN_PRICE(token_in: ContractAddress, market_token: ContractAddress) {
        panic(array!['unable_to_get_cached_token_pri', token_in.into(), market_token.into()])
    }

    fn MAX_POOL_AMOUNT_EXCEEDED(pool_amount: u128, max_pool_amount: u128) {
        panic(array!['max_pool_amount_exceeded', pool_amount.into(), max_pool_amount.into()])
    }

    fn INSUFFICIENT_RESERVE(reserve: u128, amount: u128) {
        panic(array!['insufficient_reserve', reserve.into(), amount.into()])
    }

    fn UNEXCEPTED_BORROWING_FACTOR(borrowing_factor: u128, next: u128) {
        panic(array!['unexpected_borrowing_factor', borrowing_factor.into(), next.into()])
    }

    fn UNEXCEPTED_TOKEN(token: ContractAddress) {
        panic(array!['unexpected_token', token.into()])
    }
}
