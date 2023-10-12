// Core lib imports
use core::option::OptionTrait;
use core::traits::TryInto;
use starknet::ContractAddress;

impl DefaultContractAddress of Default<ContractAddress> {
    fn default() -> ContractAddress {
        0.try_into().unwrap()
    }
}
