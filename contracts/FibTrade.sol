// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./FibTradeStorage.sol";

contract FibTrade is AccessControl, FibTradeStorage {
    bytes32 public constant BossRole = keccak256("FibTrade.owner");
    bytes32 public constant AdminRole = keccak256("FibTrade.admin");
    bytes32 public constant FinancialRole = keccak256("FibTrade.financial");
    bytes32 public constant SignerRole = keccak256("FibTrade.signer");

    address public constant NativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct SwapParams {
        address fromToken;             // from erc20 token
        address toToken;               // to erc20 token
        uint256 fromTokenAmount;       // from erc20 token amount
        address dexAddress;            // dex contract, which for match making
        bytes   dexCalldata;           // calldata of dex trading
        address receiver;              // receiver account
        address approveAddress;        // approve address to transfer trade token
        uint256 minOutAmount;         // minimal output of totoken which receiver shold received
        bytes   inviteCode;
        // bytes   signature;
        uint8 v; bytes32 r; bytes32 s; // signature
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
    event RebateRatioSet(uint256 newRatio, uint256 oldRatio);
    event RebateLevelSet(uint256 newLevel, uint256 oldLevel);
    event NativeTokenReceived(address indexed sender, uint256 amount);
    event RewardDispatched(address indexed receiver, address indexed tokenAddress, uint256 amount);
    event RewardClaimed(address indexed trader, address indexed receiver, address indexed tokenAddress, uint256 amount);
    event OwnerRewardClaimed(address indexed owner, address indexed receiver, address indexed tokenAddress, uint256 amount);

    constructor() {}

    receive() external payable {
        emit NativeTokenReceived(msg.sender, msg.value);
    }

    function initialize(address _owner, address _admin, address _signer, address _financial) external {
        require(!initialized, "init only once");

        _grantRole(BossRole, _owner);
        _grantRole(AdminRole, _admin);
        _grantRole(SignerRole, _signer);
        _grantRole(FinancialRole, _financial);

        feeRatio = 0.05E18;
        feeDiscount = 0.9E18;

        rebateLevel = 3;
        rebateRatio = 0.2E18;

        initialized = true;
    }

    function setRole(bytes32 role, address account, bool toGrant)
        external
        onlyRole(BossRole)
    {
        require(
            role == BossRole || role == AdminRole || role == SignerRole || role == FinancialRole,
            "not support role"
        );

        if (toGrant) {
            _grantRole(role, account);
        } else {
            _revokeRole(role, account);
        }
    }

    // set fib relationship contract
    function setFibRelationship(IFibRelationship relations) external onlyRole(AdminRole) {
        require(address(relations) != address(0), "invalid address");

        fibRealtions = relations;
    }

    // set fee ratio charged by system
    function setFeeRatio(uint256 ratio) external onlyRole(AdminRole) {
        require(ratio <= RatioPrecision, "too much fee ratio");
        uint256 oldFee = feeRatio;
        feeRatio = ratio;

        emit FeeRatioSet(ratio, oldFee);
    }
    // set discount for traders with invitation
    function setFeeDiscount(uint256 ratio) external onlyRole(AdminRole) {
        require(ratio <= RatioPrecision, "too much fee discount ratio");
        uint256 oldFee = feeDiscount;
        feeDiscount = ratio;

        emit FeeDiscountSet(ratio, oldFee);
    }
    // to set rebate ratio for fee
    function setRebateRatio(uint256 ratio) external onlyRole(AdminRole) {
        require(ratio <= RatioPrecision, "too much rebate fee ratio");
        uint256 oldFee = rebateRatio;
        rebateRatio = ratio;

        emit RebateRatioSet(ratio, oldFee);
    }
    // to set rebate level
    function setRebateLevel(uint256 level) external onlyRole(AdminRole) {
        uint256 oldLevel = rebateLevel;

        rebateLevel = level;

        emit RebateLevelSet(level, oldLevel);
    }

    /**
    * @notice withdraw fee or any other tokens from this contract to recepient by financial
    * @param tokenAddress erc20 token address
    * @param recepient address to receive token
    */
    function ownerClaimRewards(address tokenAddress, address payable recepient)
        external
        onlyRole(FinancialRole)
    {
        uint256 amount = traderRewards[address(this)][tokenAddress];
        require(amount > 0, "no pending rewards");

        traderRewards[address(this)][tokenAddress] = 0;

        if (tokenAddress == NativeToken) {
            recepient.transfer(amount);
        } else {
            IERC20(tokenAddress).transfer(recepient, amount);
        }

        emit OwnerRewardClaimed(msg.sender, recepient, tokenAddress, amount);
    }

    /**
    * @notice users claim their pending rewards
    * @param tokenAddress reward token address
    * @param recepient the address to receive rewards
     */
    function traderClaimRewards(address tokenAddress, address payable recepient) external {
        uint256 amount = traderRewards[msg.sender][tokenAddress];
        require(amount > 0, "no pending rewards");

        traderRewards[msg.sender][tokenAddress] = 0;

        if (tokenAddress == NativeToken) {
            recepient.transfer(amount);
        } else {
            IERC20(tokenAddress).transfer(recepient, amount);
        }

        emit RewardClaimed(msg.sender, recepient, tokenAddress, amount);
    }

    /**
    * @dev to estimate fee amount with specific from token amount
    * @param fromTokenAmount amount of from token
    * @return
    *   feeAmount : original fee amount
    *   feeWithDiscount : discount fee amount
    */
    function estimateFee(uint256 fromTokenAmount) external view returns(uint256, uint256) {
        uint256 feeAmount = fromTokenAmount * feeRatio / RatioPrecision;
        uint256 feeWithDiscount = feeAmount * feeDiscount / RatioPrecision;

        return (feeAmount, feeWithDiscount);
    }

    /**
    * @notice to execute the swap operation
    * @param params a struct of trading pair
     */
    function swap(SwapParams calldata params) external payable {
        require(
            params.fromTokenAmount > 0,
            "trade amount is 0"
        );
        require(
            params.receiver != address(0),
            "receiver is null"
        );

        uint256 feeAmount = params.fromTokenAmount * feeRatio / RatioPrecision;
        if (params.inviteCode.length != 0) {
            bytes32 hash = keccak256(abi.encode(msg.sender, params.inviteCode));
            bytes32 digest = ECDSA.toEthSignedMessageHash(hash);
            address signer = ECDSA.recover(digest, params.v, params.r, params.s);
            // if signed by singer, then make a discount for fee
            if (hasRole(SignerRole, signer)) {
                feeAmount = feeAmount * feeDiscount / RatioPrecision;

                (address codeOwner, /*bytes memory code*/) = abi.decode(params.inviteCode, (address, bytes));
                fibRealtions.addRelation(codeOwner, msg.sender);
            }
        }

        uint256 actualOutput;
        if (params.fromToken == NativeToken && params.toToken != NativeToken) {
            actualOutput = swapNativeToErc20(params, feeAmount);
        } else if (params.fromToken != NativeToken && params.toToken == NativeToken) {
            actualOutput = swapErc20ToNative(params, feeAmount);
        } else if (params.fromToken != NativeToken && params.toToken != NativeToken) {
            actualOutput = swapErc20ToErc20(params, feeAmount);
        } else {
            require(false, "not swap native to native");
        }

        require(
            actualOutput >= params.minOutAmount,
            "output less than required"
        );

        if (feeAmount > 0) {
            uint256 rebateAmount;
            (uint256 level, address[] memory fathers) = fibRealtions.getParents(msg.sender, rebateLevel);
            if (level > 0) {
                rebateAmount = feeAmount * rebateRatio / RatioPrecision;
                dispatchRewards(level, fathers, params.fromToken, rebateAmount);
            }

            traderRewards[address(this)][params.fromToken] += (feeAmount - rebateAmount);
        }

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

    function swapErc20ToNative(SwapParams calldata params, uint256 feeAmount) internal returns(uint256) {
        require(
            params.approveAddress != address(0),
            "approve address is null"
        );

        IERC20 fromToken = IERC20(params.fromToken);

        uint256 totalFromToken = params.fromTokenAmount  + feeAmount;
        fromToken.transferFrom(msg.sender, address(this), totalFromToken);

        uint256 receiverBalanceBefore = address(this).balance;

       fromToken.approve(params.approveAddress, params.fromTokenAmount);
        (bool success, bytes memory reason) = params.dexAddress.call(params.dexCalldata);
        require(success, string(reason));

        uint256 receiverBalanceAfter = address(this).balance;

        uint256 actualOutput = receiverBalanceAfter - receiverBalanceBefore;

        payable(params.receiver).transfer(actualOutput);

        return actualOutput;
    }

    function swapNativeToErc20(SwapParams calldata params, uint256 feeAmount) internal returns(uint256) {

        require(msg.value >= params.fromTokenAmount + feeAmount, "paied not enough value");

        IERC20 toToken = IERC20(params.toToken);

        uint256 receiverBalanceBefore = toToken.balanceOf(address(this));

        (bool success, bytes memory reason) = params.dexAddress.call{value: params.fromTokenAmount}(params.dexCalldata);
        require(success, string(reason));

        uint256 receiverBalanceAfter = toToken.balanceOf(address(this));

        uint256 actualOutput = receiverBalanceAfter - receiverBalanceBefore;

        toToken.transfer(params.receiver, actualOutput);

        return actualOutput;
    }

    function swapErc20ToErc20(SwapParams calldata params, uint256 feeAmount) internal returns(uint256) {
        require(
            params.approveAddress != address(0),
            "approve address is null"
        );

        IERC20 fromToken = IERC20(params.fromToken);
        IERC20 toToken   = IERC20(params.toToken);

        uint256 totalFromToken = params.fromTokenAmount  + feeAmount;
        fromToken.transferFrom(msg.sender, address(this), totalFromToken);

        uint256 receiverBalanceBefore = toToken.balanceOf(address(this));

        fromToken.approve(params.approveAddress, params.fromTokenAmount);
        (bool success, bytes memory reason) = params.dexAddress.call(params.dexCalldata);
        require(success, string(reason));

        uint256 receiverBalanceAfter = toToken.balanceOf(address(this));

        uint256 actualOutput = receiverBalanceAfter - receiverBalanceBefore;

        toToken.transfer(params.receiver, actualOutput);

        return actualOutput;
    }

    function dispatchRewards(uint256 level, address[] memory receivers, address tokenAddress, uint256 feeAmount) internal {
        uint256[] memory ratios = fibDispatchRatio(level);

        for (uint256 i = 0; i < level; ++i) {
            uint256 reward = feeAmount * ratios[i] / RatioPrecision;
            traderRewards[receivers[i]][tokenAddress] += reward;
            emit RewardDispatched(receivers[i], tokenAddress, reward);
        }
    }

    function fibDispatchRatio(uint256 level) internal pure returns(uint256[] memory) {
        uint256[] memory ratios = new uint256[](level);
             if (level == 1) { ratios[0] = uint256(1E18); }
        else if (level == 2) { ratios[0] = uint256(0.6E18); ratios[1] = uint256(0.4E18);}
        else if (level == 3) { ratios[0] = uint256(0.5E18); ratios[1] = uint256(0.3E18); ratios[2] = uint256(0.2E18);}
        else {
            // TODO: should revert here???
        }
        return ratios;
    }
}
