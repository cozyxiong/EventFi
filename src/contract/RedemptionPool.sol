// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Token.sol";
import "../interface/IRedemptionPool.sol";

contract RedemptionPool is ReentrancyGuardUpgradeable, IRedemptionPool {

    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    IERC20 public immutable usdt;
    uint256 public immutable unlockTime = block.timestamp + 365 * 3 days;

    event ClaimSuccess(address indexed claimer, uint256 usdtAmount, uint256 tokenAmount);

    constructor(address _tokenAddress, address _usdtAddress){
        token = IERC20(_tokenAddress);
        usdt = IERC20(_usdtAddress);
    }

    function claim(uint256 amount) external {
        require(block.timestamp > unlockTime, "Redemption.claim: redemption pool is locked");
        require(token.balanceOf(msg.sender) >= amount, "Redemption.claim: balance not enough");

        uint256 usdtAmount = exchangeToUSDT(amount);
        require(usdtAmount != 0, "Redemption.claim: the amount of usdt can exchanged is zero");
        require(usdtAmount <= redemptionPoolBalance(), "Redemption.claim: the balance of redemption pool not enough");

        Token(address(token)).burn(msg.sender, amount);
        usdt.safeTransfer(msg.sender, usdtAmount);

        emit ClaimSuccess(msg.sender, usdtAmount, amount);
    }

    function redemptionPoolBalance() internal view returns (uint256) {
        return usdt.balanceOf(address(this));
    }

    function exchangeToUSDT(uint256 amount) internal view returns (uint256) {
        return usdt.balanceOf(address(this)) * amount / token.totalSupply();
    }
}
