import { ethers } from "hardhat";
import * as config from "../deployed-info.json";

async function main() {

  const fibTrade = await ethers.getContractAt('FibTrade', config.polygon.fibProxy);

  const relation = await ethers.getContractAt('FibRelationship', await fibTrade.fibRealtions());

  const parents = await relation.getParents('0xAaD988E28b06dF38F44D249213dadC187c5C8166', 3);
  console.log(`count: ${parents[0]}, fathers: ${parents[1]}`)

  const pending = await fibTrade.traderRewards("0xAaD988E28b06dF38F44D249213dadC187c5C8166", "0xa23890375110F584517D0aDAd58364E1f7fFfF61");
  console.log(`pending: ${pending}`);
}

main();
