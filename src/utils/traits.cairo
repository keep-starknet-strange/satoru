use starknet::{ContractAddress, contract_address_const};

impl ContractAddressDefault of Default<ContractAddress> {
    fn default() -> ContractAddress {
        contract_address_const::<0>()
    }
}
