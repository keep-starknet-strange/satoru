mod OracleError {
    use starknet::ContractAddress;
    use serde::Serde;

    const ALREADY_INITIALIZED: felt252 = 'already_initialized';
    const EMPTY_ORACLE_BLOCK_NUMBERS: felt252 = 'empty_oracle_block_numbers';

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

    fn ARRAY_OUT_OF_BOUNDS_FELT252(mut data_1: Span<Span<felt252>>, data_2: usize, msg: felt252) {
        let mut data: Array<felt252> = array!['array out of bounds felt252'];
        let mut length = data_1.len();
        // TODO add data_1 data to error
        data.append(data_2.into());
        data.append(msg);
        panic(data)
    }

    fn ARRAY_OUT_OF_BOUNDS_U256(mut data_1: Span<u256>, data_2: u256, msg: felt252) {
        let mut data: Array<felt252> = array!['array out of bounds u256'];
        let mut length = data_1.len();
        loop {
            if length == 0 {
                break;
            }
            data
                .append(
                    (*data_1.pop_front().expect('array pop_front failed'))
                        .try_into()
                        .expect('u256 into felt failed')
                );
        };
        data.append(data_2.try_into().expect('u256 into felt failed'));
        data.append(msg);
        panic(data)
    }

    fn INVALID_SIGNER_MIN_MAX_PRICE(data_1: u256, data_2: u256) {
        panic(
            array![
                'invalid med min-max price',
                data_1.try_into().expect('u256 into felt failed'),
                data_2.try_into().expect('u256 into felt failed')
            ]
        )
    }

    fn INVALID_MEDIAN_MIN_MAX_PRICE(data_1: u256, data_2: u256) {
        panic(
            array![
                'invalid med min-max price',
                data_1.try_into().expect('u256 into felt failed'),
                data_2.try_into().expect('u256 into felt failed')
            ]
        )
    }

    fn INVALID_ORACLE_PRICE(data_1: ContractAddress) {
        panic(array!['invalid oracle price', data_1.into()])
    }

    fn MIN_ORACLE_SIGNERS(data_1: u256, data_2: u256) {
        let mut data: Array<felt252> = array!['min oracle signers'];
        data.append(data_1.try_into().expect('u256 into felt failed'));
        data.append(data_2.try_into().expect('u256 into felt failed'));
        panic(data)
    }

    fn MAX_ORACLE_SIGNERS(data_1: u256, data_2: u256) {
        panic(
            array![
                'max oracle signers',
                data_1.try_into().expect('u256 into felt failed'),
                data_2.try_into().expect('u256 into felt failed')
            ]
        )
    }

    fn MAX_SIGNERS_INDEX(data_1: u256, data_2: u256) {
        panic(
            array![
                'max signers index',
                data_1.try_into().expect('u256 into felt failed'),
                data_2.try_into().expect('u256 into felt failed')
            ]
        )
    }

    fn EMPTY_SIGNER(data_1: u256) {
        panic(array!['empty signers', data_1.try_into().expect('u256 into felt failed')])
    }

    fn MAX_REFPRICE_DEVIATION_EXCEEDED(
        data_1: ContractAddress, data_2: u256, data_3: u256, data_4: u256
    ) {
        panic(
            array![
                'max refprice deviation',
                data_1.into(),
                data_2.try_into().expect('u256 into felt failed'),
                data_3.try_into().expect('u256 into felt failed'),
                data_4.try_into().expect('u256 into felt failed')
            ]
        )
    }

    fn INVALID_PRICE_FEED(data_1: ContractAddress, data_2: u256) {
        panic(
            array![
                'invalid price feed',
                data_1.into(),
                data_2.try_into().expect('u256 into felt failed')
            ]
        )
    }

    fn INVALID_PRIMARY_PRICES_FOR_SIMULATION(data_1: u32, data_2: u32) {
        panic(array!['Simulation:invalid prim_prices', data_1.into(), data_2.into()])
    }

    fn PRICE_FEED_NOT_UPDATED(data_1: ContractAddress, data_2: u64, data_3: u256) {
        panic(
            array![
                'price feed not updated',
                data_1.into(),
                data_2.into(),
                data_3.try_into().expect('u256 into felt failed')
            ]
        )
    }

    fn PRICE_ALREADY_SET(data_1: ContractAddress, data_2: u256, data_3: u256) {
        panic(
            array![
                'price already set',
                data_1.into(),
                data_2.try_into().expect('u256 into felt failed'),
                data_3.try_into().expect('u256 into felt failed')
            ]
        )
    }

    fn EMPTY_PRICE_FEED(data_1: ContractAddress) {
        panic(array!['empty price feed', data_1.into()])
    }

    fn END_OF_ORACLE_SIMULATION() {
        panic(array!['end of oracle simulation'])
    }

    fn ORACLE_BLOCK_NUMBERS_NOT_WITHIN_RANGE(
        min_oracle_block_numbers: Span<u64>, max_oracle_block_numbers: Span<u64>, block_number: u64
    ) {
        let mut data: Array<felt252> = array![];
        data.append('block number not in range');
        Serde::serialize(min_oracle_block_numbers.snapshot, ref data);
        Serde::serialize(max_oracle_block_numbers.snapshot, ref data);
        data.append(block_number.into());
        panic(data)
    }

    fn ORACLE_BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED(
        min_oracle_block_numbers: Span<u64>, block_number: u64
    ) {
        let mut data: Array<felt252> = array![];
        data.append('block numbers too small');
        Serde::serialize(min_oracle_block_numbers.snapshot, ref data);
        data.append(block_number.into());
        panic(data)
    }

    fn BLOCK_NUMBER_NOT_WITHIN_RANGE(mut data_1: Span<u64>, mut data_2: Span<u64>, data_3: u64) {
        let mut data: Array<felt252> = array!['block number not within range'];
        let mut length = data_1.len();
        loop {
            if length == 0 {
                break;
            }
            let el = *data_1.pop_front().unwrap();
            data.append(el.into());
        };
        let mut length_2 = data_2.len();
        loop {
            if length_2 == 0 {
                break;
            }
            let el = *data_2.pop_front().unwrap();
            data.append(el.into());
        };
        data.append(data_3.into());
        panic(data)
    }

    fn EMPTY_COMPACTED_PRICE(data_1: usize) {
        panic(array!['empty compacted price', data_1.into()])
    }

    fn EMPTY_COMPACTED_TIMESTAMP(data_1: usize) {
        panic(array!['empty compacted timestamp', data_1.into()])
    }

    fn INVALID_SIGNATURE(data_1: felt252, data_2: felt252) {
        panic(array!['invalid signature', data_1.into(), data_2.into()])
    }

    fn BLOCK_NUMBERS_ARE_SMALLER_THAN_REQUIRED(mut data_1: Span<u64>, data_2: u64) {
        let mut data: Array<felt252> = array!['block numbers too small'];
        let mut length = data_1.len();
        loop {
            if length == 0 {
                break;
            }
            let el = *data_1.pop_front().unwrap();
            data.append(el.into());
        };
        data.append(data_2.into());
    }

    fn MIN_PRICES_NOT_SORTED(token: ContractAddress, min_price: u256, min_price_prev: u256) {
        let mut data: Array<felt252> = array![];
        data.append('min prices not sorted');
        data.append(token.into());
        data.append(min_price.try_into().expect('u256 into felt failed'));
        data.append(min_price_prev.try_into().expect('u256 into felt failed'));
        panic(data)
    }

    fn MAX_PRICES_NOT_SORTED(token: ContractAddress, max_price: u256, max_price_prev: u256) {
        let mut data: Array<felt252> = array![];
        data.append('max prices not sorted');
        data.append(token.into());
        data.append(max_price.try_into().expect('u256 into felt failed'));
        data.append(max_price_prev.try_into().expect('u256 into felt failed'));
        panic(data)
    }
}
