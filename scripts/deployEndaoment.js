const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer Address: ", deployer.address);

  const factoryAddress = "0x7bd97b75148C685f3651ceD5605F366eC7670B5d";
  let assetAddress = "0xc778417E063141139Fce010982780140Aa0cD5Ab"; //Weth
  //assetAddress = "0xF4242f9d78DB7218Ad72Ee3aE14469DBDE8731eD"; // stETH
  //assetAddress = "0x5B281A6DdA0B271e91ae35DE655Ad301C976edb1"; // compoound usdc
  //assetAddress = "0x6D7F0754FFeb405d23C51CE938289d4835bE3b14"; // compound DAI
  assetAddress = "0xd6801a1dffcd0a410336ef88def4320d6df1883e"; //compound eth

  const EndaomentFactory = await ethers.getContractFactory("EndaomentFactory");

  const factoryContract = EndaomentFactory.attach(factoryAddress);
  console.log("factoryContract address", factoryContract.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const req = await factoryContract.createErc20Endaoment(
    "FOTTW Endaoment",
    "eFOTTW",
    "700",
    "100",
    assetAddress,
    "https://endao.finance",
  );

  console.log("TxID", req.hash);
  console.log(req);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
