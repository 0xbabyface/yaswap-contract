// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IFibRelationship.sol";

contract FibRelationship is IFibRelationship {
    using EnumerableSet for EnumerableSet.AddressSet;
    address public constant Ancestor = address(1);

    struct R {
        address father;
        EnumerableSet.AddressSet sons;
    }

    event RelationBound(address indexed father, address indexed son);

    mapping(address => R) relations;
    address fibTrade;

    modifier onlyFib() {
        require(msg.sender == fibTrade, "Relation: only fib trade");
        _;
    }

    constructor(address fib) {
        fibTrade = fib;
    }

    function addRelation(address father, address son) external override onlyFib {
        R storage sonNode = relations[son];

        // bound already or invalid father
        if (sonNode.father != address(0) || father == address(0)) return;

        sonNode.father = father;
        relations[father].sons.add(son);

        emit RelationBound(father, son);
    }

    function getParents(address son, uint256 upLevel) external override view returns(uint256 count, address[] memory fathers) {
        fathers = new address[](upLevel);
        if (relations[son].father == address(0)) return (count, fathers);

        address node = son;
        for (uint i = 0; i < upLevel; ++i) {
            address father = relations[node].father;

            if (father == Ancestor) break;

            fathers[i] = father;
            ++count;

            node = father;
        }
    }
}