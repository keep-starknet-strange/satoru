/// A trait for types that can be uniquely identified.
trait UniqueId<T> {
    fn unique_id(self: T) -> felt252;
}
