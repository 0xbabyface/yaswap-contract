// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUSDT is ERC20 {
    constructor() ERC20("TestUSDT", "USDT") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}