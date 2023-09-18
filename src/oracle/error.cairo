mod OracleError {
    use starknet::ContractAddress;

    const ALREADY_INITIALIZED: felt252 = 'already_initialized';

    fn NON_EMPTY_TOKENS_WITH_PRICES(data: u32) {
        panic(array!['non empty tokens prices', data.into()])
    }

    fn DUPLICATED_TOKEN_PRICE() {
        panic(array!['duplicated token price'])
    }

    fn EMPTY_PRIMARY_PRICE() {
        panic(array!['empty primary price'])
    }

    fn EMPTY_PRICE_FEED_MULTIPLIER() {
        panic(array!['empty price feed multiplier'])
    }

    fn INVALID_MIN_MAX_BLOCK_NUMBER(data_1: u64, data_2: u64) {
        panic(array!['invalid min max block number', data_1.into(), data_2.into()])
    }

    fn INVALID_BLOCK_NUMBER(data_1: u64, data_2: u64) {
        panic(array!['invalid block number', data_1.into(), data_2.into()])
    }

    fn MAX_PRICE_EXCEEDED(data_1: u64, data_2: u64) {
        panic(array!['max price exceeded', data_1.into(), data_2.into()])
    }

    fn BLOCK_NUMBER_NOT_SORTED(data_1: u64, data_2: u64) {
        panic(array!['block number not sorted', data_1.into(), data_2.into()])
    }

    fn ARRAY_OUT_OF_BOUNDS_FELT252(mut data_1: Span<felt252>, data_2: u128, msg: felt252) {
        let mut data: Array<felt252> = array!['array out of bounds felt252'];
        let mut length = data_1.len();
        loop {
            if length == 0 {
                break;
            }
            data.append(*data_1.pop_front().unwrap());
        };
        data.append(data_2.into());
        data.append(msg);
        panic(data)
    }

    fn ARRAY_OUT_OF_BOUNDS_U128(mut data_1: Span<u128>, data_2: u128, msg: felt252) {
        let mut data: Array<felt252> = array!['array out of bounds u128'];
        let mut length = data_1.len();
        loop {
            if length == 0 {
                break;
            }
            data.append((*data_1.pop_front().unwrap()).into());
        };
        data.append(data_2.into());
        data.append(msg);
        panic(data)
    }

    fn INVALID_SIGNER_MIN_MAX_PRICE(data_1: u128, data_2: u128) {
        panic(array!['invalid med min-max price', data_1.into(), data_2.into()])
    }

    fn INVALID_MEDIAN_MIN_MAX_PRICE(data_1: u128, data_2: u128) {
        panic(array!['invalid med min-max price', data_1.into(), data_2.into()])
    }

    fn INVALID_ORACLE_PRICE(data_1: ContractAddress) {
        panic(array!['invalid oracle price', data_1.into()])
    }

    fn MIN_ORACLE_SIGNERS(data_1: u128, data_2: u128) {
        let mut data: Array<felt252> = array!['min oracle signers'];
        data.append(data_1.into());
        data.append(data_2.into());
        panic(array!['min oracle signers', data_1.into(), data_2.into()])
    }

    fn MAX_ORACLE_SIGNERS(data_1: u128, data_2: u128) {
        panic(array!['max oracle signers', data_1.into(), data_2.into()])
    }

    fn MAX_SIGNERS_INDEX(data_1: u128, data_2: u128) {
        panic(array!['max signers index', data_1.into(), data_2.into()])
    }

    fn EMPTY_SIGNER(data_1: u128) {
        panic(array!['empty signers', data_1.into()])
    }

    fn MAX_REFPRICE_DEVIATION_EXCEEDED(
        data_1: ContractAddress, data_2: u128, data_3: u128, data_4: u128
    ) {
        panic(
            array![
                'max refprice deviation', data_1.into(), data_2.into(), data_3.into(), data_4.into()
            ]
        )
    }

    fn INVALID_PRICE_FEED(data_1: ContractAddress, data_2: u128) {
        panic(array!['invalid price feed', data_1.into(), data_2.into()])
    }

    fn INVALID_PRIMARY_PRICES_FOR_SIMULATION(data_1: u32, data_2: u32) {
        panic(array!['Simulation:invalid prim_prices', data_1.into(), data_2.into()])
    }

    fn PRICE_FEED_NOT_UPDATED(data_1: ContractAddress, data_2: u64, data_3: u128) {
        panic(array!['price feed not updated', data_1.into(), data_2.into(), data_3.into()])
    }

    fn PRICE_ALREADY_SET(data_1: ContractAddress, data_2: u128, data_3: u128) {
        panic(array!['price already set', data_1.into(), data_2.into(), data_3.into()])
    }

    fn EMPTY_PRICE_FEED(data_1: ContractAddress) {
        panic(array!['empty price feed', data_1.into()])
    }

    fn END_OF_ORACLE_SIMULATION() {
        panic(array!['end of oracle simulation'])
    }
}

