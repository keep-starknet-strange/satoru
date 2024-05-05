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
    const marketTokenAddress = "0x68ad9440759f0bd0367e407d53b5e5c32203590f12d54ed8968f48fee0cf636"
    const eth: string = "0x3fa46510b749925fb3fa02e98195909683eaee8d4c982cc647cd98a7f160905"
    const usdc: string = "0x636d15cd4dfe130c744282f86496077e089cb9dc96ccc37bf0d85ea358a5760"

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