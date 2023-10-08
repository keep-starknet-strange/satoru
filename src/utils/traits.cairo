use starknet::{ContractAddress, contract_address_const};

impl ContractAddressDefault of Default<ContractAddress> {
    #[inline(always)]
    fn default() -> ContractAddress {
        contract_address_const::<0>()
    }
}
