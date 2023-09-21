mod ReaderError {
    use starknet::ContractAddress;

    fn INVALID_TOKEN_IN(token_in: ContractAddress, expected_token: ContractAddress) {
        let mut data = array!['invalid token in'];
        data.append(token_in.into());
        data.append(expected_token.into());
        panic(data)
    }
}
