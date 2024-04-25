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

    console.log("Deploying IncreaseOrderUtils")
    const compiledIncreaseOrderUtilsCasm = json.parse(fs.readFileSync( "./target/dev/satoru_IncreaseOrderUtils.compiled_contract_class.json").toString( "ascii"))
    const compiledIncreaseOrderUtilsSierra = json.parse(fs.readFileSync( "./target/dev/satoru_IncreaseOrderUtils.contract_class.json").toString( "ascii"))
    const increaseOrderUtilsCallData: CallData = new CallData(compiledIncreaseOrderUtilsSierra.abi)
    const increaseOrderUtilsConstructor: Calldata = increaseOrderUtilsCallData.compile("constructor", {})
    const deployIncreaseOrderUtilsResponse = await account0.declareAndDeploy({
        contract: compiledIncreaseOrderUtilsSierra,
        casm: compiledIncreaseOrderUtilsCasm,
    })

    console.log("Deploying DecreaseOrderUtils")
    const compiledDecreaseOrderUtilsCasm = json.parse(fs.readFileSync( "./target/dev/satoru_DecreaseOrderUtils.compiled_contract_class.json").toString( "ascii"))
    const compiledDecreaseOrderUtilsSierra = json.parse(fs.readFileSync( "./target/dev/satoru_DecreaseOrderUtils.contract_class.json").toString( "ascii"))
    const decreaseOrderUtilsCallData: CallData = new CallData(compiledDecreaseOrderUtilsSierra.abi)
    const decreaseOrderUtilsConstructor: Calldata = decreaseOrderUtilsCallData.compile("constructor", {})
    const deployDecreaseOrderUtilsResponse = await account0.declareAndDeploy({
        contract: compiledDecreaseOrderUtilsSierra,
        casm: compiledDecreaseOrderUtilsCasm,
    })

    console.log("Deploying SwapOrderUtils")
    const compiledSwapOrderUtilsCasm = json.parse(fs.readFileSync( "./target/dev/satoru_SwapOrderUtils.compiled_contract_class.json").toString( "ascii"))
    const compiledSwapOrderUtilsSierra = json.parse(fs.readFileSync( "./target/dev/satoru_SwapOrderUtils.contract_class.json").toString( "ascii"))
    const swapOrderUtilsCallData: CallData = new CallData(compiledSwapOrderUtilsSierra.abi)
    const swapOrderUtilsConstructor: Calldata = swapOrderUtilsCallData.compile("constructor", {})
    const deploySwapOrderUtilsResponse = await account0.declareAndDeploy({
        contract: compiledSwapOrderUtilsSierra,
        casm: compiledSwapOrderUtilsCasm,
    })

    console.log("Deploying OrderUtils")
    const compiledOrderUtilsCasm = json.parse(fs.readFileSync( "./target/dev/satoru_OrderUtils.compiled_contract_class.json").toString( "ascii"))
    const compiledOrderUtilsSierra = json.parse(fs.readFileSync( "./target/dev/satoru_OrderUtils.contract_class.json").toString( "ascii"))
    const orderUtilsCallData: CallData = new CallData(compiledOrderUtilsSierra.abi)
    const orderUtilsConstructor: Calldata = orderUtilsCallData.compile("constructor", {
        increase_order_address: deployIncreaseOrderUtilsResponse.deploy.contract_address,
        decrease_order_address: deployDecreaseOrderUtilsResponse.deploy.contract_address,
        swap_order_address: deploySwapOrderUtilsResponse.deploy.contract_address
    })
    const deployOrderUtilsResponse = await account0.declareAndDeploy({
        contract: compiledOrderUtilsSierra,
        casm: compiledOrderUtilsCasm,
        constructorCalldata: orderUtilsConstructor
    })


    const compiledOrderHandlerCasm = json.parse(fs.readFileSync( "./target/dev/satoru_OrderHandler.compiled_contract_class.json").toString( "ascii"))
    const compiledOrderHandlerSierra = json.parse(fs.readFileSync( "./target/dev/satoru_OrderHandler.contract_class.json").toString( "ascii"))
    const orderHandlerCallData: CallData = new CallData(compiledOrderHandlerSierra.abi)
    const orderHandlerConstructor: Calldata = orderHandlerCallData.compile("constructor", {
        data_store_address: "0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691",
        role_store_address: "0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691",
        event_emitter_address: "0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691",
        order_vault_address: "0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691",
        oracle_address: "0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691",
        swap_handler_address: "0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691",
        referral_storage_address: "0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691",
        order_utils_address: "0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691"
    })
    const deployOrderHandlerResponse = await account0.declareAndDeploy(
        {
            contract: compiledOrderHandlerSierra,
            casm: compiledOrderHandlerCasm ,
            constructorCalldata: orderHandlerConstructor,
        },
        //{ maxFee: 1485894175412100 }
    )
    console.log("OrderHandler Deployed at: " + deployOrderHandlerResponse.deploy.contract_address)
}

deploy()