import { ethers } from "hardhat";

import {arrayify, splitSignature} from "@ethersproject/bytes";
import * as config from "../deployed-info.json";

async function main() {
  const [owner] = await ethers.getSigners();
  const checkSigner = await ethers.deployContract("CheckSign");
  await checkSigner.waitForDeployment();

  // const checkSigner = await ethers.getContractAt('CheckSign', config.polygon.checkSign);

  const enc = new TextEncoder();
  const inviteCode = enc.encode("00iq80zAG01");

  const abiEncoder = ethers.AbiCoder.defaultAbiCoder();
  const message = abiEncoder.encode(['address', 'bytes'], [owner.address, inviteCode]);
  const hash = ethers.keccak256(message);
  console.log(`owner: ${owner.address}`)
  const signature = await owner.signMessage(arrayify(hash));

  let matched = await checkSigner.connect(owner).isValidSigner(inviteCode, signature);
  console.log('matched: ', matched);

  const {v, r, s} = splitSignature(signature);
  console.log(`sig: ${signature}`)
  console.log(`v: ${v}, r: ${r}: s: ${s}`)

  const m2 = await checkSigner.connect(owner).getSignerByrsv(inviteCode, r, s, v);
  console.log(`m2: ${m2}`);
}

main();
