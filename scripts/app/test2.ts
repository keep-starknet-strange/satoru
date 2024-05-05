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
    const eth: string = "0x75acffcc1c3661fe1cfbb6d2c444355ef01e85a40e65962a4d9a2ac38903934"
    const usdc: string = "0x70d22d4962de09d9ec0a590e9ff33a496425277235890575457f9582d837964"
    const account0 = new Account(provider, account0Address!, privateKey0!)
    const marketTokenAddress = "0x4b3bd2fe7f3dd02a6a143a3040ede80048388e0cf1c20dc748d6a6d6fa93069"
    console.log("Deploying with Account: " + account0Address)
    console.log("RPC: " + providerUrl)

    const dataStoreAddress = process.env.DATA_STORE as string
    const compiledDataStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_DataStore.contract_class.json").toString( "ascii"))
    const dataStoreContract = new Contract(compiledDataStoreSierra.abi, dataStoreAddress, provider)
    dataStoreContract.connect(account0);

    console.log(await dataStoreContract.get_u256(await dataStoreContract.get_pool_amount_key(marketTokenAddress, usdc)))
    console.log(await dataStoreContract.get_u256(await dataStoreContract.get_pool_amount_key(marketTokenAddress, eth)))
    const hashUSDC = await dataStoreContract.get_max_pool_amount_key(marketTokenAddress, usdc)
    // const dataCall4 = dataStoreContract.populate(
    //     "set_u256",
    //     [hashETH, 5000000000000000000000000000000000000000000n])
    // const setAddressTx4 = await dataStoreContract.set_u256(dataCall4.calldata)
    // await provider.waitForTransaction(setAddressTx4.transaction_hash)

    // dataStoreContract.connect(account0);
    // const dataCall5 = dataStoreContract.populate(
    //     "set_u256",
    //     [hashUSDC, 2500000000000000000000000000000000000000000000n])
    // const setAddressTx5 = await dataStoreContract.set_u256(dataCall5.calldata)
    // await provider.waitForTransaction(setAddressTx5.transaction_hash)
}

deploy()