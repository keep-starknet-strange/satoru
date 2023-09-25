//! `MarketToken` is an ERC20 token that represents a token of a market.
//! It stores funds for the market and keeps track of the liquidity owners;
use starknet::ContractAddress;

#[starknet::interface]
trait IMarketToken<TState> {
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn decimals(self: @TState) -> u8;
    fn total_supply(self: @TState) -> u128;
    fn balance_of(self: @TState, account: ContractAddress) -> u128;
    fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u128;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u128) -> bool;
    fn transfer_from(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u128
    ) -> bool;
    fn approve(ref self: TState, spender: ContractAddress, amount: u128) -> bool;
    fn mint(ref self: TState, recipient: ContractAddress, amount: u128);
    fn burn(ref self: TState, recipient: ContractAddress, amount: u128);
}

#[starknet::contract]
mod MarketToken {
    use integer::BoundedInt;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;

    use satoru::role::role_store::{IRoleStoreDispatcher, IRoleStoreDispatcherTrait};
    use satoru::role::role;
    use satoru::bank::bank::{Bank, IBank};

    use super::IMarketToken;

    const NAME: felt252 = 'Satoru Market';
    const SYMBOL: felt252 = 'GM';
    const DECIMALS: u8 = 6;

    #[storage]
    struct Storage {
        role_store: IRoleStoreDispatcher,
        name: felt252,
        symbol: felt252,
        total_supply: u128,
        balances: LegacyMap<ContractAddress, u128>,
        allowances: LegacyMap<(ContractAddress, ContractAddress), u128>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        value: u128
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        spender: ContractAddress,
        value: u128
    }

    #[constructor]
    fn constructor(ref self: ContractState, role_store_address: ContractAddress) {
        self.initializer(NAME, SYMBOL);
        //Might need to inherit bank. 
        // let mut bank: Bank::ContractState = Bank::unsafe_new_contract_state();
        // IBank::initialize(ref bank, data_store_address, role_store_address)
        self.role_store.write(IRoleStoreDispatcher { contract_address: role_store_address });
    }

    //
    // External
    //

    #[external(v0)]
    impl MarketTokenImpl of IMarketToken<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        fn decimals(self: @ContractState) -> u8 {
            DECIMALS
        }

        fn total_supply(self: @ContractState) -> u128 {
            self.total_supply.read()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u128 {
            self.balances.read(account)
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u128 {
            self.allowances.read((owner, spender))
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u128) -> bool {
            let sender = get_caller_address();
            self._transfer(sender, recipient, amount);
            true
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u128
        ) -> bool {
            let caller = get_caller_address();
            self._spend_allowance(sender, caller, amount);
            self._transfer(sender, recipient, amount);
            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u128) -> bool {
            let caller = get_caller_address();
            self._approve(caller, spender, amount);
            true
        }

        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u128) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            self._mint(recipient, amount);
        }

        fn burn(ref self: ContractState, recipient: ContractAddress, amount: u128) {
            // Check that the caller has permission to set the value.
            self.role_store.read().assert_only_role(get_caller_address(), role::CONTROLLER);
            self._burn(recipient, amount);
        }
    }

    #[external(v0)]
    fn increase_allowance(
        ref self: ContractState, spender: ContractAddress, added_value: u128
    ) -> bool {
        self._increase_allowance(spender, added_value)
    }

    #[external(v0)]
    fn increaseAllowance(
        ref self: ContractState, spender: ContractAddress, addedValue: u128
    ) -> bool {
        increase_allowance(ref self, spender, addedValue)
    }

    #[external(v0)]
    fn decrease_allowance(
        ref self: ContractState, spender: ContractAddress, subtracted_value: u128
    ) -> bool {
        self._decrease_allowance(spender, subtracted_value)
    }

    #[external(v0)]
    fn decreaseAllowance(
        ref self: ContractState, spender: ContractAddress, subtractedValue: u128
    ) -> bool {
        decrease_allowance(ref self, spender, subtractedValue)
    }

    //
    // Internal
    //

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, name_: felt252, symbol_: felt252) {
            self.name.write(name_);
            self.symbol.write(symbol_);
        }

        fn _increase_allowance(
            ref self: ContractState, spender: ContractAddress, added_value: u128
        ) -> bool {
            let caller = get_caller_address();
            self._approve(caller, spender, self.allowances.read((caller, spender)) + added_value);
            true
        }

        fn _decrease_allowance(
            ref self: ContractState, spender: ContractAddress, subtracted_value: u128
        ) -> bool {
            let caller = get_caller_address();
            self
                ._approve(
                    caller, spender, self.allowances.read((caller, spender)) - subtracted_value
                );
            true
        }

        fn _mint(ref self: ContractState, recipient: ContractAddress, amount: u128) {
            assert(!recipient.is_zero(), 'ERC20: mint to 0');
            self.total_supply.write(self.total_supply.read() + amount);
            self.balances.write(recipient, self.balances.read(recipient) + amount);
            self.emit(Transfer { from: Zeroable::zero(), to: recipient, value: amount });
        }

        fn _burn(ref self: ContractState, account: ContractAddress, amount: u128) {
            assert(!account.is_zero(), 'ERC20: burn from 0');
            self.total_supply.write(self.total_supply.read() - amount);
            self.balances.write(account, self.balances.read(account) - amount);
            self.emit(Transfer { from: account, to: Zeroable::zero(), value: amount });
        }

        fn _approve(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u128
        ) {
            assert(!owner.is_zero(), 'ERC20: approve from 0');
            assert(!spender.is_zero(), 'ERC20: approve to 0');
            self.allowances.write((owner, spender), amount);
            self.emit(Approval { owner, spender, value: amount });
        }

        fn _transfer(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u128
        ) {
            assert(!sender.is_zero(), 'ERC20: transfer from 0');
            assert(!recipient.is_zero(), 'ERC20: transfer to 0');
            self.balances.write(sender, self.balances.read(sender) - amount);
            self.balances.write(recipient, self.balances.read(recipient) + amount);
            self.emit(Transfer { from: sender, to: recipient, value: amount });
        }

        fn _spend_allowance(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u128
        ) {
            let current_allowance = self.allowances.read((owner, spender));
            if current_allowance != BoundedInt::max() {
                self._approve(owner, spender, current_allowance - amount);
            }
        }
    }
}
