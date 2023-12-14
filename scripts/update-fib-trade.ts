import { ethers } from "hardhat";

import * as config from "../deployed-info.json";

async function main() {
  const [owner] = await ethers.getSigners();
  const fibTrade = await ethers.deployContract('FibTrade');
  await fibTrade.waitForDeployment();

  const fibProxy = await ethers.getContractAt("FibTradeProxy", config.polygon.fibProxy);

  let tx = await fibProxy.connect(owner).setImplementation(fibTrade.target, "0x");
  await tx.wait();

  console.log(`upgraded:  ${tx.hash}`);
}

main();
