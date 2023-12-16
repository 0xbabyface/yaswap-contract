import { ethers } from "hardhat";

import * as config from "../deployed-info.json";

async function main() {
  const fibProxy = await ethers.getContractAt("FibTrade", config.polygon.fibProxy);

  await fibProxy.setRole(await fibProxy.SignerRole(), "0xEA156a8A29fc61999C079BCc9906a7e0bd8c0E4E", true);

  console.log(`fee: ${await fibProxy.feeRatio()}`)
}

main();
