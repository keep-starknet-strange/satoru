use poseidon::poseidon_hash_span;
use starknet::{ContractAddress, get_block_timestamp};

// Local imports.
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::data::keys;
use satoru::market::market::Market;
use satoru::utils::hash::hash_poseidon_single;

fn market_salt() -> felt252 {
    hash_poseidon_single('MARKET_SALT')
}

fn market_key() -> felt252 {
    hash_poseidon_single('MARKET_KEY')
}

fn market_token() -> felt252 {
    hash_poseidon_single('MARKET_TOKEN')
}

fn index_token() -> felt252 {
    hash_poseidon_single('INDEX_TOKEN')
}

fn long_token() -> felt252 {
    hash_poseidon_single('LONG_TOKEN')
}

fn short_token() -> felt252 {
    hash_poseidon_single('SHORT_TOKEN')
}

fn get(data_store: IDataStoreDispatcher, key: ContractAddress) -> Market {
    match data_store.get_market(key) {
        Option::Some => {},
        Option::None => {
            return Default::default();
        }
    }

    let hash = poseidon_hash_span(array![key.into(), market_token()].span());
    let market_token = data_store.get_address(hash);

    let hash = poseidon_hash_span(array![key.into(), index_token()].span());
    let index_token = data_store.get_address(hash);

    let hash = poseidon_hash_span(array![key.into(), long_token()].span());
    let long_token = data_store.get_address(hash);

    let hash = poseidon_hash_span(array![key.into(), short_token()].span());
    let short_token = data_store.get_address(hash);

    Market { market_token, index_token, long_token, short_token }
}
