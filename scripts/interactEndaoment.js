async function main() {
  const [deployer] = await ethers.getSigners();

  const factoryAddress = "0xabf4d308715da6a582c8f02097361ca8b4bf478f";

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
