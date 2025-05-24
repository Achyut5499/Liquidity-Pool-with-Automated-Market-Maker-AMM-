const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  const tokenA = "0xYourTokenAAddress"; // Replace with deployed token A
  const tokenB = "0xYourTokenBAddress"; // Replace with deployed token B

  const LiquidityPool = await ethers.getContractFactory("LiquidityPool");
  const pool = await LiquidityPool.deploy(tokenA, tokenB);

  await pool.deployed();
  console.log("LiquidityPool deployed to:", pool.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
