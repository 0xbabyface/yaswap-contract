// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library FibAgent {

    using EnumerableSet for EnumerableSet.AddressSet;

    struct Agent {
        address self;
        address father;
        EnumerableSet.AddressSet sons;
    }

    function register(Agent storage agent, address self, address father) internal {
        agent.self = self;
        agent.father = father;
    }

    function addSon(Agent storage agent, address son) internal {
        agent.sons.add(son);
    }
}