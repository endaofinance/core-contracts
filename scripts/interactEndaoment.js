const { utils } = require("ethers");

async function main() {
  const [deployer] = await ethers.getSigners();
  const endaomentAddress = "0x3ed4FB1E9e46c759CFA1C35b72fcA914E4F48750";
  let newBeneficiary = "0xE673E6d4De3466B70567BD8B51e4bDA9A459A6f1";

  let beneficiaryRole = utils.keccak256(utils.toUtf8Bytes("BENEFICIARY_ROLE"));

  console.log("ROLE", beneficiaryRole);

  console.log("Endaoment address", endaomentAddress);
  console.log("Deployer Address: ", deployer.address);
  console.log("newBeneficiary address", newBeneficiary);

  const Endaoment = await ethers.getContractFactory("Endaoment");

  const endaoment = Endaoment.attach(endaomentAddress);
  console.log("Attached address", endaoment.address);

  var res = await endaoment.hasRole(beneficiaryRole, newBeneficiary);
  console.log("has newBeneficiary role", res);

  res = await endaoment.grantRole(beneficiaryRole, newBeneficiary);
  console.log("Txid:", res.hash);

  //res = await endaoment.claim();
  //console.log(res.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
