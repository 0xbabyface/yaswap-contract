// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./FibTradeStorage.sol";

contract FibTrade is AccessControl, FibTradeStorage {
    bytes32 public constant OwnerRole = keccak256("FibTrade.owner");
    bytes32 public constant AdminRole = keccak256("FibTrade.admin");
    bytes32 public constant SignerRole = keccak256("FibTrade.signer");

    struct SwapParams {
        address fromToken;             // from erc20 token
        address toToken;               // to erc20 token
        uint256 fromTokenAmount;       // from erc20 token amount
        address dexAddress;            // dex contract, which for match making
        bytes   dexCalldata;           // calldata of dex trading
        address receiver;              // receiver account
        uint256 minOutAmount;         // minimal output of totoken which receiver shold received
        bytes   inviteCode;
        bytes   signature;
    }

    event TokenSwapped(
        address indexed maker,
        address indexed receiver,
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minOutAmount,
        uint256 actualOutput,
        uint256 feeAmount
    );

    event FeeRatioSet(uint256 newFee, uint256 oldFee);
    event FeeDiscountSet(uint256 newDiscount, uint256 oldDiscount);

    constructor() {}

    function initialize(address _owner, address _admin) external {
        require(!initialized, "init only once");
        _grantRole(OwnerRole, _owner);
        _grantRole(AdminRole, _admin);
        feeRatio = 0.05E18;
        feeDiscount = 0.9E18;
    }

    function setRole(bytes32 role, address account, bool toGrant)
        external
        onlyRole(OwnerRole)
    {
        require(
            role == AdminRole || role == OwnerRole || role == SignerRole,
            "not support role"
        );

        if (toGrant) {
            _grantRole(role, account);
        } else {
            _revokeRole(role, account);
        }
    }

    function setFeeRatio(uint256 ratio) external onlyRole(AdminRole) {
        uint256 oldFee = feeRatio;
        feeRatio = ratio;

        emit FeeRatioSet(ratio, oldFee);
    }

    function setFeeDiscount(uint256 ratio) external onlyRole(AdminRole) {
        uint256 oldFee = feeDiscount;
        feeDiscount = ratio;

        emit FeeDiscountSet(ratio, oldFee);
    }
    /**
    * @notice withdraw fee or any other tokens from this contract to recepient
    * @param erc20Address erc20 token address
    * @param amount how much token to withdraw
    * @param recepient address to receive token
    */
    function withdraw(address erc20Address, uint256 amount, address recepient)
        external
        onlyRole(OwnerRole)
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

        uint256 feeAmount = params.fromTokenAmount * feeRatio / RatioPrecision;
        if (params.inviteCode.length != 0) {
            address signer = ECDSA.recover(
                keccak256(abi.encode(msg.sender, params.inviteCode)),
                params.signature
            );
            // if signed by singer, then make a discount for fee
            if (hasRole(SignerRole, signer)) {
                feeAmount = feeAmount * feeDiscount / RatioPrecision;
            }
        }

        uint256 totalFromToken = params.fromTokenAmount  + feeAmount;
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
            msg.sender,
            params.receiver,
            params.fromToken,
            params.toToken,
            params.fromTokenAmount,
            params.minOutAmount,
            actualOutput,
            feeAmount
        );
    }
}