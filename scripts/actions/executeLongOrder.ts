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
    

    const compiledRoleStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_RoleStore.contract_class.json").toString( "ascii"))
    const roleStoreContract = new Contract(compiledRoleStoreSierra.abi, process.env.ROLE_STORE as string, provider)
    roleStoreContract.connect(account0);

    console.log("Granting roles...")
    const roleCall2 = roleStoreContract.populate("grant_role", [account0Address as string, shortString.encodeShortString("ORDER_KEEPER")])
    const grant_role_tx2 = await roleStoreContract.grant_role(roleCall2.calldata)
    await provider.waitForTransaction(grant_role_tx2.transaction_hash)
    const roleCall3 = roleStoreContract.populate("grant_role", [process.env.INCREASE_ORDER_UTILS as string, shortString.encodeShortString("CONTROLLER")])
    const grant_role_tx3 = await roleStoreContract.grant_role(roleCall3.calldata)
    await provider.waitForTransaction(grant_role_tx3.transaction_hash)

    console.log("Roles granted.")

    const compiledDataStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_DataStore.contract_class.json").toString( "ascii"))
    const dataStoreContract = new Contract(compiledDataStoreSierra.abi, process.env.DATA_STORE as string, provider)
    dataStoreContract.connect(account0)
    const dataCall8 = dataStoreContract.populate(
        "set_u256",
        [
            await dataStoreContract.get_max_open_interest_key(
                marketTokenAddress,
                true
            ),
            1000000000000000000000000000000000000000000000000000n
        ]
    )
    const setAddressTx8 = await dataStoreContract.set_u256(dataCall8.calldata)
    await provider.waitForTransaction(setAddressTx8.transaction_hash)


    
    orderHandlerContract.connect(account0)
    const setPricesParams = {
        signer_info: 1,
        tokens: ["0x4b76dd1e0a8d0bc196aa75d7a85a6cc81cf7bc8e0cd2e5061237477eb2c109a", "0x6b6f734dca33adeb315c1ff399886b577bc3f2b51165af9277ca0096847d267"],
        compacted_min_oracle_block_numbers: [63970, 63970],
        compacted_max_oracle_block_numbers: [64901, 64901],
        compacted_oracle_timestamps: [171119803, 10],
        compacted_decimals: [1, 1],
        compacted_min_prices: [2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: [0],
        compacted_max_prices: [2147483648010000], // 500000, 10000 compacted
        compacted_max_prices_indexes: [0],
        signatures: [
            ['signatures1', 'signatures2'], ['signatures1', 'signatures2']
        ],
        price_feed_tokens: []
    };

    orderHandlerContract.connect(account0)
    let key = "0x34d4d9d4e2539866c7c7a5fbe5f7d142afaa55af10603cb1a384d9d31e8280a";
    const executeOrderCall = orderHandlerContract.populate("execute_order_keeper", [
        key,
        setPricesParams,
        account0Address
    ])
    let tx = await orderHandlerContract.execute_order_keeper(executeOrderCall.calldata)
}

create_market()