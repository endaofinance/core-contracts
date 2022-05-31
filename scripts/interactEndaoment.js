const { utils } = require("ethers");

async function main() {
  const [deployer] = await ethers.getSigners();
  const endaomentAddress = "0xA3ACAc24e4472f99F01958113Ece3f7309ef10f0";
  let benificiary = deployer.address;

  let beneficiaryRole = utils.keccak256(utils.toUtf8Bytes("BENEFICIARY_ROLE"));

  console.log("ROLE", beneficiaryRole);

  console.log("Endaoment address", endaomentAddress);
  console.log("Deployer Address: ", deployer.address);
  console.log("benificiary address", benificiary);

  const Endaoment = await ethers.getContractFactory("Endaoment");

  const endaoment = Endaoment.attach(endaomentAddress);
  console.log("Attached address", endaoment.address);

  var res = await endaoment.hasRole(beneficiaryRole, benificiary);
  console.log("has benificiary role", res);

  //res = await endaoment.grantRole(beneficiaryRole, deployer.address);
  //console.log("Txid:", res.hash);

  res = await endaoment.claim();
  console.log(res.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
