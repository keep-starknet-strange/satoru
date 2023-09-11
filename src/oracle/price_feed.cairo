/// Mock interface used for oracle::get_price_feed_price. 
use serde::Serde;

#[starknet::interface]
trait IPriceFeed<TContractState> {
    fn latest_round_data(self: @TContractState) -> (u128, u128, u128, u64, u128);
}


impl TupleSize5Serde<
    E0,
    E1,
    E2,
    E3,
    E4,
    impl E0Serde: Serde<E0>,
    impl E0Drop: Drop<E0>,
    impl E1Serde: Serde<E1>,
    impl E1Drop: Drop<E1>,
    impl E2Serde: Serde<E2>,
    impl E2Drop: Drop<E2>,
    impl E3Serde: Serde<E3>,
    impl E3Drop: Drop<E3>,
    impl E4Serde: Serde<E4>,
    impl E4Drop: Drop<E4>,
> of Serde<(E0, E1, E2, E3, E4)> {
    fn serialize(self: @(E0, E1, E2, E3, E4), ref output: Array<felt252>) {
        let (e0, e1, e2, e3, e4) = self;
        e0.serialize(ref output);
        e1.serialize(ref output);
        e2.serialize(ref output);
        e3.serialize(ref output);
        e4.serialize(ref output)
    }
    fn deserialize(ref serialized: Span<felt252>) -> Option<(E0, E1, E2, E3, E4)> {
        Option::Some(
            (
                E0Serde::deserialize(ref serialized)?,
                E1Serde::deserialize(ref serialized)?,
                E2Serde::deserialize(ref serialized)?,
                E3Serde::deserialize(ref serialized)?,
                E4Serde::deserialize(ref serialized)?
            )
        )
    }
}
