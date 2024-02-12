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

    /// Returns the number of roles stored in the contract.
    /// # Return
    /// The number of roles.
    fn get_role_count(self: @TContractState) -> u32;
    /// Returns the keys of the roles stored in the contract.
    /// # Arguments
    /// `start` - The starting index of the range of roles to return.
    /// `end` - The ending index of the range of roles to return.
    /// # Return
    /// The keys of the roles.
    fn get_roles(self: @TContractState, start: u32, end: u32) -> Array<felt252>;
    /// Returns the number of members of the specified role.
    /// # Arguments
    /// `role_key` - The key of the role.
    /// # Return
    /// The number of members of the role.
    fn get_role_member_count(self: @TContractState, role_key: felt252) -> u32;
    /// Returns the members of the specified role.
    /// # Arguments
    /// `role_key` - The key of the role.
    /// `start` - The start index, the value for this index will be included.
    /// `end` - The end index, the value for this index will not be included.
    /// # Return
    /// The members of the role.
    fn get_role_members(
        self: @TContractState, role_key: felt252, start: u32, end: u32
    ) -> Array<ContractAddress>;
}

#[starknet::contract]
mod RoleStore {
    // *************************************************************************
    //                                  IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;
    use starknet::{ContractAddress, get_caller_address, contract_address_const};

    // Local imports.
    use satoru::role::{role, error::RoleError};


