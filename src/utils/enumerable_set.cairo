use dict::Felt252Dict;
use dict::Felt252DictTrait;
use array::ArrayTrait;
use starknet::ContractAddress;

#[derive(Destruct, Default)]
struct Set {
    // mapping of values to their index in the array (starts at 1, as 0 is for empty indexes)
    indexes: Felt252Dict<felt252>,
    // mapping of index to value
    values: Felt252Dict<felt252>,
    // length of continguous array
    length: felt252,
}

trait SetTrait<T> {
    fn new() -> Set;
    fn add(ref self: Set, value: T) -> bool;
    fn contains(ref self: Set, value: T) -> bool;
    fn remove(ref self: Set, value: T) -> bool;
    fn length(ref self: Set) -> felt252;
    fn at(ref self: Set, index: felt252) -> T;
    fn values(ref self: Set) -> Array<T>;
}

impl Felt252SetImpl of SetTrait<felt252> {
    /// Creates a new set.
    /// # Returns
    /// * A new set.
    fn new() -> Set {
        Set { 
            indexes: Default::default(), 
            values: Default::default(), 
            length: 0,
        }
    }
    
    /// Adds a value to the set.
    /// # Arguments
    /// * `value` - The value to add.
    /// # Returns
    /// * `true` if the value was added to the set, `false` otherwise.
    fn add(ref self: Set, value: felt252) -> bool {
        let is_new = !self.contains(value);

        if is_new {
            self.length += 1;
            self.values.insert(self.length, value);
            self.indexes.insert(value, self.length);
        }

        is_new
    }

    /// Removes a value from the set.
    /// # Arguments
    /// * `value` - The value to remove.
    /// # Returns
    /// * `true` if the value was removed from the set, `false` otherwise.
    fn remove(ref self: Set, value: felt252) -> bool {
        let value_index = self.indexes.get(value);
        let is_removed = value_index != 0;

        if is_removed {
            // Swap element to delete with last one then remove last element.
            let last_value = self.values.get(self.length);
            self.indexes.insert(value, 0);
            self.values.insert(value_index, last_value);
            self.indexes.insert(last_value, value_index);
            self.length -= 1;
        }

        is_removed
    }

    /// Checks if a value is in the set.
    /// # Arguments
    /// * `value` - The value to check.
    /// # Returns
    /// * `true` if the value is in the set, `false` otherwise.
    fn contains(ref self: Set, value: felt252) -> bool {
        self.indexes.get(value) != 0
    }

    /// Returns the number of elements in the set.
    /// # Returns
    /// * The number of elements in the set.
    fn length(ref self: Set) -> felt252 {
        self.length
    }

    /// Returns the value stored at position `index` in the set.
    /// # Arguments
    /// * `index` - The index of the value to return.
    fn at(ref self: Set, index: felt252) -> felt252 {
        self.values.get(index)
    }

    /// Returns the entire set as an array.
    /// # Returns
    /// * The entire set in an array.
    fn values(ref self: Set) -> Array<felt252> {
        let mut values = ArrayTrait::<felt252>::new();
        let mut i = self.length;
        loop {
            if i == 0 { break (); }
            values.append(self.at(i));
            i -= 1;
        };
        values
    }
}

impl ContractAddressSetImpl of SetTrait<ContractAddress> {
    /// Creates a new set.
    /// # Returns
    /// * A new set.
    fn new() -> Set {
        Felt252SetImpl::new()
    }
    
    /// Adds a value to the set.
    /// # Arguments
    /// * `value` - The value to add.
    /// # Returns
    /// * `true` if the value was added to the set, `false` otherwise.
    fn add(ref self: Set, value: ContractAddress) -> bool {
        Felt252SetImpl::add(ref self, value.into())
    }

    /// Removes a value from the set.
    /// # Arguments
    /// * `value` - The value to remove.
    /// # Returns
    /// * `true` if the value was removed from the set, `false` otherwise.
    fn remove(ref self: Set, value: ContractAddress) -> bool {
        Felt252SetImpl::remove(ref self, value.into())
    }

    /// Checks if a value is in the set.
    /// # Arguments
    /// * `value` - The value to check.
    /// # Returns
    /// * `true` if the value is in the set, `false` otherwise.
    fn contains(ref self: Set, value: ContractAddress) -> bool {
        Felt252SetImpl::contains(ref self, value.into())
    }

    /// Returns the number of elements in the set.
    /// # Returns
    /// * The number of elements in the set.
    fn length(ref self: Set) -> felt252 {
        self.length
    }

    /// Returns the value stored at position `index` in the set.
    /// # Arguments
    /// * `index` - The index of the value to return.
    fn at(ref self: Set, index: felt252) -> ContractAddress {
        self.values.get(index).try_into().expect('Invalid address')
    }

    /// Returns the entire set as an array.
    /// # Returns
    /// * The entire set as an array.
    fn values(ref self: Set) -> Array<ContractAddress> {
        let mut values = ArrayTrait::<ContractAddress>::new();
        let mut i = self.length;
        loop {
            if i == 0 { break (); }
            values.append(self.at(i));
            i -= 1;
        };
        values
    }
}

impl U128SetImpl of SetTrait<u128> {
    /// Creates a new set.
    /// # Returns
    /// * A new set.
    fn new() -> Set {
        Felt252SetImpl::new()
    }
    
    /// Adds a value to the set.
    /// # Arguments
    /// * `value` - The value to add.
    /// # Returns
    /// * `true` if the value was added to the set, `false` otherwise.
    fn add(ref self: Set, value: u128) -> bool {
        Felt252SetImpl::add(ref self, value.into())
    }

    /// Removes a value from the set.
    /// # Arguments
    /// * `value` - The value to remove.
    /// # Returns
    /// * `true` if the value was removed from the set, `false` otherwise.
    fn remove(ref self: Set, value: u128) -> bool {
        Felt252SetImpl::remove(ref self, value.into())
    }

    /// Checks if a value is in the set.
    /// # Arguments
    /// * `value` - The value to check.
    /// # Returns
    /// * `true` if the value is in the set, `false` otherwise.
    fn contains(ref self: Set, value: u128) -> bool {
        Felt252SetImpl::contains(ref self, value.into())
    }

    /// Returns the number of elements in the set.
    /// # Returns
    /// * The number of elements in the set.
    fn length(ref self: Set) -> felt252 {
        self.length
    }

    /// Returns the value stored at position `index` in the set.
    /// # Arguments
    /// * `index` - The index of the value to return.
    fn at(ref self: Set, index: felt252) -> u128 {
        self.values.get(index).try_into().expect('Invalid u128')
    }

    /// Returns the entire set as an array.
    /// # Returns
    /// * The entire set as an array.
    fn values(ref self: Set) -> Array<u128> {
        let mut values = ArrayTrait::<u128>::new();
        let mut i = self.length;
        loop {
            if i == 0 { break (); }
            values.append(self.at(i));
            i -= 1;
        };
        values
    }
}
