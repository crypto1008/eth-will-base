const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("ETHWill", function () {
  let will, owner, alice, bob;
  const ONE_YEAR = 365 * 24 * 60 * 60;

  beforeEach(async () => {
    [owner, alice, bob] = await ethers.getSigners();
    const future = (await time.latest()) + ONE_YEAR;
    const Will = await ethers.getContractFactory("ETHWill");
    will = await Will.deploy(future, ONE_YEAR);
  });

  it("Owner can deposit ETH", async () => {
    await will.deposit({ value: ethers.parseEther("1.0") });
    expect(await will.getBalance()).to.equal(ethers.parseEther("1.0"));
  });

  it("Owner can add beneficiaries", async () => {
    await will.addBeneficiary(alice.address, 60, "Alice");
    await will.addBeneficiary(bob.address, 40, "Bob");
    const bens = await will.getBeneficiaries();
    expect(bens.length).to.equal(2);
  });

  it("Shares cannot exceed 100 percent", async () => {
    await will.addBeneficiary(alice.address, 60, "Alice");
    await expect(
      will.addBeneficiary(bob.address, 50, "Bob")
    ).to.be.revertedWith("Shares exceed 100%");
  });

  it("Cannot claim before unlock date", async () => {
    await will.deposit({ value: ethers.parseEther("1.0") });
    await will.addBeneficiary(alice.address, 100, "Alice");
    await expect(
      will.connect(alice).claim(0)
    ).to.be.revertedWith("Will not yet unlocked");
  });

  it("Beneficiary can claim after unlock date", async () => {
    await will.deposit({ value: ethers.parseEther("1.0") });
    await will.addBeneficiary(alice.address, 100, "Alice");
    await time.increase(ONE_YEAR + 1);
    const before = await ethers.provider.getBalance(alice.address);
    await will.connect(alice).claim(0);
    const after = await ethers.provider.getBalance(alice.address);
    expect(after).to.be.gt(before);
  });

  it("Owner can cancel and reclaim ETH", async () => {
    await will.deposit({ value: ethers.parseEther("1.0") });
    await will.cancelWill();
    expect(await will.getBalance()).to.equal(0);
  });

  it("Inactivity unlock works after check in period", async () => {
    await will.deposit({ value: ethers.parseEther("1.0") });
    await will.addBeneficiary(alice.address, 100, "Alice");
    await time.increase(ONE_YEAR + 1);
    expect(await will.isUnlocked()).to.equal(true);
  });

  it("Check in resets inactivity timer", async () => {
    await time.increase(ONE_YEAR / 2);
    await will.checkIn();
    expect(await will.isUnlocked()).to.equal(false);
  });
});
