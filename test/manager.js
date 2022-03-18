const { expect } = require("chai");
const { ethers } = require("hardhat");

const ONE_E_18 = ethers.BigNumber.from("1000000000000000000");

const toContractNumber = (inNum) => {
  const res = inNum * 1e18;
  return ethers.BigNumber.from(res.toString());
};

describe("Contract", async () => {
  let contract;
  let owner;
  beforeEach(async () => {
    const signers = await ethers.getSigners();
    owner = signers[0];
    const ManagerToken = await ethers.getContractFactory("ManagerToken");
    contract = await ManagerToken.deploy("Manager token", "mgr");
  });

  describe("deploy", async () => {
    it("deploys correctly", async () => {
      expect(await contract.totalSupply()).to.equal(0);
      let currentPrice = await contract.price();
      expect(currentPrice.toString()).to.equal("1");
      let ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance).to.equal(0);
    });
  });

  describe("deposits", async () => {
    it("deposits correctly", async () => {
      const [owner, act1, act2, act3, act4] = await ethers.getSigners();
      const testCases = [
        {
          account: act1,
          deposit: "1.0",
          expectedPrice: "1",
          expectedBalance: "1",
        },
        {
          account: act2,
          deposit: "2.0",
          expectedPrice: "1",
          expectedBalance: "2",
        },
        {
          account: act3,
          deposit: "3.0",
          expectedPrice: "1",
          expectedBalance: "3",
        },
        {
          account: act4,
          deposit: "0.5",
          expectedPrice: "1",
          expectedBalance: "0.5",
        },
      ];
      for (let i = 0; i < testCases.length; i++) {
        const testCase = testCases[i];
        console.log(testCase.deposit);
        const acct = testCase.account;
        let currentPrice = await contract.price();
        expect(currentPrice.toString()).to.equal(testCase.expectedPrice);

        await acct.sendTransaction({
          to: contract.address,
          value: ethers.utils.parseEther(testCase.deposit), // Sends 1.0 ether
        });

        let userBalance = await contract.balanceOf(acct.address);
        const myExpectedBalance = toContractNumber(testCase.expectedBalance);
        expect(userBalance).to.equal(myExpectedBalance.toString());
      }
    });
  });
});
