// TODO Remove all below once natif

/// Core lib imports.
use starknet::{
    storage_access::{Store, StorageBaseAddress},
    {SyscallResult, syscalls::{storage_read_syscall, storage_write_syscall}}
};
use integer::BoundedInt;

impl I128Default of Default<i128> {
    #[inline(always)]
    fn default() -> i128 {
        0
    }
}

impl I128Div of Div<i128> {
    fn div(lhs: i128, rhs: i128) -> i128 {
        assert(rhs != 0, 'Division by 0');
        let u_lhs = abs(lhs);
        let u_rhs = abs(rhs);
        let response = u_lhs / u_rhs;
        let response: felt252 = response.into();
        if (lhs > 0 && rhs > 0) || (lhs < 0 && rhs < 0) {
            response.try_into().expect('i128 Overflow')
        } else {
            -response.try_into().expect('i128 Overflow')
        }
    }
}

impl I128Mul of Mul<i128> {
    fn mul(lhs: i128, rhs: i128) -> i128 {
        let u_lhs = abs(lhs);
        let u_rhs = abs(rhs);
        let response = u_lhs * u_rhs;
        let response: felt252 = response.into();
        if (lhs > 0 && rhs > 0) || (lhs < 0 && rhs < 0) {
            response.try_into().expect('i128 Overflow')
        } else {
            -response.try_into().expect('i128 Overflow')
        }
    }
}

fn abs(signed_integer: i128) -> u128 {
    let response = if signed_integer < 0 {
        -signed_integer
    } else {
        signed_integer
    };
    let response: felt252 = response.into();
    response.try_into().expect('u128 Overflow')
}

impl I128Store of Store<i128> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<i128> {
        Result::Ok(
            Store::<felt252>::read(address_domain, base)?.try_into().expect('I128Store - non i128')
        )
    }
    #[inline(always)]
    fn write(address_domain: u32, base: StorageBaseAddress, value: i128) -> SyscallResult<()> {
        Store::<felt252>::write(address_domain, base, value.into())
    }
    #[inline(always)]
    fn read_at_offset(
        address_domain: u32, base: StorageBaseAddress, offset: u8
    ) -> SyscallResult<i128> {
        Result::Ok(
            Store::<felt252>::read_at_offset(address_domain, base, offset)?
                .try_into()
                .expect('I128Store - non i128')
        )
    }
    #[inline(always)]
    fn write_at_offset(
        address_domain: u32, base: StorageBaseAddress, offset: u8, value: i128
    ) -> SyscallResult<()> {
        Store::<felt252>::write_at_offset(address_domain, base, offset, value.into())
    }
    #[inline(always)]
    fn size() -> u8 {
        1_u8
    }
}

impl I128Serde of Serde<i128> {
    fn serialize(self: @i128, ref output: Array<felt252>) {
        output.append((*self).into());
    }
    fn deserialize(ref serialized: Span<felt252>) -> Option<i128> {
        let felt_val = *(serialized.pop_front().expect('i128 deserialize'));
        let i128_val = felt_val.try_into().expect('i128 Overflow');
        Option::Some(i128_val)
    }
}

