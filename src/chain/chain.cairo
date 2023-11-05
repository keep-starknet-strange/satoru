//! Chain is a library contract that allows to query chain variables.
//! Right now, for some reason, it's not possible to use it as a library.
//! When doing so we get this error:
//! thread 'main' panicked at 'assertion failed: `(left == right)`
//! left: `"LibraryCall"`,
//! right: `"CallContract"`', crates/forge/src/cheatcodes_hint_processor.rs:375:5
//! note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
//! TODO: Fix this issue and use it as a library.

// *************************************************************************
//                  Interface of the `Chain` contract.
// *************************************************************************
#[starknet::interface]
trait IChain<TContractState> {
    /// Returns the current block number.
    fn get_block_number(self: @TContractState) -> u64;

    /// Returns the current block timestamp.
    fn get_block_timestamp(self: @TContractState) -> u64;
}

#[starknet::contract]
mod Chain {
    /// Storage is empty since the contract is designed to be stateless and called as a library only.
    #[storage]
    struct Storage {}

    // *************************************************************************
    //                          EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl Chain of super::IChain<ContractState> {
        fn get_block_number(self: @ContractState) -> u64 {
            starknet::info::get_block_number()
        }

        fn get_block_timestamp(self: @ContractState) -> u64 {
            starknet::info::get_block_timestamp()
        }
    }
}
