const { expect } = require("chai");
const { ethers } = require("hardhat");
const { smock } = require("@defi-wonderland/smock");

describe("EndaomentFactory", async () => {
  let contract;
  let owner;
  let endaoment;
  let asset;
  let treasury;
  beforeEach(async () => {
    const signers = await ethers.getSigners();
    owner = signers[0];
    manager = signers[10];

    const ERC20Mock = await smock.mock("ERC20Mock");
    asset = await ERC20Mock.deploy(
      "wethToken",
      "WETH",
      8,
      owner.address,
      ethers.utils.parseEther("10000"),
    );

    const Treasury = await ethers.getContractFactory("Treasury");
    treasury = await Treasury.deploy();

    const EndaomentFactory = await ethers.getContractFactory(
      "EndaomentFactory",
    );
    contract = await EndaomentFactory.deploy(treasury.address);

    await contract.createErc20Endaoment(
      "Test Endaoment",
      "tendmt",
      "700",
      "2629800",
      asset.address,
      "https://endao.finance",
    );

    const endaomentAddy = await contract.endaoments("0");

    endaoment = await ethers.getContractAt("Endaoment", endaomentAddy);
  });

  describe("deploy", async () => {
    it("deploys correctly", async () => {
      expect(await endaoment.totalSupply()).to.equal(0);
      let ownerBalance = await endaoment.balanceOf(owner.address);
      expect(ownerBalance).to.equal(0);
    });
  });

  describe("core interactions", async () => {
    it("creates another endaoment", async () => {
      await contract.createErc20Endaoment(
        "Test Endaoment2",
        "tendmt2",
        "700",
        "2629800",
        asset.address,
        "https://endao.finance",
      );

      const userEndaoments = await contract.getEndaomentsCreatedBy(
        owner.address,
      );
      expect(userEndaoments.length).to.equal(2);
    });
  });
});
