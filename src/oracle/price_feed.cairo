/// Data Types
/// The value is the `pair_id` of the data
/// For future option, pair_id and expiration timestamp
///
/// * `Spot` - Spot price
/// * `Future` - Future price
/// * `Option` - Option price
#[derive(Drop, Copy, Serde)]
enum DataType {
    SpotEntry: felt252,
    FutureEntry: (felt252, u64),
    GenericEntry: felt252,
}

#[derive(Serde, Drop, Copy)]
struct PragmaPricesResponse {
    price: u256,
    decimals: u32,
    last_updated_timestamp: u64,
    num_sources_aggregated: u32,
    expiration_timestamp: Option<u64>,
}

#[starknet::interface]
trait IPriceFeed<TContractState> {
    fn get_data_median(self: @TContractState, data_type: DataType) -> PragmaPricesResponse;
}


// NOTE: mock for testing.
#[starknet::contract]
mod PriceFeed {
    use super::{DataType, PragmaPricesResponse};

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl PriceFeedImpl of super::IPriceFeed<ContractState> {
        fn get_data_median(self: @ContractState, data_type: DataType) -> PragmaPricesResponse {
            PragmaPricesResponse {
                price: 1700,
                decimals: 18,
                last_updated_timestamp: 0,
                num_sources_aggregated: 5,
                expiration_timestamp: Option::None,
            }
        }
    }
}
