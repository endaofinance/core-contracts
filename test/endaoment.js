const { expect } = require("chai");
const { ethers } = require("hardhat");
const { smock } = require("@defi-wonderland/smock");
const { expectEvent } = require("@openzeppelin/test-helpers");

const toContractNumber = (inNum, multiplier = 1e18) => {
  const res = inNum * multiplier;
  return ethers.BigNumber.from(res.toString());
};

describe("Endaoment", async () => {
  let contract;
  let owner;
  let assetAddr;
  let asset;
  let baseToken;
  let quoteToken;
  let factory;
  beforeEach(async () => {
    const signers = await ethers.getSigners();
    owner = signers[0];
    manager = signers[10];

    const ERC20Mock = await smock.mock("ERC20Mock");
    baseToken = await ERC20Mock.deploy(
      "wethToken",
      "WETH",
      owner.address,
      ethers.utils.parseEther("10000"),
    );

    quoteToken = await ERC20Mock.deploy(
      "quoteTest",
      "qTST",
      owner.address,
      ethers.utils.parseEther("10000"),
    );

    const UniswapV2FactoryMock = await smock.mock("UniswapV2FactoryMock");
    const uniFactory = await UniswapV2FactoryMock.deploy(owner.address);
    factory = uniFactory;

    const UniswapV2Router02Mock = await smock.mock("UniswapV2Router02Mock");
    const uniRouter = await UniswapV2Router02Mock.deploy(
      uniFactory.address,
      baseToken.address,
    );

    baseToken.approve(uniRouter.address, ethers.utils.parseEther("100000000"));
    quoteToken.approve(uniRouter.address, ethers.utils.parseEther("100000000"));
    await uniFactory.createPair(baseToken.address, quoteToken.address);

    const dl = Math.floor(Date.now() / 1000) + 60; // 1 minute rom now
    await uniRouter.addLiquidity(
      baseToken.address,
      quoteToken.address,
      ethers.utils.parseEther("100"),
      ethers.utils.parseEther("200"),
      ethers.utils.parseEther("100"),
      ethers.utils.parseEther("200"),
      owner.address,
      dl.toString(),
    );

    assetAddr = await uniFactory.getPair(baseToken.address, quoteToken.address);

    const AssetErc20Contract = await ethers.getContractFactory("ERC20Mock");
    asset = AssetErc20Contract.attach(assetAddr);

    const Endaoment = await ethers.getContractFactory("Endaoment");
    contract = await Endaoment.deploy(
      "Test Endaoment",
      "tendmt",
      owner.address,
      "700",
      "2629800",
      asset.address,
    );
  });

  describe("deploy", async () => {
    it("deploys correctly", async () => {
      expect(await contract.totalSupply()).to.equal(0);
      let ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance).to.equal(0);
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
    it("can mint 1 token");
    it("Cant mint because its not approved");
    it("Cant mint because not enough balance");
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
    it("makes sure that events are firing");
    it("works with different users");
    it("works with different decimals");
    it("cant burn tokens not in reserves");
    it("cant burn tokens I dont own");
  });

  describe("claim", async () => {
    it("claims correctly");
    it("cant claim if not a benificiary");
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
