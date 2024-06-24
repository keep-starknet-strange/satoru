mod DepositError {
    const DEPOSIT_NOT_FOUND: felt252 = 'deposit_not_found';
    const DEPOSIT_INDEX_NOT_FOUND: felt252 = 'deposit_index_not_found';
    const CANT_BE_ZERO: felt252 = 'deposit account cant be 0';
    const EMPTY_DEPOSIT_AMOUNTS: felt252 = 'empty_deposit_amounts';
    const EMPTY_DEPOSIT: felt252 = 'empty_deposit';
    const EMPTY_DEPOSIT_AMOUNTS_AFTER_SWAP: felt252 = 'empty deposit amount after swap';


    fn MIN_MARKET_TOKENS(received: u256, expected: u256) {
        let mut data = array!['invalid swap output token'];
        data.append(received.try_into().expect('u256 into felt failed'));
        data.append(expected.try_into().expect('u256 into felt failed'));
        panic(data)
    }

    fn INVALID_POOL_VALUE_FOR_DEPOSIT(pool_value: u256) {
        let mut data = array!['invalid pool value for deposit'];
        data.append(pool_value.try_into().expect('u256 into felt failed'));
        panic(data)
    }
}
