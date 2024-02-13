import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString } from "starknet"
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
    
    console.log("Deploying RoleStore...")
    const compiledRoleStoreCasm = json.parse(fs.readFileSync( "./target/dev/satoru_RoleStore.compiled_contract_class.json").toString( "ascii"))
    const compiledRoleStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_RoleStore.contract_class.json").toString( "ascii"))
    const roleStoreCallData: CallData = new CallData(compiledRoleStoreSierra.abi)
    const roleStoreConstructor: Calldata = roleStoreCallData.compile("constructor", { admin: account0.address })
    const deployRoleStoreResponse = await account0.declareAndDeploy({
        contract: compiledRoleStoreSierra,
        casm: compiledRoleStoreCasm,
        constructorCalldata: roleStoreConstructor
    })
    console.log("RoleStore Deployed.")

    console.log("Deploying DataStore...")
    const compiledDataStoreCasm = json.parse(fs.readFileSync( "./target/dev/satoru_DataStore.compiled_contract_class.json").toString( "ascii"))
    const compiledDataStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_DataStore.contract_class.json").toString( "ascii"))
    const dataStoreCallData: CallData = new CallData(compiledDataStoreSierra.abi)
    const dataStoreConstructor: Calldata = dataStoreCallData.compile("constructor", {
        role_store_address: deployRoleStoreResponse.deploy.contract_address
    })
    const deployDataStoreResponse = await account0.declareAndDeploy({
        contract: compiledDataStoreSierra,
        casm: compiledDataStoreCasm ,
        constructorCalldata: dataStoreConstructor,
    })
    console.log("DataStore Deployed.")
    
    console.log("Granting Controller role...")
    const roleStoreContract = new Contract(compiledRoleStoreSierra.abi, deployRoleStoreResponse.deploy.contract_address, provider)
    roleStoreContract.connect(account0);
    const roleCall = roleStoreContract.populate("grant_role", [account0.address, shortString.encodeShortString("CONTROLLER")])
    const grant_role_tx = await roleStoreContract.grant_role(roleCall.calldata)
    await provider.waitForTransaction(grant_role_tx.transaction_hash)
    console.log("Controller role granted.")

    console.log("Deploying EventEmitter...")
    const compiledEventEmitterCasm = json.parse(fs.readFileSync( "./target/dev/satoru_EventEmitter.compiled_contract_class.json").toString( "ascii"))
    const compiledEventEmitterSierra = json.parse(fs.readFileSync( "./target/dev/satoru_EventEmitter.contract_class.json").toString( "ascii"))
    const eventEmitterCallData: CallData = new CallData(compiledEventEmitterSierra.abi)
    const eventEmitterConstructor: Calldata = eventEmitterCallData.compile("constructor", {})
    const deployEventEmitterResponse = await account0.declareAndDeploy({
        contract: compiledEventEmitterSierra,
        casm: compiledEventEmitterCasm ,
        constructorCalldata: eventEmitterConstructor,
    })
    console.log("EventEmitter Deployed.")

    console.log("Deploying OracleStore...")
    const compiledOracleStoreCasm = json.parse(fs.readFileSync( "./target/dev/satoru_OracleStore.compiled_contract_class.json").toString( "ascii"))
    const compiledOracleStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_OracleStore.contract_class.json").toString( "ascii"))
    const oracleStoreCallData: CallData = new CallData(compiledOracleStoreSierra.abi)
    const oracleStoreConstructor: Calldata = oracleStoreCallData.compile("constructor", {
        role_store_address: deployRoleStoreResponse.deploy.contract_address,
        event_emitter_address: deployEventEmitterResponse.deploy.contract_address
    })
    const deployOracleStoreResponse = await account0.declareAndDeploy({
        contract: compiledOracleStoreSierra,
        casm: compiledOracleStoreCasm ,
        constructorCalldata: oracleStoreConstructor,
    })
    console.log("OracleStore Deployed.")

    console.log("Deploying Oracle...")
    const compiledOracleCasm = json.parse(fs.readFileSync( "./target/dev/satoru_Oracle.compiled_contract_class.json").toString( "ascii"))
    const compiledOracleSierra = json.parse(fs.readFileSync( "./target/dev/satoru_Oracle.contract_class.json").toString( "ascii"))
    const oracleCallData: CallData = new CallData(compiledOracleSierra.abi)
    const oracleConstructor: Calldata = oracleCallData.compile("constructor", {
        role_store_address: deployRoleStoreResponse.deploy.contract_address,
        oracle_store_address: deployOracleStoreResponse.deploy.contract_address,
        pragma_address: account0.address
    })
    const deployOracleResponse = await account0.declareAndDeploy({
        contract: compiledOracleSierra,
        casm: compiledOracleCasm ,
        constructorCalldata: oracleConstructor,
    })
    console.log("Oracle Deployed.")

    console.log("Deploying OrderVault...")
    const compiledOrderVaultCasm = json.parse(fs.readFileSync( "./target/dev/satoru_OrderVault.compiled_contract_class.json").toString( "ascii"))
    const compiledOrderVaultSierra = json.parse(fs.readFileSync( "./target/dev/satoru_OrderVault.contract_class.json").toString( "ascii"))
    const orderVaultCallData: CallData = new CallData(compiledOrderVaultSierra.abi)
    const orderVaultConstructor: Calldata = orderVaultCallData.compile("constructor", {
        data_store_address: deployDataStoreResponse.deploy.contract_address,
        role_store_address: deployRoleStoreResponse.deploy.contract_address,
    })
    const deployOrderVaultResponse = await account0.declareAndDeploy({
        contract: compiledOrderVaultSierra,
        casm: compiledOrderVaultCasm ,
        constructorCalldata: orderVaultConstructor,
    })
    console.log("OrderVault Deployed.")

    console.log("Deploying SwapHandler...")
    const compiledSwapHandlerCasm = json.parse(fs.readFileSync( "./target/dev/satoru_SwapHandler.compiled_contract_class.json").toString( "ascii"))
    const compiledSwapHandlerSierra = json.parse(fs.readFileSync( "./target/dev/satoru_SwapHandler.contract_class.json").toString( "ascii"))
    const swapHandlerCallData: CallData = new CallData(compiledSwapHandlerSierra.abi)
    const swapHandlerConstructor: Calldata = swapHandlerCallData.compile("constructor", {
        role_store_address: deployRoleStoreResponse.deploy.contract_address,
    })
    const deploySwapHandlerResponse = await account0.declareAndDeploy({
        contract: compiledSwapHandlerSierra,
        casm: compiledSwapHandlerCasm ,
        constructorCalldata: swapHandlerConstructor,
    })
    console.log("SwapHandler Deployed.")

    console.log("Deploying ReferralStorage...")
    const compiledReferralStorageCasm = json.parse(fs.readFileSync( "./target/dev/satoru_ReferralStorage.compiled_contract_class.json").toString( "ascii"))
    const compiledReferralStorageSierra = json.parse(fs.readFileSync( "./target/dev/satoru_ReferralStorage.contract_class.json").toString( "ascii"))
    const referralStorageCallData: CallData = new CallData(compiledReferralStorageSierra.abi)
    const referralStorageConstructor: Calldata = referralStorageCallData.compile("constructor", {
        event_emitter_address: deployEventEmitterResponse.deploy.contract_address,
    })
    const deployReferralStorageResponse = await account0.declareAndDeploy({
        contract: compiledReferralStorageSierra,
        casm: compiledReferralStorageCasm ,
        constructorCalldata: referralStorageConstructor,
    })
    console.log("ReferralStorage Deployed.")

    console.log("Deploying OrderHandler...")
    const compiledOrderHandlerCasm = json.parse(fs.readFileSync( "./target/dev/satoru_OrderHandler.compiled_contract_class.json").toString( "ascii"))
    const compiledOrderHandlerSierra = json.parse(fs.readFileSync( "./target/dev/satoru_OrderHandler.contract_class.json").toString( "ascii"))
    const orderHandlerCallData: CallData = new CallData(compiledOrderHandlerSierra.abi)
    const orderHandlerConstructor: Calldata = orderHandlerCallData.compile("constructor", {
        data_store_address: deployDataStoreResponse.deploy.contract_address,
        role_store_address: deployRoleStoreResponse.deploy.contract_address,
        event_emitter_address: deployEventEmitterResponse.deploy.contract_address,
        order_vault_address: deployOrderVaultResponse.deploy.contract_address,
        oracle_address: deployOracleResponse.deploy.contract_address,
        swap_handler_address: deploySwapHandlerResponse.deploy.contract_address,
        referral_storage_address: deployReferralStorageResponse.deploy.contract_address
    })
    const deployOrderHandlerResponse = await account0.declareAndDeploy({
        contract: compiledOrderHandlerSierra,
        casm: compiledOrderHandlerCasm ,
        constructorCalldata: orderHandlerConstructor,
    })
    console.log("OrderHandler Deployed.")

    console.log("Declaring MarketToken...")
    const compiledMarketTokenCasm = json.parse(fs.readFileSync( "./target/dev/satoru_MarketToken.compiled_contract_class.json").toString( "ascii"))
    const compiledMarketTokenSierra = json.parse(fs.readFileSync( "./target/dev/satoru_MarketToken.contract_class.json").toString( "ascii"))    
    try {
        account0.declare({
            contract: compiledMarketTokenSierra,
            casm: compiledMarketTokenCasm
        })
        console.log("MarketToken Declared.")
    } catch (error) {
        console.log("Already Declared.")
    }

    console.log("Deploying MarketFactory...")
    const marketTokenClassHash = hash.computeCompiledClassHash(compiledMarketTokenCasm)
    const compiledMarketFactoryCasm = json.parse(fs.readFileSync( "./target/dev/satoru_MarketFactory.compiled_contract_class.json").toString( "ascii"))
    const compiledMarketFactorySierra = json.parse(fs.readFileSync( "./target/dev/satoru_MarketFactory.contract_class.json").toString( "ascii"))
    const marketFactoryCallData: CallData = new CallData(compiledMarketFactorySierra.abi)
    const marketFactoryConstructor: Calldata = marketFactoryCallData.compile("constructor", {
        data_store_address: deployDataStoreResponse.deploy.contract_address,
        role_store_address: deployRoleStoreResponse.deploy.contract_address,
        event_emitter_address: deployEventEmitterResponse.deploy.contract_address,
        market_token_class_hash: marketTokenClassHash
    })
    const deployMarketFactoryResponse = await account0.declareAndDeploy({
        contract: compiledMarketFactorySierra,
        casm: compiledMarketFactoryCasm ,
        constructorCalldata: marketFactoryConstructor,
    })
    console.log("MarketFactory Deployed.")

    console.log("Granting roles...")
    const roleCall2 = roleStoreContract.populate("grant_role", [account0.address, shortString.encodeShortString("MARKET_KEEPER")])
    const roleCall3 = roleStoreContract.populate("grant_role", [account0.address, shortString.encodeShortString("ORDER_KEEPER")])
    const roleCall4 = roleStoreContract.populate("grant_role",
        [
            deployOrderHandlerResponse.deploy.contract_address,
            shortString.encodeShortString("CONTROLLER")
        ]
    )
    const grant_role_tx2 = await roleStoreContract.grant_role(roleCall2.calldata)
    await provider.waitForTransaction(grant_role_tx2.transaction_hash)
    const grant_role_tx3 = await roleStoreContract.grant_role(roleCall3.calldata)
    await provider.waitForTransaction(grant_role_tx3.transaction_hash)
    const grant_role_tx4 = await roleStoreContract.grant_role(roleCall4.calldata)
    await provider.waitForTransaction(grant_role_tx4.transaction_hash)
    console.log("Roles granted.")
}

deploy()