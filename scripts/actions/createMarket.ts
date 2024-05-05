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
    await provider.waitForTransaction(setAddressTx2.transaction_hash)

    
    console.log("Deploying USDC...")
    const compiledERC20Casm = json.parse(fs.readFileSync( "./target/dev/satoru_ERC20.compiled_contract_class.json").toString( "ascii"))
    const compiledERC20Sierra = json.parse(fs.readFileSync( "./target/dev/satoru_ERC20.contract_class.json").toString( "ascii"))
    const erc20CallData: CallData = new CallData(compiledERC20Sierra.abi)
    const erc20Constructor: Calldata = erc20CallData.compile("constructor", {
        name: "USDC",
        symbol: "USDC",
        initial_supply: "100000000000000000000000",
        recipient: account0Address
    })
    const deployERC20Response = await account0.declareAndDeploy({
        contract: compiledERC20Sierra,
        casm: compiledERC20Casm,
        constructorCalldata: erc20Constructor,
    })
    console.log("USDC Deployed at: " + deployERC20Response.deploy.contract_address)

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
    console.log("Roles granted.")

    console.log("Creating Market...")
    const myCall = marketFactoryContract.populate("create_market", [
        eth,
        eth,
        deployERC20Response.deploy.contract_address,
        "market_type"
    ]);
    const res = await marketFactoryContract.create_market(myCall.calldata);
    const marketTokenAddress = (await provider.waitForTransaction(res.transaction_hash) as any).events[0].data[1];
    console.log("Market created: " + marketTokenAddress)

    const orderVaultAddress = process.env.ORDER_VAULT as string
    const ethContract = new Contract(compiledERC20Sierra.abi, eth as string, provider)
    ethContract.connect(account0)
    const transferCall = ethContract.populate("transfer", [orderVaultAddress, uint256.bnToUint256(1000n)])
    const transferTx = await ethContract.transfer(transferCall.calldata)
    await provider.waitForTransaction(transferTx.transaction_hash)
    const transferCall2 = ethContract.populate("transfer", [marketTokenAddress, uint256.bnToUint256(10000n)])
    const transferTx2 = await ethContract.transfer(transferCall2.calldata)
    await provider.waitForTransaction(transferTx2.transaction_hash)

    const usdcContract = new Contract(compiledERC20Sierra.abi, deployERC20Response.deploy.contract_address, provider)
    usdcContract.connect(account0)
    const transferUSDCCall = usdcContract.populate("transfer", [marketTokenAddress, uint256.bnToUint256(10000n)])
    const transferUSDCTx = await usdcContract.transfer(transferUSDCCall.calldata)
    await provider.waitForTransaction(transferUSDCTx.transaction_hash)

    const compiledOracleSierra = json.parse(fs.readFileSync( "./target/dev/satoru_Oracle.contract_class.json").toString( "ascii"))

    const abiOracle = compiledOracleSierra.abi
    const oracleContract = new Contract(abiOracle, process.env.ORACLE as string, provider);
    oracleContract.connect(account0);
    const setPrimaryPriceCall1 = oracleContract.populate("set_primary_price", [ethContract.address, uint256.bnToUint256(5000n)])
    const setPrimaryPriceTx1 = await oracleContract.set_primary_price(setPrimaryPriceCall1.calldata);
    await provider.waitForTransaction(setPrimaryPriceTx1.transaction_hash)

    const setPrimaryPriceCall2 = oracleContract.populate("set_primary_price", [usdcContract.address, uint256.bnToUint256(1n)])
    const setPrimaryPriceTx2 = await oracleContract.set_primary_price(setPrimaryPriceCall2.calldata);
    await provider.waitForTransaction(setPrimaryPriceTx2.transaction_hash)
    console.log("Primary prices set.")
    // const orderHandlerContract = new Contract(compiledOrderHandlerSierra.abi, orderHandlerAddress, provider);
    
    // orderHandlerContract.connect(account0)
    // const createOrderParams = {
    //     receiver: account0.address,
    //     callback_contract: 0,
    //     ui_fee_receiver: 0,
    //     market: 0,
    //     initial_collateral_token: eth,
    //     swap_path: [marketTokenAddress],
    //     size_delta_usd: uint256.bnToUint256(1000),
    //     initial_collateral_delta_amount: uint256.bnToUint256(10000),
    //     trigger_price: uint256.bnToUint256(0),
    //     acceptable_price: uint256.bnToUint256(0),
    //     execution_fee: uint256.bnToUint256(0),
    //     callback_gas_limit: uint256.bnToUint256(0),
    //     min_output_amount: uint256.bnToUint256(0),
    //     order_type: new CairoCustomEnum({ MarketSwap: {} }),
    //     decrease_position_swap_type: new CairoCustomEnum({ NoSwap: {} }),
    //     is_long: 0,
    //     referral_code: 0
    // };
    // const createOrderCall = orderHandlerContract.populate("create_order", [
    //     account0.address,
    //     createOrderParams
    // ])
    // const createOrderTx = await orderHandlerContract.create_order(createOrderCall.calldata)
    // await provider.waitForTransaction(createOrderTx.transaction_hash)
    // console.log("Order created.")
}

create_market()