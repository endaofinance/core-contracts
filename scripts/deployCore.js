const { ethers } = require("hardhat");

async function main() {
  const [owner] = await ethers.getSigners();
  console.log("Deploying Treasury");
  const TreasuryFactory = await ethers.getContractFactory("Treasury");
  var deployer = await TreasuryFactory.deploy();

  const treasury = await deployer.deployed();

  console.log("Treasury Address: ", treasury.address);

  console.log("Deploying Controller");
  const Controller = await ethers.getContractFactory("Controller");
  deployer = await Controller.deploy(treasury.address);

  const controller = await deployer.deployed();

  console.log("Controller Address: ", controller.address);

  console.log("Deploying Factory");
  const EndaomentFactory = await ethers.getContractFactory("EndaomentFactory");
  deployer = await EndaomentFactory.deploy(controller.address);

  const factory = await deployer.deployed();

  console.log("Factory Address: ", factory.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
