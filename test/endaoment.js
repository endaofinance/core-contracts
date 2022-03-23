const { expect } = require("chai");
const { ethers } = require("hardhat");
const { smock } = require("@defi-wonderland/smock");
const { constants } = require("@openzeppelin/test-helpers");

const ONE_E_18 = ethers.BigNumber.from("1000000000000000000");

const toContractNumber = (inNum) => {
  const res = inNum * 1e18;
  return ethers.BigNumber.from(res.toString());
};

describe("Contract", async () => {
  let contract;
  let owner;
  let asset;
  beforeEach(async () => {
    const signers = await ethers.getSigners();
    owner = signers[0];
    manager = signers[10];

    const assetFactory = await smock.mock("ERC20Mock");
    asset = await assetFactory.deploy(
      "Test",
      "TST",
      owner.address,
      ethers.utils.parseEther("100"),
    );

    const Endaoment = await ethers.getContractFactory("Endaoment");
    contract = await Endaoment.deploy(
      "Test Endaoment",
      "tendmt",
      "700",
      "25",
      manager.address,
      asset.address,
      constants.ZERO_ADDRESS,
    );
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

  describe("mint", async () => {
    it("mints correctly", async () => {
      const amount = ethers.utils.parseEther("10.0");
      await asset.approve(contract.address, amount);

      await contract.mint(asset.address, amount);

      expect(await asset.balanceOf(owner.address)).to.equal(
        ethers.utils.parseEther("90"),
      );
      expect(await asset.balanceOf(contract.address)).to.equal(
        ethers.utils.parseEther("10"),
      );

      // TODO: check price
    });
    it("Cant mint because its not approved");
    it("Cant mint because not enough balance");
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

  describe("management", async () => {
    it("rebalances correctly", async () => {
      const accounts = await ethers.getSigners();

      const owner = accounts[0];
      const other = accounts[1];
      const manager = accounts[10];

      await other.sendTransaction({
        to: contract.address,
        value: ethers.utils.parseEther("1.0"), // Sends 1.0 ether
      });

      await contract.rebalance();
      const mgrBalance =
        (await manager.getBalance()) + ethers.utils.parseEther("1.0");
      expect(mgrBalance.toString()).to.equal(mgrBalance);

      const contractBalance = await ethers.provider.getBalance(
        contract.address,
      );
      expect(contractBalance.toString()).to.equal(
        ethers.utils.parseEther("0.0025"),
      );

      const totalSupply = await contract.totalSupply();

      expect(totalSupply.toString()).to.equal(
        ethers.utils.parseEther("1.0058"),
      );

      const claimableBalance = await contract.balanceOf(contract.address);
      expect(claimableBalance.toString()).to.equal("5800000000000000");
    });
    it("doesnt let not approved people rebalance");
  });

  describe("claiming", async () => {
    it("claims correctly");
    it("cant claim if not a benificiary");
  });

  describe("burning", async () => {
    it("burns correctly", async () => {
      const [owner] = await ethers.getSigners();

      await owner.sendTransaction({
        to: contract.address,
        value: ethers.utils.parseEther("1.0"), // Sends 1.0 ether
      });

      let ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance.toString()).to.equal(ethers.utils.parseEther("1"));

      await contract.burn(ethers.utils.parseEther("0.5"));

      ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance.toString()).to.equal(ethers.utils.parseEther("0.5"));

      let contractBalance = await ethers.provider.getBalance(contract.address);

      expect(contractBalance.toString()).to.equal(
        ethers.utils.parseEther("0.5").toString(),
      );
    });
    it("cant burn tokens not in reserves");
    it("cant burn tokens I dont own");
  });

  describe("hard burn", async () => {
    it("works correctly");
  });

  describe("contract management", async () => {
    it("adds new benificiary");
    it("removes benificiary");
    it("assigns new admin");
    it("can enable assets");
    it("cant enable assets");
    it("can disable assets");
    it("cant disable assets");
  });
});
