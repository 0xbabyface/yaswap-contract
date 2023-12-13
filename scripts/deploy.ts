import { ethers } from "hardhat";

async function main() {

  const [owner] = await ethers.getSigners();

  const fibTrade = await ethers.deployContract("FibTrade");
  await fibTrade.waitForDeployment();

  const initData = fibTrade.interface.encodeFunctionData("initialize", [owner.address, owner.address]);

  const fibProxy = await ethers.deployContract("FibTradeProxy", [fibTrade.target, initData, owner.address]);
  await fibProxy.waitForDeployment();

  console.log(`
    {
      "fibTrade": "${fibTrade.target}",
      "fibProxy": "${fibProxy.target}"
    }
  `)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
