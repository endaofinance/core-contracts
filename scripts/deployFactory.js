async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deployer address", deployer.address);

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const EndaomentFactory = await ethers.getContractFactory("EndaomentFactory");
  const factoryContract = await EndaomentFactory.deploy();
  console.log("Factory address:", factoryContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
