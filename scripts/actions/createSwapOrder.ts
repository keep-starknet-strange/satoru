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
    const marketTokenAddress = "0x4b3bd2fe7f3dd02a6a143a3040ede80048388e0cf1c20dc748d6a6d6fa93069"
    const eth: string = "0x75acffcc1c3661fe1cfbb6d2c444355ef01e85a40e65962a4d9a2ac38903934"
    const usdc: string = "0x70d22d4962de09d9ec0a590e9ff33a496425277235890575457f9582d837964"

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

    console.log("Granting roles...")
    const roleCall2 = roleStoreContract.populate("grant_role", ["0x05fc5a52d7141a90b79663eb22b80f7a13ec1fce7232bc8c4a03528f552cb02b" as string, shortString.encodeShortString("CONTROLLER")])
    const grant_role_tx2 = await roleStoreContract.grant_role(roleCall2.calldata)
    await provider.waitForTransaction(grant_role_tx2.transaction_hash)
    console.log("Roles granted.")

    orderHandlerContract.connect(account0)
    const createOrderParams = {
        receiver: account0.address,
        callback_contract: 0,
        ui_fee_receiver: 0,
        market: 0,
        initial_collateral_token: eth,
        swap_path: [marketTokenAddress],
        size_delta_usd: uint256.bnToUint256(5000000000000000000000n),
        initial_collateral_delta_amount: uint256.bnToUint256(1000000000000000000n),
        trigger_price: uint256.bnToUint256(0),
        acceptable_price: uint256.bnToUint256(0),
        execution_fee: uint256.bnToUint256(0),
        callback_gas_limit: uint256.bnToUint256(0),
        min_output_amount: uint256.bnToUint256(0),
        order_type: new CairoCustomEnum({ MarketSwap: {} }),
        decrease_position_swap_type: new CairoCustomEnum({ NoSwap: {} }),
        is_long: 0,
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