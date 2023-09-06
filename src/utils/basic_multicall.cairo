use satoru::utils::error::UtilsError;
use starknet::{account::Call, call_contract_syscall, SyscallResultTrait};

/// Receives and executes a batch of function calls on this contract.
/// # Arguments
/// * `data` - calls to execute.
fn multicall(mut data: Array<Call>) -> Array<Span<felt252>> {
    assert(data.len() > 0, UtilsError::NO_DATA_FOR_MULTICALL);
    let mut result = ArrayTrait::new();
    loop {
        match data.pop_front() {
            Option::Some(call) => {
                let mut res = call_contract_syscall(
                    address: call.to,
                    entry_point_selector: call.selector,
                    calldata: call.calldata.span()
                )
                    .unwrap_syscall();
                result.append(res);
            },
            Option::None => {
                break; // Can't break result; because of 'variable was previously moved'
            },
        };
    };
    result
}

