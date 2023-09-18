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
    fn get_role_count(self: @TContractState) -> u128;
/// # [TO FIX]
/// Returns the keys of the roles stored in the contract.
/// # Arguments
/// `start` - The starting index of the range of roles to return.
/// `end` - The ending index of the range of roles to return.
/// # Return
/// The keys of the roles.
/// fn get_roles(self: @TContractState, start: u32, end: u32) -> Array<felt252>;

/// # [TO DO]
/// Returns the number of members of the specified role.
/// # Arguments
/// `role_key` - The key of the role.
/// # Return
/// The number of members of the role.
/// fn get_role_member_count(self: @TContractState, role_key: felt252) -> u128;

/// Returns the members of the specified role.
/// # Arguments
/// `role_key` - The key of the role.
/// `start` - The start index, the value for this index will be included.
/// `end` - The end index, the value for this index will not be included.
/// # Return
/// The members of the role.
/// fn get_role_members(self: @TContractState, role_key: felt252, start: u128, end: u128) -> Array<ContractAddress>;   
}

#[starknet::contract]
mod RoleStore {
    // *************************************************************************
    //                                  IMPORTS
    // *************************************************************************

    // Core lib imports.
    use starknet::{ContractAddress, get_caller_address};
    //use array::ArrayTrait;

    // Local imports.
    use satoru::role::{role, error::RoleError};

    // *************************************************************************
    // STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        /// Maps accounts to their roles.
        role_members: LegacyMap::<(felt252, ContractAddress), bool>,
        /// Stores unique role names.
        role_names: LegacyMap::<felt252, bool>,
        /// Store the number of unique roles.
        role_count: u128,
    /// List of all role keys.
    ///role_keys: Array<felt252>,
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
        // Initialize the role_count to 1 due to the line just above.
        self.role_count.write(1);
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

        fn get_role_count(self: @ContractState) -> u128 {
            return self.role_count.read();
        }
    //fn get_roles(self: @ContractState, start: u32, end: u32) -> Array<felt252> {
    // Create a new array to store the result.
    //let mut result = ArrayTrait::<felt252>::new();
    //let role_keys_length = self.role_keys.read().len();
    // Ensure the range is valid.
    //assert(start < end, "InvalidRange");
    //assert(end <= role_keys_length, "EndOutOfBounds");
    //let mut current_index = start;
    //loop {
    // Check if we've reached the end of the specified range.
    //if current_index >= end {
    //break;
    //}
    //let key = *self.role_keys.read().at(current_index);
    //result.append(key);
    // Increment the index.
    //current_index += 1;
    //};
    //return result;
    //}
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
                // Store the role name if it's not already stored.
                if self.role_names.read(role_key) == false {
                    self.role_names.write(role_key, true);
                    let mut current_count: u128 = self.role_count.read();
                    self.role_count.write(current_count + 1);
                // Read the current state of role_keys into a local variable.
                // let mut local_role_keys = self.role_keys.read();
                // Modify the local variable.
                // local_role_keys.append(role_key);
                // Write back the modified local variable to the contract state.
                // self.role_keys.write(local_role_keys);
                }
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