    // *************************************************************************
    // STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Maps accounts to their roles.
        has_role: LegacyMap::<(felt252, ContractAddress), bool>,
        /// Stores the number of the indexes used to a specific role.
        role_members_count: LegacyMap::<felt252, u32>,
        /// Stores all the account that have a specific role.
        role_members: LegacyMap::<(felt252, u32), ContractAddress>,
        /// Stores unique role names.
        role_names: LegacyMap::<felt252, bool>,
        /// Store the number of indexes of the roles.
        roles_count: u32,
        /// List of all role keys.
        roles: LegacyMap::<u32, felt252>,
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
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        // Grant the caller admin role.
        self._grant_role(admin, role::ROLE_ADMIN);
    // Initialize the role_count to 1 due to the line just above.
    }

    // *************************************************************************
    // EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl RoleStore of super::IRoleStore<ContractState> {
        fn has_role(self: @ContractState, account: ContractAddress, role_key: felt252) -> bool {
            self._has_role(account, role_key)
        }

        fn grant_role(ref self: ContractState, account: ContractAddress, role_key: felt252) {
            // Check that the caller has the admin role.
            self._assert_only_role(get_caller_address(), role::ROLE_ADMIN);
            // Grant the role.
            self._grant_role(account, role_key);
        }

        fn revoke_role(ref self: ContractState, account: ContractAddress, role_key: felt252) {
            // Check that the caller has the admin role.
            self._assert_only_role(get_caller_address(), role::ROLE_ADMIN);
            // check that the are more than 1 RoleAdmin
            if role_key == role::ROLE_ADMIN {
                assert(self.get_role_member_count(role_key) > 1, RoleError::UNAUTHORIZED_CHANGE);
            }
            // Revoke the role.
            self._revoke_role(account, role_key);
        }

        fn assert_only_role(self: @ContractState, account: ContractAddress, role_key: felt252) {
            self._assert_only_role(account, role_key);
        }

        fn get_role_count(self: @ContractState) -> u32 {
            let mut count = 0;
            let mut i = 1;
            loop {
                if i > self.roles_count.read() {
                    break;
                }
                if !self.roles.read(i).is_zero() {
                    count += 1;
                }
                i += 1;
            };
            count
        }

        fn get_roles(self: @ContractState, start: u32, mut end: u32) -> Array<felt252> {
            let mut arr = array![];
            let roles_count = self.roles_count.read();
            if end > roles_count {
                end = roles_count;
            }
            let mut i = start;
            loop {
                if i > end {
                    break;
                }
                let role = self.roles.read(i);
                if !role.is_zero() {
                    arr.append(role);
                }
                i += 1;
            };
            arr
        }

        fn get_role_member_count(self: @ContractState, role_key: felt252) -> u32 {
            let mut count = 0;
            let mut i = 1;
            loop {
                if i > self.role_members_count.read(role_key) {
                    break;
                }
                if !(self.role_members.read((role_key, i)) == contract_address_const::<0>()) {
                    count += 1;
                }
                i += 1;
            };
            count
        }

        fn get_role_members(
            self: @ContractState, role_key: felt252, start: u32, mut end: u32
        ) -> Array<ContractAddress> {
            let mut arr: Array<ContractAddress> = array![];
            let mut i = start;
            loop {
                if i > end || i > self.role_members_count.read(role_key) {
                    break;
                }
                let role_member = self.role_members.read((role_key, i));
                // Since some role members will have indexes with zero address if a zero address
                // is found end increase by 1 to mock array behaviour.
                if role_member.is_zero() {
                    end += 1;
                }
                if !(role_member == contract_address_const::<0>()) {
                    arr.append(role_member);
                }
                i += 1;
            };
            arr
        }
    }

    // *************************************************************************
    // INTERNAL FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _has_role(self: @ContractState, account: ContractAddress, role_key: felt252) -> bool {
            self.has_role.read((role_key, account))
        }

        fn _assert_only_role(self: @ContractState, account: ContractAddress, role_key: felt252) {
            assert(self._has_role(account, role_key), RoleError::UNAUTHORIZED_ACCESS);
        }

        fn _grant_role(ref self: ContractState, account: ContractAddress, role_key: felt252) {
            // Only grant the role if the account doesn't already have it.
            if !self._has_role(account, role_key) {
                self.has_role.write((role_key, account), true);
                // Iterates through indexes for role members, if an index has zero ContractAddress
                // it writes the account to that index for the role.
                let roles_members_count = self.role_members_count.read(role_key);
                let current_roles_count = self.roles_count.read();
                let mut i = 1;
                loop {
                    let stored_role_member = self.role_members.read((role_key, i));
                    if stored_role_member.is_zero() {
                        self.role_members.write((role_key, i), account);
                        self.role_members_count.write(role_key, roles_members_count + 1);
                        break;
                    }
                    i += 1;
                };

                // Store the role name if it's not already stored.
                if self.role_names.read(role_key) == false {
                    self.role_names.write(role_key, true);
                    self.roles_count.write(current_roles_count + 1);
                }
                self.emit(RoleGranted { role_key, account, sender: get_caller_address() });
            }
            // Iterates through indexes in stored_roles and if a value for the index is zero
            // it writes the role_key to that index.
            let mut i = 1;
            loop {
                let stored_role = self.roles.read(i);
                if stored_role.is_zero() {
                    self.roles.write(i, role_key);
                    break;
                }
                i += 1;
            };
        }

        fn _revoke_role(ref self: ContractState, account: ContractAddress, role_key: felt252) {
            let current_roles_count = self.roles_count.read();
            // Only revoke the role if the account has it.
            if self._has_role(account, role_key) {
                self.has_role.write((role_key, account), false);
                self.emit(RoleRevoked { role_key, account, sender: get_caller_address() });
                let current_role_members_count = self.role_members_count.read(role_key);
                let mut i = 1;
                loop {
                    let stored_role_member = self.role_members.read((role_key, i));
                    if stored_role_member == account {
                        self.role_members.write((role_key, i), contract_address_const::<0>());
                        break;
                    }
                    i += 1;
                };
                // If the role has no members remove the role from roles.
                if self.get_role_member_count(role_key).is_zero() {
                    let role_index = self._find_role_index(role_key);
                    self.roles.write(role_index, Zeroable::zero());
                }
            }
        }

        fn _find_role_index(ref self: ContractState, role_key: felt252) -> u32 {
            let mut index = 0;
            let mut i = 1;
            loop {
                if i > self.roles_count.read() {
                    break;
                }
                if self.roles.read(i) == role_key {
                    index = i;
                    break;
                }
                i += 1;
            };
            index
        }
    }
}
