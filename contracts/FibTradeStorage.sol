// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./relationship/IFibRelationship.sol";

contract FibTradeStorage {
    uint256 constant RatioPrecision = 1e18;

    bool    public initialized = true;
    uint256 public feeRatio;           // fee charged by total
    uint256 public feeDiscount;        // anyone who got a invitation, fee has a discount
    uint256 public rebateLevel;        // charged fee will rebate to its fathers
    uint256 public rebateRatio;        // how much fee will rebate to its fathers

    IFibRelationship public fibRealtions;

    mapping(address => mapping(address => uint256)) public traderRewards;
 }