import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString, ec, uint256 } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'

dotenv.config()

async function deploy() {
    // connect provider
    const providerUrl = process.env.PROVIDER_URL
    const provider = new RpcProvider({ nodeUrl: providerUrl! })
    // connect your account. To adapt to your own account :
    const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
    const account0Address: string = process.env.ACCOUNT_PUBLIC as string
    const eth: string = "0x3fa46510b749925fb3fa02e98195909683eaee8d4c982cc647cd98a7f160905"
    const usdc: string = "0x636d15cd4dfe130c744282f86496077e089cb9dc96ccc37bf0d85ea358a5760"
    const account0 = new Account(provider, account0Address!, privateKey0!)
    const marketTokenAddress = "0x68ad9440759f0bd0367e407d53b5e5c32203590f12d54ed8968f48fee0cf636"
    console.log("Deploying with Account: " + account0Address)
    console.log("RPC: " + providerUrl)

    const dataStoreAddress = process.env.DATA_STORE as string
    const compiledDataStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_DataStore.contract_class.json").toString( "ascii"))
    const dataStoreContract = new Contract(compiledDataStoreSierra.abi, dataStoreAddress, provider)
    dataStoreContract.connect(account0);

    // console.log(await dataStoreContract.get_u256(await dataStoreContract.get_pool_amount_key(marketTokenAddress, usdc)))
    // console.log(await dataStoreContract.get_u256(await dataStoreContract.get_pool_amount_key(marketTokenAddress, eth)))
    // const hashUSDC = await dataStoreContract.get_max_pool_amount_key(marketTokenAddress, usdc)
    // const dataCall4 = dataStoreContract.populate(
    //     "set_u256",
    //     [await dataStoreContract.get_pool_amount_key(marketTokenAddress, usdc), 25000000000000000000000000n]
    // )
    // const setAddressTx4 = await dataStoreContract.set_u256(dataCall4.calldata)
    // await provider.waitForTransaction(setAddressTx4.transaction_hash)

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

    // const dataCall5 = dataStoreContract.populate(
    //     "set_u256",
    //     [await dataStoreContract.get_pool_amount_key(marketTokenAddress, eth), 50000000000000000001000000n]
    // )
    // const setAddressTx5 = await dataStoreContract.set_u256(dataCall5.calldata)
    // await provider.waitForTransaction(setAddressTx5.transaction_hash)

    // const compiledRoleStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_RoleStore.contract_class.json").toString( "ascii"))
    // const roleStoreContract = new Contract(compiledRoleStoreSierra.abi, process.env.ROLE_STORE as string, provider)
    // roleStoreContract.connect(account0);

    // const roleCall4 = roleStoreContract.populate("grant_role", ["0x058404f75600c0fc2dfbc074e437c14fd95881145265b96714727b358070946a" as string, shortString.encodeShortString("CONTROLLER")])
    // const grant_role_tx4 = await roleStoreContract.grant_role(roleCall4.calldata)
    // await provider.waitForTransaction(grant_role_tx4.transaction_hash)

    // const compiledOracleSierra = json.parse(fs.readFileSync( "./target/dev/satoru_Oracle.contract_class.json").toString( "ascii"))

    // const oracleContract = new Contract(compiledOracleSierra.abi, process.env.ORACLE as string, provider);
    // oracleContract.connect(account0);
    // const setPrimaryPriceCall1 = oracleContract.populate("set_primary_price", [eth, uint256.bnToUint256(7000n)])
    // const setPrimaryPriceTx1 = await oracleContract.set_primary_price(setPrimaryPriceCall1.calldata);
    // await provider.waitForTransaction(setPrimaryPriceTx1.transaction_hash)


}

deploy()