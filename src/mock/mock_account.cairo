//! Mock Account for testing.

#[starknet::contract]
mod MockAccount {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::zeroable::Zeroable;
    use starknet::{get_caller_address, ContractAddress};
    use result::ResultTrait;

    // Local imports.
    use satoru::oracle::{
        interfaces::account::{IAccount, IAccountDispatcher, IAccountDispatcherTrait}
    };


    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        owner: felt252,
    }

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl MockAccount of IAccount<ContractState> {
        fn __validate_declare__(self: @ContractState, class_hash: felt252) -> felt252 {
            1
        }
        fn __validate_deploy__(
            self: @ContractState,
            class_hash: felt252,
            contract_address_salt: felt252,
            owner: felt252,
            guardian: felt252
        ) -> felt252 {
            1
        }

        fn change_owner(
            ref self: ContractState, new_owner: felt252, signature_r: felt252, signature_s: felt252
        ) {
            self.owner.write(new_owner);
        }
        fn change_guardian(ref self: ContractState, new_guardian: felt252) {}


        fn change_guardian_backup(ref self: ContractState, new_guardian_backup: felt252) {}


        fn trigger_escape_owner(ref self: ContractState, new_owner: felt252) {}

        fn trigger_escape_guardian(ref self: ContractState, new_guardian: felt252) {}

        fn escape_owner(ref self: ContractState) {}

        fn escape_guardian(ref self: ContractState) {}

        fn cancel_escape(ref self: ContractState) {}
        fn get_owner(self: @ContractState) -> felt252 {
            self.owner.read()
        }
        fn get_guardian(self: @ContractState) -> felt252 {
            1
        }
        fn get_guardian_backup(self: @ContractState) -> felt252 {
            1
        }
        fn get_name(self: @ContractState) -> felt252 {
            1
        }
        fn get_guardian_escape_attempts(self: @ContractState) -> u32 {
            1
        }
        fn get_owner_escape_attempts(self: @ContractState) -> u32 {
            1
        }
    }
}
