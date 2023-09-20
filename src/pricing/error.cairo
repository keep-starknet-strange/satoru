mod PricingError {
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
}
