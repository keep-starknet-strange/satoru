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
    const account0 = new Account(provider, account0Address!, privateKey0!)
    console.log("Interacting with Account: " + account0Address)

    let eth = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"

    const dataStoreAddress = process.env.DATA_STORE as string
    const compiledDataStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_DataStore.contract_class.json").toString( "ascii"))
    const dataStoreContract = new Contract(compiledDataStoreSierra.abi, dataStoreAddress, provider)
    dataStoreContract.connect(account0);
    const dataCall = dataStoreContract.populate(
        "set_address",
        [ec.starkCurve.poseidonHashMany([BigInt(shortString.encodeShortString("FEE_TOKEN"))]), process.env.FEE_TOKEN as string])
    const setAddressTx = await dataStoreContract.set_address(dataCall.calldata)
    await provider.waitForTransaction(setAddressTx.transaction_hash)
    const dataCall2 = dataStoreContract.populate(
        "set_u256",
        [ec.starkCurve.poseidonHashMany([BigInt(shortString.encodeShortString("MAX_SWAP_PATH_LENGTH"))]), 5n])
    const setAddressTx2 = await dataStoreContract.set_u256(dataCall2.calldata)
    await provider.waitForTransaction(setAddressTx2.transaction_hash)

    const dataCall3 = dataStoreContract.populate(
        "set_u256",
        [ec.starkCurve.poseidonHashMany([BigInt(shortString.encodeShortString("MAX_ORACLE_PRICE_AGE"))]), 1000000000000n])
    const setAddressTx3 = await dataStoreContract.set_u256(dataCall3.calldata)
    await provider.waitForTransaction(setAddressTx3.transaction_hash)
    
    const compiledERC20Casm = json.parse(fs.readFileSync( "./target/dev/satoru_ERC20.compiled_contract_class.json").toString( "ascii"))
    const compiledERC20Sierra = json.parse(fs.readFileSync( "./target/dev/satoru_ERC20.contract_class.json").toString( "ascii"))
    const erc20CallData: CallData = new CallData(compiledERC20Sierra.abi)
    const erc20Constructor: Calldata = erc20CallData.compile("constructor", {
        name: "USDC",
        symbol: "USDC",
        initial_supply: "10000000000000000000",
        recipient: account0Address
    })
    const deployERC20Response = await account0.declareAndDeploy({
        contract: compiledERC20Sierra,
        casm: compiledERC20Casm,
        constructorCalldata: erc20Constructor,
    })
    console.log("USDC Deployed at: " + deployERC20Response.deploy.contract_address)

    const zETHCallData: CallData = new CallData(compiledERC20Sierra.abi)
    const zETHConstructor: Calldata = zETHCallData.compile("constructor", {
        name: "zEthereum",
        symbol: "zETH",
        initial_supply: "50000000000000000000000",
        recipient: account0Address
    })
    const deployzETHResponse = await account0.declareAndDeploy({
        contract: compiledERC20Sierra,
        casm: compiledERC20Casm,
        constructorCalldata: zETHConstructor,
    })
    console.log("zETH Deployed at: " + deployzETHResponse.deploy.contract_address)

    const marketFactoryAddress = process.env.MARKET_FACTORY as string
    const compiledMarketFactorySierra = json.parse(fs.readFileSync( "./target/dev/satoru_MarketFactory.contract_class.json").toString( "ascii"))

    const roleStoreAddress = process.env.ROLE_STORE as string
    const compiledRoleStoreSierra = json.parse(fs.readFileSync( "./target/dev/satoru_RoleStore.contract_class.json").toString( "ascii"))
    const roleStoreContract = new Contract(compiledRoleStoreSierra.abi, roleStoreAddress, provider)
    roleStoreContract.connect(account0)
    const roleCall = roleStoreContract.populate("grant_role", [marketFactoryAddress, shortString.encodeShortString("CONTROLLER")])
    const grant_role_tx = await roleStoreContract.grant_role(roleCall.calldata)
    await provider.waitForTransaction(grant_role_tx.transaction_hash)


    const abi = compiledMarketFactorySierra.abi
    const marketFactoryContract = new Contract(abi, marketFactoryAddress, provider);
    console.log("Connected to MarketFactory: " + marketFactoryAddress)
    marketFactoryContract.connect(account0)

    console.log("Granting roles...")
    const roleCall2 = roleStoreContract.populate("grant_role", [process.env.MARKET_FACTORY as string, shortString.encodeShortString("MARKET_KEEPER")])
    const grant_role_tx2 = await roleStoreContract.grant_role(roleCall2.calldata)
    await provider.waitForTransaction(grant_role_tx2.transaction_hash)

    const roleCall3 = roleStoreContract.populate("grant_role", [process.env.DEPOSIT_HANDLER as string, shortString.encodeShortString("CONTROLLER")])
    const grant_role_tx3 = await roleStoreContract.grant_role(roleCall3.calldata)
    await provider.waitForTransaction(grant_role_tx3.transaction_hash)

    const roleCall4 = roleStoreContract.populate("grant_role", [process.env.ORDER_HANDLER as string, shortString.encodeShortString("CONTROLLER")])
    const grant_role_tx4 = await roleStoreContract.grant_role(roleCall4.calldata)
    await provider.waitForTransaction(grant_role_tx4.transaction_hash)
    console.log("Roles granted.")

    console.log("Creating Market...")
    const myCall = marketFactoryContract.populate("create_market", [
        deployzETHResponse.deploy.contract_address,
        deployzETHResponse.deploy.contract_address,
        deployERC20Response.deploy.contract_address,
        "market_type"
    ]);
    const res = await marketFactoryContract.create_market(myCall.calldata);
    const marketTokenAddress = (await provider.waitForTransaction(res.transaction_hash) as any).events[0].data[1];
    console.log("Market created: " + marketTokenAddress)

    dataStoreContract.connect(account0);
    const dataCall5 = dataStoreContract.populate(
        "set_u256",
        [
            await dataStoreContract.get_max_pool_amount_key(marketTokenAddress, deployzETHResponse.deploy.contract_address),
            2500000000000000000000000000000000000000000000n
        ]
    )
    const setAddressTx5 = await dataStoreContract.set_u256(dataCall5.calldata)
    await provider.waitForTransaction(setAddressTx5.transaction_hash)

    const dataCall6 = dataStoreContract.populate(
        "set_u256",
        [
            await dataStoreContract.get_max_pool_amount_key(marketTokenAddress, deployERC20Response.deploy.contract_address),
            2500000000000000000000000000000000000000000000n
        ]
    )
    const setAddressTx6 = await dataStoreContract.set_u256(dataCall6.calldata)
    await provider.waitForTransaction(setAddressTx6.transaction_hash)

    const dataCall7 = dataStoreContract.populate(
        "set_u256",
        [
            await dataStoreContract.get_max_pnl_factor_key(
                "0x4896bc14d7c67b49131baf26724d3f29032ddd7539a3a8d88324140ea2de9b4",
                marketTokenAddress,
                true
            ),
            50000000000000000000000000000000000000000000000n
        ]
    )
    const setAddressTx7 = await dataStoreContract.set_u256(dataCall7.calldata)
    await provider.waitForTransaction(setAddressTx7.transaction_hash)

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


    const usdcContract = new Contract(compiledERC20Sierra.abi, deployERC20Response.deploy.contract_address, provider)
    usdcContract.connect(account0)

    const depositVaultAddress = process.env.DEPOSIT_VAULT as string
    const zEthContract = new Contract(compiledERC20Sierra.abi, deployzETHResponse.deploy.contract_address, provider)
    zEthContract.connect(account0)

    const transferCall2 = zEthContract.populate("mint", [marketTokenAddress, uint256.bnToUint256(50000000000000000000000000000000000000n)])
    const transferTx2 = await zEthContract.mint(transferCall2.calldata)
    await provider.waitForTransaction(transferTx2.transaction_hash)
    const transferUSDCCall = usdcContract.populate("mint", [marketTokenAddress, uint256.bnToUint256(25000000000000000000000000000000000000000n)])
    const transferUSDCTx = await usdcContract.mint(transferUSDCCall.calldata)
    await provider.waitForTransaction(transferUSDCTx.transaction_hash)

    const transferCall = zEthContract.populate("mint", [depositVaultAddress, uint256.bnToUint256(50000000000000000000000000000n)])
    const transferTx = await zEthContract.mint(transferCall.calldata)
    await provider.waitForTransaction(transferTx.transaction_hash)
    const transferUSDCCall2 = usdcContract.populate("mint", [depositVaultAddress, uint256.bnToUint256(50000000000000000000000000000n)])
    const transferUSDCTx2 = await usdcContract.mint(transferUSDCCall2.calldata)
    await provider.waitForTransaction(transferUSDCTx2.transaction_hash)

    const compiledOracleSierra = json.parse(fs.readFileSync( "./target/dev/satoru_Oracle.contract_class.json").toString( "ascii"))

    const abiOracle = compiledOracleSierra.abi
    const oracleContract = new Contract(abiOracle, process.env.ORACLE as string, provider);
    oracleContract.connect(account0);
    const setPrimaryPriceCall1 = oracleContract.populate("set_primary_price", [deployzETHResponse.deploy.address, uint256.bnToUint256(5000n)])
    const setPrimaryPriceTx1 = await oracleContract.set_primary_price(setPrimaryPriceCall1.calldata);
    await provider.waitForTransaction(setPrimaryPriceTx1.transaction_hash)

    const setPrimaryPriceCall2 = oracleContract.populate("set_primary_price", [usdcContract.address, uint256.bnToUint256(1n)])
    const setPrimaryPriceTx2 = await oracleContract.set_primary_price(setPrimaryPriceCall2.calldata);
    await provider.waitForTransaction(setPrimaryPriceTx2.transaction_hash)
    console.log("Primary prices set.")

    console.log("Sending tokens to the deposit vault...")

    console.log("Creating Deposit...")
    const compiledDepositHandlerSierra = json.parse(fs.readFileSync( "./target/dev/satoru_DepositHandler.contract_class.json").toString( "ascii"))

    const depositHandlerContract = new Contract(compiledDepositHandlerSierra.abi, process.env.DEPOSIT_HANDLER as string, provider);
    
    depositHandlerContract.connect(account0)
    const createDepositParams = {
        receiver: account0.address,
        callback_contract: 0,
        ui_fee_receiver: 0,
        market: marketTokenAddress,
        initial_long_token: zEthContract.address,
        initial_short_token: deployERC20Response.deploy.contract_address,
        long_token_swap_path: [],
        short_token_swap_path: [],
        min_market_tokens: uint256.bnToUint256(0),
        execution_fee: uint256.bnToUint256(0),
        callback_gas_limit: uint256.bnToUint256(0),
    };
    const createOrderCall = depositHandlerContract.populate("create_deposit", [
        account0.address,
        createDepositParams
    ])
    const createOrderTx = await depositHandlerContract.create_deposit(createOrderCall.calldata)
    await provider.waitForTransaction(createOrderTx.transaction_hash)
    console.log("Deposit created.")
}

create_market()