const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer Address: ", deployer.address);

  const factoryAddress = "0xa1575b30D21Ca0864EF77F9580963109910c1618";
  let assetAddress = "0xc778417E063141139Fce010982780140Aa0cD5Ab"; //Weth
  //assetAddress = "0xF4242f9d78DB7218Ad72Ee3aE14469DBDE8731eD"; // stETH
  //assetAddress = "0x5B281A6DdA0B271e91ae35DE655Ad301C976edb1"; // compoound usdc
  //assetAddress = "0x6D7F0754FFeb405d23C51CE938289d4835bE3b14"; // compound DAI

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
