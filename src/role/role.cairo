//! Define the roles that an account can have.
//! Notes:
//! - Consider using a hash of the role name as the role key. The problem is that right now only literal constants are supported.

const ROLE_ADMIN: felt252 = 'ADMIN';

const TIMELOCK_ADMIN: felt252 = 'TIMELOCK_ADMIN';

const TIMELOCK_MULTISIG: felt252 = 'TIMELOCK_MULTISIG';

const CONFIG_KEEPER: felt252 = 'CONFIG_KEEPER';

const CONTROLLER: felt252 = 'CONTROLLER';

const ROUTER_PLUGIN: felt252 = 'ROUTER_PLUGIN';

const MARKET_KEEPER: felt252 = 'MARKET_KEEPER';

const FEE_KEEPER: felt252 = 'FEE_KEEPER';

const ORDER_KEEPER: felt252 = 'ORDER_KEEPER';

const FROZEN_ORDER_KEEPER: felt252 = 'FROZEN_ORDER_KEEPER';

const PRICING_KEEPER: felt252 = 'PRICING_KEEPER';

const LIQUIDATION_KEEPER: felt252 = 'LIQUIDATION_KEEPER';

const ADL_KEEPER: felt252 = 'ADL_KEEPER';

