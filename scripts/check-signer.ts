import { ethers } from "hardhat";

import {arrayify, splitSignature} from "@ethersproject/bytes";
import * as config from "../deployed-info.json";

async function main() {
  const [owner] = await ethers.getSigners();
  const checkSigner = await ethers.deployContract("CheckSign");
  await checkSigner.waitForDeployment();

  // const checkSigner = await ethers.getContractAt('CheckSign', config.polygon.checkSign);
  const codeOwner = '0x7C2d769d55f71aa5546334416F50cDF7Fc41457F';

  const abiEncoder = ethers.AbiCoder.defaultAbiCoder();
  const relations = abiEncoder.encode(['address', 'bytes'], [codeOwner, Buffer.from('00iOm6zPG01')])

  console.log(`inviteCode: ${relations}`);

  const message = abiEncoder.encode(['address', 'bytes'], [owner.address, relations]);
  const hash = ethers.keccak256(message);
  console.log(`owner: ${owner.address}`)
  const signature = await owner.signMessage(arrayify(hash));

  let matched = await checkSigner.connect(owner).isValidSigner(relations, signature);
  console.log('matched: ', matched);

  const {v, r, s} = splitSignature(signature);
  console.log(`sig: ${signature}`)
  console.log(`v: ${v}, r: ${r}: s: ${s}`)

  const m2 = await checkSigner.connect(owner).getSignerByrsv(relations, r, s, v);
  console.log(`m2: ${m2}`);

  const signer = ethers.verifyMessage(arrayify(hash), signature);
  console.log(`signer is : ${signer}`)
}

main();
