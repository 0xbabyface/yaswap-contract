import { ethers } from "hardhat";


let a = 1;
let b = 2;
let fib: bigint[] = [1n,2n];
let total = 3n;
for (let i = 2; i < 100; ++i) {
  let fn = fib[i - 1] + fib[i-2];
  fib[i] = fn;
  total += fn;
}

for (let i = 99; i >= 0; --i) {
  const index = fib[i] * 10n**18n / total;
  console.log(`${i+1} : ${ethers.formatEther(index)}`)
}

