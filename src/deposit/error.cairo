mod DepositError {
    const DEPOSIT_NOT_FOUND: felt252 = 'deposit_not_found';
    const DEPOSIT_INDEX_NOT_FOUND: felt252 = 'deposit_index_not_found';
    const CANT_BE_ZERO: felt252 = 'deposit account cant be 0';
    const EMPTY_DEPOSIT_AMOUNTS: felt252 = 'empty_deposit_amounts';
    const EMPTY_DEPOSIT: felt252 = 'empty_deposit';
    const EMPTY_DEPOSIT_AMOUNTS_AFTER_SWAP: felt252 = 'empty deposit amount after swap';
    const INVALID_POOL_VALUE_FOR_DEPOSIT: felt252 = 'invalid pool value for deposit';


    fn MIN_MARKET_TOKENS(received: u128, expected: u128) {
        let mut data = array!['invalid swap output token'];
        data.append(received.into());
        data.append(expected.into());
        panic(data)
    }
}
