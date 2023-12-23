// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TDex {
    address public constant NativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    receive() external payable {}

    function swap(
            address fromTokenAddress,
            uint256 fromTokenAmount,
            address toTokenAddress,
            uint256 toTokenAmount
    )
        external
        payable
    {
        if (fromTokenAddress != NativeToken) {
            IERC20(fromTokenAddress).transferFrom(msg.sender, address(this), fromTokenAmount);
        }

        if (toTokenAddress == NativeToken) {
            payable(msg.sender).transfer(toTokenAmount);
        } else {
            IERC20(toTokenAddress).transfer(msg.sender, toTokenAmount);
        }
    }
}
