//! Stores roles and their members.

use starknet::ContractAddress;

#[starknet::interface]
trait IRoleStore<TContractState> {
    /// Returns true if the given account has the given role.
    fn has_role(ref self: TContractState, account: ContractAddress, role_key: felt252) -> bool;

    /// Grants the specified role to the given account.
    /// # Arguments
    /// * `account` - The account to grant the role to.
    /// * `role_key` - The role to grant.
    fn grant_role(ref self: TContractState, account: ContractAddress, role_key: felt252);
}

#[starknet::contract]
mod RoleStore {
    use starknet::{ContractAddress, get_caller_address};

    // STORAGE
    #[storage]
    struct Storage {
        role_members: LegacyMap::<ContractAddress, felt252>, 
    }

    // CONSTRUCTOR
    #[constructor]
    fn constructor(ref self: ContractState) {
        let caller = get_caller_address();
    // TODO: grant caller admin role.
    }

    // EXTERNAL FUNCTIONS
    #[external(v0)]
    impl RoleStore of super::IRoleStore<ContractState> {
        fn has_role(ref self: ContractState, account: ContractAddress, role_key: felt252) -> bool {
            self.role_members.read(account) == role_key
        }

        fn grant_role(ref self: ContractState, account: ContractAddress, role_key: felt252) {
            self.role_members.write(account, role_key);
        }
    }
}
