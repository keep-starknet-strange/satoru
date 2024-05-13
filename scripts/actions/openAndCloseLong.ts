import { Account, Contract, json, Calldata, CallData, RpcProvider, shortString, uint256, CairoCustomEnum, ec } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'

dotenv.config()

async function create_market() {

    // connect provider
    const providerUrl = process.env.PROVIDER_URL
    const provider = new RpcProvider({ nodeUrl: providerUrl! })
    // connect your account. To adapt to your own account :
    const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
    const account0Address: string = process.env.ACCOUNT_PUBLIC as string
    const marketTokenAddress = "0x69cfad927e7e4ef53261ad9a4630631ff8404746720ce3c73368de8291c4c4d"
    const eth: string = "0x376bbceb1a044263cba28211fdcaee4e234ebf0c012521e1b258684bbc44949"
    const usdc: string = "0x42a9a03ceb10ca07d3f598a627c414fe218b1138a78e3da6ce1675680cf95f2"

    const account0 = new Account(provider, account0Address!, privateKey0!)
    console.log("Interacting with Account: " + account0Address)

    const compiledOrderHandlerSierra = json.parse(fs.readFileSync( "./target/dev/satoru_OrderHandler.contract_class.json").toString( "ascii"))

    const orderHandlerContract = new Contract(compiledOrderHandlerSierra.abi, process.env.ORDER_HANDLER as string, provider);
    const compiledERC20Sierra = json.parse(fs.readFileSync( "./target/dev/satoru_ERC20.contract_class.json").toString( "ascii"))
    
    const ethContract = new Contract(compiledERC20Sierra.abi, eth as string, provider)
    ethContract.connect(account0)
    const transferCall = ethContract.populate("transfer", [process.env.ORDER_VAULT as string, uint256.bnToUint256(1000000000000000000n)])
    const transferTx = await ethContract.transfer(transferCall.calldata)
    await provider.waitForTransaction(transferTx.transaction_hash)

    const compiledRoleStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_RoleStore.contract_class.json").toString( "ascii"))
    const roleStoreContract = new Contract(compiledRoleStoreSierra.abi, process.env.ROLE_STORE as string, provider)
    roleStoreContract.connect(account0);

    const roleCall4 = roleStoreContract.populate("grant_role", [process.env.ORDER_UTILS as string, shortString.encodeShortString("CONTROLLER")])
    const grant_role_tx4 = await roleStoreContract.grant_role(roleCall4.calldata)
    await provider.waitForTransaction(grant_role_tx4.transaction_hash)

    orderHandlerContract.connect(account0)
    const createOrderParams = {
        receiver: account0.address,
        callback_contract: 0,
        ui_fee_receiver: 0,
        market: marketTokenAddress,
        initial_collateral_token: eth,
        swap_path: [],
        size_delta_usd: uint256.bnToUint256(10000000000000000000000n),
        initial_collateral_delta_amount: uint256.bnToUint256(2000000000000000000n),
        trigger_price: uint256.bnToUint256(5000),
        acceptable_price: uint256.bnToUint256(5500),
        execution_fee: uint256.bnToUint256(0),
        callback_gas_limit: uint256.bnToUint256(0),
        min_output_amount: uint256.bnToUint256(0),
        order_type: new CairoCustomEnum({ MarketIncrease: {} }),
        decrease_position_swap_type: new CairoCustomEnum({ NoSwap: {} }),
        is_long: 1,
        referral_code: 0
    };
    const createOrderCall = orderHandlerContract.populate("create_order", [
        account0.address,
        createOrderParams
    ])
    const createOrderTx = await orderHandlerContract.create_order(createOrderCall.calldata)
    await provider.waitForTransaction(createOrderTx.transaction_hash)
    console.log("Order created.")
}

create_market()