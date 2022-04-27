const { expect } = require("chai");
const { ethers } = require("hardhat");
const { smock } = require("@defi-wonderland/smock");

describe("EndaomentFactory", async () => {
  let contract;
  let owner;
  let assetAddr;
  let endaoment;
  let baseToken;
  let quoteToken;
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

    //const AssetErc20Contract = await ethers.getContractFactory("ERC20Mock");
    //asset = AssetErc20Contract.attach(assetAddr);

    const EndaomentFactory = await ethers.getContractFactory(
      "EndaomentFactory",
    );
    contract = await EndaomentFactory.deploy();

    await contract.createSushiEndaomant(
      "Test Endaoment",
      "tendmt",
      "700",
      "2629800",
      assetAddr,
    );

    const userEndaoments = await contract.getEndaoments(owner.address);
    const endaomentAddy = await contract.getEndaoment(userEndaoments[0]);

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
      await contract.createSushiEndaomant(
        "Test Endaoment2",
        "tendmt2",
        "700",
        "2629800",
        assetAddr,
      );

      const userEndaoments = await contract.getEndaoments(owner.address);
      expect(userEndaoments.length).to.equal(2);
    });
  });
});
