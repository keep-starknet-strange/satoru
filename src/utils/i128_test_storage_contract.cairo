// use satoru::utils::i128::I128Serde;

// #[starknet::interface]
// trait ITestI128Storage<TContractState> {
//     fn set_i128(ref self: TContractState, new_val: i128);
//     fn get_i128(self: @TContractState) -> i128;
// }

// #[starknet::contract]
// mod test_i128_storage_contract {
//     use satoru::utils::i128::{I128Store, I128Serde};
//     use super::ITestI128Storage;

//     #[storage]
//     struct Storage {
//         my_i128: i128
//     }

//     #[external(v0)]
//     impl Public of ITestI128Storage<ContractState> {
//         fn set_i128(ref self: ContractState, new_val: i128) {
//             self.my_i128.write(new_val);
//         }
//         fn get_i128(self: @ContractState) -> i128 {
//             self.my_i128.read()
//         }
//     }
// }


