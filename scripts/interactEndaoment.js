async function main() {
  const [deployer] = await ethers.getSigners();

  const factoryAddress = "0x2Ee3B26be40Ea1F33F4BF976EF447bF6E906E39A";

  console.log("Deployer Address: ", deployer.address);

  const EndaomentFactory = await ethers.getContractFactory("EndaomentFactory");

  const factoryContract = EndaomentFactory.attach(factoryAddress);

  const endaoments = await factoryContract.getEndaoments(deployer.address);

  console.log("Endaoment:", endaoments);

  for (let i = 0; i < endaoments.length; i++) {
    const endaomentAddress = await factoryContract.getEndaoment(endaoments[i]);
    console.log(endaomentAddress);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
