import { ethers } from "hardhat";

import * as config from "../deployed-info.json";

async function updateSettings() {
  const fib = await ethers.getContractAt('FibTrade', config.polygon.fibProxy);

  let tx = await fib.setRebateLevel(3);
  await tx.wait();

  tx = await fib.setRebateRatio(ethers.parseEther("0.2"));
  await tx.wait();

  const Relationship = await ethers.deployContract('FibRelationship', [config.polygon.fibProxy]);
  await Relationship.waitForDeployment();

  tx = await fib.setFibRelationship(Relationship.target);
  await tx.wait();
}

async function main() {
  const [owner] = await ethers.getSigners();
  let fibTrade = await ethers.deployContract('FibTrade');
  await fibTrade.waitForDeployment();

  console.log(`fibTrade: ${fibTrade.target}`);

  const fibProxy = await ethers.getContractAt("FibTradeProxy", config.polygon.fibProxy);

  let tx = await fibProxy.connect(owner).setImplementation(fibTrade.target, "0x");
  await tx.wait();

  fibTrade = await ethers.getContractAt('FibTrade', config.polygon.fibProxy);

  tx = await fibTrade.setRebateLevel(3);
  await tx.wait();

  tx = await fibTrade.setRebateRatio(ethers.parseEther("0.2"));
  await tx.wait();

  const Relationship = await ethers.deployContract('FibRelationship', [config.polygon.fibProxy]);
  await Relationship.waitForDeployment();

  tx = await fibTrade.setFibRelationship(Relationship.target);
  await tx.wait();

  console.log(`upgraded:  ${tx.hash}`);
}

main();
