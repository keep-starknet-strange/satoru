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
    console.log("Deploying with Account: " + account0Address)
    console.log("RPC: " + providerUrl)


    const compiledReaderCasm = json.parse(fs.readFileSync( "./target/dev/satoru_ReferralStorage.compiled_contract_class.json").toString( "ascii"))
    const compiledReferralStorageSierra = json.parse(fs.readFileSync("./target/dev/satoru_ReferralStorage.contract_class.json").toString( "ascii"))
    const referralStorageCallData: CallData = new CallData(compiledReferralStorageSierra.abi)
    const referralStorageConstructor: Calldata = referralStorageCallData.compile("constructor", {
        event_emitter_address: process.env.EVENT_EMITTER as string
    })
    const deployReferralStorageResponse = await account0.declareAndDeploy({
        contract: compiledReferralStorageSierra,
        casm: compiledReaderCasm ,
        constructorCalldata: referralStorageConstructor,
    })
    console.log("Reader Deployed: " + deployReferralStorageResponse.deploy.contract_address)


}

deploy()