// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract YaswapStorage {
    uint256 constant RatioPrecision = 1e18;

    bool    public initialized = true;
    uint256 public feeRatio;
}