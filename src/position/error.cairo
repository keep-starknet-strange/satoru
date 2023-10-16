mod PositionError {
    use satoru::utils::i128::i128;

    const EMPTY_POSITION: felt252 = 'empty_position';
    const INVALID_POSITION_SIZE_VALUES: felt252 = 'invalid_position_size_values';
    const POSITION_NOT_FOUND: felt252 = 'position_not_found';
    const POSITION_INDEX_NOT_FOUND: felt252 = 'position_index_not_found';
    const UNEXPECTED_POSITION_STATE: felt252 = 'unexpected_position_state';
    const CANT_BE_ZERO: felt252 = 'position_account_cant_be_0';
    const INVALID_OUTPUT_TOKEN: felt252 = 'invalid_output_token';
    const MIN_POSITION_SIZE: felt252 = 'minimum_position_size';
    const LIQUIDATABLE_POSITION: felt252 = 'liquidatable_position';
    const EMPTY_HOLDING_ADDRESS: felt252 = 'empty_holding_address';

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

    fn INSUFFICIENT_FUNDS_TO_PAY_FOR_COSTS(remaining_cost_usd: u128, step: felt252) {
        let mut data = array!['InsufficientFundsToPayForCosts', remaining_cost_usd.into(), step];
        panic(data);
    }
}
