// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./TradeStorage.sol";
import "../interface/ITrade.sol";

contract Trade is Initializable, OwnableUpgradeable, TradeStorage, ITrade {

    using SafeERC20 for IERC20;
    IERC20 public token;
    IERC20 public usdt;

    event TokenPurchased(address purchaser, uint256 usdtAmount, uint256 tokenAmount);

    constructor(){
        _disableInitializers();
    }

    function initialize(address _owner, address _tokenAddress, address _usdtAddress, address _redemptionPool) public initializer {
        __Ownable_init(_owner);

        token = IERC20(_tokenAddress);
        usdt = IERC20(_usdtAddress);
        redemptionPool = _redemptionPool;
    }

    function purchaseTokenWithUSDT(uint256 tokenAmount) external {
        require(token.balanceOf(address(this)) >= tokenAmount, "Trade.purchaseTokenByUSDT: token pool storage not enough");

        uint256 usdtAmount = tokenAmount / 10;
        require(
            usdt.allowance(msg.sender, address(this)) >= usdtAmount && usdt.balanceOf(msg.sender) >= usdtAmount,
            "Trade.purchaseTokenByUSDT: balance or allowance not enough"
        );

        totalReceivedUSDTAmount += usdtAmount;
        totalSoldTokenAmount += tokenAmount;

        usdt.safeTransferFrom(msg.sender, address(redemptionPool), usdtAmount);
        token.safeTransfer(msg.sender, tokenAmount);

        emit TokenPurchased(msg.sender, usdtAmount, tokenAmount);
    }

    function purchaseTokenByUSDT(uint256 usdtAmount) external {
        require(
            usdt.allowance(msg.sender, address(this)) >= usdtAmount && usdt.balanceOf(msg.sender) >= usdtAmount,
            "Trade.purchaseTokenByUSDT: balance or allowance not enough"
        );

        // 1 USDT = 10 CXC token
        uint256 tokenAmount = usdtAmount * 10;
        require(token.balanceOf(address(this)) >= tokenAmount, "Trade.purchaseTokenByUSDT: token pool storage not enough");

        totalReceivedUSDTAmount += usdtAmount;
        totalSoldTokenAmount += tokenAmount;

        usdt.safeTransferFrom(msg.sender, address(redemptionPool), usdtAmount);
        token.safeTransfer(msg.sender, tokenAmount);

        emit TokenPurchased(msg.sender, usdtAmount, tokenAmount);
    }

    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getTotalSoldTokenAmount() public view returns (uint256) {
        return totalSoldTokenAmount;
    }

    function getTotalReceivedUSDTAmount() public view returns (uint256) {
        return totalReceivedUSDTAmount;
    }
}
