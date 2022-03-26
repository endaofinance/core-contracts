async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deployer address", deployer.address);

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const EndaomentFactory = await ethers.getContractFactory("EndaomentFactory");
  const factoryContract = await EndaomentFactory.deploy();
  console.log("Factory address:", factoryContract.address);

  await factoryContract.createSushiEndaomant(
    "Test Endaoment",
    "tendmt",
    "700",
    "25",
    // From https://dev.sushi.com/sushiswap/contracts#alternative-networks
    "0xc35DADB65012eC5796536bD9864eD8773aBc74C4",
    "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506",
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", //WETH
    "0xe22da380ee6b445bb8273c81944adeb6e8450422", // USDC
  );

  const endaomentAddy = await factoryContract.getEndaoment(0);
  console.log("Endaoment address:", endaomentAddy);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
