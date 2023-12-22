// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IFibRelationship {
    function addRelation(address father, address son) external;
    function getParents(address son, uint256 upLevel) external view returns(uint256 count, address[] memory fathers);
}