mod OrderError {
    const ORDER_NOT_FOUND: felt252 = 'order_not_found';
    const ORDER_INDEX_NOT_FOUND: felt252 = 'order_index_not_found';
    const CANT_BE_ZERO: felt252 = 'order account cant be 0';
    const EMPTY_ORDER: felt252 = 'empty_order';
    const ORDER_NOT_FULFILLABLE_AT_ACCEPTABLE_PRICE: felt252 =
        'order_unfulfillable_at_price'; // TODO: unshorten value
    const NEGATIVE_EXECUTION_PRICE: felt252 = 'negative_execution_price';
    const PRICE_IMPACT_LARGER_THAN_ORDER_SIZE: felt252 =
        'price_impact_too_large'; // TODO: unshorten value
    const EMPTY_SIZE_DELTA_IN_TOKENS: felt252 = 'empty_size_delta_in_tokens';
    const UNSUPPORTED_ORDER_TYPE: felt252 = 'unsupported_order_type';
    const INVALID_ORDER_PRICES: felt252 = 'invalid_order_prices';
}
