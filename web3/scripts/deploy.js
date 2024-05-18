const hre = require("hardhat");

async function main() {
  //staking contract
  const tokenStaking = await hre.ethers.deployContract("TokenStaking");

  await tokenStaking.waitForDeployment();

  //token contract
  const theblockchaincoders = await hre.ethers.deployContract("Theblockchaincoders");

  await theblockchaincoders.waitForDeployment();

  //contract address
  console.log(` TOKEN: ${theblockchaincoders.target}`);
  console.log(` STACKING: ${tokenStaking.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
