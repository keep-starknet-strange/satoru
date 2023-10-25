mod PricingError {
    use satoru::utils::i128::i128;

    fn USD_DELTA_EXCEEDS_LONG_OPEN_INTEREST(usd_delta: i128, long_open_interest: u128) {
        let mut data = array!['usd delta exceeds long interest'];
        data.append(usd_delta.into());
        data.append(long_open_interest.into());
        panic(data)
    }
    fn USD_DELTA_EXCEEDS_SHORT_OPEN_INTEREST(usd_delta: i128, short_open_interest: u128) {
        let mut data = array!['usd delta exceed short interest'];
        data.append(usd_delta.into());
        data.append(short_open_interest.into());
        panic(data)
    }

    fn USD_DELTA_EXCEEDS_POOL_VALUE(usd_delta: felt252, pool_usd_for_token: u128) {
        let mut data = array!['usd_delta_exceeds_pool_value'];
        // data.append(usd_delta.into());
        data.append(pool_usd_for_token.into());
        panic(data)
    }
}
