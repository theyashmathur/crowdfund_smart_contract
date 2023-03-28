const hre = require("hardhat");

async function main() {

  const Cf = await hre.ethers.getContractFactory("CrowdFund");
  const cf = await hre.upgrades.deployProxy(Cf);

  console.log("Crowdfund proxy contract deployed to: ", cf.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
