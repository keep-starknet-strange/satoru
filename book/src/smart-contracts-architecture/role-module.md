# Role Module

The Role Module is crucial for managing who has access to what, controlling the assignment and removal of roles to different accounts in the system.

It consists of the following smart contracts and Cairo library files:

- [RoleStore](https://github.com/keep-starknet-strange/satoru/blob/main/src/role/role_store.cairo): The central contract of the module, focusing on storing roles and managing access control across the protocol.
- [role.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/role/role.cairo): Holds the definitions of different roles existing within the protocol.
- [error.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/role/error.cairo): Encompasses the error codes specific to this module.
- [role_module.cairo](https://github.com/keep-starknet-strange/satoru/blob/main/src/role/role_module.cairo): Implements the `RoleModule` contract interface, focusing on role validation and interaction with `RoleStore`.

### Features of role_module.cairo

- **Initialization**: It initializes the role store with the provided address.
- **Role Validation Functions**: Provides a set of functions like `only_timelock_admin`, `only_controller`, etc., each validating a specific role in the protocol.
- **Role Verification**: Utilizes `RoleStore` to verify if an account holds the specified role, ensuring secure and accurate role-based access control.
- **Access Restriction**: Employs role validation to restrict access to specific functions, maintaining the protocol's security and integrity.

## Roles Defined

The following roles are defined within the protocol:

- `ADMIN`
- `TIMELOCK_ADMIN`
- `TIMELOCK_MULTISIG`
- `CONFIG_KEEPER`
- `CONTROLLER`
- `ROUTER_PLUGIN`
- `MARKET_KEEPER`
- `FEE_KEEPER`
- `ORDER_KEEPER`
- `FROZEN_ORDER_KEEPER`
- `PRICING_KEEPER`
- `LIQUIDATION_KEEPER`
- `ADL_KEEPER`

These roles are represented by constants defined in `role.cairo`, and they are essential in maintaining the integrity and functionality of the system by granting specific permissions to different accounts.

## Functions

### `has_role`
Determines whether a given account holds a specified role.
### `grant_role`
Assigns a particular role to a specific account.
### `revoke_role`
Removes a designated role from a given account.
### `assert_only_role`
Ensures that a specified account holds only a particular role, reverting if the condition is not met.
### `get_role_count`
Returns the number of roles stored within the contract.
### `get_roles`
Retrieves the keys of roles stored within the contract, based on the provided range of indices.
### `get_role_member_count`
Returns the number of members assigned to a specified role.
### `get_role_members`
Retrieves the members of a specified role, based on the given range of indices.

## Events

### `RoleGranted`
Emitted when a role is assigned to an account.
### `RoleRevoked`
Emitted when a role is removed from an account.

## Errors

### `UNAUTHORIZED_ACCESS`
Indicates that an operation was attempted by an account lacking the necessary role.

## Example

```cairo
// Granting a role to an account
RoleStore.grant_role(account: ContractAddress, role_key: 'ADMIN')