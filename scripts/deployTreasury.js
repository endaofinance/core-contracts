const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer Address: ", deployer.address);

  const TreasuryFactory = await ethers.getContractFactory("Treasury");

  const res = await TreasuryFactory.deploy(deployer.address);

  console.log(res);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
