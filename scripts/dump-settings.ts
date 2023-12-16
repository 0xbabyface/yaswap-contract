import { ethers } from "hardhat";

import * as config from "../deployed-info.json";

(BigInt.prototype as any).toJSON = function () {
  return this.toString();
};

async function main() {
  const fibProxy = await ethers.getContractAt("FibTrade", config.polygon.fibProxy);

  console.log(`feeRatio   :  ${ethers.formatEther(await fibProxy.feeRatio())}`)
  console.log(`feeDiscount:  ${ethers.formatEther(await fibProxy.feeDiscount())}`)

}

main();
