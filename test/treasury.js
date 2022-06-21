const { expect } = require("chai");
const { ethers } = require("hardhat");
const { smock } = require("@defi-wonderland/smock");
const { expectRevert } = require("@openzeppelin/test-helpers");

describe("Treasury", async () => {
  let treasury;
  let owner;
  let otherUser;
  let token;
  beforeEach(async () => {
    [owner, otherUser] = await ethers.getSigners();
    const Treasury = await ethers.getContractFactory("Treasury");
    treasury = await Treasury.deploy();
    const ERC20Mock = await smock.mock("ERC20Mock");
    token = await ERC20Mock.deploy(
      "wethToken",
      "WETH",
      18,
      owner.address,
      ethers.utils.parseEther("10000"),
    );
  });
  describe("claimERC20", async () => {
    it("claims correctly", async () => {
      await token.approve(treasury.address, "10000");
      token.transfer(treasury.address, "1000");
      token.transfer(otherUser.address, await token.balanceOf(owner.address));
      await treasury.claimERC20(token.address, "100", owner.address);
      expect(await token.balanceOf(owner.address)).to.eq("100");
    });
    it("fails trying to claim a token with no balance", async () => {
      await expectRevert(
        treasury.claimERC20(token.address, "100", owner.address),
        "ERC20: transfer amount exceeds balance",
      );
    });
    it("doesnt have permission to claim", async () => {
      const otherUserTreasury = treasury.connect(otherUser);
      await expectRevert(
        otherUserTreasury.claimERC20(token.address, "100", owner.address),
        "Ownable: caller is not the owner",
      );
    });
  });
});
