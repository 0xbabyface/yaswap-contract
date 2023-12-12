// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract FibRelationship {

    function getInviteCode(address account) public view returns(bytes12) {
        bytes32 hash = keccak256(abi.encode(address(this), account));
        return bytes12(hash);
    }
}