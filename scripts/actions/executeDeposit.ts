import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString, ec } from "starknet"
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
    const account0 = new Account(provider, account0Address!, privateKey0!)
    // const marketToken = "0x122cd6989d2429f580a0bff5e70cdb84b2bff4f8d19cee6b30a15d08c447e85"
    // const eth = "0x369c220f2a4699495bfe73ffe8a522f1bf1570c903c0d8fcf3767a252f7ae9a"
    // const usdc = "0x6f82b80bfead3a249ee4352b27075dfa327de91e8e6df9755eb4f31de406d98"
    console.log("Deploying with Account: " + account0Address)
    console.log("RPC: " + providerUrl)

    const depositHandlerAddress = "0x7d82433606ef19a1f8a2d7e9be45c02677e214b83d2a079c930bc379ee246ef";
    // const dataStoreAddress = "0x12b79d662e668a585b978c8fa80c33c269297ee14eba2383829ef1890a6e201";
    const compiledDepositHandlerSierra = json.parse(fs.readFileSync("./target/dev/satoru_DepositHandler.contract_class.json").toString( "ascii"))

    // const compiledDataStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_DataStore.contract_class.json").toString( "ascii"))
    // const dataStoreContract = new Contract(compiledDataStoreSierra.abi, dataStoreAddress, provider)
    // dataStoreContract.connect(account0);

    // dataStoreContract.connect(account0);
    // const dataCall5 = dataStoreContract.populate(
    //     "set_u256",
    //     [
    //         await dataStoreContract.get_pool_amount_key(marketToken, eth),
    //         50000000000000000000000000000n
    //     ]
    // )
    // const setAddressTx5 = await dataStoreContract.set_u256(dataCall5.calldata)
    // await provider.waitForTransaction(setAddressTx5.transaction_hash)

    // const dataCall6 = dataStoreContract.populate(
    //     "set_u256",
    //     [
    //         await dataStoreContract.get_pool_amount_key(marketToken, usdc),
    //         50000000000000000000000000000n
    //     ]
    // )
    // const setAddressTx6 = await dataStoreContract.set_u256(dataCall6.calldata)
    // await provider.waitForTransaction(setAddressTx6.transaction_hash)

    const depositHandlerContract = new Contract(compiledDepositHandlerSierra.abi, depositHandlerAddress, provider);

    const setPricesParams = {
        signer_info: 1,
        tokens: ["0x369c220f2a4699495bfe73ffe8a522f1bf1570c903c0d8fcf3767a252f7ae9a", "0x6f82b80bfead3a249ee4352b27075dfa327de91e8e6df9755eb4f31de406d98"],
        compacted_min_oracle_block_numbers: [8189, 8189],
        compacted_max_oracle_block_numbers: [81189, 81189],
        compacted_oracle_timestamps: [171119803, 10],
        compacted_decimals: [1, 1],
        compacted_min_prices: [2147483648010000], // 500000, 10000 compacted
        compacted_min_prices_indexes: [0],
        compacted_max_prices: [3060, 1], // 500000, 10000 compacted
        compacted_max_prices_indexes: [0],
        signatures: [
            ['signatures1', 'signatures2'], ['signatures1', 'signatures2']
        ],
        price_feed_tokens: []
    };

    depositHandlerContract.connect(account0)
    let key = "0x4d65a6c15f989ebcccc12f7ad07d69e0d2e3caede2bd40de1f2eb5898c50c17";
    const executeOrderCall = depositHandlerContract.populate("execute_deposit", [
        key,
        setPricesParams
    ])
    let tx = await depositHandlerContract.execute_deposit(executeOrderCall.calldata)

}

deploy()