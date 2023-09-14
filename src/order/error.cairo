mod OrderError {
    const EMPTY_ORDER: felt252 = 'empty_order';
    const INVALID_KEEPER_FOR_FROZEN_ORDER: felt252 = 'invalid_keeper_for_frozen_order';
    const UNSUPPORTED_ORDER_TYPE: felt252 = 'unsupported_order_type';
    const INVALID_ORDER_PRICES: felt252 = 'invalid_order_prices';
    const INVALID_FROZEN_ORDER_KEEPER: felt252 = 'invalid_frozen_order_keeper';
    const ORDER_NOT_FOUND: felt252 = 'order_not_found';
    const ORDER_INDEX_NOT_FOUND: felt252 = 'order_index_not_found';
    const CANT_BE_ZERO: felt252 = 'order account cant be 0';
}
