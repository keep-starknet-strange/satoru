// *************************************************************************
//                                  IMPORTS
// *************************************************************************
// Core lib imports.
use starknet::ContractAddress;

/// Validates an account.
/// # Arguments
/// * `account` - Account to validate.
fn validate_account(account: ContractAddress) {
    assert(account.is_non_zero(), 'satoru/null-account');
}

/// Validates a receiver.
/// # Arguments
/// * `receiver` - Account to validate.
fn validate_receiver(receiver: ContractAddress) { // TODO
    assert(receiver.is_non_zero(), 'satoru/null-receiver');
}
