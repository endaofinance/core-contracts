const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer Address: ", deployer.address);

  const factoryAddress = "0x2Ee3B26be40Ea1F33F4BF976EF447bF6E906E39A";
  // From https://dev.sushi.com/sushiswap/contracts#alternative-networks
  const sushiRouter = "0xc35DADB65012eC5796536bD9864eD8773aBc74C4";
  const weth = "0xc778417E063141139Fce010982780140Aa0cD5Ab";
  const usdc = "0x07865c6e87b9f70255377e024ace6630c1eaa37f";

  const uniswapv2Router = await ethers.getContractAt(
    "IUniswapV2Factory",
    sushiRouter,
  );
  const pairAddress = await uniswapv2Router.getPair(weth, usdc);
  console.log("pair address", pairAddress);

  const EndaomentFactory = await ethers.getContractFactory("EndaomentFactory");

  const factoryContract = EndaomentFactory.attach(factoryAddress);

  console.log("factoryContract address", factoryContract.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const req = await factoryContract.createSushiEndaomant(
    "Test Endaoment",
    "tendmt",
    ethers.BigNumber.from("25"),
    ethers.BigNumber.from("700"),
    pairAddress,
  );

  console.log("TxID", req.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
