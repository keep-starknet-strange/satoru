mod PositionError {
    use satoru::utils::i256::i256;

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

    fn INVALID_DECREASE_ORDER_SIZE(size_delta_usd: u256, size_in_usd: u256) {
        let mut data = array!['invalid decrease order size'];
        data.append(size_delta_usd.try_into().expect('u256 into felt failed'));
        data.append(size_in_usd.try_into().expect('u256 into felt failed'));
        panic(data)
    }

    fn UNABLE_TO_WITHDRAW_COLLATERAL(estimated_remaining_collateral_usd: i256) {
        let mut data = array!['unable to withdraw collateral'];
        data.append(estimated_remaining_collateral_usd.into());
        panic(data)
    }

    fn POSITION_SHOULD_NOT_BE_LIQUIDATED() {
        let data = array!['position not be liquidated'];
        panic(data)
    }

    fn INSUFFICIENT_FUNDS_TO_PAY_FOR_COSTS(remaining_cost_usd: u256, step: felt252) {
        let mut data = array![
            'InsufficientFundsToPayForCosts',
            remaining_cost_usd.try_into().expect('u256 into felt failed'),
            step
        ];
        panic(data);
    }

    fn INSUFFICIENT_COLLATERAL_AMOUNT(collateral_amount: u256, collateral_delta_amount: i256) {
        let mut data = array![
            'Insufficient collateral amount',
            collateral_amount.try_into().expect('u256 into felt failed'),
            collateral_delta_amount.into()
        ];
        panic(data);
    }

    fn INSUFFICIENT_COLLATERAL_USD(remaining_collateral_usd: i256) {
        let mut data = array!['Insufficient collateral usd', remaining_collateral_usd.into()];
        panic(data);
    }

    fn PRICE_IMPACT_LARGER_THAN_ORDER_SIZE(price_impact_usd: i256, size_delta_usd: u256) {
        let mut data = array![
            'Price impact larger order size',
            size_delta_usd.try_into().expect('u256 into felt failed')
        ];
        panic(data);
    }
}
