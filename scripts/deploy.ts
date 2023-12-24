import { ethers } from "hardhat";

async function main() {

  const [owner] = await ethers.getSigners();

  const fibTrade = await ethers.deployContract("FibTrade");
  await fibTrade.waitForDeployment();

  const proxyAdmin = owner;
  const bossRole = owner;
  const adminRole = owner;
  const signerRole = owner;
  const financialRole = owner;

  const initData = fibTrade.interface.encodeFunctionData("initialize", [bossRole.address, adminRole.address, signerRole.address, financialRole.address]);

  const fibProxy = await ethers.deployContract("FibTradeProxy", [fibTrade.target, initData, proxyAdmin.address]);
  await fibProxy.waitForDeployment();

  const fibRelation = await ethers.deployContract('FibRelationship', [fibProxy.target]);
  await fibRelation.waitForDeployment();

  const fibImpl = await ethers.getContractAt('FibTrade', fibProxy.target);
  const tx = await fibImpl.setFibRelationship(fibRelation.target);
  await tx.wait();

  console.log(`
    {
      "fibRelation": "${fibRelation.target}",
      "fibTrade"   : "${fibTrade.target}",
      "fibProxy"   : "${fibProxy.target}"
    }
  `)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
