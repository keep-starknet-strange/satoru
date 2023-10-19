mod RouterError {
    use starknet::ContractAddress;

    const ALREADY_INITIALIZED: felt252 = 'already_initialized';
    const DEPOSIT_NOT_VALID: felt252 = 'deposit_not_valid';
    const WITHDRAWAL_NOT_VALID: felt252 = 'withdrawal_not_valid';
    const ORDER_NOT_VALID: felt252 = 'order_not_valid';
    const EMPTY_DEPOSIT: felt252 = 'empty_deposit';
    const EMPTY_ORDER: felt252 = 'empty_order';

    fn UNAUTHORIZED(sender: ContractAddress, message: felt252) {
        let mut data = array![message.into()];
        data.append(sender.into());
        panic(data)
    }

    fn INVALID_CLAIM_FUNDING_FEES_INPUT(markets_len: u32, tokens_len: u32) {
        let mut data = array![markets_len.into(), tokens_len.into()];
        panic(data)
    }

    fn INVALID_CLAIM_COLLATERAL_INPUT(markets_len: u32, tokens_len: u32, time_keys_len: u32) {
        let mut data = array![markets_len.into(), tokens_len.into(), time_keys_len.into()];
        panic(data)
    }

    fn INVALID_CLAIM_AFFILIATE_REWARDS_INPUT(markets_len: u32, tokens_len: u32) {
        let mut data = array![markets_len.into(), tokens_len.into()];
        panic(data)
    }

    fn INVALID_CLAIM_UI_FEES_INPUT(markets_len: u32, tokens_len: u32) {
        let mut data = array![markets_len.into(), tokens_len.into()];
        panic(data)
    }
}
