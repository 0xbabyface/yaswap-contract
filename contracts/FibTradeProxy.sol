// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract FibTradeProxy is ERC1967Proxy {

    event OwnershipTransfered(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "only amdin");
        _;
    }

    constructor(
        address _logic,
        bytes memory _data,
        address owner
    ) ERC1967Proxy(_logic, _data) {
        _changeAdmin(owner);
    }

    function transferOwnership(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "invalid admin");
        address oldAdmin = _getAdmin();
        _changeAdmin(newAdmin);
        emit OwnershipTransfered(oldAdmin, newAdmin);
    }

    function setImplementation(
        address _newLogic,
        bytes memory _data
    ) external onlyAdmin {
        _upgradeToAndCall(_newLogic, _data, false);
    }

    function implementation() external view returns (address) {
        return _getImplementation();
    }
}