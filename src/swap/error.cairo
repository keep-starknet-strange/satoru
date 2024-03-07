mod SwapError {
    use starknet::ContractAddress;
    use satoru::utils::i256::i256;

    const ALREADY_INITIALIZED: felt252 = 'already_initialized';

    fn INSUFFICIENT_OUTPUT_AMOUNT(amount_in: u256, min_output_amount: u256) {
        let mut data = array!['insufficient output amount'];
        data.append(amount_in.try_into().expect('u256 into felt failed'));
        data.append(min_output_amount.try_into().expect('u256 into felt failed'));
        panic(data)
    }

    fn INVALID_TOKEN_IN(token_in: ContractAddress, expected_token: ContractAddress) {
        let mut data = array!['invalid token in'];
        data.append(token_in.into());
        data.append(expected_token.into());
        panic(data)
    }

    fn SWAP_PRICE_IMPACT_EXCEEDS_AMOUNT_IN(amount_after_fees: u256, negative_impact_amount: i256) {
        let mut data = array!['price impact exceeds amount'];
        data.append(amount_after_fees.try_into().expect('u256 into felt failed'));
        data.append(negative_impact_amount.try_into().expect('i256 into felt failed'));
        panic(data)
    }

    fn DUPLICATED_MARKET_IN_SWAP_PATH(market: ContractAddress) {
        let mut data = array!['duplicated market path'];
        data.append(market.into());
        panic(data)
    }

    fn INVALID_SWAP_OUTPUT_TOKEN(
        output_token: ContractAddress, expected_output_token: ContractAddress
    ) {
        let mut data = array!['invalid swap output token'];
        data.append(output_token.into());
        data.append(expected_output_token.into());
        panic(data)
    }
}
