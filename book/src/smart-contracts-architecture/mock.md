# Mock Module

The Mock Module is essential for testing environments and testnets. It holds mocked implementations of contracts.

## Cairo Library Files
- [error.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/mock/error.cairo): Contains error codes pertinent to the Mock Module.

## Smart Contracts

### [ReferralStorage.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/mock/referral_stoage.cairo)
- **Key Functions:**
  - Manages Set and Get functions for handling referral-related data and operations.
  - Allows the registration and management of referral codes, setting of trader and referrer tiers, and handling of referral-related data with robust error handling mechanisms.

- **Interface: IReferralStorage<TContractState>**
  - **Functions:**
    1. `initialize`: Initializes the contract state with the given event_emitter_address.
    2. `only_handler`: Ensures that the caller is a handler.
    3. `set_handler`: Sets an address as a handler, controlling the active status of handlers.
    4. `set_referrer_discount_share`: Sets the trader discount share for an affiliate.
    5. `set_trader_referral_code_by_user`: Sets the referral code for a trader.
    6. `register_code`: Registers a referral code.
    7. `set_code_owner`: Sets the owner of a referral code.
    8. `code_owners`: Gets the owner of a referral code.
    9. `trader_referral_codes`: Gets the referral code of a trader.
    10. `referrer_discount_shares`: Gets the trader discount share for an affiliate.
    11. `referrer_tiers`: Gets the tier level of an affiliate.
    12. `get_trader_referral_info`: Gets the referral info for a trader.
    13. `set_trader_referral_code`: Sets the referral code for a trader.
    14. `set_tier`: Sets the values for a tier.
    15. `set_referrer_tier`: Sets the tier for an affiliate.
    16. `gov_set_code_owner`: Sets the owner for a referral code by the governor.
    17. `tiers`: Gets the tier values for a tier level.

### [Governable.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/referral/governable.cairo)
- **Key Functions:**
  - Provides functionalities to manage governance-related operations and states.
  - Ensures that only authorized entities can perform certain operations, enhancing the security of the contract.

- **Interface: IGovernable<TContractState>**
  - **Functions:**
    1. `initialize`: Initializes the contract state with the given event_emitter_address.
    2. `only_gov`: Ensures that the caller has governance permissions; triggers panic if unauthorized.
    3. `transfer_ownership`: Initiates the transfer of contract governance to a new address; only the current governance address can call this.
    4. `accept_ownership`: Accepts the governance of the contract; only the pending governance address can call this.

## Structures and Types
### `ReferralTier`
  - Represents a referral tier, holding information such as total rebate and discount share for the tier.

### `ContractState`
  - Holds the contract state, facilitating the storage and retrieval of state information like event emitters, governance, and handler status.

## Errors
- The module defines a `MockError` to handle mock-specific errors with constants representing specific error cases in the Mock module, such as `INVALID_TOTAL_REBATE`, `INVALID_DISCOUNT_SHARE`, and `FORBIDDEN`.

## Usage Example
```cairo
// Example of registering a referral code
let code: felt252 = /* ... */;
referral_storage::register_code(code);