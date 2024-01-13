import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ethers } from "hardhat";
import { deploySystem } from "./common";
import { arrayify, splitSignature } from "@ethersproject/bytes";
import { expect } from "chai";

const Ancestor = '0x0000000000000000000000000000000000000001';
const codeOwner = '0x7C2d769d55f71aa5546334416F50cDF7Fc41457F';
const NativeToken = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

const fibDispatch2 = [ethers.parseEther('0.6'), ethers.parseEther('0.4')]
const fibDispatch3 = [ethers.parseEther('0.5'), ethers.parseEther('0.3'), ethers.parseEther('0.2')]

describe("fib trade test", function () {
  async function inviteSigner(father: any, player: any, signer: any) {

    const abiEncoder = ethers.AbiCoder.defaultAbiCoder();
    const relations = abiEncoder.encode(['address', 'bytes'], [father, Buffer.from('00iOm6zPG01')])


    const message = abiEncoder.encode(['address', 'bytes'], [player.address, relations]);
    const hash = ethers.keccak256(message);

    const signature = await signer.signMessage(arrayify(hash));
    const { v, r, s } = splitSignature(signature);

    return { inviteCode: relations, v, r, s }
  }

  it('swap erc20 for erc20', async () => {

    const { TDex, player1, player2, player3, player4, signer, TestUSDT, TestDAI, fibTrade, FibRelationship } = await loadFixture(deploySystem);

    const feeRatio = await fibTrade.feeRatio();
    const feeDiscount = await fibTrade.feeDiscount();
    const rebateRatio = await fibTrade.rebateRatio();
    const RatioPrecision = ethers.parseEther("1");

    const fromTokenAmount = ethers.parseEther("100");
    const toTokenAmount = ethers.parseEther('99.5');
    const toTokenMinAmount = ethers.parseEther("99");

    let { inviteCode, v, r, s } = await inviteSigner(Ancestor, player1, signer);
    const calldata = TDex.interface.encodeFunctionData('swap', [TestUSDT.target, fromTokenAmount, TestDAI.target, toTokenAmount]);

    let swapParams = {
      fromToken: TestUSDT.target,
      toToken: TestDAI.target,
      fromTokenAmount,
      dexAddress: TDex.target,
      dexCalldata: calldata,
      approveAddress: TDex.target,
      minOutAmount: toTokenMinAmount,
      inviteCode,
      v,
      r,
      s
    };

    await TestUSDT.connect(player1).approve(fibTrade.target, ethers.parseEther("200"));
    let tx = await fibTrade.connect(player1).swap(swapParams, false);
    await tx.wait();

    const relations = await FibRelationship.getParents(player1.address, 3);
    expect(relations[0]).to.equal(0);

    // nobody share fee, so all the fee deposit to FibTrade contract
    let fee = fromTokenAmount * feeRatio * feeDiscount / RatioPrecision / RatioPrecision;
    expect(await TestUSDT.balanceOf(fibTrade.target)).to.equal(fee);

    expect(await TestDAI.balanceOf(player1.address)).to.equal(toTokenAmount);

    // to test second level agent
    let p = await inviteSigner(player1.address, player2, signer);
    swapParams.inviteCode = p.inviteCode;
    swapParams.v = p.v;
    swapParams.r = p.r;
    swapParams.s = p.s;

    let player1UsdtBalanceBefore = await fibTrade.traderRewards(player1.address, TestUSDT.target);
    let contractUsdtBalanceBefore = await fibTrade.traderRewards(fibTrade.target, TestUSDT.target);

    await TestUSDT.connect(player2).approve(fibTrade.target, ethers.parseEther("200"));
    tx = await fibTrade.connect(player2).swap(swapParams, false);
    await tx.wait();

    let player1UsdtBalanceAfter = await fibTrade.traderRewards(player1.address, TestUSDT.target);
    let contractUsdtBalanceAfter = await fibTrade.traderRewards(fibTrade.target, TestUSDT.target);

    // the contract got (1 - rebateRatio) * fee, player1 got rebateRatio * fee
    expect(player1UsdtBalanceAfter - player1UsdtBalanceBefore).to.equal(
      fee * rebateRatio / RatioPrecision
    );

    expect(contractUsdtBalanceAfter - contractUsdtBalanceBefore).to.equal(
      fee * (RatioPrecision - rebateRatio) / RatioPrecision
    );

    // to test third level agent
    p = await inviteSigner(player2.address, player3, signer);
    swapParams.inviteCode = p.inviteCode;
    swapParams.v = p.v;
    swapParams.r = p.r;
    swapParams.s = p.s;

    player1UsdtBalanceBefore = await fibTrade.traderRewards(player1.address, TestUSDT.target);
    let player2UsdtBalanceBefore = await fibTrade.traderRewards(player2.address, TestUSDT.target);
    contractUsdtBalanceBefore = await fibTrade.traderRewards(fibTrade.target, TestUSDT.target);

    await TestUSDT.connect(player3).approve(fibTrade.target, ethers.parseEther("200"));
    tx = await fibTrade.connect(player3).swap(swapParams, false);
    await tx.wait();

    player1UsdtBalanceAfter = await fibTrade.traderRewards(player1.address, TestUSDT.target);
    let player2UsdtBalanceAfter = await fibTrade.traderRewards(player2.address, TestUSDT.target);
    contractUsdtBalanceAfter = await fibTrade.traderRewards(fibTrade.target, TestUSDT.target);

    // the contract got (1 - rebateRatio) * fee, player1 got rebateRatio * fee
    expect(player2UsdtBalanceAfter - player2UsdtBalanceBefore).to.equal(
      fee * rebateRatio * fibDispatch2[0] / RatioPrecision / RatioPrecision
    );

    expect(player1UsdtBalanceAfter - player1UsdtBalanceBefore).to.equal(
      fee * rebateRatio * fibDispatch2[1] / RatioPrecision / RatioPrecision
    );

    expect(contractUsdtBalanceAfter - contractUsdtBalanceBefore).to.equal(
      fee * (RatioPrecision - rebateRatio) / RatioPrecision
    );

    // forth level agent
    p = await inviteSigner(player3.address, player4, signer);
    swapParams.inviteCode = p.inviteCode;
    swapParams.v = p.v;
    swapParams.r = p.r;
    swapParams.s = p.s;

    player1UsdtBalanceBefore = await fibTrade.traderRewards(player1.address, TestUSDT.target);
    player2UsdtBalanceBefore = await fibTrade.traderRewards(player2.address, TestUSDT.target);
    let player3UsdtBalanceBefore = await fibTrade.traderRewards(player3.address, TestUSDT.target);
    contractUsdtBalanceBefore = await fibTrade.traderRewards(fibTrade.target, TestUSDT.target);

    await TestUSDT.connect(player4).approve(fibTrade.target, ethers.parseEther("200"));
    tx = await fibTrade.connect(player4).swap(swapParams, false);
    await tx.wait();

    player1UsdtBalanceAfter = await fibTrade.traderRewards(player1.address, TestUSDT.target);
    player2UsdtBalanceAfter = await fibTrade.traderRewards(player2.address, TestUSDT.target);
    let player3UsdtBalanceAfter = await fibTrade.traderRewards(player3.address, TestUSDT.target);
    contractUsdtBalanceAfter = await fibTrade.traderRewards(fibTrade.target, TestUSDT.target);

    // the contract got (1 - rebateRatio) * fee, player1 got rebateRatio * fee
    expect(player3UsdtBalanceAfter - player3UsdtBalanceBefore).to.equal(
      fee * rebateRatio * fibDispatch3[0] / RatioPrecision / RatioPrecision
    );

    expect(player2UsdtBalanceAfter - player2UsdtBalanceBefore).to.equal(
      fee * rebateRatio * fibDispatch3[1] / RatioPrecision / RatioPrecision
    );

    expect(player1UsdtBalanceAfter - player1UsdtBalanceBefore).to.equal(
      fee * rebateRatio * fibDispatch3[2] / RatioPrecision / RatioPrecision
    );

    expect(contractUsdtBalanceAfter - contractUsdtBalanceBefore).to.equal(
      fee * (RatioPrecision - rebateRatio) / RatioPrecision
    );
  });

  it('swap erc20 for native', async () => {

    const { TDex, player1, signer, TestUSDT, fibTrade } = await loadFixture(deploySystem);

    const fromTokenAmount = ethers.parseEther("100");
    const toTokenAmount = ethers.parseEther('99.5');
    const toTokenMinAmount = ethers.parseEther("99");

    let { inviteCode, v, r, s } = await inviteSigner(Ancestor, player1, signer);
    const calldata = TDex.interface.encodeFunctionData('swap', [TestUSDT.target, fromTokenAmount, NativeToken, toTokenAmount]);

    let swapParams = {
      fromToken: TestUSDT.target,
      toToken: NativeToken,
      fromTokenAmount,
      dexAddress: TDex.target,
      dexCalldata: calldata,
      receiver: player1.address,
      approveAddress: TDex.target,
      minOutAmount: toTokenMinAmount,
      inviteCode,
      v,
      r,
      s
    };

    let player1BalanceBefore = await ethers.provider.getBalance(player1.address);

    await TestUSDT.connect(player1).approve(fibTrade.target, ethers.parseEther("200"));
    let tx = await fibTrade.connect(player1).swap(swapParams, false);
    await tx.wait();

    let player1BalanceAfter = await ethers.provider.getBalance(player1.address);

    // pay fee and gaslimit, so we judge with lessthan
    expect(toTokenAmount - (player1BalanceAfter - player1BalanceBefore)).to.lessThan(
      ethers.parseEther('0.0005')
    );
  });

  it('swap native for erc20', async () => {

    const { TDex, player1, player2, player3, player4, signer, TestUSDT, TestDAI, fibTrade, FibRelationship } = await loadFixture(deploySystem);

    const fromTokenAmount = ethers.parseEther("100");
    const toTokenAmount = ethers.parseEther('99.5');
    const toTokenMinAmount = ethers.parseEther("99");

    let { inviteCode, v, r, s } = await inviteSigner(Ancestor, player1, signer);
    const calldata = TDex.interface.encodeFunctionData('swap', [NativeToken, fromTokenAmount, TestDAI.target, toTokenAmount]);

    let swapParams = {
      fromToken: NativeToken,
      toToken: TestDAI.target,
      fromTokenAmount,
      dexAddress: TDex.target,
      dexCalldata: calldata,
      receiver: player1.address,
      approveAddress: TDex.target,
      minOutAmount: toTokenMinAmount,
      inviteCode,
      v,
      r,
      s
    };

    const fees = await fibTrade.estimateFee(fromTokenAmount);

    let player1BalanceBefore = await TestDAI.balanceOf(player1.address);

    let tx = await fibTrade.connect(player1).swap(swapParams, false, {value: fromTokenAmount + fees[1]});
    await tx.wait();

    let player1BalanceAfter = await TestDAI.balanceOf(player1.address);

    // pay fee and gaslimit, so we judge with lessthan
    expect( player1BalanceAfter - player1BalanceBefore).to.equal(
      toTokenAmount
    );
  });
});

