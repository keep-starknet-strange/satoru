// *************************************************************************
//                                  IMPORTS
// *************************************************************************

// Core lib imports.
use starknet::{ContractAddress, SyscallResult,};
use starknet::storage_access::{Store, StoreContractAddress, StorageBaseAddress};

// Local imports.
use satoru::withdrawal::withdrawal::Withdrawal;

// Span32.
#[derive(Copy, Drop, PartialEq)]
struct Span32<T> {
    snapshot: Span<T>
}

fn serialize_array_helper<T, +Serde<T>, +Drop<T>>(
    mut input: Span32<T>, ref output: Array<felt252>
) {
    match input.pop_front() {
        Option::Some(value) => {
            value.serialize(ref output);
            serialize_array_helper(input, ref output);
        },
        Option::None => {},
    }
}

fn deserialize_array_helper<T, +Serde<T>, +Drop<T>>(
    ref serialized: Span<felt252>, mut curr_output: Array<T>, remaining: felt252
) -> Option<Array<T>> {
    if remaining == 0 {
        return Option::Some(curr_output);
    }
    curr_output.append(Serde::deserialize(ref serialized)?);
    deserialize_array_helper(ref serialized, curr_output, remaining - 1)
}

impl Span32Serde<T, +Serde<T>, +Drop<T>, +Copy<T>> of Serde<Span32<T>> {
    fn serialize(self: @Span32<T>, ref output: Array<felt252>) {
        (*self).len().serialize(ref output);
        serialize_array_helper(*self, ref output)
    }

    fn deserialize(ref serialized: Span<felt252>) -> Option<Span32<T>> {
        let length = *serialized.pop_front()?;
        let mut arr: Array<T> = ArrayTrait::new();
        Option::Some(Array32Trait::span32(@deserialize_array_helper(ref serialized, arr, length)?))
    }
}

#[generate_trait]
impl Span32Impl<T, +Serde<T>> of Span32Trait<T> {
    fn pop_front(ref self: Span32<T>) -> Option<@T> {
        self.snapshot.pop_front()
    }
    fn pop_back(ref self: Span32<T>) -> Option<@T> {
        self.snapshot.pop_back()
    }
    fn get(self: Span32<T>, index: usize) -> Option<Box<@T>> {
        self.snapshot.get(index)
    }
    fn at(self: Span32<T>, index: usize) -> @T {
        self.snapshot.at(index)
    }
    fn slice(self: Span32<T>, start: usize, length: usize) -> Span32<T> {
        Span32 { snapshot: self.snapshot.slice(start, length) }
    }
    fn len(self: Span32<T>) -> usize {
        self.snapshot.len()
    }
    fn is_empty(self: Span32<T>) -> bool {
        self.snapshot.is_empty()
    }
}

impl DefaultSpan32<T, +Drop<T>> of Default<Span32<T>> {
    fn default() -> Span32<T> {
        Array32Trait::<T>::span32(@ArrayTrait::new())
    }
}

impl Span32Index<T> of IndexView<Span32<T>, usize, @T> {
    fn index(self: @Span32<T>, index: usize) -> @T {
        self.snapshot.index(index)
    }
}

trait Array32Trait<T> {
    fn span32(self: @Array<T>) -> Span32<T>;
}

impl Array32<T> of Array32Trait<T> {
    fn span32(self: @Array<T>) -> Span32<T> {
        assert(self.len() <= 32, 'array too big');
        Span32 { snapshot: Span { snapshot: self } }
    }
}

impl StoreContractAddressSpan32 of Store<Span32<ContractAddress>> {
    fn read(
        address_domain: u32, base: StorageBaseAddress
    ) -> SyscallResult<Span32<ContractAddress>> {
        StoreContractAddressSpan32::read_at_offset(address_domain, base, 0)
    }

    fn write(
        address_domain: u32, base: StorageBaseAddress, value: Span32<ContractAddress>
    ) -> SyscallResult<()> {
        StoreContractAddressSpan32::write_at_offset(address_domain, base, 0, value)
    }

    fn read_at_offset(
        address_domain: u32, base: StorageBaseAddress, mut offset: u8
    ) -> SyscallResult<Span32<ContractAddress>> {
        let mut arr: Array<ContractAddress> = ArrayTrait::new();

        // Read the stored array's length. If the length is superior to 255, the read will fail.
        let len: u8 = Store::<u8>::read_at_offset(address_domain, base, offset)
            .expect('Storage Span too large');
        offset += 1;

        // Sequentially read all stored elements and append them to the array.
        let exit = len + offset;
        loop {
            if offset >= exit {
                break;
            }

            let value = Store::<ContractAddress>::read_at_offset(address_domain, base, offset)
                .expect('read_ad_offset failed');
            arr.append(value);
            offset += Store::<ContractAddress>::size();
        };

        // Return the array.
        Result::Ok(Array32Trait::span32(@arr))
    }

    fn write_at_offset(
        address_domain: u32,
        base: StorageBaseAddress,
        mut offset: u8,
        mut value: Span32<ContractAddress>
    ) -> SyscallResult<()> {
        // // Store the length of the array in the first storage slot.
        let len: u8 = value.len().try_into().expect('Storage - Span too large');
        Store::<u8>::write_at_offset(address_domain, base, offset, len);
        offset += 1;

        // Store the array elements sequentially
        loop {
            match value.pop_front() {
                Option::Some(element) => {
                    Store::<
                        ContractAddress
                    >::write_at_offset(address_domain, base, offset, *element);
                    offset += Store::<felt252>::size();
                },
                Option::None(_) => { break Result::Ok(()); }
            };
        }
    }

    fn size() -> u8 {
        32 * Store::<ContractAddress>::size()
    }
}
