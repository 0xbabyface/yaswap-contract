// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract FibTradeProxy is ERC1967Proxy {
    event OwnershipTransfered(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == ERC1967Utils.getAdmin(), "only amdin");
        _;
    }

    constructor(
        address _logic,
        bytes memory _data,
        address proxyAdmin
    ) ERC1967Proxy(_logic, _data) {
        ERC1967Utils.changeAdmin(proxyAdmin);
    }

    function transferOwnership(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "invalid admin");
        address oldAdmin = ERC1967Utils.getAdmin();
        ERC1967Utils.changeAdmin(newAdmin);
        emit OwnershipTransfered(oldAdmin, newAdmin);
    }

    function setImplementation(
        address _newLogic,
        bytes memory _data
    ) external onlyAdmin {
        ERC1967Utils.upgradeToAndCall(_newLogic, _data);
    }

    function implementation() external view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    receive() payable external {}
}