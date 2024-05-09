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
    const marketToken = "0x69cfad927e7e4ef53261ad9a4630631ff8404746720ce3c73368de8291c4c4d"
    const eth = "0x376bbceb1a044263cba28211fdcaee4e234ebf0c012521e1b258684bbc44949"
    const usdc = "0x42a9a03ceb10ca07d3f598a627c414fe218b1138a78e3da6ce1675680cf95f2"
    console.log("Deploying with Account: " + account0Address)
    console.log("RPC: " + providerUrl)

    const depositHandlerAddress = process.env.DEPOSIT_HANDLER as string
    const compiledDepositHandlerSierra = json.parse(fs.readFileSync("./target/dev/satoru_DepositHandler.contract_class.json").toString( "ascii"))

    const compiledDataStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_DataStore.contract_class.json").toString( "ascii"))
    const dataStoreContract = new Contract(compiledDataStoreSierra.abi, process.env.DATA_STORE as string, provider)
    dataStoreContract.connect(account0);

    dataStoreContract.connect(account0);
    const dataCall5 = dataStoreContract.populate(
        "set_u256",
        [
            await dataStoreContract.get_max_pool_amount_key(marketToken, eth),
            2500000000000000000000000000000000000000000000n
        ]
    )
    const setAddressTx5 = await dataStoreContract.set_u256(dataCall5.calldata)
    await provider.waitForTransaction(setAddressTx5.transaction_hash)

    const dataCall6 = dataStoreContract.populate(
        "set_u256",
        [
            await dataStoreContract.get_max_pool_amount_key(marketToken, usdc),
            2500000000000000000000000000000000000000000000n
        ]
    )
    const setAddressTx6 = await dataStoreContract.set_u256(dataCall6.calldata)
    await provider.waitForTransaction(setAddressTx6.transaction_hash)

    const depositHandlerContract = new Contract(compiledDepositHandlerSierra.abi, depositHandlerAddress, provider);

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

    depositHandlerContract.connect(account0)
    let key = "0x6dd0864e0640b9fe1c5a8afc54e569bad9992e3fd55e422dc09dc6e95572a17";
    const executeOrderCall = depositHandlerContract.populate("execute_deposit", [
        key,
        setPricesParams
    ])
    let tx = await depositHandlerContract.execute_deposit(executeOrderCall.calldata)

}

deploy()