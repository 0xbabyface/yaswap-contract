// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract CheckSign {

    function isValidSigner(bytes memory inviteCode, bytes memory signature) public view returns(address) {
        bytes32 hash = keccak256(abi.encode(msg.sender, inviteCode));

        bytes32 digest = ECDSA.toEthSignedMessageHash(hash);

        address signer = ECDSA.recover(digest, signature);
        // return signer == msg.sender;
        return signer;
    }

    function getSignerByrsv(bytes memory inviteCode, bytes32 r, bytes32 s, uint8 v) public view returns(address) {
        bytes32 hash = keccak256(abi.encode(msg.sender, inviteCode));

        bytes32 digest = ECDSA.toEthSignedMessageHash(hash);

        address signer = ECDSA.recover(digest, v, r, s);
        // return signer == msg.sender;
        return signer;
    }
}