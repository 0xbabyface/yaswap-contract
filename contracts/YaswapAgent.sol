// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./YaswapStorage.sol";

contract YaswapAgent is Ownable, YaswapStorage {
    struct SwapParams {
        address fromToken;             // from erc20 token
        address toToken;               // to erc20 token
        uint256 fromTokenAmount;       // from erc20 token amount
        address dexAddress;            // dex contract, which for match making
        bytes   dexCalldata;           // calldata of dex trading
        address receiver;              // receiver account
        uint256 minOutAmount;         // minimal output of totoken which receiver shold received
    }

    event TokenSwapped(
        address indexed receiver,
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 requiredOutput,
        uint256 actualOutput
    );

    constructor() Ownable(msg.sender) {}

    function initialize(address _owner) external {
        require(!initialized, "init only once");
        _transferOwnership(_owner);
        feeRatio = 0.05E18;
    }

    function setFeeRatio(uint256 ratio) external onlyOwner {
        feeRatio = ratio;
    }
    /**
    * @notice withdraw fee or any other tokens from this contract to recepient
    * @param erc20Address erc20 token address
    * @param amount how much token to withdraw
    * @param recepient address to receive token
    */
    function withdraw(address erc20Address, uint256 amount, address recepient)
        external
        onlyOwner
    {
        IERC20 erc20Token = IERC20(erc20Address);

        require(erc20Token.balanceOf(address(this)) >= amount, "not enough balance");
        require(recepient != address(0), "recepient is null address");

        erc20Token.transfer(recepient, amount);
    }

    /**
    * @notice to execute the swap operation
    * @param params a struct of trading pair
     */
    function swap(SwapParams memory params) external {
        require(
            params.fromTokenAmount > 0,
            "trade amount is 0"
        );
        require(
            params.receiver != address(0),
            "receiver is null"
        );

        IERC20 fromToken = IERC20(params.fromToken);
        IERC20 toToken   = IERC20(params.toToken);

        uint256 totalFromToken = params.fromTokenAmount * (RatioPrecision + feeRatio) / RatioPrecision;
        fromToken.transferFrom(msg.sender, address(this), totalFromToken);

        uint256 receiverBalanceBefore = toToken.balanceOf(params.receiver);

        fromToken.approve(params.dexAddress, params.fromTokenAmount);
        (bool success, bytes memory reason) = params.dexAddress.call(params.dexCalldata);
        require(success, string(reason));

        uint256 receiverBalanceAfter = toToken.balanceOf(params.receiver);
        uint256 actualOutput = receiverBalanceAfter - receiverBalanceBefore;
        require(
            actualOutput >= params.minOutAmount,
            "output less than required"
        );

        emit TokenSwapped(
            params.receiver,
            params.fromToken,
            params.toToken,
            params.fromTokenAmount,
            params.minOutAmount,
            actualOutput
        );
    }
}