import { ethers } from "hardhat";

export async function deploySystem() {
  const [owner, boss, admin, signer, financial, player1, player2, player3, player4] = await ethers.getSigners();

  const TestUSDT = await ethers.deployContract("TestUSDT");
  await TestUSDT.waitForDeployment();

  const TestDAI = await ethers.deployContract("TestDAI");
  await TestDAI.waitForDeployment();

  const TDex = await ethers.deployContract("TDex");
  await TDex.waitForDeployment();


  const FibTrade = await ethers.deployContract('FibTrade');
  await FibTrade.waitForDeployment();

  const initData = FibTrade.interface.encodeFunctionData("initialize", [boss.address, admin.address, signer.address, financial.address]);
  const FibTradeProxy = await ethers.deployContract('FibTradeProxy', [FibTrade.target, initData, owner.address]);
  await FibTradeProxy.waitForDeployment();

  const FibRelationship = await ethers.deployContract('FibRelationship', [FibTradeProxy.target])
  await FibRelationship.waitForDeployment();

  const fibTrade = await ethers.getContractAt('FibTrade', FibTradeProxy.target);
  let tx = await fibTrade.connect(admin).setFibRelationship(FibRelationship.target);
  await tx.wait();

  tx = await TestUSDT.mint(player1.address, ethers.parseEther("10000000"));
  await tx.wait();

  tx = await TestUSDT.mint(player2.address, ethers.parseEther("10000000"));
  await tx.wait();

  tx = await TestUSDT.mint(player3.address, ethers.parseEther("10000000"));
  await tx.wait();

  tx = await TestUSDT.mint(player4.address, ethers.parseEther("10000000"));
  await tx.wait();

  tx = await TestDAI.mint(TDex.target, ethers.parseEther("10000000"));
  await tx.wait();

  await owner.sendTransaction({to: TDex.target, value: ethers.parseEther("150")});

  return { owner, boss, admin, signer, financial, player1, player2, player3, player4, TDex, TestDAI, TestUSDT, fibTrade, FibRelationship };
}