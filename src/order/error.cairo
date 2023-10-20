mod OrderError {
    use satoru::order::order::OrderType;
    use satoru::price::price::Price;
    use satoru::utils::i128::i128;

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
    const POSTION_NOT_VALID: felt252 = 'position_not_valid';


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

    fn INSUFFICIENT_OUTPUT_AMOUNT(output_usd: u128, min_output_amount: u128) {
        let mut data = array!['Insufficient output amount'];
        data.append(output_usd.into());
        data.append(min_output_amount.into());
        panic(data);
    }

    fn INVALID_ORDER_PRICE(primary_price: Price, trigger_price: u128, order_type: OrderType) {
        let mut data: Array<felt252> = array![];
        data.append('invalid_order_price');
        data.append(primary_price.min.into());
        data.append(primary_price.max.into());
        data.append(trigger_price.into());
        data.append(order_type.into());
        panic(data);
    }

    fn ORDER_NOT_FULFILLABLE_AT_ACCEPTABLE_PRICE(execution_price: u128, acceptable_price: u128) {
        let mut data: Array<felt252> = array![];
        data.append('order_unfulfillable_at_price');
        data.append(execution_price.into());
        data.append(acceptable_price.into());
        panic(data);
    }

    fn PRICE_IMPACT_LARGER_THAN_ORDER_SIZE(price_impact_usd: i128, size_delta_usd: u128) {
        let mut data: Array<felt252> = array![];
        data.append('price_impact_too_large');
        data.append(price_impact_usd.into());
        data.append(size_delta_usd.into());
        panic(data);
    }

    fn NEGATIVE_EXECUTION_PRICE(
        execution_price: i128,
        price: u128,
        position_size_in_usd: u128,
        adjusted_price_impact_usd: i128,
        size_delta_usd: u128
    ) {
        let mut data: Array<felt252> = array![];
        data.append('negative_execution_price');
        data.append(execution_price.into());
        data.append(price.into());
        data.append(position_size_in_usd.into());
        data.append(adjusted_price_impact_usd.into());
        data.append(size_delta_usd.into());
        panic(data);
    }
}
