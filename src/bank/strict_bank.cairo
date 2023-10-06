//! Contract to handle storing and transferring of tokens.

// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use traits::{Into, TryInto};
use starknet::{ContractAddress, get_contract_address};

// *************************************************************************
//                  Interface of the `StrictBank` contract.
// *************************************************************************
#[starknet::interface]
trait IStrictBank<TContractState> {
    /// Initialize the contract.
    /// # Arguments
    /// * `data_store_address` - The address of the data store contract.
    /// * `role_store_address` - The address of the role store contract.
    fn initialize(
        ref self: TContractState,
        data_store_address: ContractAddress,
        role_store_address: ContractAddress,
    );

    /// Transfer tokens from this contract to a receiver.
    /// # Arguments
    /// * `token` - The token address to transfer.
    /// * `receiver` - The address of the receiver.
    /// * `amount` - The amount of tokens to transfer.
    fn transfer_out(
        ref self: TContractState, token: ContractAddress, receiver: ContractAddress, amount: u128,
    );

    /// Records a token transfer into the contract
    /// # Arguments
    /// * `token` - The token to record the transfer for
    /// # Return
    /// The amount of tokens transferred in
    fn record_transfer_in(ref self: TContractState, token: ContractAddress) -> u128;

    /// this can be used to update the tokenBalances in case of token burns
    /// or similar balance changes
    /// the prevBalance is not validated to be more than the nextBalance as this
    /// could allow someone to block this call by transferring into the contract    
    /// # Arguments
    /// * `token` - The token to record the burn for
    /// # Return
    /// The new balance
    fn sync_token_balance(ref self: TContractState, token: starknet::ContractAddress) -> u128;
}

#[starknet::contract]
mod StrictBank {
    // *************************************************************************
    //                               IMPORTS
    // *************************************************************************

    // Core lib imports.
    use core::traits::TryInto;
    use starknet::{get_caller_address, get_contract_address, ContractAddress, contract_address_const};
    use debug::PrintTrait;

    // Local imports.
    use satoru::bank::bank::{Bank, IBank};
    use super::IStrictBank;
    use satoru::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};
    use satoru::role::role_module::{RoleModule, IRoleModule};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        token_balances: LegacyMap::<ContractAddress, u128>,
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************
    /// Constructor of the contract.
    /// # Arguments
    /// * `data_store_address` - The address of the data store contract.
    /// * `role_store_address` - The address of the role store contract.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        data_store_address: ContractAddress,
        role_store_address: ContractAddress,
    ) {
        self.initialize(data_store_address, role_store_address);
    }

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[external(v0)]
    impl StrictBank of super::IStrictBank<ContractState> {
        fn initialize(
            ref self: ContractState,
            data_store_address: ContractAddress,
            role_store_address: ContractAddress,
        ) {
            let mut state: Bank::ContractState = Bank::unsafe_new_contract_state();
            IBank::initialize(ref state, data_store_address, role_store_address);
        }

        fn transfer_out(
            ref self: ContractState,
            token: ContractAddress,
            receiver: ContractAddress,
            amount: u128,
        ) {
            let mut state: Bank::ContractState = Bank::unsafe_new_contract_state();
            IBank::transfer_out(ref state, token, receiver, amount);
            self.after_transfer_out_infernal(token);
        }

        fn sync_token_balance(ref self: ContractState, token: ContractAddress) -> u128 {
            // assert that caller is a controller
            let mut role_module: RoleModule::ContractState = RoleModule::unsafe_new_contract_state();
            role_module.only_controller();

            let this_contract = get_contract_address();
            let next_balance: u128 = IERC20Dispatcher{contract_address: token}.balance_of(this_contract).try_into().unwrap(); 
            self.token_balances.write(token, next_balance);
            next_balance 
        }

        fn record_transfer_in(ref self: ContractState, token: ContractAddress) -> u128 {
            // assert that caller is a controller
            let mut role_module: RoleModule::ContractState = RoleModule::unsafe_new_contract_state();
            role_module.only_controller();
            
            self.record_transfer_in_internal(token)
        }
    }

    #[generate_trait]
    impl PrivateMethods of PrivateMethodsTrait {
        /// Transfer tokens from this contract to a receiver
        /// # Arguments
        /// * `token` - token the token to transfer
        fn after_transfer_out_infernal(ref self: ContractState, token: starknet::ContractAddress) {
            let this_contract = get_contract_address();
            let balance: u128 = IERC20Dispatcher{contract_address: token}.balance_of(this_contract).try_into().unwrap();
            self.token_balances.write(token, balance);
        }

        /// Records a token transfer into the contract
        /// # Arguments
        /// * `token` - The token to record the transfer for
        /// # Return
        /// The amount of tokens transferred in
        fn record_transfer_in_internal(ref self: ContractState, token: starknet::ContractAddress) -> u128 {
            let prev_balance: u128 = self.token_balances.read(token);
            let this_contract = get_contract_address(); 
            let next_balance: u128 = IERC20Dispatcher{contract_address: token}.balance_of(this_contract).try_into().unwrap(); 
            self.token_balances.write(token, next_balance); 
            next_balance - prev_balance
        }
    }
}
