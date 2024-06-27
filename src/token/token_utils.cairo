// ! Library for token functions, helps with transferring of tokens and native token functions
use starknet::ContractAddress;
use starknet::contract_address::ContractAddressZeroable;
use satoru::data::data_store::{IDataStoreDispatcher, IDataStoreDispatcherTrait};
use satoru::data::keys;
use satoru::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};
use satoru::utils::account_utils::validate_receiver;
use satoru::bank::error::BankError;

fn fee_token(data_store: IDataStoreDispatcher) -> ContractAddress {
    data_store.get_address(keys::fee_token())
}
use debug::PrintTrait;
// Transfers the specified amount of `token` from the caller to `receiver`.
// # Arguments
// data_store - The data store that contains the `tokenTransferGasLimit` for the specified `token`.
// token - The address of the ERC20 token that is being transferred.
// receiver - The address of the recipient of the `token` transfer.
// amount - The amount of `token` to transfer.
fn transfer(
    data_store: IDataStoreDispatcher,
    token: ContractAddress,
    receiver: ContractAddress,
    amount: u256
) {
    if (amount.is_zero()) {
        return ();
    }
    validate_receiver(receiver);

    // TODO: implement gas limit

    // transfer tokens to receiver and return if it suceeeds
    let amount_u256 = amount.into();
    let success0 = IERC20Dispatcher { contract_address: token }
        .transfer(recipient: receiver, amount: amount_u256);
    if (success0 == true) {
        return ();
    }

    // in case transfers to the receiver fail due to blacklisting or other reasons send the tokens to a holding address to avoid possible gaming through reverting transfers
    let holding_address = data_store.get_address(keys::holding_address());
    assert(!holding_address.is_zero(), 'empty_holding_address');
    let amount_u256 = amount.into();
    let success1 = IERC20Dispatcher { contract_address: token }
        .transfer(recipient: holding_address, amount: amount_u256);

    // throw error if transfer fails
    assert(success1 == true, BankError::TOKEN_TRANSFER_FAILED);
}
