// use satoru::utils::i256::I256Serde;

// #[starknet::interface]
// trait ITestI256Storage<TContractState> {
//     fn set_i256(ref self: TContractState, new_val: i256);
//     fn get_i256(self: @TContractState) -> i256;
// }

// #[starknet::contract]
// mod test_i256_storage_contract {
//     use satoru::utils::i256::{I256Store, I256Serde};
//     use super::ITestI256Storage;

//     #[storage]
//     struct Storage {
//         my_i256: i256
//     }

//     #[external(v0)]
//     impl Public of ITestI256Storage<ContractState> {
//         fn set_i256(ref self: ContractState, new_val: i256) {
//             self.my_i256.write(new_val);
//         }
//         fn get_i256(self: @ContractState) -> i256 {
//             self.my_i256.read()
//         }
//     }
// }


