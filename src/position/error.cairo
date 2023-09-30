mod PositionError {
    const EMPTY_POSITION: felt252 = 'empty_position';
    const INVALID_POSITION_SIZE_VALUES: felt252 = 'invalid_position_size_values';
    const POSITION_NOT_FOUND: felt252 = 'position_not_found';
    const POSITION_INDEX_NOT_FOUND: felt252 = 'position_index_not_found';
    const CANT_BE_ZERO: felt252 = 'position account cant be 0';
    const INVALID_OUTPUT_TOKEN: felt252 = 'invalid output token';
    const MIN_POSITION_SIZE: felt252 = 'minumum position size';
    const LIQUIDATABLE_POSITION: felt252 = 'liquidatable position';
    const UNEXPECTED_POSITION_STATE: felt252 = 'unexpected_position_state';

    fn INVALID_DECREASE_ORDER_SIZE(size_delta_usd: u128, size_in_usd: u128) {
        let mut data = array!['invalid decrease order size'];
        data.append(size_delta_usd.into());
        data.append(size_in_usd.into());
        panic(data)
    }

    fn UNABLE_TO_WITHDRAW_COLLATERAL(estimated_remaining_collateral_usd: i128) {
        let mut data = array!['unable to withdraw collateral'];
        data.append(estimated_remaining_collateral_usd.into());
        panic(data)
    }

    fn POSITION_SHOULD_BE_LIQUIDATED() {
        let data = array!['position should be liquidated'];
        panic(data)
    }
}
