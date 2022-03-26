const { ethers } = require("hardhat");

async function main() {
  const randomWallet = ethers.Wallet.createRandom();
  console.log("New Privat Key:", randomWallet.privateKey);
  console.log("address", randomWallet.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
