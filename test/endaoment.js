const { expect } = require("chai");
const { ethers } = require("hardhat");
const { smock } = require("@defi-wonderland/smock");
const { BN } = require("@openzeppelin/test-helpers");

const toContractNumber = (inNum, multiplier = 1e18) => {
  const res = inNum * multiplier;
  return ethers.BigNumber.from(res.toString());
};

describe("Contract", async () => {
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
      "700",
      "25",
      uniFactory.address,
      uniRouter.address,
      baseToken.address,
      quoteToken.address,
    );
  });

  describe.only("deploy", async () => {
    it("deploys correctly", async () => {
      expect(await contract.totalSupply()).to.equal(0);
      let ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance).to.equal(0);

      const price = await contract.price();
      expect(price).equal(toContractNumber("1", 1));
    });
  });

  describe.only("mint", async () => {
    it("mints correctly", async () => {
      const startingBalance = await asset.balanceOf(owner.address);

      let price = await contract.price();
      expect(price).to.eq(toContractNumber("1", 1));

      let assetBalance = await asset.balanceOf(contract.address);
      expect(assetBalance).to.equal("0");

      await asset.approve(contract.address, ethers.utils.parseEther("100000"));

      await contract.mint("1");

      const ownerBalance = await asset.balanceOf(owner.address);
      expect(ownerBalance).to.equal(startingBalance.sub("1"));

      assetBalance = await asset.balanceOf(contract.address);
      expect(assetBalance).to.equal("1");

      price = await contract.price();
      expect(price).to.eq(toContractNumber("1", 1));
    });
    it("can mint 1 token");
    it("Cant mint because its not approved");
    it("Cant mint because not enough balance");
  });
  describe.only("burning", async () => {
    it("burns correctly", async () => {
      const [owner] = await ethers.getSigners();

      await asset.approve(contract.address, ethers.utils.parseEther("10000"));

      let assetBalance = await asset.balanceOf(contract.address);
      expect(assetBalance).to.equal("0");

      let price = await contract.price();
      expect(price).to.eq(toContractNumber("1", 1));

      let ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance).to.equal("0");

      await contract.mint("10");
      ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance).to.equal("10");

      assetBalance = await asset.balanceOf(contract.address);
      expect(assetBalance).to.equal("10");

      price = await contract.price();
      expect(price).to.eq(toContractNumber("1", 1));

      await contract.burn("5");
      ownerBalance = await contract.balanceOf(owner.address);
      expect(ownerBalance).to.equal("5");

      assetBalance = await asset.balanceOf(contract.address);
      expect(assetBalance).to.equal("5");

      price = await contract.price();
      expect(price).to.eq(toContractNumber("1", 1));

      await contract.epoch();
      price = await contract.price();
      expect(price).to.eq(toContractNumber("1", 1));
    });
    it("works with different decimals");
    it("cant burn tokens not in reserves");
    it("cant burn tokens I dont own");
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
