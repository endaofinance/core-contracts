const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ManagerToken", function () {
  it("Should set a cap", async () => {
    const ManagerToken = await ethers.getContractFactory("ManagerToken");
    const managerToken = ManagerToken.deploy(100, 10);
    await managerToken.deployed();

    expect(await managerToken.cap()).to.eq(100);
  });
});
