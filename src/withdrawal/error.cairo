mod WithdrawalError {
    const ALREADY_INITIALIZED: felt252 = 'already_initialized';
    const NOT_FOUND: felt252 = 'withdrawal not found';
    const CANT_BE_ZERO: felt252 = 'withdrawal account cant be 0';
    const EMPTY_WITHDRAWAL_AMOUNT: felt252 = 'empty withdrawal amount';
    const EMPTY_WITHDRAWAL: felt252 = 'empty withdrawal';

    fn INSUFFICIENT_FEE_TOKEN_AMOUNT(data_1: u128, data_2: u128) {
        panic(array!['insufficient fee token amout', data_1.into(), data_2.into()])
    }

    fn INSUFFICIENT_MARKET_TOKENS(data_1: u128, data_2: u128) {
        panic(array!['insufficient market token', data_1.into(), data_2.into()])
    }

    fn INVALID_POOL_VALUE_FOR_WITHDRAWAL(data: i128) {
        panic(array!['insuff pool val for withdrawal', data.into()])
    }

    fn INVALID_WITHDRAWAL_KEY(data: felt252) {
        panic(array!['invalid withdrawal key', data])
    }
}
