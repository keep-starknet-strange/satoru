mod SwapError {
    use starknet::ContractAddress;

    const ALREADY_INITIALIZED: felt252 = 'already_initialized';

    fn INSUFFICIENT_OUTPUT_AMOUNT(amount_in: u128, min_output_amount: u128) {
        let mut data = array!['insufficient output amount'];
        data.append(amount_in.into());
        data.append(min_output_amount.into());
        panic(data)
    }

    fn INVALID_TOKEN_IN(token_in: ContractAddress, expected_token: ContractAddress) {
        let mut data = array!['invalide token in'];
        data.append(token_in.into());
        data.append(expected_token.into());
        panic(data)
    }

    fn SWAP_PRICE_IMPACT_EXCEEDS_AMOUNT_IN(amount_after_fees: u128, negative_impact_amount: i128) {
        let mut data = array!['price impact exceeds amount'];
        data.append(amount_after_fees.into());
        data.append(negative_impact_amount.into());
        panic(data)
    }
}
