const { expect } = require("chai");
const { ethers } = require("hardhat");
const { smock } = require("@defi-wonderland/smock");
const { expectRevert, constants } = require("@openzeppelin/test-helpers");

const toContractNumber = (inNum, multiplier = 1e18) => {
  const res = inNum * multiplier;
  return ethers.BigNumber.from(res.toString());
};

describe("Endaoment", async () => {
  let contract;
  let owner;
  let benificiary;
  let miscUser;
  let asset;
  let treasury;
  beforeEach(async () => {
    const signers = await ethers.getSigners();
    owner = signers[0];
    miscUser = signers[10];
    benificiary = signers[5];

    const ERC20Mock = await smock.mock("ERC20Mock");
    asset = await ERC20Mock.deploy(
      "CompoundToken",
      "cETH",
      8,
      owner.address,
      ethers.utils.parseEther("10000"),
    );

    const Treasury = await ethers.getContractFactory("Treasury");
    treasury = await Treasury.deploy(owner.address);

    const Endaoment = await ethers.getContractFactory("Endaoment");
    contract = await Endaoment.deploy(
      "Test Endaoment",
      "tendmt",
      benificiary.address,
      treasury.address,
      "100",
      "1",
      asset.address,
      "https://endao.finance",
    );
  });

  describe("default behavior", async () => {
    it("receives eth");
  });

  describe("deploy", async () => {
    it("deploys correctly", async () => {
      expect(await contract.totalSupply()).to.equal(0);
      let ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance).to.equal(0);
      let decimals = await contract.decimals();
      expect(decimals).to.equal(8);
    });
  });

  describe("mint", async () => {
    it("mints correctly", async () => {
      const startingBalance = await asset.balanceOf(owner.address);

      let assetBalance = await asset.balanceOf(contract.address);
      expect(assetBalance).to.equal("0");

      await asset.approve(contract.address, ethers.utils.parseEther("100000"));

      await contract.mint("1");

      const ownerBalance = await asset.balanceOf(owner.address);
      expect(ownerBalance).to.equal(startingBalance.sub("1"));

      assetBalance = await asset.balanceOf(contract.address);
      expect(assetBalance).to.equal("1");
    });
    it("Cant mint because its not enough approved", async () => {
      const startingBalance = await asset.balanceOf(owner.address);
      await asset.approve(contract.address, ethers.utils.parseEther("0"));

      await expectRevert(contract.mint("1"), "NOT_ENOUGH_ASSETS_TO_LOCK");

      const ownerBalance = await asset.balanceOf(owner.address);
      expect(ownerBalance).to.equal(startingBalance);
    });
    it("Cant mint because not enough balance", async () => {
      const startingBalance = await asset.balanceOf(owner.address);

      await asset.approve(contract.address, startingBalance);
      await asset.transfer(miscUser.address, startingBalance, {
        from: owner.address,
      });

      await expectRevert(contract.mint("1"), "NOT_ENOUGH_ASSETS_TO_LOCK");

      const ownerBalance = await asset.balanceOf(owner.address);
      expect(ownerBalance).to.equal("0");
    });
  });
  describe("burning", async () => {
    it("burns correctly", async () => {
      const [owner] = await ethers.getSigners();

      await asset.approve(contract.address, ethers.utils.parseEther("10000"));

      let assetBalance = await asset.balanceOf(contract.address);
      expect(assetBalance).to.equal("0");

      let ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance).to.equal("0");

      await contract.mint("10");
      ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance).to.equal("10");

      assetBalance = await asset.balanceOf(contract.address);
      expect(assetBalance).to.equal("10");

      await contract.burn("5");
      ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance).to.equal("5");

      assetBalance = await asset.balanceOf(contract.address);
      expect(assetBalance).to.equal("5");

      await contract.mint("1");
      ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance).to.equal("6");
      await contract.burn("6");
      ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance).to.equal("0");

      assetBalance = await asset.balanceOf(contract.address);
      expect(assetBalance).to.equal("0");
    });
    it("cant burn tokens I dont own (no supply)", async () => {
      await asset.approve(contract.address, ethers.utils.parseEther("50"));
      await expectRevert(contract.burn("6"), "NOT_ENOUGH_TOKENS_TO_BURN");
    });
    it("cant burn tokens I dont own", async () => {
      await asset.approve(contract.address, ethers.utils.parseEther("50"));
      await contract.mint("1");
      await expectRevert(contract.burn("6"), "NOT_ENOUGH_TOKENS_TO_BURN");
    });
    it("works with different users");
    it("makes sure that events are firing");
    it("works with different decimals");
  });

  describe("claim", async () => {
    it("claims correctly", async () => {
      const benificiaryContract = contract.connect(benificiary);
      await treasury.setProtocolFee("0");

      const startingBalance = await contract.balanceOf(benificiary.address);
      expect(startingBalance).to.equal("0");

      await asset.approve(contract.address, "10000");
      await contract.mint("100");

      await contract.epoch();
      const claimable = await contract.balanceOf(contract.address);
      expect(claimable).to.equal("1");

      await benificiaryContract.claim();
      const newBalance = await contract.balanceOf(benificiary.address);
      expect(newBalance).to.equal("1");
    });
    it("claims correctly with protocolFee", async () => {
      const benificiaryContract = contract.connect(benificiary);
      await treasury.setProtocolFee("5000");

      await asset.approve(contract.address, "10000");
      await contract.mint("200");

      await contract.epoch();

      await benificiaryContract.claim();
      const newBalance = await contract.balanceOf(benificiary.address);
      expect(newBalance).to.equal("1");

      const treasuryBalance = await contract.balanceOf(treasury.address);
      expect(treasuryBalance).to.equal("1");
    });
    it("cant claim if not a benificiary", async () => {
      const miscUserContract = contract.connect(miscUser);
      await asset.approve(contract.address, "10000");
      await contract.mint("100");

      await contract.epoch();

      await expectRevert(
        miscUserContract.claim(),
        "DOES_NOT_HAVE_BENIFICIARY_ROLE",
      );
      expect(await contract.balanceOf(miscUser.address)).to.equal("0");
    });
    it("claimAndBurn correctly");
    it("cant claimAndBurn if not a benificiary");
  });

  describe("contract management", async () => {
    it("epochs correctly");
    it("doesnt let not approved people epoch");
    it("adds new benificiary");
    it("removes benificiary");
    it("assigns new admin");
    it("can enable assets");
    it("cant enable assets");
    it("can disable assets");
    it("cant disable assets");
  });
});
