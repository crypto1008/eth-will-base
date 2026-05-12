const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying with account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");

  const oneYear = 365 * 24 * 60 * 60;
  const unlockDate = Math.floor(Date.now() / 1000) + oneYear;

  console.log("Deploying ETHWill contract...");

  const Will = await ethers.getContractFactory("ETHWill");
  const will = await Will.deploy(unlockDate, oneYear);
  await will.waitForDeployment();

  const address = await will.getAddress();

  console.log("------------------------------------------");
  console.log("ETHWill deployed to:", address);
  console.log("Unlock date: 1 year from now");
  console.log("View on Basescan:");
  console.log("https://basescan.org/address/" + address);
  console.log("------------------------------------------");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
