import { ethers } from "hardhat";

import * as config from "../deployed-info.json";

(BigInt.prototype as any).toJSON = function () {
  return this.toString();
};

async function main() {
  const fibProxy = await ethers.getContractAt("FibTrade", config.polygon.fibProxy);

  console.log(`feeRatio   :  ${ethers.formatEther(await fibProxy.feeRatio())}`)
  console.log(`feeDiscount:  ${ethers.formatEther(await fibProxy.feeDiscount())}`)
  console.log(`hasRole:      ${await fibProxy.hasRole(await fibProxy.SignerRole(), "0xEA156a8A29fc61999C079BCc9906a7e0bd8c0E4E")}`);

}

main();
