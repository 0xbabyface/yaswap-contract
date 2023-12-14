import { ethers } from "hardhat";

import {arrayify} from "@ethersproject/bytes";

async function main() {
  const [owner] = await ethers.getSigners();
  const checkSigner = await ethers.deployContract("CheckSign");
  await checkSigner.waitForDeployment();

  const enc = new TextEncoder();
  const inviteCode = enc.encode("123456aABbCc");

  const abiEncoder = new ethers.AbiCoder();
  const message = abiEncoder.encode(['address', 'bytes'], [owner.address, inviteCode]);
  const hash = ethers.keccak256(message);

  const signature = await owner.signMessage(arrayify(hash));

  let matched = await checkSigner.isValidSigner(inviteCode, signature);
  console.log('matched: ', matched);
}

main();
