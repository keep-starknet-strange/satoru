mod PricingError {
    use satoru::utils::i256::i256;

    fn USD_DELTA_EXCEEDS_LONG_OPEN_INTEREST(usd_delta: i256, long_open_interest: u256) {
        let mut data = array!['usd delta exceeds long interest'];
        data.append(usd_delta.into());
        data.append(long_open_interest.try_into().expect('u256 into felt failed'));
        panic(data)
    }
    fn USD_DELTA_EXCEEDS_SHORT_OPEN_INTEREST(usd_delta: i256, short_open_interest: u256) {
        let mut data = array!['usd delta exceed short interest'];
        data.append(usd_delta.into());
        data.append(short_open_interest.try_into().expect('u256 into felt failed'));
        panic(data)
    }

    fn USD_DELTA_EXCEEDS_POOL_VALUE(usd_delta: felt252, pool_usd_for_token: u256) {
        let mut data = array!['usd_delta_exceeds_pool_value'];
        // TODO adding this crash on swap test
        // data.append(usd_delta.into());
        data.append(pool_usd_for_token.try_into().expect('u256 into felt failed'));
        panic(data)
    }
}
