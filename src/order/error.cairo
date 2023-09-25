mod OrderError {
    const EMPTY_ORDER: felt252 = 'empty_order';
    const INVALID_KEEPER_FOR_FROZEN_ORDER: felt252 = 'invalid_keeper_for_frozen_order';
    const UNSUPPORTED_ORDER_TYPE: felt252 = 'unsupported_order_type';
    const INVALID_ORDER_PRICES: felt252 = 'invalid_order_prices';
    const INVALID_FROZEN_ORDER_KEEPER: felt252 = 'invalid_frozen_order_keeper';
    const ORDER_NOT_FOUND: felt252 = 'order_not_found';
    const ORDER_INDEX_NOT_FOUND: felt252 = 'order_index_not_found';
    const CANT_BE_ZERO: felt252 = 'order account cant be 0';
    const ORDER_NOT_FULFILLABLE_AT_ACCEPTABLE_PRICE: felt252 =
        'order_unfulfillable_at_price'; // TODO: unshorten value
    const NEGATIVE_EXECUTION_PRICE: felt252 = 'negative_execution_price';
    const PRICE_IMPACT_LARGER_THAN_ORDER_SIZE: felt252 =
        'price_impact_too_large'; // TODO: unshorten value
    const EMPTY_SIZE_DELTA_IN_TOKENS: felt252 = 'empty_size_delta_in_tokens';

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
        panic(data)
    }
}
