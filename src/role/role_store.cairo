//! Stores roles and their members.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::ContractAddress;

// *************************************************************************
// Interface of the `RoleStore` contract.
// *************************************************************************
#[starknet::interface]
trait IRoleStore<TContractState> {
    /// Returns true if the given account has the given role.
    /// # Arguments
    /// * `account` - The account to check.
    /// * `role_key` - The role to check.
    /// # Returns
    /// * `true` if the account has the role, `false` otherwise.
    fn has_role(self: @TContractState, account: ContractAddress, role_key: felt252) -> bool;

    /// Grants the specified role to the given account.
    /// # Arguments
    /// * `account` - The account to grant the role to.
    /// * `role_key` - The role to grant.
    fn grant_role(ref self: TContractState, account: ContractAddress, role_key: felt252);

    /// Revokes the specified role from the given account.
    /// # Arguments
    /// * `account` - The account to revoke the role from.
    /// * `role_key` - The role to revoke.
    fn revoke_role(ref self: TContractState, account: ContractAddress, role_key: felt252);

    /// Asserts that the given account has only the given role.
    /// # Arguments
    /// * `account` - The account to check.
    /// * `role_key` - The role to check.
    /// # Reverts
    /// * If the account doesn't have the role.
    fn assert_only_role(self: @TContractState, account: ContractAddress, role_key: felt252);
}

#[starknet::contract]
mod RoleStore {
    // *************************************************************************
    //                                  IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::{ContractAddress, get_caller_address};

    // Local imports.
    use gojo::role::{role, error::RoleError};

    // *************************************************************************
    // STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Maps accounts to their roles.
        role_members: LegacyMap::<(felt252, ContractAddress), bool>,
    }

    // *************************************************************************
    // EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        RoleGranted: RoleGranted,
        RoleRevoked: RoleRevoked,
    }

    /// Emitted when `account` is granted `role`.
    ///
    /// `sender` is the account that originated the contract call, an admin role
    /// bearer (except if `_grant_role` is called during initialization from the constructor).
    #[derive(Drop, starknet::Event)]
    struct RoleGranted {
        role_key: felt252,
        account: ContractAddress,
        sender: ContractAddress
    }

    /// Emitted when `account` is revoked `role`.
    ///
    /// `sender` is the account that originated the contract call:
    ///   - If using `revoke_role`, it is the admin role bearer.
    ///   - If using `renounce_role`, it is the role bearer (i.e. `account`).
    #[derive(Drop, starknet::Event)]
    struct RoleRevoked {
        role_key: felt252,
        account: ContractAddress,
        sender: ContractAddress
    }

    // *************************************************************************
    // CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState) {
        let caller = get_caller_address();
        // Grant the caller admin role.
        self._grant_role(caller, role::ROLE_ADMIN);
    }

    // *************************************************************************
    // EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl RoleStore of super::IRoleStore<ContractState> {
        fn has_role(self: @ContractState, account: ContractAddress, role_key: felt252) -> bool {
            self._has_role(account, role_key)
        }

        fn grant_role(ref self: ContractState, account: ContractAddress, role_key: felt252) {
            let caller = get_caller_address();
            // Check that the caller has the admin role.
            self._assert_only_role(caller, role::ROLE_ADMIN);
            // Grant the role.
            self._grant_role(account, role_key);
        }

        fn revoke_role(ref self: ContractState, account: ContractAddress, role_key: felt252) {
            let caller = get_caller_address();
            // Check that the caller has the admin role.
            self._assert_only_role(caller, role::ROLE_ADMIN);
            // Revoke the role.
            self._revoke_role(account, role_key);
        }

        fn assert_only_role(self: @ContractState, account: ContractAddress, role_key: felt252) {
            self._assert_only_role(account, role_key);
        }
    }

    // *************************************************************************
    // INTERNAL FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        #[inline(always)]
        fn _has_role(self: @ContractState, account: ContractAddress, role_key: felt252) -> bool {
            self.role_members.read((role_key, account))
        }

        #[inline(always)]
        fn _assert_only_role(self: @ContractState, account: ContractAddress, role_key: felt252) {
            assert(self._has_role(account, role_key), RoleError::UNAUTHORIZED_ACCESS);
        }

        fn _grant_role(ref self: ContractState, account: ContractAddress, role_key: felt252) {
            // Only grant the role if the account doesn't already have it.
            if !self._has_role(account, role_key) {
                let caller: ContractAddress = get_caller_address();
                self.role_members.write((role_key, account), true);
                self.emit(RoleGranted { role_key, account, sender: caller });
            }
        }

        fn _revoke_role(ref self: ContractState, account: ContractAddress, role_key: felt252) {
            // Only revoke the role if the account has it.
            if self._has_role(account, role_key) {
                let caller: ContractAddress = get_caller_address();
                self.role_members.write((role_key, account), false);
                self.emit(RoleRevoked { role_key, account, sender: caller });
            }
        }
    }
}
