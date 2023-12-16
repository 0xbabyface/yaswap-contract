import { ethers } from "hardhat";

async function main() {

  const [owner] = await ethers.getSigners();

  const cs = await ethers.deployContract('CheckSign');
  await cs.waitForDeployment();

  console.log(`
    {
      "checkSign": "${cs.target}",
    }
  `)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
