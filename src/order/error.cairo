mod OrderError {
    use satoru::order::order::OrderType;
    use satoru::price::price::Price;
    use satoru::utils::i256::i256;

    const EMPTY_ORDER: felt252 = 'empty_order';
    const INVALID_ORDER_PRICES: felt252 = 'invalid_order_prices';
    const INVALID_KEEPER_FOR_FROZEN_ORDER: felt252 = 'invalid_keeper_for_frozen_order';
    const UNSUPPORTED_ORDER_TYPE: felt252 = 'unsupported_order_type';
    const INVALID_FROZEN_ORDER_KEEPER: felt252 = 'invalid_frozen_order_keeper';
    const ORDER_NOT_FOUND: felt252 = 'order_not_found';
    const ORDER_INDEX_NOT_FOUND: felt252 = 'order_index_not_found';
    const CANT_BE_ZERO: felt252 = 'order account cant be 0';
    const EMPTY_SIZE_DELTA_IN_TOKENS: felt252 = 'empty_size_delta_in_tokens';
    const UNEXPECTED_MARKET: felt252 = 'unexpected market';
    const INVALID_SIZE_DELTA_FOR_ADL: felt252 = 'invalid_size_delta_for_adl';
    const POSITION_NOT_VALID: felt252 = 'position_not_valid';
    const ORDER_ALREADY_FROZEN: felt252 = 'order_already_frozen';


    fn ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED(
        min_oracle_block_numbers: Span<u64>, latest_updated_at_block: u64
    ) {
        let mut data: Array<felt252> = array!['Block nbs smaller than required'];
        let len: u32 = min_oracle_block_numbers.len();
        let mut i: u32 = 0;
        loop {
            if (i == len) {
                break;
            }
            let value: u64 = *min_oracle_block_numbers.at(i);
            data.append(value.into());
            i += 1;
        };
        data.append(latest_updated_at_block.into());
        panic(data)
    }

    fn INSUFFICIENT_OUTPUT_AMOUNT(output_usd: u256, min_output_amount: u256) {
        let mut data = array!['Insufficient output amount'];
        data.append(output_usd.try_into().expect('u256 into felt failed'));
        data.append(min_output_amount.try_into().expect('u256 into felt failed'));
        panic(data);
    }

    fn INVALID_ORDER_PRICE(primary_price: Price, trigger_price: u256, order_type: OrderType) {
        let mut data: Array<felt252> = array![];
        data.append('invalid_order_price');
        // data.append(primary_price.min.try_into().expect('u256 into felt failed')); // TODO Find a way to test them test_takeprofit_long_increase_fails
        // data.append(primary_price.max.try_into().expect('u256 into felt failed'));
        // data.append(trigger_price.try_into().expect('u256 into felt failed'));
        data.append(order_type.into());
        panic(data);
    }

    fn ORDER_NOT_FULFILLABLE_AT_ACCEPTABLE_PRICE(execution_price: u256, acceptable_price: u256) {
        let mut data: Array<felt252> = array![];
        data.append('order_unfulfillable_at_price');
        data.append(execution_price.try_into().expect('u256 into felt failed'));
        data.append(acceptable_price.try_into().expect('u256 into felt failed'));
        panic(data);
    }

    fn PRICE_IMPACT_LARGER_THAN_ORDER_SIZE(price_impact_usd: i256, size_delta_usd: u256) {
        let mut data: Array<felt252> = array![];
        data.append('price_impact_too_large');
        data.append(price_impact_usd.try_into().expect('u256 into felt failed'));
        data.append(size_delta_usd.try_into().expect('u256 into felt failed'));
        panic(data);
    }

    fn NEGATIVE_EXECUTION_PRICE(
        execution_price: i256,
        price: u256,
        position_size_in_usd: u256,
        adjusted_price_impact_usd: i256,
        size_delta_usd: u256
    ) {
        let mut data: Array<felt252> = array![];
        data.append('negative_execution_price');
        data.append(execution_price.into());
        data.append(price.try_into().expect('u256 into felt failed'));
        data.append(position_size_in_usd.try_into().expect('u256 into felt failed'));
        data.append(adjusted_price_impact_usd.into());
        data.append(size_delta_usd.try_into().expect('u256 into felt failed'));
        panic(data);
    }

    fn ORDER_TYPE_CANNOT_BE_CREATED(order_type: OrderType,) {
        let mut data: Array<felt252> = array![];
        data.append('order_type_cannot_be_created');
        data.append(order_type.into());
        panic(data);
    }

    fn INSUFFICIENT_WNT_AMOUNT_FOR_EXECUTION_FEE(first_amount: u256, secont_amount: u256) {
        let mut data = array!['Insufficient wnt amount for fee'];
        data.append(first_amount.try_into().expect('u256 into felt failed'));
        data.append(secont_amount.try_into().expect('u256 into felt failed'));
        panic(data);
    }
}
