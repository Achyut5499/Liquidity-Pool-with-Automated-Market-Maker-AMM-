// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract LiquidityPool {
    using SafeERC20 for IERC20;

    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public totalShares;
    mapping(address => uint256) public shares;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 sharesMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 sharesBurned);
    event Swap(address indexed user, address inputToken, uint256 inputAmount, address outputToken, uint256 outputAmount);

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        tokenB.safeTransferFrom(msg.sender, address(this), amountB);

        uint256 share;
        if (totalShares == 0) {
            share = Math.sqrt(amountA * amountB);
        } else {
            share = Math.min((amountA * totalShares) / reserveA, (amountB * totalShares) / reserveB);
        }

        require(share > 0, "Invalid share");

        reserveA += amountA;
        reserveB += amountB;
        totalShares += share;
        shares[msg.sender] += share;

        emit LiquidityAdded(msg.sender, amountA, amountB, share);
    }

    function removeLiquidity(uint256 share) external {
        require(share > 0 && shares[msg.sender] >= share, "Invalid share");

        uint256 amountA = (share * reserveA) / totalShares;
        uint256 amountB = (share * reserveB) / totalShares;

        shares[msg.sender] -= share;
        totalShares -= share;
        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.safeTransfer(msg.sender, amountA);
        tokenB.safeTransfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, share);
    }

    function swap(address inputToken, uint256 inputAmount) external {
        require(inputAmount > 0, "Invalid input");

        bool isAToB = inputToken == address(tokenA);
        require(isAToB || inputToken == address(tokenB), "Invalid token");

        (IERC20 input, IERC20 output, uint256 reserveIn, uint256 reserveOut) =
            isAToB ? (tokenA, tokenB, reserveA, reserveB) : (tokenB, tokenA, reserveB, reserveA);

        input.safeTransferFrom(msg.sender, address(this), inputAmount);

        uint256 inputAmountWithFee = (inputAmount * 997) / 1000;
        uint256 numerator = inputAmountWithFee * reserveOut;
        uint256 denominator = reserveIn + inputAmountWithFee;
        uint256 outputAmount = numerator / denominator;

        require(outputAmount > 0, "Insufficient output");

        output.safeTransfer(msg.sender, outputAmount);

        if (isAToB) {
            reserveA += inputAmount;
            reserveB -= outputAmount;
        } else {
            reserveB += inputAmount;
            reserveA -= outputAmount;
        }

        emit Swap(msg.sender, address(input), inputAmount, address(output), outputAmount);
    }
}
