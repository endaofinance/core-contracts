const { ethers } = require("hardhat");
const { smock } = require("@defi-wonderland/smock");
const { expectRevert } = require("@openzeppelin/test-helpers");

describe("Controller", async () => {
  let controller;
  let owner;
  let otherUser;
  let token;
  beforeEach(async () => {
    [owner, otherUser] = await ethers.getSigners();
    const Controller = await ethers.getContractFactory("Controller");
    controller = await Controller.deploy(owner.address);
    const ERC20Mock = await smock.mock("ERC20Mock");
    token = await ERC20Mock.deploy(
      "wethToken",
      "WETH",
      18,
      owner.address,
      ethers.utils.parseEther("10000"),
    );
  });
  describe("owner actions", async () => {
    it("can set protocolFeeBips");
    it("can set treasuryAddress");
    it("can set factory");
  });
});
