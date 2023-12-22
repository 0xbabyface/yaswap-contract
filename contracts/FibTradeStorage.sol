// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./relationship/IFibRelationship.sol";

contract FibTradeStorage {
    uint256 constant RatioPrecision = 1e18;

    bool    public initialized = true;
    uint256 public feeRatio;
    uint256 public feeDiscount;

    IFibRelationship public fibRealtions;
}