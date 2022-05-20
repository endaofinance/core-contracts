const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer Address: ", deployer.address);

  const factoryAddress = "0xaBF4d308715DA6a582c8F02097361Ca8B4bf478F";
  const assetAddress = "0xc778417E063141139Fce010982780140Aa0cD5Ab";

  const EndaomentFactory = await ethers.getContractFactory("EndaomentFactory");

  const factoryContract = EndaomentFactory.attach(factoryAddress);
  console.log("factoryContract address", factoryContract.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const req = await factoryContract.createErc20Endaoment(
    "Test Endaoment",
    "tendmt",
    "700",
    "100",
    assetAddress,
    "https://endao.finance",
  );

  console.log("TxID", req.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
